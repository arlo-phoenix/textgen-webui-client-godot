extends Node
class_name TextgenChatNode

var _system_message: TextgenAPI.ChatMessage = null
var _messages: Array[TextgenAPI.ChatMessage] = []

## if not set uses global server config
@export var custom_chat_config: TextgenChatConfig

signal new_chunk(token: String)
signal chat_response(text: String)

var _processing: bool = false

func _handle_server_chat_response(full_text: String):
	_messages.push_back(TextgenAPI.ChatMessage.create(TextgenAPI.ChatMessage.Role.ASSISTANT, full_text))
	_processing=false

	chat_response.emit(full_text)

## Just passes signal from server on
func _handle_server_new_chunk(token: String):
	new_chunk.emit(token)

## Add new message and request server completions
func send_message(message: String):
	assert(!_processing)
	_processing=true
	_messages.push_back(TextgenAPI.ChatMessage.create(TextgenAPI.ChatMessage.Role.USER, message))
	TextgenServer.create_completions(_messages, _handle_server_chat_response,
		_handle_server_new_chunk, custom_chat_config)

func add_message(message: TextgenAPI.ChatMessage):
	_messages.push_back(message)

func clear():
	_messages.clear()

func get_messages() -> Array[TextgenAPI.ChatMessage]:
	return _messages

func stop():
	TextgenServer.stop()
