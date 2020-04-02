extends KinematicBody

# Some ideas and code are borrowed from
# https://pastebin.com/7bVvEJwp

var velocity = Vector3()
#var gravity = Vector3.DOWN * 50;
var gravity = 50;
var glide_grav = 200;
var jump_1 = Vector3.UP * 100;
var jump_1_imp = 2000;
var jump_2_imp = 1500;
var airborne = false;
var move_mult = 800;
var term_vel = 6000;

var curr_pos = Vector3();
var prev_pos = Vector3();
var init_pos = Vector3();

var prev_on_ground = false;
var curr_on_ground = false;
var is_on_ground = false;

var has_won = false;
var num_restarts = 0;

#Animations
var walking = false;
var jumping_1 = false;
var jumping_2 = false;
var gliding = false;
var falling = false;
var running = false;
var pecking = false;
var done_peck = false;

var starting_transform;

onready var anim = get_node("duck").get_node("AnimationPlayer");

const H_LOOK_SENS = 1.0
const V_LOOK_SENS = .25
const CON_H_LOOK_SENS = 1.0
const CON_V_LOOK_SENS = 1.0

#onready var cam = get_node("Camera");
onready var cam = get_node("camera_base/Camera")

var video = preload("res://win_game.ogv");
onready var vidPlayer = get_node("VideoPlayer"); 


# Called when the node enters the scene tree for the first time.
func _ready():
	
	set_as_toplevel(true)
	starting_transform = global_transform;
	pass # Replace with function body.

#Stolen
func _input(event):
	if event is InputEventMouseMotion:
		cam.rotation_degrees.x -= event.relative.y * V_LOOK_SENS
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -25, 25)
		cam.rotation_degrees.y -= event.relative.x * H_LOOK_SENS
		cam.rotation_degrees.y = clamp(cam.rotation_degrees.y, -35, 35);

func _physics_process(delta):
	
	#You win
	if (translation.x > 1100):
		win();
	#You lose
	elif (translation.y < 4):
		reset();
	
	
	#print(cam)
	#cam = get_node("camera_base/Camera").get_global_transform();
	
	var turn_rate = 1.25 *  delta;
	
	#prev_pos = get_global_transform().get_translation();
	prev_pos = curr_pos;
	
	var dir = Vector3();
	
	velocity.x = 0;
	velocity.z = 0;
	
	walking = false;
	pecking = false;
	#velocity = Vector3(0, 0, 0)
	if (gliding == false and falling == false):
		if Input.is_action_pressed("ui_up"):
			#dir = -cam.basis[1];
			velocity.z = -move_mult * delta
			walking = true;
		if Input.is_action_pressed("ui_down"):
			#dir = cam.basis[1];
			velocity.z = move_mult * delta
			walking = true;
	else:
		velocity.z = -move_mult * delta;
			
	if Input.is_action_pressed("ui_left"):
		#dir = -cam.basis[0];
		rotate_y(turn_rate)
		walking = true;
	if Input.is_action_pressed("ui_right"):
		#dir = cam.basis[0];
		rotate_y(-turn_rate)
		walking = true;
		
	
	#Controller camera
	
	if Input.is_action_pressed("ui_downCamera"):
		cam.rotation_degrees.x -= CON_V_LOOK_SENS;# * delta
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -25, 25)
	if Input.is_action_pressed("ui_upCamera"):
		cam.rotation_degrees.x += CON_V_LOOK_SENS;# * delta
		cam.rotation_degrees.x = clamp(cam.rotation_degrees.x, -25, 25)
	if Input.is_action_pressed("ui_rightCamera"):
		cam.rotation_degrees.y -= CON_H_LOOK_SENS;# * delta
		cam.rotation_degrees.y = clamp(cam.rotation_degrees.y, -35, 35);
	if Input.is_action_pressed("ui_leftCamera"):
		cam.rotation_degrees.y += CON_H_LOOK_SENS;# * delta
		cam.rotation_degrees.y = clamp(cam.rotation_degrees.y, -35, 35);
	
	#dir = dir.normalized() * delta * move_mult;
	#velocity += dir;
	
	running = false;
	if Input.is_action_pressed("ui_shift"):
		velocity.z = -move_mult * delta * 2;
		
		running = true;
	
	if Input.is_action_just_pressed("ui_peck"):
		pecking = true;
	
	if Input.is_action_just_pressed("ui_reset"):
		reset();
	
	#print(is_on_ground);
	#print(jumping_1);
	
	if (is_on_ground):
		jumping_1 = false;
		jumping_2 = false;
		gliding = false;
		falling = false;
	
	
	if Input.is_action_just_pressed("ui_select"):
		if (is_on_ground == true):
			if running:
				velocity.y += jump_1_imp * delta * .75;
			else:
				velocity.y += jump_1_imp * delta;
			jumping_1 = true;
		
		elif (jumping_2 == false):
			jumping_2 = true;
			if running:
				velocity.y += jump_2_imp * delta * .75;
			else:
				velocity.y += jump_2_imp * delta;
			
		elif (jumping_2 == true and gliding == false):
			gliding = true;
			falling = false;
			
		elif (gliding == true):
			falling = true;
			gliding = false;
		
	
	calc_anim(walking,jumping_1,jumping_2,gliding,falling,running,pecking);
	
	var bruh_vel = get_transform().basis.xform(velocity);
	
	self.move_and_slide(bruh_vel)
	curr_pos = translation;
	
	
	
	#Are we on the ground?
	#THIS DOESN'T WORK SO I'M GOING TO TRY SOMETHING DIFFERENT
	#var on_ground = self.is_on_floor();
	#Determine if the y direction hasn't changed, and we need to use two frames
	is_on_ground = false; 
	var on_ground = false;	
	#Define an okay range because we gots to
	var okay_range = .001;
	var low_prev = prev_pos.y - okay_range;
	var high_prev = prev_pos.y + okay_range;
	if (curr_pos.y > low_prev):
		if (curr_pos.y < high_prev):
			on_ground=true;
	curr_on_ground = on_ground;
	if (on_ground):
		velocity.y = -gravity * delta;
	else:
		if (gliding):
			velocity.y = -glide_grav * delta;
		else:
			velocity.y -= gravity * delta
			if(velocity.y < -term_vel):
				velocity.y = -term_vel;
	if (prev_on_ground == true):
		if (curr_on_ground == true):
			is_on_ground = true;
	prev_on_ground = on_ground;
	

	

func calc_anim(walk,jump1,jump2,glide,fall,run,peck):
	if (peck or done_peck):
		play_anim("duck_peck")
	elif (glide):
		play_anim("duck_glide");
	elif (fall):
		play_anim("duck_fall");
	elif (jump2):
		play_anim("duck_double_jump");
	elif (jump1):
		play_anim("duck_jump");
	elif (run):
		play_anim("duck_run")
	elif (walk):
		play_anim("duck_walk");
	else:
		play_anim("duck_idle");
		#print("FUCK")
		

#Stolen
func play_anim(animation):
	if anim.current_animation == animation:
		pass
	else:
		#print(animation)
		if (anim.current_animation != "duck_peck"):
			anim.play(animation)
	

func reset():
	num_restarts += 1;
	global_transform = starting_transform;

func win():
	
	if (has_won == false):
		vidPlayer.set_stream(video);
		set_process(true);
		
		if not vidPlayer.is_playing():
			vidPlayer.play();
			
	has_won = true;
	
