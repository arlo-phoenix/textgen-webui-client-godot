extends Node

@export var chat_config: TextgenChatConfig
@onready var internal_api:=TextgenAPI.InternalAPI.new()

## Signal for streaming response
signal new_chunk(token: String)

## Signal for stream and non stream response. Sent after request is done.
signal chat_response(response: String)

## Only used internally for queue
class ServerRequest:
	func _init(messages: Array[TextgenAPI.ChatMessage], chat_response_callback: Callable,
		new_chunk_callback: Callable, custom_config: TextgenChatConfig=null):
		self.messages=messages
		self.chat_response_callback=chat_response_callback
		self.new_chunk_callback=new_chunk_callback
		self.custom_config=custom_config

	var messages: Array[TextgenAPI.ChatMessage]
	var custom_config: TextgenChatConfig
	var chat_response_callback: Callable
	var new_chunk_callback: Callable

var _thread:=Thread.new()
var _chat_completion:=TextgenAPI.ChatCompletion.new()

## FIFO queue for handling requests from nodes
var _request_queue: Array[ServerRequest] = []
var _queue_mutex: Mutex = Mutex.new()

func _exit_tree():
	stop()

#region stupid utility methods
# why tf is there seemingly no good way to do this
func _connect_signal_deferred(server_signal: Signal, target: Callable):
	call_deferred("connect", server_signal.get_name(), target, CONNECT_DEFERRED)

func _disconnect_signal_deferred(server_signal: Signal, target: Callable):
	call_deferred("disconnect", server_signal.get_name(), target)

func _emit_signal_deferred(server_signal: Signal, text: String):
	call_deferred("emit_signal", server_signal.get_name(), text)
#endregion

#region thread methods
func _process_request(request: ServerRequest):
	var request_config:TextgenChatConfig=chat_config if request.custom_config == null else request.custom_config
	var stream:=request_config.stream
	_connect_signal_deferred(chat_response, request.chat_response_callback)
	if stream:
		_connect_signal_deferred(new_chunk, request.new_chunk_callback)

	var response:=_chat_completion.create(
		TextgenAPI.ChatMessage.array_to_dict(request.messages),
		request_config.to_dict())
	var text_response:=TextgenAPI.SimpleChatResponse.new(response)

	var full_text:=""
	for chunk_text in text_response:
		if chunk_text.is_empty():
			continue
		full_text+=chunk_text
		if stream:
			_emit_signal_deferred(new_chunk, chunk_text)

	_emit_signal_deferred(chat_response, full_text)
	_disconnect_signal_deferred(chat_response, request.chat_response_callback)
	if stream:
		_disconnect_signal_deferred(new_chunk, request.new_chunk_callback)

## Runs until no requests left in queue
func _process_text_generation():
	while true:
		_queue_mutex.lock()
		if _request_queue.is_empty():
			_queue_mutex.unlock()
			break
		var request:=_request_queue.pop_front()
		_queue_mutex.unlock()
		_process_request(request)
#endregion


#region Server methods
## [param target]: Target which will receive signals
## [param messages]: messsages
## [param custom_config]: Keep at null to use global server config
func create_completions(messages: Array[TextgenAPI.ChatMessage], chat_response_callback: Callable, new_chunk_callback: Callable=Callable(), custom_config: TextgenChatConfig=null):
	_queue_mutex.lock()
	_request_queue.push_back(ServerRequest.new(messages, chat_response_callback, new_chunk_callback, custom_config))
	if not _thread.is_alive():
		if _thread.is_started():
			#for some reason even if not alive need to properly finish it
			_thread.wait_to_finish()
		_thread.start(_process_text_generation)
	_queue_mutex.unlock()

## Just for textgeneration webui for now
func stop():
	internal_api.stop_generation()
#endregion
