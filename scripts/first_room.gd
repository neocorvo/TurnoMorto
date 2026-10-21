extends Node3D


@onready var player: CharacterBody3D = $Player
@onready var door: Node3D = $Door
@onready var manager: InspectionManager = $InspectionManager
@onready var camera: Camera3D = $Player/Head/Camera3D
@onready var time_label: Label = $HUDLayer/HUD/TimeLabel
@onready var phase_label: Label = $HUDLayer/HUD/PhaseLabel
@onready var status_label: Label = $HUDLayer/HUD/StatusLabel
@onready var photo_status_label: Label = $HUDLayer/HUD/PhotoStatusLabel
@onready var report_label: Label = $HUDLayer/HUD/ReportLabel
@onready var hint_label: Label = $HUDLayer/HUD/HintLabel

var status_message := "Inspeção pronta. Consulte o protocolo antes de sair."
var status_until: float = 0.0
var report_console_position := Vector3(3.25, 0.0, 2.25)
var target_body: StaticBody3D
var protocol_body: StaticBody3D
var anomaly_label: Label3D
var clock_label: Label3D
var last_visual_hour: int = -1
var protocol_overlay: CanvasLayer
var protocol_open := false

var atmosphere: RoomAtmosphere
var flicker_light: SpotLight3D
var flicker_panel_material: StandardMaterial3D
var emergency_light: OmniLight3D
var emergency_material: StandardMaterial3D
var viewfinder: ViewfinderFrame
var flash_rect: ColorRect

var floor_material: StandardMaterial3D
var corridor_floor_material: StandardMaterial3D
var wall_material: StandardMaterial3D
var wall_lower_material: StandardMaterial3D
var ceiling_material: StandardMaterial3D
var ceiling_panel_material: StandardMaterial3D
var metal_material: StandardMaterial3D
var steel_dark_material: StandardMaterial3D
var drawer_material: StandardMaterial3D
var unit_material: StandardMaterial3D
var trim_material: StandardMaterial3D
var sheet_material: StandardMaterial3D
var glass_material: StandardMaterial3D
var rubber_material: StandardMaterial3D
var plastic_material: StandardMaterial3D
var screen_material: StandardMaterial3D
var monitor_screen_material: StandardMaterial3D
var light_material: StandardMaterial3D
var warning_material: StandardMaterial3D
var paper_material: StandardMaterial3D
var form_paper_material: StandardMaterial3D
var ink_material: StandardMaterial3D
var stamp_material: StandardMaterial3D
var joint_material: StandardMaterial3D
var stain_material: StandardMaterial3D
var scuff_material: StandardMaterial3D
var bag_material: StandardMaterial3D


func _ready() -> void:
	_create_materials()
	_build_room_and_corridor()
	_override_door_materials()
	_create_atmosphere()
	_create_screen_effects()
	_create_protocol_overlay()
	_update_anomaly_visual()
	status_label.visible = false
	photo_status_label.visible = false
	report_label.visible = false
	status_message = manager.last_result_message


func _process(_delta: float) -> void:
	if manager.is_exploring() and player.global_position.z < -0.2:
		manager.mark_environment_visited()

	_update_clock_and_phase()
	_update_photo_hint()

	if status_until > 0.0 and Time.get_ticks_msec() / 1000.0 > status_until:
		status_message = manager.last_result_message
		status_until = 0.0
		if not manager.is_complete():
			status_label.visible = false
	status_label.text = status_message


func _update_clock_and_phase() -> void:
	time_label.text = "%02d:00" % manager.current_hour
	phase_label.text = manager.phase_text()
	if clock_label != null:
		clock_label.text = "%02d:00" % manager.current_hour
	if manager.current_hour != last_visual_hour:
		last_visual_hour = manager.current_hour
		_update_anomaly_visual()
	if manager.is_complete():
		status_label.text = "06:00 — turno encerrado. O relatório final foi aceito."
		status_label.visible = true


func _update_photo_hint() -> void:
	if protocol_open:
		hint_label.text = "E ou Esc fechar protocolo"
	else:
		hint_label.text = "WASD mover  •  mouse olhar  •  E interagir  •  F fotografar  •  Esc liberar mouse"
		if _ray_hits_protocol():
			hint_label.text = "E consultar protocolo  •  WASD mover  •  F fotografar"

	var target_framed := _ray_hits_anomaly()
	if viewfinder != null:
		viewfinder.armed = target_framed and manager.is_exploring() and manager.can_take_photo()

	if manager.is_exploring() and manager.can_take_photo():
		photo_status_label.visible = true
		if target_framed:
			photo_status_label.text = "CÂMERA: alvo válido — pressione F"
			photo_status_label.modulate = Color(0.55, 0.95, 0.78, 1.0)
		else:
			photo_status_label.text = "CÂMERA: procure uma alteração visível"
			photo_status_label.modulate = Color(0.72, 0.78, 0.75, 1.0)
	else:
		photo_status_label.visible = false
		photo_status_label.text = "CÂMERA: " + manager.photo_reason()
		photo_status_label.modulate = Color(0.55, 0.62, 0.60, 1.0)

	if manager.is_complete():
		report_label.visible = true
		report_label.text = "O turno terminou às 06:00."
	elif _near_report_console():
		report_label.visible = true
		report_label.text = "R registrar anomalia   •   N confirmar sem anomalia"
	else:
		report_label.visible = false
		report_label.text = "Volte à mesa de registro para concluir a inspeção."


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if protocol_open:
		if event.keycode == KEY_E or event.keycode == KEY_ESCAPE:
			_close_protocol()
		return
	if event.keycode == KEY_E:
		if _ray_hits_protocol():
			_open_protocol()
		else:
			_handle_door()
	elif event.keycode == KEY_F:
		_take_photo()
	elif event.keycode == KEY_R:
		_submit_anomaly()
	elif event.keycode == KEY_N:
		_submit_no_anomaly()


func _handle_door() -> void:
	if player.global_position.distance_to(door.global_position) >= 3.0:
		_set_status("A porta do setor está longe demais.", 2.0)
		return
	if manager.is_complete():
		_set_status("O turno terminou às 06:00.", 2.0)
		return
	if manager.is_ready():
		manager.begin_inspection()
		door.interact()
		_set_status(manager.last_result_message, 3.0)
		return
	door.interact()
	_set_status("Porta " + ("aberta." if door.is_open else "fechada."), 2.0)


func _take_photo() -> void:
	if not manager.can_take_photo():
		_set_status(manager.photo_reason(), 2.5)
		return
	if not _ray_hits_anomaly():
		manager.last_result_message = "Fotografia inválida: o alvo não está enquadrado."
		_set_status(manager.last_result_message, 2.5)
		return
	if manager.record_photo("drawer_M02"):
		_play_photo_flash()
		_set_status(manager.last_result_message, 4.0)


func _play_photo_flash() -> void:
	if flash_rect == null:
		return
	flash_rect.color.a = 0.85
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(flash_rect, "color:a", 0.0, 0.4)


func _submit_anomaly() -> void:
	if not _near_report_console():
		_set_status("Aproxime-se da mesa de registro na sala de segurança.", 2.5)
		return
	var accepted: bool = manager.submit_anomaly()
	_set_status(manager.last_result_message, 4.0)
	if accepted:
		door.close()
		_update_anomaly_visual()


func _submit_no_anomaly() -> void:
	if not _near_report_console():
		_set_status("Aproxime-se da mesa de registro na sala de segurança.", 2.5)
		return
	var accepted: bool = manager.submit_no_anomaly()
	_set_status(manager.last_result_message, 4.0)
	if accepted:
		door.close()
		_update_anomaly_visual()


func _near_report_console() -> bool:
	return player.global_position.distance_to(report_console_position) < 2.2 and player.global_position.z > 0.25


func _ray_hits_anomaly() -> bool:
	if target_body == null:
		return false
	var origin: Vector3 = camera.global_position
	var destination: Vector3 = origin + (-camera.global_transform.basis.z * 8.0)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit["collider"] == target_body


func _ray_hits_protocol() -> bool:
	if protocol_body == null or player.global_position.distance_to(protocol_body.global_position) > 3.2:
		return false
	var origin: Vector3 = camera.global_position
	var destination: Vector3 = origin + (-camera.global_transform.basis.z * 4.5)
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(origin, destination)
	query.exclude = [player.get_rid()]
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit["collider"] == protocol_body


