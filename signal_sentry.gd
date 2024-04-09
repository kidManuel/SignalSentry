class_name SignalSentry
extends Object

enum Result {
	SUCCESS,
	CANCELLED,
	TIMEOUT
}

signal done(status: Result)

# Shape is { int: Signal }
var dependencies: Dictionary = {}
var fallback_timer: SceneTreeTimer

# God please grant us nullable types soon
func _init(_dependencies: Array[Signal], _max_wait: float=- 1.0) -> void:
	print('init`')
	if _dependencies.size() == 0:
		push_warning('Attempted creation of SignalSentry without dependencies')
		return

	if _dependencies.size() == 1:
		print_rich('You know you can just [i]watch[/i] a single dependency, right? (￣ω￣;)')
	
	for single_signal in _dependencies:
		var signal_id := single_signal.get_object_id()
		dependencies[signal_id] = single_signal
		single_signal.connect(_on_dependency_done.bind(signal_id))
		print(single_signal.get_connections())
	
	if _max_wait > 0.0:
		fallback_timer = Engine.get_main_loop().create_timer(_max_wait)
		fallback_timer.timeout.connect(_on_timeout)

func _on_dependency_done(id: int) -> void:
	if dependencies[id] is Signal:
		dependencies[id].disconnect(_on_dependency_done)
		dependencies.erase(id)

	if dependencies.is_empty():
		clear(Result.SUCCESS)

func clear(response: Result) -> void:
	done.emit(response)

	if fallback_timer is SceneTreeTimer:
		fallback_timer.free()

	for dependency: Signal in dependencies:
		dependency.disconnect(_on_dependency_done)

	call_deferred('free')

func _on_timeout() -> void:
	clear(Result.TIMEOUT)

func cancel() -> void:
	clear(Result.CANCELLED)

static func wait_for(_dependencies: Array[Signal], _callback: Callable, _max_wait: float=- 1.0) -> SignalSentry:
	var new_watcher := SignalSentry.new(_dependencies, _max_wait)
	new_watcher.done.connect(_callback)
	return new_watcher
