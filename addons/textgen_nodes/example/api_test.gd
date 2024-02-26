extends Node2D


var full_response:=""

func _low_level_api():
	var chat_completion:=TextgenAPI.ChatCompletion.new("")
	var input_text:="Hey"
	var messages:Array[TextgenAPI.ChatMessage]=[TextgenAPI.ChatMessage.create(TextgenAPI.ChatMessage.Role.USER, input_text)]
	var config:=TextgenChatConfig.new()
	config.instruction_template="ChatML"
	config.generation_config=TextgenGenerationConfig.new()
	config.stream=true

	var full_string:=""
	var response_completion:=chat_completion.create(TextgenAPI.ChatMessage.array_to_dict(messages), config.to_dict())
	assert(response_completion.connected)

	## Simple wrapper which just gives you the chunk content if you don't need the metadata
	var simple_response:=TextgenAPI.SimpleChatResponse.new(response_completion)
	for text_chunk in simple_response:
		full_string+=text_chunk

	print("\n", full_string)

func _high_level_api():
	var simple_chat_config:=TextgenAPI.SimpleChatConfig.new()
	simple_chat_config.stream=true
	simple_chat_config.instruction_template="ChatML"
	simple_chat_config.temperature=0.8
	var simple_chat:=TextgenAPI.SimpleChat.new(simple_chat_config)

	for i in simple_chat.send_message("Write a poem about cats!"):
		print(i)


func _textgen_node():
	$TextgenChatNode.send_message("Write a haiku about Ikarus, but ikarus is a penguin.")

# Called when the node enters the scene tree for the first time.
func _ready():
	_low_level_api()
	_high_level_api()
	_textgen_node()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_textgen_chat_node_new_chunk(token):
	full_response+=token

func _on_textgen_chat_node_chat_response(text):
	print(text)
