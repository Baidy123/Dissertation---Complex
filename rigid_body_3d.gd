extends RigidBody3D

@export var hp := 50

# Called when the node enters the scene tree for the first time.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Label3D.text = "HP: " + str(hp)

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		$"..".queue_free()
		
func take_backstab_damage(amount : int):
	take_damage(amount * 10)
