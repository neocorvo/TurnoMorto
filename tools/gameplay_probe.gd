extends Node3D

## Sonda de gameplay: valida que a reforma visual preservou todos os
## contratos de inspeção (porta, corredor, anomalia M-02, foto, registro,
## protocolo). Não modifica código de jogo — só dirige o jogador simulado.

var failures := 0


func _ready() -> void:
	var room: Node3D = (load("res://scenes/first_room.tscn") as PackedScene).instantiate()
	add_child(room)
	for i in range(10):
		await get_tree().process_frame

	var player: CharacterBody3D = room.get_node("Player")
	var camera: Camera3D = room.get_node("Player/Head/Camera3D")
	var manager: InspectionManager = room.get_node("InspectionManager")
	var door: Node3D = room.get_node("Door")

	_check(room.target_body != null, "target_body (gaveta M-02) foi criado")
	_check(room.protocol_body != null, "protocol_body (folha) foi criado")
	_check(room.anomaly_label != null, "anomaly_label foi criado")
	_check(room.anomaly_label.text == "M-07", "anomalia inicial troca a etiqueta para M-07")

	# 1. Porta: aproxima e interage para iniciar a inspeção.
	player.global_position = Vector3(0.0, 0.0, -3.3)
	room._handle_door()
	_check(manager.is_exploring(), "E na porta iniciou a inspeção")

	# 2. Corredor: entrar marca o ambiente como visitado.
	player.global_position = Vector3(0.0, 0.0, -1.0)
	await get_tree().process_frame
	_check(manager.environment_visited, "entrada no corredor marca ambiente visitado")

	# 3. Mira na gaveta M-02 (z = -9.3, face em x ~ 2.0).
	camera.global_position = Vector3(1.0, 1.5, -8.6)
	camera.look_at(Vector3(2.1, 1.35, -9.3), Vector3.UP)
	await get_tree().process_frame
	_check(room._ray_hits_anomaly(), "raycast enquadra a gaveta M-02")

	# 4. Foto válida.
	room._take_photo()
	_check(manager.is_returning(), "foto válida move para RETURNING")
	_check(manager.photo_taken, "evidência registrada no gerenciador")

	# 5. Registro no console.
	player.global_position = Vector3(3.0, 0.0, 2.6)
	room._submit_anomaly()
	_check(manager.current_hour == 1, "registro aceito avança o relógio para 01:00")

	# 6. Ciclo sem anomalia (01:00): confirmar com N.
	_check(room.anomaly_label.text == "M-02", "ciclo limpo restaura a etiqueta M-02")
	player.global_position = Vector3(0.0, 0.0, -3.3)
	room._handle_door()
	_check(manager.is_exploring(), "segunda inspeção iniciada")
	player.global_position = Vector3(0.0, 0.0, -1.0)
	# Dois frames: o primeiro retoma antes do _process da cena.
	await get_tree().process_frame
	await get_tree().process_frame
	# O jogador volta ao console para confirmar (exigência do fluxo real).
	player.global_position = Vector3(3.0, 0.0, 2.6)
	room._submit_no_anomaly()
	_check(manager.current_hour == 2, "confirmação sem anomalia avança para 02:00")

	# 7. Protocolo: mira na folha e abre/fecha (jogador fora da colisão da mesa).
	player.global_position = Vector3(2.3, 0.0, 0.3)
	camera.global_position = Vector3(2.3, 1.5, 0.55)
	camera.look_at(Vector3(2.98, 0.947, 1.18), Vector3.UP)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(room._ray_hits_protocol(), "raycast enquadra a folha de protocolo")
	room._open_protocol()
	_check(room.protocol_open, "protocolo abre com E")
	room._close_protocol()
	_check(not room.protocol_open, "protocolo fecha")

	# 8. Atmosfera e efeitos existem.
	_check(room.get_node_or_null("Atmosphere") != null, "atmosfera (flicker/poeira) criada")
	_check(room.get_node_or_null("ScreenEffects") != null, "pós-efeto de câmera criado")
	_check(room.get_node_or_null("WallClock/WallClockLabel") != null, "relógio de parede criado")
	_check(room.viewfinder != null and room.flash_rect != null, "visor e flash da câmera criados")

	if failures == 0:
		print("gameplay_probe: OK")
		get_tree().quit(0)
	else:
		print("gameplay_probe: %d FALHAS" % failures)
		get_tree().quit(1)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("  ok: " + message)
	else:
		failures += 1
		push_error("gameplay_probe: FALHOU — " + message)
		print("  FALHOU: " + message)
