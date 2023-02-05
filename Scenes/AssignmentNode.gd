extends Control
class_name AssignmentNode

signal removeAssignment(assignmentNode)

var assignmentID:int = -1
var className
var assignment

onready var classLabel:Label = $HBoxContainer/ClassPanel/Label
onready var assignmentLabel:Label = $HBoxContainer/AssignmentPanel/Label
onready var dateLabel:Label = $HBoxContainer/DatePanel/Label

func _ready():
	if assignment == null:
		queue_free()
		return
	
	classLabel.text = className
	assignmentLabel.text = assignment.assignmentName
	var hour = assignment.dueDate.hour if assignment.dueDate.hour <= 11 else assignment.dueDate.hour - 12
	if hour == 0:
		hour = 12
	dateLabel.text = str(assignment.dueDate.month, "/", assignment.dueDate.day, "/", assignment.dueDate.year, " ", hour, ":", str(assignment.dueDate.minute).pad_zeros(2), " AM" if assignment.dueDate.hour < 12 else " PM")

func getDueDateUnix() -> int:
	return Time.get_unix_time_from_datetime_dict(assignment.dueDate)

func _on_CloseButton_pressed():
	emit_signal("removeAssignment", self)

static func sortByDate(a, b) -> bool:
	if a.getDueDateUnix() < b.getDueDateUnix():
		return true
	return false

static func sortByClass(a, b) -> bool:
	if a.className < b.className:
		return true
	return false

static func sortByAssignment(a, b) -> bool:
	if a.assignment.assignmentName < b.assignment.assignmentName:
		return true
	return false
