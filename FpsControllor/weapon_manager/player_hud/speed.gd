extends Label

func _process(delta: float) -> void:
	self.text = "Speed : " + str($"../..".player.velocity.length()).left(5) + "m/s"
