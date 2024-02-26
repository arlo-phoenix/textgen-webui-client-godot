extends Object
class_name TextgenClient


class SimpleChatClient:
	var _messages: Array[TextgenAPI.ChatMessage]=[]
	static var _non_stream_chat_config: TextgenChatConfig

	signal chat_response(text: String)
	signal new_chunk(text: String)

	func _propagate_chat_response(text: String):
		chat_response.emit(text)
	func _propagate_new_chunk(text: String):
		new_chunk.emit(text)

	func send_message(message: String) -> void:
		_messages.push_back(TextgenAPI.ChatMessage.create(TextgenAPI.ChatMessage.Role.USER, message))
		TextgenServer.create_completions(_messages, _propagate_chat_response, _propagate_new_chunk)

class SimpleBlockingChatClient:
	var _async_client=SimpleChatClient.new()

	func send_message(message: String) -> String:
		_async_client.send_message(message)
		return await _async_client.chat_response

