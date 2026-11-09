class_name ESHealth
extends Node

signal changed(current: float, maximum: float)
signal damaged(amount: float)
signal died

@export var maximum: float = 100.0
var current: float = 100.0
var is_dead := false
# A guard receives this component and must restore positive health to intercept death.
# The owning skill is responsible for consuming its once-per-run charge.
var lethal_guards: Array[Callable] = []
var damage_filters: Array[Callable] = []
var _resolving := false

func reset() -> void:
	current = maximum
	is_dead = false
	changed.emit(current, maximum)

func heal(amount: float) -> void:
	if is_dead:
		return
	current = clampf(current + amount, 0.0, maximum)
	changed.emit(current, maximum)

func hurt(amount: float, source: Node = null) -> void:
	if is_dead or _resolving or amount <= 0.0:
		return
	for filter_damage in damage_filters:
		if filter_damage.is_valid():
			amount = maxf(0.0, float(filter_damage.call(amount, source)))
	if amount <= 0.0:
		return
	_resolving = true
	current = maxf(0.0, current - amount)
	if current <= 0.0:
		for guard in lethal_guards.duplicate():
			if guard.is_valid():
				guard.call(self)
			if current > 0.0:
				break
		is_dead = current <= 0.0
	damaged.emit(amount)
	changed.emit(current, maximum)
	if is_dead:
		died.emit()
	_resolving = false
