class_name RoomAtmosphere
extends Node3D

## Animações de atmosfera: flicker de fluorescente, pulso da luz de
## emergência e poeira em suspensão. Puramente visual — nenhum estado
## de gameplay depende destes nós.

var flicker_light: Light3D
var flicker_material: StandardMaterial3D
var flicker_energy := 1.0
var pulse_light: OmniLight3D
var pulse_material: StandardMaterial3D
var pulse_energy := 0.35

var _time := 0.0
var _flicker_timer := 0.0
var _flicker_state := 1.0
var _flicker_target := 1.0
var _rng := RandomNumberGenerator.new()


func setup(p_flicker_light: Light3D, p_flicker_material: StandardMaterial3D, p_pulse_light: OmniLight3D, p_pulse_material: StandardMaterial3D) -> void:
	flicker_light = p_flicker_light
	flicker_material = p_flicker_material
	pulse_light = p_pulse_light
	pulse_material = p_pulse_material
	if flicker_light != null:
		flicker_energy = flicker_light.light_energy
	_rng.randomize()


func _process(delta: float) -> void:
	_time += delta
	_update_flicker(delta)
	_update_emergency_pulse()


func _update_flicker(delta: float) -> void:
	if flicker_light == null:
		return
	_flicker_timer -= delta
	if _flicker_timer <= 0.0:
		# Maioria do tempo estável; de vez em quando entra em crise elétrica.
		if _rng.randf() < 0.72:
			_flicker_target = _rng.randf_range(0.88, 1.0)
			_flicker_timer = _rng.randf_range(1.2, 4.5)
		else:
			_flicker_target = _rng.randf_range(0.05, 0.55)
			_flicker_timer = _rng.randf_range(0.08, 0.5)
	_flicker_state = lerpf(_flicker_state, _flicker_target, clampf(delta * 26.0, 0.0, 1.0))
	# Micro-tremor permanente de reator antigo.
	var tremor := 1.0 + sin(_time * 97.0) * 0.018 + sin(_time * 31.7) * 0.012
	var level := flicker_energy * _flicker_state * tremor
	flicker_light.light_energy = level
	if flicker_material != null:
		flicker_material.emission_energy_multiplier = clampf(level / maxf(flicker_energy, 0.001), 0.0, 2.5) * _base_panel_energy()


func _base_panel_energy() -> float:
	return 1.6


func _update_emergency_pulse() -> void:
	if pulse_light == null:
		return
	var wave := 0.5 + 0.5 * sin(_time * 2.2)
	var level := pulse_energy * (0.25 + 0.75 * wave * wave)
	pulse_light.light_energy = level
	if pulse_material != null:
		pulse_material.emission_energy_multiplier = 0.35 + 1.45 * wave * wave


## Poeira em suspensão: partículas CPU (compatíveis com qualquer renderer).
func add_dust(area_center: Vector3, area_extents: Vector3, amount: int) -> void:
	var particles := CPUParticles3D.new()
	particles.name = "Dust_%d" % get_child_count()
	particles.position = area_center
	particles.amount = amount
	particles.lifetime = 9.0
	particles.preprocess = 8.0
	particles.randomness = 0.9
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = area_extents
	particles.gravity = Vector3.ZERO
	particles.initial_velocity_min = 0.008
	particles.initial_velocity_max = 0.05
	particles.direction = Vector3(0.0, 0.06, 0.0)
	particles.spread = 180.0
	particles.scale_amount_min = 0.4
	particles.scale_amount_max = 1.4
	particles.angular_velocity_min = -4.0
	particles.angular_velocity_max = 4.0

	var quad := QuadMesh.new()
	quad.size = Vector2(0.02, 0.02)
	var dust_material := StandardMaterial3D.new()
	dust_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_material.albedo_color = Color(0.72, 0.78, 0.75, 0.16)
	dust_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust_material.disable_receive_shadows = true
	quad.material = dust_material
	particles.mesh = quad
	add_child(particles)
