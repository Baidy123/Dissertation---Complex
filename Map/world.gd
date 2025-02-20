#extends Node3D
#
##var player = null
##var player_path = "../../../Player"
## Called when the node enters the scene tree for the first time.
#@onready var spawns = $Map/Spawns
#@onready var map = $Map
#@onready var player = %Player
#
#@export var waves = 1
#var zombie = load("res://models/enemy/enemy.tscn")
#var instance
#var area := "Area1"
#
#func _ready() -> void:
	#randomize()
#
#func _get_random_child(parent_node):
	#var random_id = randi() % parent_node.get_child_count()
	#return parent_node.get_child(random_id)
	#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	##if has_overlapping_areas():
		##print(self.name)
	#pass
#
#func new_area_entered(new_area: String):
	#area = new_area
#
#
#
#
#func _on_spawn_timer_timeout() -> void:
	#var spwan_pt = _get_random_child(spawns.get_node(area)).global_position
	#instance = zombie.instantiate()
	#instance.position = spwan_pt
	#map.add_child(instance)
	#
	
extends Node3D

@onready var spawns = $Map/Spawns
@onready var map = $Map
@onready var spawn_timer = %SpawnTimer
#@onready var player = %Player
@onready var player_scene = load("res://FpsControllor/player.tscn")
# 载入你僵尸预制体
var zombie_scene = load("res://models/enemy/enemy.tscn")


var area := "Area1"
# 当前波数，从 1 开始
var current_wave: int = 1
# 本波要生成的僵尸总数
var wave_zombies_to_spawn: int = 20
# 已经生成了几个
var wave_zombies_spawned: int = 0
# 当前场景里活着的僵尸数
var wave_zombies_alive: int = 0
# 已经被杀死的僵尸数
var wave_zombies_killed: int = 0

var total_zombies_killed: int = 0
# 同屏最多的僵尸数量
@export var max_on_screen = 10

# 每波在上一波基础上 +10
@export var wave_increment = 10
# 第一波默认 15 个, 之后加 wave_increment
@export var first_wave_count = 20

var door_unlocked :int = 0

var hud
func _ready() -> void:
	var player = player_scene.instantiate()
	$Map.add_child(player)
	player.position = $Map/PlayerPosition.position
	$GUI.init_sheet()
	hud = player.get_node("PlayerHUD").get_node("WaveNotice")
	hud.visible = true
	hud.text = "WAVE: " + str(current_wave)
	randomize()
	# 设定第一波数据
	_set_wave(current_wave)
	# 启动生成定时器
	spawn_timer.wait_time = 3
	spawn_timer.start()

# 每当 timer 超时，就试着生成一个僵尸(若还没达上限)
func _on_spawn_timer_timeout() -> void:
	# 如果这一波还没生成完 && 场上还不超过max_on_screen
	if wave_zombies_spawned < wave_zombies_to_spawn and wave_zombies_alive < max_on_screen:
		_spawn_one_zombie()

func _spawn_one_zombie():
	var spawn_pt = _get_random_spawn_position()
	var new_zombie = zombie_scene.instantiate()

	# 把新僵尸加到场景
	map.add_child(new_zombie)
	new_zombie.position = spawn_pt

	# 记数
	wave_zombies_spawned += 1
	wave_zombies_alive += 1

	# 给每只僵尸连接“死亡”信号 (需要僵尸脚本发出)
	if new_zombie.has_signal("zombie_died"):
		new_zombie.zombie_died.connect(_on_zombie_died)

func _on_zombie_died() -> void:
	# 僵尸死后
	wave_zombies_alive -= 1
	wave_zombies_killed += 1


	# 僵尸自己QueueFree或在它内部QueueFree
	# (此时可以选择移除连接)
	# 这里假设僵尸脚本里会 queue_free()

	# 如果本波所有都被杀了 => 进入下一波
	if wave_zombies_killed >= wave_zombies_to_spawn:
		_next_wave()

func _next_wave() -> void:
	current_wave += 1
	_set_wave(current_wave)
	# 重启 spawn 计时器
	spawn_timer.set_paused(true)
	await get_tree().create_timer(10).timeout
	spawn_timer.set_paused(false)
	hud.text = "WAVE: " + str(current_wave)
	spawn_timer.start()

func _set_wave(wave_num: int) -> void:
	# 重置本波数据
	wave_zombies_spawned = 0
	wave_zombies_alive = 0
	total_zombies_killed += wave_zombies_killed
	wave_zombies_killed = 0
	

	# 计算本波一共要生成多少
	if wave_num == 1:
		wave_zombies_to_spawn = first_wave_count  # =15
	else:
		wave_zombies_to_spawn = first_wave_count + wave_increment * (wave_num - 1)

	print("== Start Wave ", wave_num, " : Need to spawn ", wave_zombies_to_spawn)

func new_area_entered(new_area: String):
	area = new_area

var last_position := -1  # 用于记录上一次使用的随机索引，初始设为 -1 表示“无”
func _get_random_spawn_position() -> Vector3:
	if not spawns or spawns.get_node(area).get_child_count() == 0:
		return Vector3.ZERO
	
	var child_count = spawns.get_node(area).get_child_count()
	var random_id = randi() % child_count
	
	# 若只有 1 个子节点，其实无法避免“同样位置”，除非你想要别的逻辑
	if child_count > 1:
		# 如果 child_count > 1，则可以保证我们能找个不同于 last_position 的位置
		while random_id == last_position:
			random_id = randi() % child_count
	
	# 记录本次索引，以防下次重复
	last_position = random_id
	
	var spawn_node = spawns.get_node(area).get_child(random_id)
	if spawn_node:
		return spawn_node.global_position
	return Vector3.ZERO
