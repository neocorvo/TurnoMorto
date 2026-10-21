extends Node
class_name InspectionManager

signal phase_changed
signal hour_advanced
signal shift_completed

enum Phase {
	READY,
	EXPLORING,
	RETURNING,
	COMPLETE,
}

var phase: int = Phase.READY
var current_hour: int = 0
var anomaly_active: bool = true
var photo_taken: bool = false
var environment_visited: bool = false
var photo_target_id: String = ""
var last_result_message: String = ""

var anomaly_schedule: Array[bool] = [true, false, true, false, true, false]


func _ready() -> void:
	_prepare_cycle()


func _prepare_cycle() -> void:
	if current_hour >= 6:
		phase = Phase.COMPLETE
		anomaly_active = false
		shift_completed.emit()
		return
	phase = Phase.READY
	anomaly_active = anomaly_schedule[current_hour]
	photo_taken = false
	environment_visited = false
	photo_target_id = ""
	last_result_message = "Inspeção pronta. Abra a porta para iniciar."
	phase_changed.emit()


func begin_inspection() -> bool:
	if phase != Phase.READY:
		return false
	phase = Phase.EXPLORING
	environment_visited = false
	photo_taken = false
	photo_target_id = ""
	last_result_message = "Inspeção iniciada. Procure mudanças no corredor."
	phase_changed.emit()
	return true


func mark_environment_visited() -> void:
	if phase == Phase.EXPLORING:
		environment_visited = true


func can_take_photo() -> bool:
	return phase == Phase.EXPLORING and environment_visited and anomaly_active and not photo_taken


func photo_reason() -> String:
	if phase == Phase.READY:
		return "Abra a porta para iniciar a inspeção."
	if phase == Phase.RETURNING:
		return "A evidência já foi registrada. Volte à sala de segurança."
	if not environment_visited:
		return "Entre no corredor antes de fotografar."
	if not anomaly_active:
		return "Nenhuma anomalia foi detectada neste ciclo."
	if photo_taken:
		return "Evidência registrada. Volte para fazer o relatório."
	return "Aponte para uma alteração visível e pressione F."


func record_photo(target_id: String) -> bool:
	if not can_take_photo():
		last_result_message = photo_reason()
		return false
	photo_taken = true
	photo_target_id = target_id
	phase = Phase.RETURNING
	last_result_message = "Fotografia válida. Retorne à sala e pressione R para registrar."
	phase_changed.emit()
	return true


func submit_anomaly() -> bool:
	if phase != Phase.RETURNING or not photo_taken:
		if phase == Phase.EXPLORING and anomaly_active:
			last_result_message = "Relatório rejeitado: a anomalia ainda precisa ser fotografada."
		elif not anomaly_active:
			last_result_message = "Relatório rejeitado: este ciclo não possui anomalia."
		else:
			last_result_message = "Nenhuma evidência válida está pronta para registro."
		phase_changed.emit()
		return false
	_resolve_inspection("Anomalia documentada. O próximo ciclo foi liberado.")
	return true


func submit_no_anomaly() -> bool:
	if phase != Phase.EXPLORING or not environment_visited:
		last_result_message = "Inspeção incompleta: percorra o corredor antes de confirmar."
		phase_changed.emit()
		return false
	if anomaly_active:
		last_result_message = "Confirmação incorreta: existe uma anomalia no corredor."
		phase_changed.emit()
		return false
	_resolve_inspection("Inspeção sem anomalia confirmada. O próximo ciclo foi liberado.")
	return true


func _resolve_inspection(message: String) -> void:
	last_result_message = message
	current_hour += 1
	if current_hour >= 6:
		current_hour = 6
		phase = Phase.COMPLETE
		anomaly_active = false
		last_result_message = "06:00 — turno encerrado. O relatório final foi aceito."
		shift_completed.emit()
	else:
		_prepare_cycle()
		last_result_message = message + " Próximo ciclo: %02d:00." % current_hour
	hour_advanced.emit()
	phase_changed.emit()


func is_ready() -> bool:
	return phase == Phase.READY


func is_exploring() -> bool:
	return phase == Phase.EXPLORING


func is_returning() -> bool:
	return phase == Phase.RETURNING


func is_complete() -> bool:
	return phase == Phase.COMPLETE


func phase_text() -> String:
	match phase:
		Phase.READY:
			return "PRONTO PARA INSPEÇÃO"
		Phase.EXPLORING:
			return "EXPLORANDO O CORREDOR"
		Phase.RETURNING:
			return "RETORNAR À SEGURANÇA"
		Phase.COMPLETE:
			return "TURNO ENCERRADO"
	return "ESTADO DESCONHECIDO"
