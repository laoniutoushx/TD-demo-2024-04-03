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

