extends Label


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):	
	var r = get_parent().get_node("KinematicBody").get("num_restarts");
	text = "Deaths: " + str(r);
	
