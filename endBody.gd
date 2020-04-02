extends RigidBody


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var base_transform;
var settled = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	base_transform = transform;
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	print(transform)
	if (base_transform != transform and settled == false):
		base_transform = transform;
	elif (base_transform != transform):
		print("Fuck");
	elif (base_transform == transform):
		settled = true;
	pass
