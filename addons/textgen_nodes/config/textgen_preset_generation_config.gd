extends TextgenGenerationConfig
class_name TextgenPresetGenerationConfig

## preset name that exists in webui
@export var preset: String = ""

func to_dict() -> Dictionary:
	var ret:=super.to_dict()
	ret["preset"]=preset
	return ret
