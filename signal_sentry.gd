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

var _max_time_timer: SceneTreeTimer
var _min_time_timer: SceneTreeTimer
var _past_min_time: bool

# God please grant us union types soon
func _init(_dependencies: Array[Signal], _max_wait: float=- 1.0, _min_wait: float=- 1.0) -> void:
	if _dependencies.size() == 0:
		push_warning('Attempted creation of SignalSentry without dependencies')
		return

	for single_signal in _dependencies:
		var signal_id := single_signal.get_object_id()
		dependencies[signal_id] = single_signal
		single_signal.connect(_on_dependency_done.bind(signal_id))
		print(single_signal.get_connections())
	
	if _max_wait > 0.0:
		_max_time_timer = Engine.get_main_loop().create_timer(_max_wait)
		_max_time_timer.timeout.connect(_on_timeout)
	
	if _min_wait > 0.0:
		_min_time_timer = Engine.get_main_loop().create_timer(_min_wait)
		_min_time_timer.timeout.connect(_on_min_time_expired)

func _on_dependency_done(id: int) -> void:
	if dependencies[id] is Signal:
		dependencies[id].disconnect(_on_dependency_done)
		dependencies.erase(id)

	if dependencies.is_empty():
		if (_min_time_timer is SceneTreeTimer) and (not _past_min_time): return
		
		clear(Result.SUCCESS)

func clear(response: Result) -> void:
	done.emit(response)

	for key: int in dependencies:
		dependencies[key].disconnect(_on_dependency_done)

	call_deferred('free')

func _on_min_time_expired() -> void:
	if dependencies.is_empty():
		clear(Result.SUCCESS)
	else:
		_past_min_time = true

func _on_timeout() -> void:
	clear(Result.TIMEOUT)

func cancel() -> void:
	clear(Result.CANCELLED)

static func wait_for(_dependencies: Array[Signal], _callback: Callable, _max_wait: float=- 1.0, _min_wait: float=- 1.0) -> SignalSentry:
	var new_watcher := SignalSentry.new(_dependencies, _max_wait, _min_wait)
	new_watcher.done.connect(_callback)
	return new_watcher
