class_name SaveCodec
extends RefCounted

func encode_state(payload: Dictionary) -> Dictionary:
	return payload.duplicate(true)


func decode_state(payload: Dictionary) -> Dictionary:
	return payload.duplicate(true)
