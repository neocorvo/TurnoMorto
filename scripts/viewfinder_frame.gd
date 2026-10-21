class_name ViewfinderFrame
extends Control

## Moldura de visor da câmera fotográfica: cantos discretos que ganham brilho
## quando um alvo válido está enquadrado. Feedback puramente visual.

const IDLE_COLOR := Color(0.55, 0.72, 0.68, 0.30)
const ARMED_COLOR := Color(0.62, 0.95, 0.80, 0.95)

var armed := false:
	set(value):
		if armed != value:
			armed = value
			queue_redraw()

var _pulse := 0.0


func _process(delta: float) -> void:
	if armed:
		_pulse += delta * 5.0
		queue_redraw()
	elif _pulse != 0.0:
		_pulse = 0.0
		queue_redraw()


func _draw() -> void:
	var inset := minf(size.x, size.y) * 0.11
	var arm := inset * 0.6
	var thickness := 2.0
	var color := IDLE_COLOR
	if armed:
		var wave := 0.75 + 0.25 * sin(_pulse)
		color = ARMED_COLOR
		color.a *= wave
	for corner in [
		Vector2(inset, inset),
		Vector2(size.x - inset, inset),
		Vector2(inset, size.y - inset),
		Vector2(size.x - inset, size.y - inset)
	]:
		var horizontal := arm if corner.x < size.x * 0.5 else -arm
		var vertical := arm if corner.y < size.y * 0.5 else -arm
		draw_line(corner, corner + Vector2(horizontal, 0.0), color, thickness)
		draw_line(corner, corner + Vector2(0.0, vertical), color, thickness)
