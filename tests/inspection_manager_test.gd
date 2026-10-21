extends SceneTree


func _init() -> void:
	var manager := InspectionManager.new()
	root.add_child(manager)

	_assert(manager.current_hour == 0, "o ciclo deve começar em 00:00")
	_assert(manager.is_ready(), "o primeiro ciclo deve começar pronto")
	_assert(manager.anomaly_active, "o primeiro ciclo deve conter a anomalia de teste")

	manager.begin_inspection()
	manager.mark_environment_visited()
	_assert(not manager.submit_no_anomaly(), "não deve aceitar ausência quando há anomalia")
	_assert(manager.current_hour == 0, "erro de relatório não pode avançar o relógio")
	_assert(manager.record_photo("drawer_M02"), "a foto válida deve ser registrada")
	_assert(manager.submit_anomaly(), "o relatório com evidência deve ser aceito")
	_assert(manager.current_hour == 1, "o ciclo válido deve avançar para 01:00")

	manager.begin_inspection()
	manager.mark_environment_visited()
	_assert(manager.submit_no_anomaly(), "o ciclo sem anomalia deve aceitar confirmação")
	_assert(manager.current_hour == 2, "a confirmação sem anomalia deve avançar o relógio")

	while manager.current_hour < 6:
		manager.begin_inspection()
		manager.mark_environment_visited()
		if manager.anomaly_active:
			_assert(manager.record_photo("drawer_M02"), "cada anomalia deve aceitar uma evidência")
			_assert(manager.submit_anomaly(), "cada anomalia fotografada deve ser aceita")
		else:
			_assert(manager.submit_no_anomaly(), "cada ciclo limpo deve aceitar confirmação")

	_assert(manager.current_hour == 6, "o turno deve terminar exatamente às 06:00")
	_assert(manager.is_complete(), "o estado final deve ser concluído")
	print("inspection_manager_test: OK")
	quit(0)


func _assert(condition: bool, message: String) -> void:
	if not condition:
		push_error("inspection_manager_test: " + message)
		quit(1)
