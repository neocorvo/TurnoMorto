extends Node3D

@export var open_angle := -90.0
@export var animation_time := 0.65

var is_open := false
var is_moving := false


func interact() -> void:
	if is_moving:
		return

	is_open = not is_open
	is_moving = true
	var target_angle := deg_to_rad(open_angle if is_open else 0.0)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", target_angle, animation_time)
	tween.finished.connect(_on_animation_finished)


func close() -> void:
	if is_open and not is_moving:
		interact()


func _on_animation_finished() -> void:
	is_moving = false
