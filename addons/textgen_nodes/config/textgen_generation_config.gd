extends Resource
class_name TextgenGenerationConfig

## if 0 using auto_max_new_tokens
@export var max_new_tokens: int = 0
## if 0 using shared setting
@export var truncation_length: int = 0
@export var custom_stopping_strings: PackedStringArray = []

func to_dict() -> Dictionary:
	return {
		"max_new_tokens": max_new_tokens,
		"stop": custom_stopping_strings,
		"truncation_length": truncation_length
	}
