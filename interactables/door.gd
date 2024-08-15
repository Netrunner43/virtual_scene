extends Interactable
@onready var door_animation = $door_animation

var isOpen := false
var canInteract := true
@export var isLocked := false
@export_node_path("Area3D") var keyPath
var actualKey

func _ready():
	if keyPath != null:
		actualKey = get_node(keyPath)

func action_use():
	if isLocked and !is_instance_valid(actualKey):
		isLocked = false
		print("door unlocked")
	if !isLocked:
		if canInteract:
			if isOpen:
				print("closing door")
				close()
			else:
				print("opening door")
				open()
	else:
		door_animation.play("locked_door")

func close():
	door_animation.play("door_close")
	canInteract = false
	isOpen = false

func open():
	door_animation.play("door_open")
	canInteract = false
	isOpen = true


@warning_ignore("unused_parameter")
func _on_animation_player_animation_finished(anim_name):
	canInteract = true
