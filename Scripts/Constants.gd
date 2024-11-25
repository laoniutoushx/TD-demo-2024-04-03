extends Node

const RAY_LENGTH = 1000
const MOVE_MARGIN = 20
const MOVE_SPEED = 30


const WAVE_RESOURCE = "WAVE_RESOURCE"

var ROOT_NODE: Node = null
var GLB_TICKET: float = 0.0


# SIGNAL PREFIX
var LOGIC_DEAD = "logic_dead:"
var PHYSIC_DEAD = "physic_dead:"


# ANIMATION
var ANIM_RUN = "running"
var ANIM_WALK = "walk"
var ANIM_IDEL = "idel"
var ANIM_DEATH = "destory"
var ANIM_RELEASE = "release"


# Script Type
var MeshInstance3D_CLZ = "MeshInstance3D"
var AnimationPlayer_CLZ = "AnimationPlayer"
var AnimationTree_CLZ = "AnimationTree"

# Enemy Icon Dir Prefix
var ICON_ENEMY_DIR_PREFIX = "res://Asserts/Images/icon/enemy/"
var ICON_DEFAULT = "res://Asserts/Images/icon/default.svg"


# Selection Box Start and End controller flag
var SELECTION_START = false


# Action Bar
var SELECTION_BAR_MAX_SLOT_NUM = 16 * 2


# Input Event handler state control ( action bar and other _input func)
var CAN_PASS_THROUGH_3D = true


# Corsor Type
enum CURSOR_STATUS {
	DEFAULT,
	TARGETED
}