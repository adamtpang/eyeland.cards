extends Button
var accepts: Callable
var dropped: Callable
func _can_drop_data(_at: Vector2,data: Variant) -> bool:
	return accepts.is_valid() and accepts.call(data)
func _drop_data(_at: Vector2,data: Variant):
	if dropped.is_valid(): dropped.call(data)
