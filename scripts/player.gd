extends CharacterBody3D

@export var walk_speed := 3.2
@export var mouse_sensitivity := 0.0022
@export var acceleration := 12.0
@export var deceleration := 16.0
@export var head_bob_amplitude := 0.026
@export var head_bob_frequency := 1.9

@onready var head: Node3D = $Head

var gravity: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
var pitch := 0.0
var head_bob_time := 0.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clamp(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-78.0), deg_to_rad(78.0))
		head.rotation.x = pitch
	elif event is InputEventMouseButton and event.pressed:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = -0.1

	var input_vector := Vector2.ZERO
	if Input.is_key_pressed(KEY_A):
		input_vector.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input_vector.x += 1.0
	if Input.is_key_pressed(KEY_W):
		input_vector.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input_vector.y += 1.0
	input_vector = input_vector.normalized()

	var direction := (transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)).normalized()
	var target_speed := walk_speed
	if direction != Vector3.ZERO:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, deceleration * delta)

	move_and_slide()
	_apply_head_bob(delta)


func _apply_head_bob(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var intensity := clampf(horizontal_speed / walk_speed, 0.0, 1.0)
	if is_on_floor() and intensity > 0.05:
		head_bob_time += delta * head_bob_frequency * intensity
		head.position.y = 1.6 + sin(head_bob_time * TAU) * head_bob_amplitude * intensity
		head.position.x = sin(head_bob_time * TAU * 0.5) * head_bob_amplitude * 0.35 * intensity
	else:
		head_bob_time = 0.0
		head.position.y = lerpf(head.position.y, 1.6, clampf(delta * 8.0, 0.0, 1.0))
		head.position.x = lerpf(head.position.x, 0.0, clampf(delta * 8.0, 0.0, 1.0))
