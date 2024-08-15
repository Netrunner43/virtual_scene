extends CharacterBody3D

#nodes
@onready var camera_3d = $Camera3D
@onready var origCamPos : Vector3 = camera_3d.position
@onready var floorcast = $FloorDetectRayCast
@onready var player_footstep_sound = $PlayerFootstepSound
@onready var interact_cast = $Camera3D/InteractRayCast
@onready var interact_label = $InteractLabel

#camera
var mouse_sens := 0.15

#movement
var direction
var isRunning := false
var speed := 5
var jump := 15.0
const GRAVITY = 1
var distanceFootstep := 0.0
var playFootstep := 9 #Higher if we want to play the sounds faster
var _delta := 0.0
var camBobSpeed := 12
var camBobUpDown := 1

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$MeshInstance3D.visible = false

func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sens))
		camera_3d.rotate_x(deg_to_rad(-event.relative.y * mouse_sens))
		camera_3d.rotation.x = clamp(camera_3d.rotation.x,deg_to_rad(-89),deg_to_rad(89))
	if Input.is_action_just_pressed("run"):
		isRunning = true
	if Input.is_action_just_released("run"):
		isRunning = false
	if Input.is_action_just_pressed("interact"):
		var interacted = interact_cast.get_collider()
		if interacted !=null and interacted.is_in_group("Interactable") and interacted.has_method("action_use"):
			interacted.action_use()

func _process(delta):
	process_camBob(delta)
	
	if floorcast.is_colliding():
		var walkingTerrain = floorcast.get_collider().get_parent()
		if walkingTerrain != null and walkingTerrain.get_groups().size() > 0:
			var terraingroup = walkingTerrain.get_groups()[0]
			#print(terraingroup)
			processGroundSounds(terraingroup)
	prompInteractables()

func prompInteractables():
	if interact_cast.is_colliding():
		if is_instance_valid(interact_cast.get_collider()):
			if interact_cast.get_collider().is_in_group("Interactable"):
				interact_label.text = interact_cast.get_collider().type
				interact_label.visible = true
			else:
				interact_label.visible = false
	else:
		interact_label.visible = false


func processGroundSounds(group : String):
	if isRunning:
		playFootstep = 6
	else:
		playFootstep = 9
	if (int(velocity.x) != 0) || int(velocity.z) != 0:
		distanceFootstep+=.1
	
	if distanceFootstep > playFootstep and is_on_floor():
		match group:
			"WoodTerrain":
				player_footstep_sound.stream = load("res://player/soundsFootsteps/wood/1.ogg")
			"Grass":
				player_footstep_sound.stream = load("res://player/soundsFootsteps/grass/1.ogg")
		player_footstep_sound.pitch_scale = randf_range(.8,1.2)
		player_footstep_sound.play()
		distanceFootstep = 0.0

func _physics_process(delta):
	process_movement(delta)

func process_camBob(delta):
	_delta += delta
	
	var cam_bob #Speed
	var objCam #how much up/down the camera moves
	
	if isRunning:
		cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camBobSpeed * 1.5
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown
	elif direction != Vector3.ZERO:#moving
		cam_bob = floor(abs(direction.z) + abs(direction.x)) * _delta * camBobSpeed
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown
	else:#not moving
		cam_bob = floor(abs(1) + abs(1)) * _delta * .6
		objCam = origCamPos + Vector3.UP * sin(cam_bob) * camBobUpDown * .1

	camera_3d.position = camera_3d.position.lerp(objCam,delta)

func process_movement(delta):
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	direction.x = -Input.get_action_strength("ui_left") + Input.get_action_strength("ui_right")
	direction.z = -Input.get_action_strength("ui_up") + Input.get_action_strength("ui_down")
	direction = Vector3(direction.x,0,direction.z).rotated(Vector3.UP,h_rot).normalized()
	
	var actualSpeed = speed if !isRunning else speed*1.5
	velocity.x = direction.x * actualSpeed
	velocity.z = direction.z * actualSpeed
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y += jump
	if !is_on_floor():
		velocity.y -= GRAVITY
	
	move_and_slide()
