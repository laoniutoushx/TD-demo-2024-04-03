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


# Script Type
var MeshInstance3D_CLZ = "MeshInstance3D"

# Enemy Icon Dir Prefix
var ICON_ENEMY_DIR_PREFIX = "res://Asserts/Images/icon/enemy/"

# State Control
var SELECTION_START = false

# Action Bar
var SELECTION_BAR_MAX_SLOT_NUM = 16 * 2
