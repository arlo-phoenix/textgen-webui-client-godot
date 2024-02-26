extends Object
class_name TextgenAPI

class ConnectionData:
	static var HOST_URL = "http://127.0.0.1"
	static var HOST_PORT=5000

class TextgenRequest:

	var _api_key: String
	var headers=[
		"Content-Type: application/json"
	]

	var http = HTTPClient.new()

	func _init(api_key: String):
		self._api_key=api_key
		headers.push_back("Authorization: Bearer %s" % _api_key)
		connect_http()


	func connect_http() -> Error:
		var err := http.connect_to_host(ConnectionData.HOST_URL, ConnectionData.HOST_PORT) # Connect to host/port.
		if err != OK:
			return err

		# Wait until resolved and connected.
		while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
			http.poll()
			print("Connecting...")
			if not OS.has_feature("web"):
				OS.delay_msec(500)
			else:
				Engine.get_main_loop()

		return OK if http.get_status() == HTTPClient.STATUS_CONNECTED else ERR_CANT_CONNECT

class TextgenResponse:
	var ENDPOINT
	const END_TOKEN="[DONE]"
	var http: HTTPClient
	var json=JSON.new()
	#FIFO storage for read chunks
	var chunks=[]
	var end_message: String
	var response_code
	var connected: bool
	var stream_response: bool


	func _init(http: HTTPClient, request_data: Dictionary, headers: PackedStringArray):
		self.http=http
		self.stream_response=request_data["stream"]
		var err:=http.request(HTTPClient.METHOD_POST, ENDPOINT,
			headers, JSON.stringify(request_data))
		if err != OK:
			printerr("Error %s. Couldn't request response for %s." % [ENDPOINT, headers])
			return
		while http.get_status() == HTTPClient.STATUS_REQUESTING:
			http.poll()

		if http.get_status() not in [HTTPClient.STATUS_BODY, HTTPClient.STATUS_CONNECTED]:
			printerr("Request failed (no response).")
			connected=false
			response_code=0 #this means no response
			return

		if http.has_response():
			connected=true
			response_code=http.get_response_code()

	func should_continue():
		return len(chunks)>=0 or http.get_status()==HTTPClient.STATUS_BODY

	func read_chunk() -> bool:
		while http.get_status()==HTTPClient.STATUS_BODY:
			http.poll()
			var chunk := http.read_response_body_chunk()
			if chunk.size() == 0:
				if not OS.has_feature("web"):
					# Got nothing, wait for buffers to fill a bit.
					OS.delay_usec(1000)
				else:
					Engine.get_main_loop()
			else:
				#sometimes might load two chunks together
				var chunk_text:=chunk.get_string_from_utf8()
				if chunk_text[0]==":":
					#commands like ping, format is : ping - datetime
					#don't really know why they exist
					return read_chunk()

				var chunk_data=chunk_text.substr(6) if stream_response else chunk_text
				if chunk_data==END_TOKEN:
					#TODO: this probably isn't used anymore
					end_message=chunk_text
				elif String(chunk_data).length():
					chunks.append(chunk_data)

				return true
		return false

	func _iter_init(_arg):
		if not connected:
			return false
		read_chunk()
		return should_continue()

	func _iter_next(_arg):
		if chunks.is_empty():
			if !read_chunk():
				return false
		return true

	func _iter_get(_arg) -> Dictionary:
		var chunk_text: String=chunks[0]
		chunks.remove_at(0)
		var err:=json.parse(chunk_text)
		if err == OK:
			return json.data
		else:
			printerr("Chunk not json parseable ", chunk_text, " of length ", chunk_text.length())
			return {}


class ChatCompletionReponse extends TextgenResponse:
	func _init(http: HTTPClient, request_data: Dictionary, headers: PackedStringArray) -> void:
		ENDPOINT="/v1/chat/completions"
		super._init(http, request_data, headers)


class ChatCompletion extends TextgenRequest:
	func _init(api_key: String = ""):
		super._init(api_key)

	func create(messages: Array, params: Dictionary={}) -> ChatCompletionReponse:
		http.poll()
		if http.get_status() != HTTPClient.STATUS_CONNECTED:
			connect_http()

		var request_data := {
		"messages": messages,
		}
		request_data.merge(params)

		return ChatCompletionReponse.new(http, request_data, headers)


