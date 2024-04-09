![Signal Sentry](/assets/signal_sentry_splash.svg "Signal Sentry")

# Signal Sentry

A micro util script for Godot Engine: Group a bunch of [Signals](https://docs.godotengine.org/en/stable/classes/class_signal.html), get a notification when all of them are done!

This is of course inspired by [Javascript's Promise.all()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise/all), and similar asynchronous grouping APIs.

## Installation

Drop signal_sentry.gd anywhere on your project. That's it.

## Usage

### Basic example

```
func _ready() -> void:
	var timershort := get_tree().create_timer(2.0)
	var timerlong := get_tree().create_timer(5.0)

	SignalSentry.wait_for( \
		[timershort.timeout, timerlong.timeout] \
		func(_status: SignalSentry.Result) -> void: print('all timers done'), \
	)
```

`SignalSentry.wait_for()` is a static function that takes an Array of Signals to watch for, and a callback func to call when all Signals are done.

The callback is func is called with an enum Result for the group stautus : `SUCCESS | CANCEL | TIMEOUT`

### Usage Pattern

Consider a turn based game, the way I would go about it would be something like:

```
func execute_enemies_turns() -> void:
	var enemy_turns: Array[Signal] = []

	for enemy in enemies:
		enemy.attack()
		enemy_turns.push_back(enemy.turn_finished)

	SignalSentry.wait_for(enemy_turns, new_player_turn)

func new_player_turn(enemy_turn_result: SignalSentry.Result) -> void:
	if enemy_turn_result == SignalSentry.Result.SUCCESS:
		player_options.display()
```

### Timeouts and safety

It is important to use SignalSentry carefuly: If any of your dependency Signals fails to emit, the SignalSentry instance will _NOT_ free automatically. This will cause an orphan instance and a memory leak (not a big one, but still). If you are going to be risky with your Signals, I recommend setting a safety `timeout: float` as the third argument of the `watch_for()` static function.

```
func risky_biz() -> void:
	var requests: Array[Signal] = []

	for client in http_client_list:
		client.make_request()
		requests.push_back(client.request_completed)

	SignalSentry.watch_for(requests, on_requests_finished, 10.0)

func on_requests_finished(result: SignalSentry.Result) -> void:
	match result:
		SignalSentry.Result.SUCCESS:
			start()
		SignalSentry.Result.TIMEOUT:
			retry()
```

### Referencing

`watch_for()` returns a referene to the SignalSentry instance created. You can store this reference in a var and pass it around. You can then hook to the instance's `done` Signal from other Nodes.

```
	var my_sentry := SignalSentry.watch_for(bunch_o_signals, on_signals_done, 60.0)

	sibling_node_ref.pass_me_the_sentry(my_sentry)
```

```
	func pass_me_the_sentry(sentry: SignalSentry) -> void:
		sentry.done.connect(on_sentry_done)

	func on_sentry_done(result: SignalSentry.Result) -> void:
		[...]
```

### Cancelling out

If for whatever reason you want to invalidate the Sentry instance, you can call the `cancel()` func on that instance. This will emit the `done` signal with the `CANCELLED` enum entry (index 1)
