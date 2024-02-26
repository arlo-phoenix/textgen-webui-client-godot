@tool
extends EditorPlugin

const TEXTGEN_SERVER_NAME = "TextgenServer"

func _enter_tree():
	add_autoload_singleton(TEXTGEN_SERVER_NAME, "res://addons/textgen_nodes/servers/textgen_server.tscn")

func _exit_tree():
	remove_autoload_singleton(TEXTGEN_SERVER_NAME)
