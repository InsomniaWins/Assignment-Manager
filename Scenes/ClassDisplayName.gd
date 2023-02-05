extends MarginContainer

signal removeClass(className)

var className = ""

func _ready():
	$HBoxContainer/Label.text = className

func _on_CloseButton_pressed():
	emit_signal("removeClass", className)
