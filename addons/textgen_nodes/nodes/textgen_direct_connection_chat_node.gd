extends Node
class_name TextgenDirectConnectionChatNode

var _system_message: TextgenAPI.ChatMessage = null
var _messages: Array[TextgenAPI.ChatMessage] = []

@export var chat_config: TextgenChatConfig

@onready var internal_api:=TextgenAPI.InternalAPI.new()

signal new_chunk(token: String)
signal finished

var _thread:=Thread.new()
var _chat_completion:=TextgenAPI.ChatCompletion.new()

func _ready():
	pass

func _process_text_generation():
	var messages:=_messages
	if _system_message:
		messages.push_front(_system_message)

	var response:=_chat_completion.create(
		TextgenAPI.ChatMessage.array_to_dict(messages),
		chat_config.to_dict())

	var full_text:=""
	var chat_response:=TextgenAPI.SimpleChatResponse.new(response)
	for chunk_text in chat_response:
		full_text+=chunk_text
		call_deferred("emit_signal", "new_chunk", chunk_text)

	_messages.push_back(TextgenAPI.ChatMessage.create(TextgenAPI.ChatMessage.Role.ASSISTANT, full_text))
	call_deferred("emit_signal", "finished")

func send_message(message: String):
	if _thread.is_started():
		_thread.wait_to_finish()

	_messages.push_back(TextgenAPI.ChatMessage.create(TextgenAPI.ChatMessage.Role.USER, message))
	_thread.start(_process_text_generation)

func add_message(message: TextgenAPI.ChatMessage):
	_messages.push_back(message)

func clear():
	_messages.clear()

func get_messages() -> Array[TextgenAPI.ChatMessage]:
	return _messages

func stop():
	internal_api.stop_generation()
