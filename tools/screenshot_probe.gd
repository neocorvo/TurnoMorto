extends Node3D

## Sonda de validação visual: instancia a cena principal, posiciona a câmera
## em poses fixas e salva capturas reais do viewport em /tmp/turnomorto_shots.
## Imprime estatística de luminância para detectar frames pretos ou estourados.

const OUTPUT_DIR := "/tmp/turnomorto_shots"

var poses := [
	{"name": "01_spawn", "position": Vector3(0.0, 1.6, 2.45), "target": Vector3(0.0, 1.05, -2.0)},
	{"name": "02_gurney", "position": Vector3(-2.2, 1.5, -1.0), "target": Vector3(0.5, 0.92, -0.9)},
	{"name": "03_worktable", "position": Vector3(2.0, 1.5, 2.6), "target": Vector3(3.0, 0.95, 1.18)},
	{"name": "04_console", "position": Vector3(1.6, 1.5, 3.0), "target": Vector3(3.25, 1.0, 2.25)},
	{"name": "05_corridor_mid", "position": Vector3(0.0, 1.6, -5.0), "target": Vector3(0.0, 1.3, -14.0)},
	{"name": "06_morgue_drawers", "position": Vector3(0.6, 1.45, -8.2), "target": Vector3(2.2, 1.4, -9.4)},
	{"name": "07_anomaly_close", "position": Vector3(1.0, 1.5, -8.6), "target": Vector3(2.1, 1.35, -9.3)},
	{"name": "08_corridor_end", "position": Vector3(-1.0, 1.6, -19.0), "target": Vector3(0.0, 1.4, -25.9)},
	{"name": "09_wheelchair", "position": Vector3(-2.6, 1.5, 1.1), "target": Vector3(-4.9, 0.65, 1.45)},
	{"name": "10_cart", "position": Vector3(0.2, 1.5, -0.9), "target": Vector3(1.7, 0.95, -2.1)},
]


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT_DIR)
	var room: Node3D = (load("res://scenes/first_room.tscn") as PackedScene).instantiate()
	add_child(room)

	# Aguarda geração das texturas de noise e estabilização do ambiente.
	for i in range(24):
		await get_tree().process_frame

	var camera: Camera3D = room.get_node("Player/Head/Camera3D")
	for pose in poses:
		camera.global_position = pose["position"]
		camera.look_at(pose["target"], Vector3.UP)
		for i in range(4):
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var image := get_viewport().get_texture().get_image()
		var path := "%s/%s.png" % [OUTPUT_DIR, pose["name"]]
		image.save_png(path)
		print("shot %s | %dx%d | luminancia media %.3f" % [pose["name"], image.get_width(), image.get_height(), _mean_luminance(image)])

	print("screenshot_probe: OK")
	get_tree().quit(0)


func _mean_luminance(image: Image) -> float:
	var total := 0.0
	var samples := 0
	for y in range(0, image.get_height(), 24):
		for x in range(0, image.get_width(), 24):
			var pixel := image.get_pixel(x, y)
			total += pixel.r * 0.3 + pixel.g * 0.59 + pixel.b * 0.11
			samples += 1
	return total / maxf(float(samples), 1.0)
