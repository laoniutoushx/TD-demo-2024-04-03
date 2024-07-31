# ##########################################################################
# This file is auto generated and should ne be edited !
# It can safely be committed to your VCS.
# This script is automatically declared as singleton in your
# Project Settings. Do not remove it or disable it or GTraits will not
# work as expected
# ##########################################################################

extends RefCounted
class_name GTraits

#region Core methods

## Shortcut for [method GTraitsCore.as_a]
static func as_a(a_trait:Script, object:Object) -> Object:
	return GTraitsCore.as_a(a_trait, object)

## Shortcut for [method GTraitsCore.is_a]
static func is_a(a_trait:Script, object:Object) -> bool:
	return GTraitsCore.is_a(a_trait, object)

## Shortcut for [method GTraitsCore.add_trait_to]
static func add_trait_to(a_trait:Script, object:Object) -> Object:
	return GTraitsCore.add_trait_to(a_trait, object)

## Shortcut for [method GTraitsCore.remove_trait_from]
static func remove_trait_from(a_trait:Script, object:Object) -> void:
	GTraitsCore.remove_trait_from(a_trait, object)

## Shortcut for [method GTraitsCore.if_is_a]
static func if_is_a(a_trait:Script, object:Object, if_callable:Callable, deferred_call:bool = false) -> Variant:
	return GTraitsCore.if_is_a(a_trait, object, if_callable, deferred_call)

## Shortcut for [method GTraitsCore.if_is_a_or_else]
static func if_is_a_or_else(a_trait:Script, object:Object, if_callable:Callable, else_callable:Callable, deferred_call:bool = false) -> Variant:
	return GTraitsCore.if_is_a_or_else(a_trait, object, if_callable, else_callable, deferred_call)

#endregion

#region Trait WaveManager
# Trait script path: 'res://Waves/WaveManager.gd'


## Get [WaveManager] trait from the given object. Raise an assertion error if trait is not found.
## See [method GTraits.as_a] for more details.
static func as_wave_manager(object:Object) -> WaveManager:
	return as_a(WaveManager, object)

## Gets if the given object is a [WaveManager].
## See [method GTraits.is_a] for more details.
static func is_wave_manager(object:Object) -> bool:
	return is_a(WaveManager, object)

## Add trait [WaveManager] to the given object.
## See [method GTraits.add_trait_to] for more details.
static func set_wave_manager(object:Object) -> WaveManager:
	return add_trait_to(WaveManager, object)

## Remove trait [WaveManager] from the given object. Removed trait instance is automatically freed.
## See [method GTraits.remove_trait_from] for more details.
static func unset_wave_manager(object:Object) -> void:
	remove_trait_from(WaveManager, object)

## Calls the given [Callable] if and only if an object is a [WaveManager]. The callable.
## takes the [WaveManager] trait as argument. Returns the callable result if the object is a
## [WaveManager], [code]null[/code] otherwise.
## [br][br]
## If [code]deferred_call[/code] is [code]true[/code], the callable is called using [method Callable.call_deferred] and
## the returned value will always be [code]null[/code].
## [br][br]
## See [method GTraits.if_is_a] for more details.
static func if_is_wave_manager(object:Object, if_callable:Callable, deferred_call:bool = false) -> Variant:
	return if_is_a(WaveManager, object, if_callable, deferred_call)

## Calls the given [i]if[/i] [Callable] if and only if an object is a [WaveManager], or else calls
## the given [i]else[/i] callable. The [i]if[/i] callable takes the [WaveManager] trait as argument, and the
## [i]else[/i] callable does not take any argument. Returns the called callable result..
## [br][br]
## If [code]deferred_call[/code] is [code]true[/code], the callable is called using [method Callable.call_deferred] and
## the returned value will always be [code]null[/code].
## [br][br]
## See [method GTraits.if_is_a_or_else] for more details.
static func if_is_wave_manager_or_else(object:Object, if_callable:Callable, else_callable:Callable, deferred_call:bool = false) -> Variant:
	return if_is_a_or_else(WaveManager, object, if_callable, else_callable, deferred_call)

#endregion

