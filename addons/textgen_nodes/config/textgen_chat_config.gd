extends Resource
class_name TextgenChatConfig

@export var instruction_template: String
@export var stream: bool = false
@export var generation_config: TextgenGenerationConfig

func to_dict() -> Dictionary:
	var params:=generation_config.to_dict()
	params.merge({
		"instruction_template": instruction_template,
		"stream": stream
	})
	return params
