extends Area3D

signal body_part_hit()
@export var critical_multi := 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print(self.collision_layer)
	#print(self.global_position)
	pass

func take_damage(dmg: int):
	emit_signal("body_part_hit", dmg, critical_multi)
	