func _open_protocol() -> void:
	if protocol_overlay == null:
		return
	protocol_open = true
	protocol_overlay.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _close_protocol() -> void:
	protocol_open = false
	if protocol_overlay != null:
		protocol_overlay.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _create_protocol_overlay() -> void:
	protocol_overlay = CanvasLayer.new()
	protocol_overlay.name = "ProtocolOverlay"
	protocol_overlay.layer = 30
	add_child(protocol_overlay)

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.005, 0.009, 0.01, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	protocol_overlay.add_child(backdrop)

	var paper := ColorRect.new()
	paper.name = "ProtocolPaper"
	paper.anchor_left = 0.19
	paper.anchor_top = 0.14
	paper.anchor_right = 0.81
	paper.anchor_bottom = 0.86
	paper.color = Color(0.78, 0.8, 0.74, 0.98)
	paper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	protocol_overlay.add_child(paper)

	var edge := ColorRect.new()
	edge.name = "PaperEdge"
	edge.anchor_left = 0.19
	edge.anchor_top = 0.14
	edge.anchor_right = 0.81
	edge.anchor_bottom = 0.145
	edge.color = Color(0.18, 0.25, 0.24, 1.0)
	edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	protocol_overlay.add_child(edge)

	var title := Label.new()
	title.position = Vector2(42, 38)
	title.size = Vector2(600, 42)
	title.text = "PROTOCOLO DE TURNO  /  NECROTÉRIO"
	title.add_theme_color_override("font_color", Color(0.06, 0.12, 0.12, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	paper.add_child(title)

	var rule := ColorRect.new()
	rule.position = Vector2(42, 92)
	rule.size = Vector2(600, 3)
	rule.color = Color(0.18, 0.28, 0.27, 0.8)
	paper.add_child(rule)

	var body := Label.new()
	body.position = Vector2(42, 122)
	body.size = Vector2(600, 260)
	body.text = "TURNO NOTURNO — SETOR 01\n\n1. Consulte este protocolo antes de sair da sala.\n2. Prepare ou utilize a câmera de inspeção.\n3. Entre no corredor indicado e observe cada compartimento.\n4. Registre apenas alterações realmente confirmadas.\n5. Retorne à sala de segurança para concluir o relatório.\n\nMantenha a porta fechada quando o setor não estiver em uso."
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_color_override("font_color", Color(0.08, 0.13, 0.13, 1.0))
	body.add_theme_font_size_override("font_size", 17)
	paper.add_child(body)

	var footer := Label.new()
	footer.position = Vector2(42, 438)
	footer.size = Vector2(600, 34)
	footer.text = "DOCUMENTO DE USO INTERNO  •  Pressione E ou Esc para fechar"
	footer.add_theme_color_override("font_color", Color(0.16, 0.25, 0.24, 0.9))
	footer.add_theme_font_size_override("font_size", 13)
	paper.add_child(footer)

	protocol_overlay.visible = false


func _create_screen_effects() -> void:
	var fx_layer := CanvasLayer.new()
	fx_layer.name = "ScreenEffects"
	fx_layer.layer = 90
	add_child(fx_layer)

	var grain_rect := ColorRect.new()
	grain_rect.name = "PostFx"
	grain_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	grain_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader_material := ShaderMaterial.new()
	shader_material.shader = load("res://shaders/post_fx.gdshader")
	grain_rect.material = shader_material
	fx_layer.add_child(grain_rect)

	viewfinder = ViewfinderFrame.new()
	viewfinder.name = "ViewfinderFrame"
	viewfinder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewfinder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(viewfinder)

	flash_rect = ColorRect.new()
	flash_rect.name = "PhotoFlash"
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(0.92, 0.98, 0.95, 0.0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx_layer.add_child(flash_rect)


func _create_atmosphere() -> void:
	atmosphere = RoomAtmosphere.new()
	atmosphere.name = "Atmosphere"
	add_child(atmosphere)
	emergency_light = get_node_or_null("EmergencyLight") as OmniLight3D
	atmosphere.setup(flicker_light, flicker_panel_material, emergency_light, emergency_material)
	atmosphere.add_dust(Vector3(0.0, 1.5, -0.4), Vector3(5.4, 1.5, 3.4), 80)
	atmosphere.add_dust(Vector3(0.0, 1.5, -15.0), Vector3(2.6, 1.5, 10.4), 150)


func _update_anomaly_visual() -> void:
	if anomaly_label == null:
		return
	if manager.anomaly_active:
		anomaly_label.text = "M-07"
		anomaly_label.modulate = Color(0.95, 0.36, 0.24, 1.0)
	else:
		anomaly_label.text = "M-02"
		anomaly_label.modulate = Color(0.68, 0.78, 0.74, 1.0)


func _set_status(message: String, duration: float) -> void:
	status_message = message
	status_until = Time.get_ticks_msec() / 1000.0 + duration
	status_label.visible = true
	status_label.text = status_message


func _override_door_materials() -> void:
	var panel_mesh: MeshInstance3D = door.get_node_or_null("Panel/Mesh")
	if panel_mesh is MeshInstance3D:
		panel_mesh.material_override = ProceduralMaterials.painted_metal(Color(0.34, 0.4, 0.39), 0.4, 0.42)
	var door_glass: MeshInstance3D = door.get_node_or_null("Panel/Window")
	if door_glass is MeshInstance3D:
		door_glass.material_override = glass_material
	var door_handle: MeshInstance3D = door.get_node_or_null("Panel/Handle")
	if door_handle is MeshInstance3D:
		door_handle.material_override = ProceduralMaterials.steel(Color(0.6, 0.64, 0.62), 0.95, 0.22)
	for frame_path in ["FrameLeft", "FrameRight", "FrameTop", "Panel/WindowBar"]:
		var frame_mesh: MeshInstance3D = door.get_node_or_null(frame_path)
		if frame_mesh is MeshInstance3D:
			frame_mesh.material_override = steel_dark_material


func _create_materials() -> void:
	# Piso com PBR real (Poly Haven smooth_concrete_floor, CC0) tingido de
	# cinza frio com nuance verde; corredor mais escuro, mesma instalação.
	floor_material = ProceduralMaterials.external_pbr_floor(
		"res://assets/textures/smooth_concrete_floor/smooth_concrete_floor_diff_1k.jpg",
		"res://assets/textures/smooth_concrete_floor/smooth_concrete_floor_nor_gl_1k.jpg",
		"res://assets/textures/smooth_concrete_floor/smooth_concrete_floor_arm_1k.jpg",
		Color(0.62, 0.68, 0.655), 0.5
	)
	corridor_floor_material = ProceduralMaterials.external_pbr_floor(
		"res://assets/textures/smooth_concrete_floor/smooth_concrete_floor_diff_1k.jpg",
		"res://assets/textures/smooth_concrete_floor/smooth_concrete_floor_nor_gl_1k.jpg",
		"res://assets/textures/smooth_concrete_floor/smooth_concrete_floor_arm_1k.jpg",
		Color(0.5, 0.55, 0.535), 0.5
	)
	wall_material = ProceduralMaterials.paint(Color(0.35, 0.39, 0.38))
	wall_lower_material = ProceduralMaterials.tile_wall(Color(0.34, 0.42, 0.385))
	ceiling_material = ProceduralMaterials.paint(Color(0.13, 0.15, 0.15), 0.6)
	ceiling_panel_material = ProceduralMaterials.ceiling_panel(Color(0.44, 0.46, 0.45))
	metal_material = ProceduralMaterials.steel(Color(0.52, 0.56, 0.55), 0.9, 0.38)
	steel_dark_material = ProceduralMaterials.steel(Color(0.14, 0.16, 0.16), 0.75, 0.5)
	drawer_material = ProceduralMaterials.painted_metal(Color(0.5, 0.55, 0.52), 0.35, 0.42)
	unit_material = ProceduralMaterials.painted_metal(Color(0.42, 0.49, 0.46), 0.28, 0.5)
	trim_material = steel_dark_material
	sheet_material = ProceduralMaterials.sheet(Color(0.8, 0.82, 0.78))
	glass_material = ProceduralMaterials.glass(Color(0.1, 0.16, 0.17))
	rubber_material = ProceduralMaterials.rubber(Color(0.04, 0.045, 0.045))
	plastic_material = ProceduralMaterials.plastic(Color(0.22, 0.24, 0.23))
	screen_material = ProceduralMaterials.screen(Color(0.05, 0.2, 0.17), 1.0)
	monitor_screen_material = ProceduralMaterials.screen(Color(0.045, 0.16, 0.13), 1.6)
	light_material = ProceduralMaterials.light_panel(Color(0.72, 0.86, 0.82), 1.6)
	warning_material = ProceduralMaterials.warning_light(Color(0.5, 0.06, 0.03), 1.1)
	emergency_material = ProceduralMaterials.warning_light(Color(0.55, 0.06, 0.03), 1.3)
	paper_material = ProceduralMaterials.paper(Color(0.68, 0.69, 0.62))
	form_paper_material = ProceduralMaterials.paper(Color(0.87, 0.87, 0.815))
	ink_material = _flat_material(Color(0.08, 0.09, 0.09))
	stamp_material = _flat_material(Color(0.33, 0.08, 0.055))
	joint_material = ProceduralMaterials.plastic(Color(0.185, 0.21, 0.205), 0.8)
	stain_material = _grime_material(Color(0.05, 0.06, 0.055), 0.3, 141)
	scuff_material = _grime_material(Color(0.07, 0.08, 0.075), 0.26, 142)
	bag_material = ProceduralMaterials.glass(Color(0.55, 0.68, 0.6))
	bag_material.albedo_color.a = 0.3


static func _flat_material(albedo: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.9
	return material


## Sombra de contato falsa: disco radial suave para assentar papéis na mesa.
static func _contact_shadow_material(strength: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var gradient := Gradient.new()
	gradient.set_color(0, Color(0.0, 0.0, 0.0, strength))
	gradient.set_color(1, Color(0.0, 0.0, 0.0, 0.0))
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 128
	texture.height = 128
	material.albedo_texture = texture
	return material


static func _grime_material(tint: Color, alpha_max: float, seed_value: int) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE
	var texture := ProceduralMaterials._noise_texture(seed_value, 0.012, 3, 0.0)
	var ramp := Gradient.new()
	ramp.set_color(0, Color(tint.r, tint.g, tint.b, 0.0))
	ramp.set_color(1, Color(tint.r, tint.g, tint.b, alpha_max))
	texture.color_ramp = ramp
	material.albedo_texture = texture
	material.uv1_scale = Vector3(0.4, 0.4, 0.4)
	return material


func _build_room_and_corridor() -> void:
	# --- Casca da sala de segurança ---
	_box("Floor", Vector3(0.0, -0.1, 0.0), Vector3(12.0, 0.2, 8.0), floor_material)
	_box("Ceiling", Vector3(0.0, 3.2, 0.0), Vector3(12.0, 0.2, 8.0), ceiling_material, false)
	_box("WallLeft", Vector3(-6.0, 1.55, 0.0), Vector3(0.2, 3.3, 8.0), wall_material)
	_box("WallRight", Vector3(6.0, 1.55, 0.0), Vector3(0.2, 3.3, 8.0), wall_material)
	_box("WallFront", Vector3(0.0, 1.55, 4.0), Vector3(12.0, 3.3, 0.2), wall_material)
	_box("WallBackLeft", Vector3(-3.55, 1.55, -4.0), Vector3(4.9, 3.3, 0.2), wall_material)
	_box("WallBackRight", Vector3(3.55, 1.55, -4.0), Vector3(4.9, 3.3, 0.2), wall_material)

	# Meia-parede azulejada, trilho e rodapé sanitário curvo.
	_box("RoomLowerWallLeft", Vector3(-5.86, 0.82, 0.0), Vector3(0.08, 1.05, 7.6), wall_lower_material, false)
	_box("RoomLowerWallRight", Vector3(5.86, 0.82, 0.0), Vector3(0.08, 1.05, 7.6), wall_lower_material, false)
	_box("RoomLowerWallFront", Vector3(0.0, 0.82, 3.88), Vector3(11.6, 1.05, 0.08), wall_lower_material, false)
	_box("RoomLowerWallBackLeft", Vector3(-3.5, 0.82, -3.88), Vector3(4.8, 1.05, 0.08), wall_lower_material, false)
	_box("RoomLowerWallBackRight", Vector3(3.5, 0.82, -3.88), Vector3(4.8, 1.05, 0.08), wall_lower_material, false)
	_box("WallChairRailLeft", Vector3(-5.86, 1.38, 0.0), Vector3(0.09, 0.07, 7.6), metal_material, false)
	_box("WallChairRailRight", Vector3(5.86, 1.38, 0.0), Vector3(0.09, 0.07, 7.6), metal_material, false)
	_box("WallChairRailFront", Vector3(0.0, 1.38, 3.88), Vector3(11.6, 0.07, 0.09), metal_material, false)
	_make_cove_base([
		Vector3(-5.78, 0.055, 3.7), Vector3(-5.78, 0.055, -3.7),
		Vector3(-5.78, 0.055, -3.82), Vector3(-3.0, 0.055, -3.82),
		Vector3(3.0, 0.055, -3.82), Vector3(5.78, 0.055, -3.82),
		Vector3(5.78, 0.055, -3.7), Vector3(5.78, 0.055, 3.7),
		Vector3(5.78, 0.055, 3.82), Vector3(3.0, 0.055, 3.82),
		Vector3(-3.0, 0.055, 3.82), Vector3(-5.78, 0.055, 3.82)
	])
	_box("WallCornerLeft", Vector3(-5.87, 1.72, -3.82), Vector3(0.08, 2.0, 0.08), trim_material, false)
	_box("WallCornerRight", Vector3(5.87, 1.72, -3.82), Vector3(0.08, 2.0, 0.08), trim_material, false)
	_box("FloorDrain", Vector3(0.0, 0.025, -1.85), Vector3(0.14, 0.04, 5.55), trim_material, false)
	# Juntas de dilatação da resina, discretas.
	for joint_z in [-2.4, 1.9]:
		_box("FloorJoint", Vector3(0.0, 0.015, joint_z), Vector3(11.6, 0.02, 0.045), joint_material, false)

	# Teto modular com trilhos, grade de retorno de ar e luminárias embutidas.
	for x in [-3.0, 3.0]:
		for z in [-3.0, -1.0, 1.0, 3.0]:
			_box("CeilingPanel", Vector3(x, 3.08, z), Vector3(5.72, 0.035, 1.72), ceiling_panel_material, false)
	_box("CeilingServiceRail", Vector3(0.0, 3.055, -3.92), Vector3(11.2, 0.035, 0.08), trim_material, false)
	_box("CeilingServiceRailBack", Vector3(0.0, 3.055, 3.92), Vector3(11.2, 0.035, 0.08), trim_material, false)
	_make_ceiling_grille(Vector3(0.0, 3.03, 2.2), 0.0)

	# Manchas e marcas de uso.
	_make_stain(Vector3(1.6, 0.013, -2.2), Vector2(1.7, 1.1), 0.3)
	_make_stain(Vector3(-2.3, 0.013, 1.6), Vector2(1.2, 0.8), -0.8)
	_make_scuff(Vector3(-5.835, 0.55, -0.6), Vector2(1.1, 1.0), 90.0)

	# --- Corredor ---
	_box("CorridorFloor", Vector3(0.0, -0.1, -15.0), Vector3(6.0, 0.2, 22.0), corridor_floor_material)
	_box("CorridorCeiling", Vector3(0.0, 3.2, -15.0), Vector3(6.0, 0.2, 22.0), ceiling_material, false)
	_box("CorridorLeft", Vector3(-3.0, 1.55, -15.0), Vector3(0.2, 3.3, 22.0), wall_material)
	_box("CorridorRight", Vector3(3.0, 1.55, -15.0), Vector3(0.2, 3.3, 22.0), wall_material)
	_box("CorridorEnd", Vector3(0.0, 1.55, -26.0), Vector3(6.0, 3.3, 0.2), trim_material)
	_make_cove_base([
		Vector3(-2.78, 0.055, -4.2), Vector3(-2.78, 0.055, -25.8),
		Vector3(-2.88, 0.055, -25.8), Vector3(-2.88, 0.055, -4.3)
	])
	_make_cove_base([
		Vector3(2.78, 0.055, -4.2), Vector3(2.78, 0.055, -25.8),
		Vector3(2.88, 0.055, -25.8), Vector3(2.88, 0.055, -4.3)
	])
	for z in [-5.0, -8.5, -12.0, -15.5, -19.0, -22.5, -25.0]:
		_box("FloorSeam", Vector3(0.0, 0.015, z), Vector3(5.7, 0.025, 0.045), joint_material, false)
	for z in [-7.0, -13.0, -19.0, -24.0]:
		_make_fluorescent_fixture(Vector3(0.0, 3.02, z), z == -13.0)
	_make_corridor_door(-1.0, -4.9, "01")
	_make_corridor_door(1.0, -4.9, "02")
	_make_corridor_pipes()
	_make_ceiling_grille(Vector3(0.0, 2.55, -25.87), 90.0)
	_make_stain(Vector3(0.5, 0.013, -9.0), Vector2(1.8, 1.3), 0.7)
	_make_stain(Vector3(-1.1, 0.013, -16.2), Vector2(1.4, 0.9), 1.9)
	_make_stain(Vector3(0.2, 0.013, -23.0), Vector2(2.2, 1.5), -0.4)
	_make_scuff(Vector3(2.835, 0.5, -20.0), Vector2(1.4, 1.0), -90.0)
	_make_scuff(Vector3(-2.835, 0.45, -6.5), Vector2(0.9, 0.8), 90.0)

	for i in range(6):
		_make_mortuary_compartment(1.0, -6.2 - i * 3.1, i + 1)

	# --- Mobiliário e equipamento da sala ---
	_make_autopsy_table(Vector3(0.0, 0.0, -0.9))
	_make_iv_stand(Vector3(-1.9, 0.0, -1.1))
	_make_document_table(Vector3(3.3, 0.0, 1.2))
	_make_cabinet(Vector3(-4.8, 0.0, -2.7))
	_make_wall_shelves(Vector3(3.7, 1.45, -3.78))
	_make_instrument_cart(Vector3(1.7, 0.0, -2.1))
	_make_report_console()
	_make_surgical_lamp(Vector3(-1.65, 0.0, -1.0))
	_make_extinguisher(Vector3(-5.655, 0.0, 2.5))
	_make_wall_clock(Vector3(0.0, 2.6, 3.868))
	_make_cart(Vector3(-1.85, 0.0, -10.6))

	_box("CeilingLightA", Vector3(-2.6, 3.06, -0.9), Vector3(2.2, 0.08, 0.28), light_material, false)
	_box("CeilingLightB", Vector3(2.6, 3.06, -0.9), Vector3(2.2, 0.08, 0.28), light_material, false)
	_decoration("EmergencyIndicator", _panel_mesh(Vector3(0.05, 0.24, 0.5), 4.0), emergency_material, Vector3(5.873, 2.3, -1.8))
	_make_wheelchair(Vector3(-4.9, 0.0, 1.4))
	# Arandela de parede no canto da cadeira de rodas: legibilidade sem lavar a sala.
	_decoration("CornerWallLamp", ProceduralMeshes.rounded_box(Vector3(0.06, 0.12, 0.34), 5.0, 8), light_material, Vector3(-5.85, 2.42, 1.4))
	var corner_light := OmniLight3D.new()
	corner_light.name = "CornerWallLampLight"
	corner_light.position = Vector3(-5.7, 2.35, 1.4)
	corner_light.light_color = Color(0.68, 0.8, 0.76, 1.0)
	corner_light.light_energy = 0.5
	corner_light.omni_range = 3.0
	add_child(corner_light)


func _make_cove_base(points: PackedVector3Array) -> void:
	_decoration("CoveBase_%d" % get_child_count(), ProceduralMeshes.tube(points, 0.055, 8, false), trim_material, Vector3.ZERO)


## Cadeira de rodas real (Poly Haven wheelchair_01, CC0, escala de metro).
## Aparência fotogramétrica âncora a leitura "hospital" da sala.
func _make_wheelchair(position: Vector3) -> void:
	var wheelchair_scene: PackedScene = load("res://assets/models/wheelchair_01/wheelchair_01.gltf")
	if wheelchair_scene == null:
		push_warning("wheelchair_01.gltf indisponível; seguindo sem o modelo")
		return
	var body := StaticBody3D.new()
	body.name = "Wheelchair"
	body.position = position
	body.rotation_degrees.y = 28.0
	add_child(body)
	body.add_child(wheelchair_scene.instantiate())
	var shape := CollisionShape3D.new()
	shape.position = Vector3(0.0, 0.55, 0.0)
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 1.05, 1.15)
	shape.shape = box
	body.add_child(shape)


func _make_ceiling_grille(position: Vector3, yaw_degrees: float) -> void:
	var grille := Node3D.new()
	grille.name = "CeilingGrille"
	grille.position = position
	grille.rotation_degrees.y = yaw_degrees
	add_child(grille)
	var frame := MeshInstance3D.new()
	frame.mesh = ProceduralMeshes.rounded_box(Vector3(0.9, 0.05, 0.5), 5.0, 10)
	frame.material_override = steel_dark_material
	grille.add_child(frame)
	var slat := BoxMesh.new()
	slat.size = Vector3(0.8, 0.03, 0.045)
	for i in range(5):
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = slat
		mesh_instance.position = Vector3(0.0, -0.015, -0.16 + i * 0.08)
		mesh_instance.rotation.x = 0.5
		mesh_instance.material_override = metal_material
		grille.add_child(mesh_instance)


func _make_corridor_pipes() -> void:
	var pipe := CylinderMesh.new()
	pipe.top_radius = 0.065
	pipe.bottom_radius = 0.065
	pipe.height = 21.6
	pipe.radial_segments = 14
	pipe.cap_top = false
	pipe.cap_bottom = false
	var pipe_mesh := MeshInstance3D.new()
	pipe_mesh.name = "CorridorPipeA"
	pipe_mesh.mesh = pipe
	pipe_mesh.position = Vector3(0.85, 3.02, -15.0)
	pipe_mesh.rotation_degrees.x = 90.0
	pipe_mesh.material_override = metal_material
	add_child(pipe_mesh)

	var pipe_b := CylinderMesh.new()
	pipe_b.top_radius = 0.042
	pipe_b.bottom_radius = 0.042
	pipe_b.height = 17.8
	pipe_b.radial_segments = 12
	pipe_b.cap_top = false
	pipe_b.cap_bottom = false
	var pipe_b_mesh := MeshInstance3D.new()
	pipe_b_mesh.name = "CorridorPipeB"
	pipe_b_mesh.mesh = pipe_b
	pipe_b_mesh.position = Vector3(1.12, 2.95, -16.9)
	pipe_b_mesh.rotation_degrees.x = 90.0
	pipe_b_mesh.material_override = steel_dark_material
	add_child(pipe_b_mesh)

	for z in [-6.0, -12.0, -18.0, -24.0]:
		_box("PipeHanger", Vector3(0.85, 3.1, z), Vector3(0.05, 0.2, 0.04), steel_dark_material, false)
		_box("PipeHangerB", Vector3(1.12, 3.06, z + 1.5), Vector3(0.04, 0.18, 0.04), steel_dark_material, false)
	# Registro com volante na tubulação A.
	_decoration("PipeValveWheel", _ring_mesh(0.16, 0.028, 16), steel_dark_material, Vector3(0.85, 2.72, -12.0))
	_cylinder("PipeValveStem", Vector3(0.85, 2.85, -12.0), 0.03, 0.28, steel_dark_material, 10, false)


func _cyl_mesh(radius: float, height: float, segments: int) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = segments
	return mesh


func _ring_mesh(radius: float, thickness: float, segments: int) -> ArrayMesh:
	var points := PackedVector3Array()
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		points.append(Vector3(cos(angle) * radius, sin(angle) * radius, 0.0))
	return ProceduralMeshes.tube(points, thickness, 8, false)


func _panel_mesh(size: Vector3, sharpness: float) -> ArrayMesh:
	return ProceduralMeshes.rounded_box(size, sharpness, 12)


func _make_stain(position: Vector3, size: Vector2, yaw_degrees: float) -> void:
	var stain := MeshInstance3D.new()
	stain.name = "FloorStain_%d" % get_child_count()
	var quad := PlaneMesh.new()
	quad.size = size
	stain.mesh = quad
	stain.position = position
	stain.rotation_degrees.y = yaw_degrees
	stain.material_override = stain_material
	stain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(stain)


func _make_scuff(position: Vector3, size: Vector2, yaw_degrees: float) -> void:
	var scuff := MeshInstance3D.new()
	scuff.name = "WallScuff_%d" % get_child_count()
	var quad := PlaneMesh.new()
	quad.size = size
	scuff.mesh = quad
	scuff.position = position
	scuff.rotation_degrees.y = yaw_degrees
	scuff.material_override = scuff_material
	scuff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(scuff)


func _make_fluorescent_fixture(position: Vector3, flicker := false) -> void:
	var fixture_root := Node3D.new()
	fixture_root.name = "FluorescentFixture_Z%d" % int(round(-position.z * 10.0))
	fixture_root.position = position
	add_child(fixture_root)

	var housing := MeshInstance3D.new()
	housing.name = "Housing"
	housing.mesh = ProceduralMeshes.rounded_box(Vector3(2.5, 0.1, 0.32), 7.0, 10)
	housing.material_override = steel_dark_material
	fixture_root.add_child(housing)

	var panel_material: StandardMaterial3D = light_material
	if flicker:
		panel_material = light_material.duplicate()
		flicker_panel_material = panel_material
	var diffuser := MeshInstance3D.new()
	diffuser.name = "Diffuser"
	diffuser.mesh = ProceduralMeshes.rounded_box(Vector3(2.34, 0.055, 0.24), 5.0, 8)
	diffuser.position.y = -0.06
	diffuser.material_override = panel_material
	fixture_root.add_child(diffuser)

	for side_x in [-1.0, 1.0]:
		var stem := MeshInstance3D.new()
		stem.mesh = CylinderMesh.new()
		(stem.mesh as CylinderMesh).top_radius = 0.02
		(stem.mesh as CylinderMesh).bottom_radius = 0.02
		(stem.mesh as CylinderMesh).height = 0.16
		(stem.mesh as CylinderMesh).radial_segments = 8
		stem.position = Vector3(side_x * 1.05, 0.12, 0.0)
		stem.material_override = steel_dark_material
		fixture_root.add_child(stem)

	var light := SpotLight3D.new()
	light.name = "FluorescentSpot"
	light.position = Vector3(0.0, -0.12, 0.0)
	light.rotation_degrees.x = -90.0
	light.light_color = Color(0.72, 0.84, 0.83, 1.0)
	light.light_energy = 2.9
	light.spot_range = 7.5
	light.spot_angle = 78.0
	light.spot_angle_attenuation = 0.85
	light.spot_attenuation = 1.1
	light.shadow_enabled = true
	light.shadow_bias = 0.03
	fixture_root.add_child(light)
	if flicker:
		flicker_light = light
		light.light_energy = 2.7


func _make_corridor_door(side: float, z: float, number: String) -> void:
	var x := side * 2.87
	var door_root := Node3D.new()
	door_root.name = "IndustrialDoor" + number
	door_root.position = Vector3(x, 0.0, z)
	door_root.rotation_degrees.y = 90.0 if side > 0.0 else -90.0
	add_child(door_root)

	var leaf := MeshInstance3D.new()
	leaf.name = "Leaf"
	leaf.position = Vector3(0.0, 1.3, 0.0)
	leaf.mesh = ProceduralMeshes.rounded_box(Vector3(1.85, 2.5, 0.1), 7.0, 12)
	leaf.material_override = ProceduralMaterials.painted_metal(Color(0.36, 0.43, 0.42), 0.35, 0.45)
	door_root.add_child(leaf)

	var window := MeshInstance3D.new()
	window.name = "Window"
	window.position = Vector3(0.0, 1.78, -0.055)
	window.mesh = ProceduralMeshes.rounded_box(Vector3(0.72, 0.42, 0.05), 6.0, 8)
	window.material_override = glass_material
	door_root.add_child(window)

	_decoration("KickPlate", ProceduralMeshes.rounded_box(Vector3(1.7, 0.3, 0.035), 6.0, 8), steel_dark_material, Vector3(0.0, 0.22, -0.05))
	_decoration("PushPlate", ProceduralMeshes.rounded_box(Vector3(0.24, 0.72, 0.03), 6.0, 8), metal_material, Vector3(-0.55, 1.15, -0.065))
	_decoration("HandleBar", ProceduralMeshes.tube(PackedVector3Array([
		Vector3(0.45, 0.92, -0.1), Vector3(0.45, 1.18, -0.15), Vector3(0.45, 1.38, -0.15), Vector3(0.45, 1.64, -0.1)
	]), 0.022, 8, true), metal_material, Vector3.ZERO)
	for hinge_y in [0.35, 1.3, 2.25]:
		_decoration("Hinge_%d" % int(hinge_y * 10.0), ProceduralMeshes.rounded_box(Vector3(0.06, 0.14, 0.05), 4.0, 6), metal_material, Vector3(-0.86, hinge_y, -0.05))

	var label := _label("PORTA " + number, Vector3(x - side * 0.1, 2.32, z), 0.009, Color(0.72, 0.8, 0.76))
	label.rotation_degrees.y = 90.0 if side > 0.0 else -90.0


func _make_mortuary_compartment(side: float, z: float, number: int) -> void:
	var x := side * 2.52
	var body := _box("MorgueUnit_%02d" % number, Vector3(x, 1.35, z), Vector3(0.82, 2.7, 2.65), unit_material)
	_decoration("UnitFascia_%02d" % number, ProceduralMeshes.rounded_box(Vector3(0.88, 0.16, 2.72), 6.0, 8), steel_dark_material, Vector3(x, 2.78, z))
	_decoration("UnitKick_%02d" % number, ProceduralMeshes.rounded_box(Vector3(0.88, 0.22, 2.72), 6.0, 8), steel_dark_material, Vector3(x, 0.11, z))

	var front_x := side * 2.075
	var drawer_front := _smooth_box("DrawerFront_%02d" % number, Vector3(front_x, 1.35, z), Vector3(0.07, 2.25, 2.35), drawer_material, 8.0, 12, true)
	drawer_front.set_meta("drawer_id", "M-%02d" % number)
	if number == 2:
		target_body = drawer_front
		anomaly_label = _label("M-02", Vector3(front_x - side * 0.08, 2.12, z), 0.011, Color(0.68, 0.78, 0.74))
		anomaly_label.rotation_degrees.y = 90.0 if side > 0.0 else -90.0
	else:
		var label := _label("M-%02d" % number, Vector3(front_x - side * 0.08, 2.12, z), 0.011, Color(0.68, 0.78, 0.74))
		label.rotation_degrees.y = 90.0 if side > 0.0 else -90.0

	# Placa de identificação acima do puxador.
	_decoration("LabelPlate_%02d" % number, ProceduralMeshes.rounded_box(Vector3(0.03, 0.2, 0.52), 5.0, 8), steel_dark_material, Vector3(front_x - side * 0.045, 2.12, z))
	# Cartão de papel na gaveta inferior.
	_decoration("LabelCard_%02d" % number, ProceduralMeshes.rounded_box(Vector3(0.025, 0.17, 0.66), 5.0, 8), paper_material, Vector3(front_x - side * 0.04, 0.62, z))
	_decoration("LabelCardFrame_%02d" % number, ProceduralMeshes.rounded_box(Vector3(0.015, 0.21, 0.7), 5.0, 8), steel_dark_material, Vector3(front_x - side * 0.032, 0.62, z))

	# Dois trilhos-puxador em aço inox por gaveta.
	for y in [1.05, 1.55]:
		var pull_base := front_x - side * 0.08
		var pull_points := PackedVector3Array([
			Vector3(pull_base, y, z - 0.29), Vector3(front_x - side * 0.13, y, z - 0.29),
			Vector3(front_x - side * 0.145, y, z - 0.26), Vector3(front_x - side * 0.145, y, z),
			Vector3(front_x - side * 0.145, y, z + 0.26), Vector3(front_x - side * 0.13, y, z + 0.29),
			Vector3(pull_base, y, z + 0.29)
		])
		_decoration("DrawerPull_%02d_%d" % [number, int(y * 10.0)], ProceduralMeshes.tube(pull_points, 0.02, 8, true), metal_material, Vector3.ZERO)
		_decoration("DrawerRecess_%02d_%d" % [number, int(y * 10.0)], ProceduralMeshes.rounded_box(Vector3(0.02, 0.3, 0.72), 5.0, 8), steel_dark_material, Vector3(front_x - side * 0.02, y, z))

	# Rebites nos cantos da frente.
	for corner_z in [-1.05, 1.05]:
		for corner_y in [0.35, 2.35]:
			_decoration("Rivet_%02d_%d_%d" % [number, int(corner_y * 10.0), int(corner_z * 10.0)], ProceduralMeshes.rounded_box(Vector3(0.025, 0.05, 0.05), 3.0, 6), metal_material, Vector3(front_x - side * 0.02, corner_y, z + corner_z))


func _make_autopsy_table(position: Vector3) -> void:
	# Mesa de necropsia: bacia de aço com fundo rebaixado e borda elevada
	# contendo o lençol; estrutura inferior em perfis visíveis com pés de borracha.
	# Fundo da bacia (peça única: topo rebaixo em 0,88, base encontra o quadro).
	_smooth_box("AutopsyTableBasin", position + Vector3(0.0, 0.84, 0.0), Vector3(2.3, 0.08, 0.9), metal_material, 6.0, 8, true)
	# Borda elevada contornando a bacia (0,88 a 0,93).
	for rim_z in [-0.475, 0.475]:
		_smooth_box("AutopsyTableRim", position + Vector3(0.0, 0.905, rim_z), Vector3(2.4, 0.05, 0.05), metal_material, 6.0, 6)
	for rim_x in [-1.175, 1.175]:
		_smooth_box("AutopsyTableRimEnd", position + Vector3(rim_x, 0.905, 0.0), Vector3(0.05, 0.05, 0.90), metal_material, 6.0, 6)
	# Dreno no pé da bacia.
	_cylinder("AutopsyTableDrain", position + Vector3(-0.92, 0.8835, 0.0), 0.05, 0.012, rubber_material, 16, false)
	_decoration("AutopsyTableDrainRing", _ring_mesh(0.065, 0.01, 16), steel_dark_material, position + Vector3(-0.92, 0.8815, 0.0))
	# Estrutura: quadro sob a bacia, quatro pernas, travessas em H e pés.
	_decoration("AutopsyTableFrame", ProceduralMeshes.rounded_box(Vector3(2.0, 0.06, 0.7), 6.0, 6), steel_dark_material, position + Vector3(0.0, 0.775, 0.0))
	for leg_x in [-0.82, 0.82]:
		for leg_z in [-0.28, 0.28]:
			_smooth_box("AutopsyTableLeg", position + Vector3(leg_x, 0.42, leg_z), Vector3(0.06, 0.72, 0.06), steel_dark_material, 6.0, 6)
			_cylinder("AutopsyTableFoot", position + Vector3(leg_x, 0.0425, leg_z), 0.05, 0.025, rubber_material, 12, false)
	for stretcher_z in [-0.28, 0.28]:
		_decoration("AutopsyTableStretcher", ProceduralMeshes.rounded_box(Vector3(1.7, 0.06, 0.05), 6.0, 6), steel_dark_material, position + Vector3(0.0, 0.30, stretcher_z))
	_decoration("AutopsyTableCross", ProceduralMeshes.rounded_box(Vector3(0.05, 0.06, 0.61), 6.0, 6), steel_dark_material, position + Vector3(0.0, 0.30, 0.0))
	_make_draped_body(position)


func _make_iv_stand(position: Vector3) -> void:
	var stand := Node3D.new()
	stand.name = "IVStand"
	stand.position = position
	add_child(stand)
	for i in range(5):
		var angle := TAU * float(i) / 5.0
		var leg_points := PackedVector3Array([
			Vector3(0.0, 0.62, 0.0),
			Vector3(cos(angle) * 0.18, 0.28, sin(angle) * 0.18),
			Vector3(cos(angle) * 0.3, 0.05, sin(angle) * 0.3),
			Vector3(cos(angle) * 0.32, 0.02, sin(angle) * 0.32)
		])
		var leg := MeshInstance3D.new()
		leg.mesh = ProceduralMeshes.tube(leg_points, 0.014, 6, true)
		leg.material_override = metal_material
		stand.add_child(leg)
	var pole := MeshInstance3D.new()
	pole.mesh = CylinderMesh.new()
	(pole.mesh as CylinderMesh).top_radius = 0.016
	(pole.mesh as CylinderMesh).bottom_radius = 0.016
	(pole.mesh as CylinderMesh).height = 1.85
	(pole.mesh as CylinderMesh).radial_segments = 10
	pole.position.y = 1.24
	pole.material_override = metal_material
	stand.add_child(pole)
	var hook_points := PackedVector3Array([
		Vector3(-0.22, 2.1, 0.0), Vector3(-0.05, 2.14, 0.0), Vector3(0.1, 2.16, 0.0)
	])
	var hook := MeshInstance3D.new()
	hook.mesh = ProceduralMeshes.tube(hook_points, 0.011, 6, true)
	hook.material_override = metal_material
	stand.add_child(hook)
	_decoration("IVBag", ProceduralMeshes.rounded_box(Vector3(0.14, 0.24, 0.05), 3.5, 8), bag_material, position + Vector3(-0.22, 1.97, 0.0))
	_decoration("IVTube", ProceduralMeshes.tube(PackedVector3Array([
		position + Vector3(-0.22, 1.85, 0.02), position + Vector3(-0.12, 1.35, 0.1),
		position + Vector3(0.05, 1.05, 0.05), position + Vector3(0.15, 1.02, 0.0)
	]), 0.006, 6, false), plastic_material, Vector3.ZERO)


func _make_document_table(position: Vector3) -> void:
	var desk_light := OmniLight3D.new()
	desk_light.name = "WorktableTaskLight"
	desk_light.position = position + Vector3(0.0, 1.7, 0.05)
	desk_light.light_color = Color(0.62, 0.78, 0.68, 1.0)
	desk_light.light_energy = 0.5
	desk_light.omni_range = 3.0
	add_child(desk_light)

	# Mesa de apoio hospitalar: tampo de aço inox sobre avental e quatro
	# pernas quadradas com pés niveladores; prateleira inferior.
	_smooth_box("DeskTop", position + Vector3(0.0, 0.90, 0.0), Vector3(1.8, 0.08, 0.75), metal_material, 6.0, 8, true)
	for apron_z in [-0.315, 0.315]:
		_decoration("DeskApron", ProceduralMeshes.rounded_box(Vector3(1.66, 0.04, 0.04), 6.0, 4), steel_dark_material, position + Vector3(0.0, 0.845, apron_z))
	for apron_x in [-0.82, 0.82]:
		_decoration("DeskApronSide", ProceduralMeshes.rounded_box(Vector3(0.04, 0.04, 0.59), 6.0, 4), steel_dark_material, position + Vector3(apron_x, 0.845, 0.0))
	for leg_x in [-0.80, 0.80]:
		for leg_z in [-0.28, 0.28]:
			_smooth_box("DeskLeg", position + Vector3(leg_x, 0.46, leg_z), Vector3(0.05, 0.80, 0.05), steel_dark_material, 6.0, 6)
			_cylinder("DeskFoot", position + Vector3(leg_x, 0.0425, leg_z), 0.045, 0.025, rubber_material, 10, false)
	for stretcher_z in [-0.28, 0.28]:
		_decoration("DeskStretcher", ProceduralMeshes.rounded_box(Vector3(1.56, 0.04, 0.04), 6.0, 4), steel_dark_material, position + Vector3(0.0, 0.26, stretcher_z))
	_decoration("DeskShelf", ProceduralMeshes.rounded_box(Vector3(1.6, 0.02, 0.56), 6.0, 4), steel_dark_material, position + Vector3(0.0, 0.29, 0.0))

	# --- Documento de protocolo apoiado no tampo (contrato E preservado) ---
	protocol_body = _box("ProtocolSheet", position + Vector3(-0.32, 0.947, -0.02), Vector3(0.42, 0.015, 0.30), form_paper_material)
	protocol_body.set_meta("interaction", "protocol")

	var document := Node3D.new()
	document.name = "ProtocolDocument"
	document.position = position + Vector3(-0.32, 0.9397, -0.02)
	document.rotation_degrees.y = 3.0
	add_child(document)
	var paper_shadow := _child_mesh(document, "ProtocolContactShadow", PlaneMesh.new(), _contact_shadow_material(0.3), Vector3(0.0, 0.001, 0.0))
	(paper_shadow.mesh as PlaneMesh).size = Vector2(0.56, 0.4)
	_child_mesh(document, "ProtocolSheetBase", ProceduralMeshes.rounded_box(Vector3(0.42, 0.005, 0.30), 9.0, 6), form_paper_material, Vector3(0.0, 0.0038, 0.0))
	var top_sheet := _child_mesh(document, "ProtocolSheetTop", ProceduralMeshes.rounded_box(Vector3(0.405, 0.005, 0.285), 9.0, 6), form_paper_material, Vector3(0.005, 0.0088, 0.005))
	top_sheet.rotation_degrees.y = -5.0
	_child_mesh(top_sheet, "ProtocolTitleBlock", ProceduralMeshes.rounded_box(Vector3(0.16, 0.0015, 0.022), 9.0, 4), ink_material, Vector3(-0.02, 0.0033, -0.10))
	_child_mesh(top_sheet, "ProtocolRule", ProceduralMeshes.rounded_box(Vector3(0.30, 0.0012, 0.006), 9.0, 4), ink_material, Vector3(0.0, 0.0031, -0.065))
	_child_mesh(top_sheet, "ProtocolLine1", ProceduralMeshes.rounded_box(Vector3(0.28, 0.0012, 0.009), 9.0, 4), ink_material, Vector3(-0.01, 0.0031, -0.02))
	_child_mesh(top_sheet, "ProtocolLine2", ProceduralMeshes.rounded_box(Vector3(0.24, 0.0012, 0.009), 9.0, 4), ink_material, Vector3(-0.03, 0.0031, 0.01))
	_child_mesh(top_sheet, "ProtocolLine3", ProceduralMeshes.rounded_box(Vector3(0.27, 0.0012, 0.009), 9.0, 4), ink_material, Vector3(-0.01, 0.0031, 0.04))
	_child_mesh(top_sheet, "ProtocolSignature", ProceduralMeshes.rounded_box(Vector3(0.12, 0.0012, 0.006), 9.0, 4), ink_material, Vector3(0.09, 0.0031, 0.105))
	var stamp := _child_mesh(top_sheet, "ProtocolStamp", ProceduralMeshes.rounded_box(Vector3(0.05, 0.0015, 0.05), 9.0, 4), stamp_material, Vector3(0.11, 0.0033, 0.06))
	stamp.rotation_degrees.y = 8.0

	# Caneta apoiada sobre o próprio documento.
	_decoration("DeskPen", ProceduralMeshes.tube(PackedVector3Array([
		position + Vector3(-0.40, 0.960, 0.04), position + Vector3(-0.26, 0.960, -0.08)
	]), 0.009, 6, true), plastic_material, Vector3.ZERO)
	_decoration("DeskPenTip", ProceduralMeshes.tube(PackedVector3Array([
		position + Vector3(-0.26, 0.960, -0.08), position + Vector3(-0.225, 0.960, -0.115)
	]), 0.006, 6, true), ink_material, Vector3.ZERO)


func _make_cabinet(position: Vector3) -> void:
	_smooth_box("MorgueCabinet", position + Vector3(0.0, 1.25, 0.0), Vector3(1.6, 2.5, 0.65), unit_material, 7.0, 10, true)
	for y in [0.55, 1.15, 1.75, 2.35]:
		_smooth_box("CabinetDrawer", position + Vector3(0.0, y, -0.36), Vector3(1.4, 0.42, 0.06), drawer_material, 8.0, 8, true)
		_decoration("CabinetPull_%d" % int(y * 100.0), ProceduralMeshes.tube(PackedVector3Array([
			position + Vector3(-0.21, y, -0.41), position + Vector3(-0.21, y, -0.44),
			position + Vector3(0.0, y, -0.46), position + Vector3(0.21, y, -0.44),
			position + Vector3(0.21, y, -0.41)
		]), 0.018, 8, true), metal_material, Vector3.ZERO)


func _make_wall_shelves(position: Vector3) -> void:
	for y in [0.0, 0.58, 1.16]:
		_smooth_box("Shelf", position + Vector3(0.0, y, 0.0), Vector3(2.1, 0.1, 0.42), steel_dark_material, 7.0, 8, true)
		for bracket_x in [-0.95, 0.95]:
			var bracket := MeshInstance3D.new()
			bracket.mesh = ProceduralMeshes.tube(PackedVector3Array([
				position + Vector3(bracket_x, y - 0.32, -0.02), position + Vector3(bracket_x, y - 0.04, -0.14)
			]), 0.018, 6, true)
			bracket.material_override = metal_material
			add_child(bracket)
	for x in [-0.85, 0.0, 0.85]:
		var bottle_profile := PackedVector2Array([
			Vector2(0.0, 0.0), Vector2(0.07, 0.01), Vector2(0.075, 0.2),
			Vector2(0.035, 0.26), Vector2(0.03, 0.4), Vector2(0.035, 0.42)
		])
		_decoration("ShelfBottle_%d" % int(x * 100.0), ProceduralMeshes.lathe(bottle_profile, 14, true), glass_material, position + Vector3(x, 0.05, 0.0))


func _make_instrument_cart(position: Vector3) -> void:
	# Carrinho auxiliar tipo "mesa de Mayo": bandeja basculante de aço sobre
	# poste fino, base de quatro pernas com rodízios alinhados.
	var cart := Node3D.new()
	cart.name = "InstrumentCart"
	cart.position = position
	cart.rotation_degrees.y = -15.0
	add_child(cart)

	var body := StaticBody3D.new()
	body.name = "InstrumentCartBody"
	cart.add_child(body)
	var shape := CollisionShape3D.new()
	shape.position = Vector3(0.0, 0.5, 0.0)
	var box := BoxShape3D.new()
	box.size = Vector3(0.72, 1.0, 0.5)
	shape.shape = box
	body.add_child(shape)

	for leg_dir: Vector2 in [Vector2(1.0, 0.62), Vector2(-1.0, 0.62), Vector2(1.0, -0.62), Vector2(-1.0, -0.62)]:
		var dir := leg_dir.normalized()
		var leg_points := PackedVector3Array([
			Vector3(0.0, 0.24, 0.0),
			Vector3(dir.x * 0.14, 0.13, dir.y * 0.14),
			Vector3(dir.x * 0.27, 0.055, dir.y * 0.27)
		])
		var leg := MeshInstance3D.new()
		leg.mesh = ProceduralMeshes.tube(leg_points, 0.013, 6, true)
		leg.material_override = metal_material
		body.add_child(leg)
		var wheel := MeshInstance3D.new()
		wheel.mesh = _cyl_mesh(0.045, 0.026, 14)
		wheel.position = Vector3(dir.x * 0.30, 0.045, dir.y * 0.30)
		wheel.rotation.z = PI * 0.5
		wheel.rotation.y = atan2(dir.y, dir.x)
		wheel.material_override = rubber_material
		body.add_child(wheel)

	var post := MeshInstance3D.new()
	post.mesh = _cyl_mesh(0.022, 0.68, 12)
	post.position = Vector3(0.0, 0.58, 0.0)
	post.material_override = metal_material
	body.add_child(post)

	var pivot := Node3D.new()
	pivot.name = "TrayPivot"
	pivot.position = Vector3(0.0, 0.93, 0.0)
	pivot.rotation_degrees.x = -6.0
	body.add_child(pivot)
	_child_mesh(pivot, "CartTray", ProceduralMeshes.rounded_box(Vector3(0.66, 0.03, 0.46), 6.0, 6), metal_material, Vector3(0.0, 0.015, 0.0))
	for rim_z in [-0.215, 0.215]:
		_child_mesh(pivot, "CartTrayRim", ProceduralMeshes.rounded_box(Vector3(0.66, 0.05, 0.03), 6.0, 4), metal_material, Vector3(0.0, 0.045, rim_z))
	for rim_x in [-0.315, 0.315]:
		_child_mesh(pivot, "CartTrayRimEnd", ProceduralMeshes.rounded_box(Vector3(0.03, 0.05, 0.40), 6.0, 4), metal_material, Vector3(rim_x, 0.045, 0.0))

	# Instrumentos cenográficos apoiados no fundo da bandeja (y local 0.03).
	var barrel := _child_mesh(pivot, "SyringeBarrel", _cyl_mesh(0.011, 0.10, 12), plastic_material, Vector3(-0.16, 0.041, -0.10))
	barrel.rotation_degrees.z = 90.0
	var plunger := MeshInstance3D.new()
	plunger.mesh = ProceduralMeshes.tube(PackedVector3Array([
		Vector3(-0.21, 0.041, -0.10), Vector3(-0.245, 0.041, -0.10)
	]), 0.0035, 6, true)
	plunger.material_override = plastic_material
	pivot.add_child(plunger)
	var thumb := _child_mesh(pivot, "SyringeThumb", _cyl_mesh(0.013, 0.007, 10), plastic_material, Vector3(-0.247, 0.041, -0.10))
	thumb.rotation_degrees.z = 90.0
	var needle := MeshInstance3D.new()
	needle.mesh = ProceduralMeshes.tube(PackedVector3Array([
		Vector3(-0.11, 0.041, -0.10), Vector3(-0.072, 0.041, -0.10)
	]), 0.0022, 6, true)
	needle.material_override = metal_material
	pivot.add_child(needle)

	var scalpel_handle := _child_mesh(pivot, "CartScalpelHandle", ProceduralMeshes.rounded_box(Vector3(0.15, 0.012, 0.02), 6.0, 4), trim_material, Vector3(0.12, 0.036, -0.12))
	scalpel_handle.rotation_degrees.y = -18.0
	var scalpel_blade := _child_mesh(pivot, "CartScalpelBlade", ProceduralMeshes.rounded_box(Vector3(0.08, 0.006, 0.016), 6.0, 4), metal_material, Vector3(0.22, 0.033, -0.16))
	scalpel_blade.rotation_degrees.y = -18.0

	for tine_z in [0.10, 0.14]:
		var tine := MeshInstance3D.new()
		tine.mesh = ProceduralMeshes.tube(PackedVector3Array([
			Vector3(-0.20, 0.036, tine_z), Vector3(-0.10, 0.043, tine_z + 0.045), Vector3(-0.02, 0.036, tine_z + 0.03)
		]), 0.006, 6, false)
		tine.material_override = metal_material
		pivot.add_child(tine)

	var scissors_a := MeshInstance3D.new()
	scissors_a.mesh = ProceduralMeshes.tube(PackedVector3Array([
		Vector3(0.05, 0.036, 0.15), Vector3(0.17, 0.040, 0.08)
	]), 0.005, 6, false)
	scissors_a.material_override = metal_material
	pivot.add_child(scissors_a)
	var scissors_b := MeshInstance3D.new()
	scissors_b.mesh = ProceduralMeshes.tube(PackedVector3Array([
		Vector3(0.05, 0.036, 0.08), Vector3(0.17, 0.040, 0.15)
	]), 0.005, 6, false)
	scissors_b.material_override = metal_material
	pivot.add_child(scissors_b)
	var pivot_ring := _child_mesh(pivot, "ScissorsPivot", _ring_mesh(0.012, 0.004, 12), metal_material, Vector3(0.11, 0.040, 0.115))
	pivot_ring.rotation_degrees.x = 90.0

	_child_mesh(pivot, "CartGauze", ProceduralMeshes.rounded_box(Vector3(0.12, 0.03, 0.10), 5.0, 4), sheet_material, Vector3(-0.24, 0.045, 0.14))


func _make_report_console() -> void:
	var console := Node3D.new()
	console.name = "ReportConsole"
	console.position = report_console_position
	add_child(console)
	_child_box(console, "ConsoleDesk", Vector3(0.0, 0.72, 0.0), Vector3(1.9, 0.14, 0.8), steel_dark_material, true)
	_child_box(console, "ConsoleFront", Vector3(0.0, 0.4, 0.12), Vector3(1.8, 0.52, 0.06), unit_material, true)
	_child_box(console, "ConsoleSide", Vector3(0.8, 0.4, 0.0), Vector3(0.06, 0.52, 0.7), unit_material, true)
	_child_box(console, "ConsoleSideB", Vector3(-0.8, 0.4, 0.0), Vector3(0.06, 0.52, 0.7), unit_material, true)
	_child_mesh(console, "ConsoleMonitor", ProceduralMeshes.rounded_box(Vector3(0.62, 0.46, 0.1), 7.0, 8), plastic_material, Vector3(-0.25, 1.32, -0.12))
	_child_mesh(console, "ConsoleScreen", ProceduralMeshes.rounded_box(Vector3(0.5, 0.34, 0.015), 8.0, 6), monitor_screen_material, Vector3(-0.25, 1.32, -0.185))
	_child_mesh(console, "ConsoleMonitorStand", ProceduralMeshes.rounded_box(Vector3(0.08, 0.3, 0.08), 6.0, 6), steel_dark_material, Vector3(-0.25, 0.94, -0.12))
	_child_mesh(console, "ConsoleMonitorFoot", ProceduralMeshes.rounded_box(Vector3(0.3, 0.02, 0.22), 6.0, 6), steel_dark_material, Vector3(-0.25, 0.8, -0.12))
	_child_mesh(console, "ConsoleKeyboard", ProceduralMeshes.rounded_box(Vector3(0.55, 0.04, 0.2), 6.0, 6), plastic_material, Vector3(-0.2, 0.81, 0.14))
	_child_mesh(console, "ConsoleButtonPanel", ProceduralMeshes.rounded_box(Vector3(0.3, 0.03, 0.14), 6.0, 6), steel_dark_material, Vector3(0.45, 0.805, 0.1))
	for i in range(3):
		_child_mesh(console, "ConsoleButton_%d" % i, ProceduralMeshes.rounded_box(Vector3(0.05, 0.03, 0.05), 3.0, 6), warning_material if i == 0 else plastic_material, Vector3(0.36 + i * 0.09, 0.835, 0.1))
	_child_mesh(console, "ConsolePapers", ProceduralMeshes.rounded_box(Vector3(0.4, 0.03, 0.3), 8.0, 6), paper_material, Vector3(0.45, 0.805, -0.2))
	var cable := MeshInstance3D.new()
	cable.name = "ConsoleCable"
	cable.mesh = ProceduralMeshes.tube(PackedVector3Array([
		Vector3(-0.25, 1.1, -0.1), Vector3(-0.35, 0.8, -0.3), Vector3(-0.3, 0.2, -0.28), Vector3(-0.2, 0.05, -0.3)
	]), 0.014, 6, false)
	cable.material_override = rubber_material
	console.add_child(cable)
	# Luz de tarefa: o console é ponto de leitura e registro (R/N).
	var console_light := OmniLight3D.new()
	console_light.name = "ConsoleTaskLight"
	console_light.position = Vector3(0.0, 1.95, -0.1)
	console_light.light_color = Color(0.58, 0.76, 0.62, 1.0)
	console_light.light_energy = 0.8
	console_light.omni_range = 2.8
	console.add_child(console_light)


func _child_box(parent: Node3D, node_name: String, local_position: Vector3, size: Vector3, material: Material, collision: bool) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = local_position
	parent.add_child(body)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = ProceduralMeshes.rounded_box(size, 6.0, 8)
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collision:
		var collision_shape := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		collision_shape.shape = shape
		body.add_child(collision_shape)
	return body


func _child_mesh(parent: Node3D, node_name: String, mesh: Mesh, material: Material, local_position: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = local_position
	parent.add_child(mesh_instance)
	return mesh_instance


func _make_surgical_lamp(position: Vector3) -> void:
	_box("LampCeilingMount", position + Vector3(0.0, 2.78, 0.0), Vector3(0.34, 0.12, 0.34), trim_material, false)
	_cylinder("LampArmVertical", position + Vector3(0.0, 2.45, 0.0), 0.055, 0.62, metal_material, 14, false)
	_box("LampArmHorizontal", position + Vector3(0.22, 2.2, 0.0), Vector3(0.5, 0.07, 0.07), metal_material, false)
	var head := _cylinder("LampHead", position + Vector3(0.52, 2.105, 0.0), 0.34, 0.12, metal_material, 24, false)
	_decoration("LampDiffuser", ProceduralMeshes.rounded_box(Vector3(0.4, 0.05, 0.4), 4.0, 10), light_material, position + Vector3(0.52, 2.04, 0.0))
	var lamp_light := SpotLight3D.new()
	lamp_light.name = "SurgicalLampLight"
	lamp_light.position = position + Vector3(0.52, 1.9, 0.0)
	lamp_light.look_at_from_position(lamp_light.position, Vector3(0.4, 0.88, -0.85), Vector3.UP)
	lamp_light.light_color = Color(0.85, 0.9, 0.86, 1.0)
	lamp_light.light_energy = 3.2
	lamp_light.spot_range = 5.0
	lamp_light.spot_angle = 52.0
	lamp_light.spot_angle_attenuation = 0.9
	lamp_light.shadow_enabled = true
	lamp_light.shadow_bias = 0.03
	add_child(lamp_light)


func _make_extinguisher(position: Vector3) -> void:
	var extinguisher := Node3D.new()
	extinguisher.name = "Extinguisher"
	extinguisher.position = position
	add_child(extinguisher)
	var body := MeshInstance3D.new()
	body.mesh = CylinderMesh.new()
	(body.mesh as CylinderMesh).top_radius = 0.09
	(body.mesh as CylinderMesh).bottom_radius = 0.09
	(body.mesh as CylinderMesh).height = 0.52
	(body.mesh as CylinderMesh).radial_segments = 18
	body.position.y = 0.32
	var red_paint := ProceduralMaterials.painted_metal(Color(0.4, 0.05, 0.03), 0.25, 0.35)
	body.material_override = red_paint
	extinguisher.add_child(body)
	var neck := MeshInstance3D.new()
	neck.mesh = CylinderMesh.new()
	(neck.mesh as CylinderMesh).top_radius = 0.028
	(neck.mesh as CylinderMesh).bottom_radius = 0.05
	(neck.mesh as CylinderMesh).height = 0.09
	(neck.mesh as CylinderMesh).radial_segments = 12
	neck.position.y = 0.62
	neck.material_override = metal_material
	extinguisher.add_child(neck)
	var valve := MeshInstance3D.new()
	valve.mesh = ProceduralMeshes.rounded_box(Vector3(0.14, 0.05, 0.06), 5.0, 6)
	valve.position.y = 0.69
	valve.material_override = metal_material
	extinguisher.add_child(valve)
	var hose := MeshInstance3D.new()
	hose.mesh = ProceduralMeshes.tube(PackedVector3Array([
		Vector3(0.05, 0.68, 0.0), Vector3(0.16, 0.6, 0.03), Vector3(0.2, 0.45, 0.05), Vector3(0.16, 0.36, 0.03)
	]), 0.014, 6, true)
	hose.material_override = rubber_material
	extinguisher.add_child(hose)
	var bracket := MeshInstance3D.new()
	bracket.mesh = ProceduralMeshes.rounded_box(Vector3(0.05, 0.3, 0.2), 5.0, 6)
	bracket.position = Vector3(-0.13, 0.42, 0.0)
	bracket.material_override = steel_dark_material
	extinguisher.add_child(bracket)
	var base := MeshInstance3D.new()
	base.mesh = CylinderMesh.new()
	(base.mesh as CylinderMesh).top_radius = 0.1
	(base.mesh as CylinderMesh).bottom_radius = 0.11
	(base.mesh as CylinderMesh).height = 0.03
	(base.mesh as CylinderMesh).radial_segments = 16
	base.position.y = 0.06
	base.material_override = rubber_material
	extinguisher.add_child(base)


func _make_wall_clock(position: Vector3) -> void:
	var clock := Node3D.new()
	clock.name = "WallClock"
	clock.position = position
	clock.rotation_degrees.y = 180.0
	add_child(clock)
	var housing := MeshInstance3D.new()
	housing.mesh = ProceduralMeshes.rounded_box(Vector3(0.52, 0.26, 0.06), 6.0, 8)
	housing.material_override = plastic_material
	clock.add_child(housing)
	var face := MeshInstance3D.new()
	face.mesh = ProceduralMeshes.rounded_box(Vector3(0.46, 0.2, 0.02), 6.0, 6)
	face.position.z = -0.032
	face.material_override = ProceduralMaterials.screen(Color(0.14, 0.24, 0.2), 0.9)
	clock.add_child(face)
	clock_label = Label3D.new()
	clock_label.name = "WallClockLabel"
	clock_label.text = "00:00"
	clock_label.position = Vector3(0.0, 0.0, -0.045)
	clock_label.pixel_size = 0.0042
	clock_label.modulate = Color(0.6, 0.92, 0.8, 1.0)
	clock_label.outline_size = 4
	clock_label.outline_modulate = Color(0.01, 0.03, 0.025, 1.0)
	clock.add_child(clock_label)


func _make_cart(position: Vector3) -> void:
	var cart := Node3D.new()
	cart.name = "ServiceCart"
	cart.position = position
	add_child(cart)
	var body := StaticBody3D.new()
	body.name = "CartBody"
	cart.add_child(body)
	var shape := CollisionShape3D.new()
	shape.position = Vector3(0.0, 0.55, 0.0)
	var box := BoxShape3D.new()
	box.size = Vector3(0.9, 1.05, 0.55)
	shape.shape = box
	body.add_child(shape)
	for shelf_y in [0.42, 0.86]:
		var shelf := MeshInstance3D.new()
		shelf.mesh = ProceduralMeshes.rounded_box(Vector3(0.9, 0.04, 0.55), 6.0, 8)
		shelf.position = Vector3(0.0, shelf_y, 0.0)
		shelf.material_override = metal_material
		body.add_child(shelf)
	for leg_x in [-0.42, 0.42]:
		for leg_z in [-0.24, 0.24]:
			var leg := MeshInstance3D.new()
			leg.mesh = CylinderMesh.new()
			(leg.mesh as CylinderMesh).top_radius = 0.018
			(leg.mesh as CylinderMesh).bottom_radius = 0.018
			(leg.mesh as CylinderMesh).height = 0.82
			(leg.mesh as CylinderMesh).radial_segments = 8
			leg.position = Vector3(leg_x, 0.45, leg_z)
			leg.material_override = steel_dark_material
			body.add_child(leg)
			var wheel := MeshInstance3D.new()
			wheel.mesh = CylinderMesh.new()
			(wheel.mesh as CylinderMesh).top_radius = 0.045
			(wheel.mesh as CylinderMesh).bottom_radius = 0.045
			(wheel.mesh as CylinderMesh).height = 0.03
			(wheel.mesh as CylinderMesh).radial_segments = 12
			wheel.position = Vector3(leg_x, 0.045, leg_z)
			wheel.rotation.z = PI * 0.5
			wheel.material_override = rubber_material
			body.add_child(wheel)
	var rail := MeshInstance3D.new()
	rail.mesh = ProceduralMeshes.tube(PackedVector3Array([
		Vector3(-0.42, 0.92, -0.24), Vector3(-0.42, 0.94, 0.24),
		Vector3(0.42, 0.94, 0.24), Vector3(0.42, 0.92, -0.24)
	]), 0.016, 8, false)
	rail.material_override = metal_material
	body.add_child(rail)
	# Caixa e frascos sobre a prateleira superior.
	var cart_box := MeshInstance3D.new()
	cart_box.mesh = ProceduralMeshes.rounded_box(Vector3(0.34, 0.16, 0.24), 6.0, 8)
	cart_box.position = Vector3(-0.15, 0.96, 0.05)
	cart_box.material_override = plastic_material
	body.add_child(cart_box)
	var jug := MeshInstance3D.new()
	jug.mesh = ProceduralMeshes.lathe(PackedVector2Array([
		Vector2(0.0, 0.0), Vector2(0.06, 0.01), Vector2(0.065, 0.18), Vector2(0.03, 0.23)
	]), 12, true)
	jug.position = Vector3(0.25, 0.88, -0.08)
	jug.material_override = plastic_material
	body.add_child(jug)


func _make_draped_body(position: Vector3) -> void:
	var cloth := MeshInstance3D.new()
	cloth.name = "CoveredBody"
	cloth.position = position
	cloth.mesh = _create_draped_sheet_mesh()
	cloth.material_override = sheet_material
	add_child(cloth)


func _create_draped_sheet_mesh() -> ArrayMesh:
	# Lençol contido pela borda da mesa de necropsia: volume sugerido de
	# cabeça, tronco, quadril e pés; bordas dobram-se para dentro da bacia.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := 30
	var rows := 14
	for row in range(rows):
		for column in range(columns):
			var u := float(column) / float(columns - 1)
			var v := float(row) / float(rows - 1)
			var x: float = lerp(-1.13, 1.13, u)
			var z: float = lerp(-0.44, 0.44, v)
			var head_bump := exp(-pow((x - 0.52) / 0.40, 2.0) - pow((z + 0.02) / 0.30, 2.0)) * 0.20
			var torso := exp(-pow(x / 0.55, 2.0) - pow(z / 0.30, 2.0)) * 0.14
			var hips := exp(-pow((x + 0.38) / 0.34, 2.0) - pow(z / 0.26, 2.0)) * 0.09
			var feet := exp(-pow((x + 0.80) / 0.24, 2.0) - pow(z / 0.14, 2.0)) * 0.075
			var folds := sin(x * 11.0 + z * 5.0) * 0.012 + cos(z * 15.0 - x * 3.0) * 0.009 + sin(x * 2.7 + z * 1.9) * 0.01
			var body_height := 0.8885 + head_bump + torso + hips + feet + folds
			# Dobra interna: perto da borda o tecido desce até o fundo da bacia.
			var overhang := maxf((absf(x) - 0.99) / 0.14, (absf(z) - 0.30) / 0.14)
			var drape := clampf(overhang, 0.0, 1.0)
			drape = drape * drape * (3.0 - 2.0 * drape)
			var pooled := 0.8845 + folds * 0.25
			var y := lerpf(body_height, pooled, drape)
			surface.set_uv(Vector2(u, v))
			surface.add_vertex(Vector3(x, y, z))
	for row in range(rows - 1):
		for column in range(columns - 1):
			var current := row * columns + column
			var next_row := (row + 1) * columns + column
			surface.add_index(current)
			surface.add_index(next_row)
			surface.add_index(current + 1)
			surface.add_index(current + 1)
			surface.add_index(next_row)
			surface.add_index(next_row + 1)
	surface.generate_normals()
	return surface.commit()


func _capsule(node_name: String, position: Vector3, radius: float, height: float, material: Material, collision := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 20
	mesh.rings = 8
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collision:
		var collision_shape := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = radius
		shape.height = height
		collision_shape.shape = shape
		body.add_child(collision_shape)
	return body


func _cylinder(node_name: String, position: Vector3, radius: float, height: float, material: Material, radial_segments: int = 16, collision := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	add_child(body)
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = radial_segments
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	if collision:
		var collision_shape := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		collision_shape.shape = shape
		body.add_child(collision_shape)
	return body


func _box(node_name: String, position: Vector3, size: Vector3, material: Material, collision := true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	if collision:
		var collision_shape := CollisionShape3D.new()
		collision_shape.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = size
		collision_shape.shape = shape
		body.add_child(collision_shape)
	return body


func _smooth_box(node_name: String, position: Vector3, size: Vector3, material: Material, sharpness: float, segments: int, collision := false) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	add_child(body)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = "Mesh"
	mesh_instance.mesh = ProceduralMeshes.rounded_box(size, sharpness, segments)
	mesh_instance.material_override = material
	body.add_child(mesh_instance)

	if collision:
		var collision_shape := CollisionShape3D.new()
		collision_shape.name = "Collision"
		var shape := BoxShape3D.new()
		shape.size = size * 0.92
		collision_shape.shape = shape
		body.add_child(collision_shape)
	return body


func _decoration(node_name: String, mesh: Mesh, material: Material, position: Vector3) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.name = node_name
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	mesh_instance.position = position
	add_child(mesh_instance)
	return mesh_instance


func _label(text_value: String, position: Vector3, pixel_size: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = text_value.replace(" ", "_").replace("/", "_")
	label.text = text_value
	label.position = position
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = 8
	label.outline_modulate = Color(0.015, 0.02, 0.02, 0.95)
	add_child(label)
	return label
