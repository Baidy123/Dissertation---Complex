extends Area3D

@onready var world = $"../../../.."  # 获取 Timer 节点

func _on_body_entered(body):
	#print("111")
	if body.is_in_group("Player"):
		var all_groups = get_groups()  # 获取当前节点的所有组
		if all_groups.size() > 0:
			var random_group = all_groups[randi() % all_groups.size()]  # 随机选一个组
			print(random_group)
			world.new_area_entered(random_group)