class ChatMessage:
	enum Role{
		SYSTEM=0,
		USER=1,
		ASSISTANT=2
	}

	var content: String
	var role: Role

	static func create(role: ChatMessage.Role, content: String) -> ChatMessage:
		var chat_message:=ChatMessage.new()
		chat_message.content=content
		chat_message.role=role
		return chat_message

	## allows converting a simple dictionary of the form {"content": "", role": <see enum>}
	static func from_dict(dict: Dictionary):
		return create(dict["role"], dict["content"])

	func to_dict() -> Dictionary:
		var role_str: String
		match role:
			ChatMessage.Role.SYSTEM:
				role_str="system"
			ChatMessage.Role.USER:
				role_str="user"
			ChatMessage.Role.ASSISTANT:
				role_str="assistant"
		return {"role": role_str, "content": content}

	static func array_to_dict(messages: Array[ChatMessage]) -> Array:
		var json_messages:=Array()
		json_messages.resize(messages.size())
		for i in range(messages.size()):
			json_messages[i]=messages[i].to_dict()
		return json_messages


class SimpleChatConfig:
	var instruction_template: String
	var temperature: float = 0.7
	var stream: bool = false

	func to_dict()->Dictionary:
		return {
			"instruction_template": instruction_template,
			"temperature": temperature,
			"stream": stream
		}

## Wrapper which has a helpful completed signal for SimpleChat to auto add messages
## Also changes iter_get to actually return string to not have to work with dictionary
class SimpleChatResponse:
	var _response: ChatCompletionReponse
	var _full_response: String = ""

	signal completed(full_response: String)

	func _init(response: ChatCompletionReponse):
		_response=response

	func _iter_init(_arg):
		if _response._iter_init(_arg):
			return true
		else:
			completed.emit(_full_response)
			return false

	func _iter_next(_arg):
		if _response._iter_next(_arg):
				return true
		else:
			completed.emit(_full_response)
			return false

	func _iter_get(_arg) -> String:
		var chunk_json:Dictionary=_response._iter_get(_arg)
		if chunk_json["object"] != "chat.completions.chunk":
			return ""

		var message_key:="message"
		if not chunk_json["choices"][0].has(message_key):
			message_key="delta" #streaming responses use delta and not message

		var chunk_text:String=chunk_json["choices"][0][message_key]["content"]
		_full_response+=chunk_text
		return chunk_text

	## just gets full_response
	func get_text() -> String:
		# causes things to process
		#need to do something or else for loop might get optimized out
		var num_responses:=0
		for i in self:
			num_responses+=1
		return _full_response

class SimpleChat:
	var _config: SimpleChatConfig
	## public since sometimes maybe want to change individual messages
	var messages: Array[ChatMessage]=[]
	var _chat_request:=ChatCompletion.new()
	var _waiting_for_response:=false

	func _init(config: SimpleChatConfig):
		self._config=config

	static func create(config: SimpleChatConfig, system_message: String="") -> SimpleChat:
		var new_chat=SimpleChat.new(config)

		var system_message_object:=ChatMessage.create(ChatMessage.Role.SYSTEM, system_message)
		new_chat.add_message(system_message_object)
		return new_chat

	## adds user message to messages and requests bot response
	## also automatically adds the response at end to message queue
	func send_message(user_message: String) -> SimpleChatResponse:
		if _waiting_for_response:
			printerr("Still waiting for response to finish. Can't send new message in the meantime")
			return

		add_message(ChatMessage.create(ChatMessage.Role.USER, user_message))
		var api_response:= _chat_request.create(ChatMessage.array_to_dict(messages), _config.to_dict())

		var chat_response:=SimpleChatResponse.new(api_response)
		chat_response.completed.connect(_handle_assistant_response)
		_waiting_for_response=true
		return chat_response

	func _handle_assistant_response(response: String):
		add_message(ChatMessage.create(ChatMessage.Role.ASSISTANT, response))
		_waiting_for_response=false

	func add_message(message: ChatMessage) -> void:
		messages.push_back(message)

	func is_ready() -> bool:
		return !_waiting_for_response


class InternalAPI:
	var json_api: SimpleJsonApi

	func _init():
		json_api=SimpleJsonApi.new(ConnectionData.HOST_URL, ConnectionData.HOST_PORT)

	## Contains model name and lora_names
	func model_info() -> Dictionary:
		return json_api.request(HTTPClient.METHOD_GET, "/v1/internal/model/info")

	func model_list() -> PackedStringArray:
		return json_api.request(HTTPClient.METHOD_GET, "/v1/internal/model/list")["model_names"]

	func load_model(model_name: String, args: Dictionary={}, settings: Dictionary={}):
		var request_body:={
			"model_name": model_name,
			"args": args,
			"settings": settings
		}
		json_api.request(HTTPClient.METHOD_POST, "/v1/internal/model/load", [], request_body, true)

	func unload_model() -> void:
		json_api.request(HTTPClient.METHOD_POST, "/v1/internal/model/unload", [], {}, true)

	func stop_generation() -> void:
		json_api.request(HTTPClient.METHOD_POST, "/v1/internal/stop-generation", [], {}, true)
