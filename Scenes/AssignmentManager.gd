extends Control

class Class:
	signal assignmentAdded
	
	var className:String
	var assignments:Array
	
	func _init(className:String):
		self.className = className
	
	func addAssignment(newAssignment : Assignment):
		assignments.append(newAssignment)
		emit_signal("assignmentAdded")
	
	func _to_string():
		return toString()
	
	func toString() -> String:
		var returnString = className + " : {"
		
		for assignment in assignments:
			returnString = returnString + "\n    " + assignment.toString()
		
		returnString = returnString + "\n}"
		
		return returnString

class Assignment:
	
	var assignmentName:String
	var dueDate:Dictionary
	
	func _init(assignmentName:String, dueDate:Dictionary):
		self.assignmentName = assignmentName
		self.dueDate = dueDate
	
	func _to_string():
		return toString()
	
	func toString() -> String:
		var returnString:String = assignmentName + " : " + String(dueDate)
		return returnString

const ASSIGNMENT_NODE = preload("res://Scenes/AssignmentNode.tscn")
const CLASS_LABEL = preload("res://Scenes/ClassDisplayName.tscn")

const FILE_PATH = "user://SaveFile.cfg"

# errors
const EMPTY_NAME_ERROR = 1
const ALREADY_EXISTS_ERROR = 2
const COULD_NOT_FIND_ERROR = 3

var classes:Array = []

onready var addClassWindow = $AddClassPopup
onready var addAssignmentWindow = $AddAssignmentPopup
onready var assignmentsVBox = $ScrollContainer/VBoxContainer
onready var selectClassNode = $AddAssignmentPopup/VBoxContainer/OptionButton
onready var classDisplay = $LeftPanel/HBoxContainer/ScrollContainer/ClassList

func _ready():
	
	var sortButtons = $LeftPanel/HBoxContainer/SortButtons
	sortButtons.add_item("By Class")
	sortButtons.add_item("By Assignment")
	sortButtons.add_item("By Due Date")
	sortButtons.select(2)
	
	var ampmOptions = $AddAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions
	ampmOptions.add_item("AM")
	ampmOptions.add_item("PM")
	ampmOptions.select(0)
	
	loadFile()
	
	connect("tree_exited", self, "exitedTree")

func exitedTree():
	saveFile()

func refreshClasses():
	for child in classDisplay.get_children():
		child.queue_free()
	
	for classObj in classes:
		var newClassLabel = CLASS_LABEL.instance()
		newClassLabel.className = classObj.className
		classDisplay.add_child(newClassLabel)
		newClassLabel.connect("removeClass", self, "removeClassButtonPressed")

func removeClassButtonPressed(className):
	$ConfirmDeleteClass.dialog_text = "Are you sure you want to delete " + className + "?"
	$ConfirmDeleteClass.popup_centered()

func removeClass(className:String):
	for i in classes.size():
		var classObj = classes[i]
		if classObj.className == className:
			classes.remove(i)
			break
	
	refreshClasses()
	refreshAssignments()

func addClass(className:String) -> int:
	
	if className.empty():
		return EMPTY_NAME_ERROR
	
	if classExists(className):
		return ALREADY_EXISTS_ERROR
	
	var newClass = Class.new(className)
	newClass.connect("assignmentAdded", self, "refreshAssignments")
	classes.append(newClass)
	
	refreshClasses()
	
	return 0

func getClass(className):
	
	for classObject in classes:
		if classObject.className == className:
			return classObject
	
	return null

func classExists(className) -> bool:
	for classObj in classes:
		if classObj.className == className:
			return true
	return false

static func timeUntil(date:Dictionary) -> int:
	var days:int = 0
	
	var currentUnixTime:int = getUnixTime()
	var unixDifference:int = OS.get_unix_time_from_datetime(date) - currentUnixTime
	
	return unixDifference

static func secondsToDatetime(seconds:int) -> Dictionary:
	var days:int = 0
	var hours:int = 0
	var minutes:int = 0
	
	while seconds >= 60:
		seconds -= 60
		minutes += 1
	
	while minutes >= 60:
		minutes -= 60
		hours += 1
	
	while hours >= 24:
		hours -= 24
		days += 1
	
	return {
		"days":days,
		"hours":hours,
		"minutes":minutes,
		"seconds":seconds
	}

static func getUnixTime() -> int:
	return OS.get_unix_time_from_datetime(OS.get_datetime())

static func newDate(month:int, day:int, year:int, hour:int, minute:int = 0, second:int = 0, weekday:int = 0, dst:bool = false) -> Dictionary:
	return {
		"day":day,
		"dst":dst,
		"hour":hour,
		"minute":minute,
		"month":month,
		"second":second,
		"weekday":weekday,
		"year":year
	}

func addAssignmentNode(className, assignment):
	var assignmentNode = ASSIGNMENT_NODE.instance()
	assignmentNode.className = className
	assignmentNode.assignment = assignment
	assignmentNode.connect("removeAssignment",self,"removeAssignment")
	return assignmentNode

func removeAssignment(assignmentNode):
	var classObj = getClass(assignmentNode.className)
	
	if classObj == null:
		return
	
	
	for i in classObj.assignments.size():
		var assignment = classObj.assignments[i]
		if assignment == assignmentNode.assignment:
			classObj.assignments.remove(i)
			break
	
	refreshAssignments()

func _on_AddClassButton_pressed():
	addClassWindow.popup_centered()

func _on_CancelAddClassButton_pressed():
	addClassWindow.hide()

func _on_PopupAddClassButton_pressed():
	var classSuccess = addClass($AddClassPopup/VBoxContainer/LineEdit.text)
	
	addClassWindow.hide()
	
	match classSuccess:
		EMPTY_NAME_ERROR:
			$Error.dialog_text = "Class cannot have a blank name!"
			$Error.popup_centered()
			return
		ALREADY_EXISTS_ERROR:
			$Error.dialog_text = "Class already exists!"
			$Error.popup_centered()
			return

func _on_AddAssignmentButton_pressed():
	var possibleClassesNode = selectClassNode
	
	var selectedClass = possibleClassesNode.get_selected_id()
	
	for i in possibleClassesNode.items.size():
		if possibleClassesNode.items.size() == 0:
			break
		possibleClassesNode.remove_item(0)
	
	if possibleClassesNode.items.size() != classes.size():
		for i in classes.size():
			var classObj = classes[i]
			possibleClassesNode.add_item(classObj.className)
	
	if selectedClass < possibleClassesNode.items.size():
		possibleClassesNode.select(selectedClass)
	
	
	addAssignmentWindow.popup_centered()


func _on_CancelAddAssignmentButton_pressed():
	addAssignmentWindow.hide()

func _on_AddAssignmentWindowButton_pressed():
	
	var classSelected:bool = true
	var addAssignmentSuccess:int = 0
	if $AddAssignmentPopup/VBoxContainer/OptionButton.selected == -1 or $AddAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions.selected == -1:
		classSelected = false
		addAssignmentSuccess = COULD_NOT_FIND_ERROR
	
	if classSelected:
		var className:String = $AddAssignmentPopup/VBoxContainer/OptionButton.get_item_text($AddAssignmentPopup/VBoxContainer/OptionButton.selected)
		var assignmentName:String = $AddAssignmentPopup/VBoxContainer/LineEdit.text
		var month:int = $AddAssignmentPopup/VBoxContainer/HBoxContainer/VBoxContainer/MonthSpin.value
		var day:int = $AddAssignmentPopup/VBoxContainer/HBoxContainer/VBoxContainer2/DaySpin.value
		var year:int = $AddAssignmentPopup/VBoxContainer/HBoxContainer/VBoxContainer3/YearSpin.value
		var hour:int = $AddAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer/HourSpin.value
		var minute:int = $AddAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer2/MinuteSpin.value
		var ampm:String = "AM" if $AddAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions.selected == 0 else "PM"
		
		match ampm:
			"AM":
				if hour == 12:
					hour = 0
			"PM":
				
				if hour == 12:
					hour = 0
				
				hour += 12
		
		var dueDate = newDate(month, day, year, hour, minute)
		
		addAssignmentSuccess = addAssignment(className, assignmentName, dueDate)
	
	addAssignmentWindow.hide()
	
	match addAssignmentSuccess:
		EMPTY_NAME_ERROR:
			$Error.dialog_text = "Assignment name cannot be blank!"
			$Error.popup_centered()
		ALREADY_EXISTS_ERROR:
			$Error.dialog_text = "Assignment with that name already exists!"
			$Error.popup_centered()
		COULD_NOT_FIND_ERROR:
			$Error.dialog_text = "No class specified could be found!"
			$Error.popup_centered()

func assignmentExists(className, assignmentName) -> bool:
	
	for classObj in classes:
		if classObj.className == className:
			
			for assignment in classObj.assignments:
				if assignment.assignmentName == assignmentName:
					
					return true
	
	return false

func addAssignment(className, assignmentName, dueDate) -> int:
	
	if assignmentName.empty():
		return EMPTY_NAME_ERROR
	
	if assignmentExists(className, assignmentName):
		return ALREADY_EXISTS_ERROR
	
	var classObj = getClass(className)
	if classObj == null:
		return COULD_NOT_FIND_ERROR
	
	var assignment = Assignment.new(assignmentName, dueDate)
	classObj.addAssignment(assignment)
	
	return 0

func refreshAssignments():
	var vbox = $ScrollContainer/VBoxContainer
	for child in vbox.get_children():
		child.queue_free()
	
	var assignmentNodes = []
	
	for classObj in classes:
		for assignment in classObj.assignments:
			assignmentNodes.append(addAssignmentNode(classObj.className, assignment))
	
	var sortSelection = $LeftPanel/HBoxContainer/SortButtons.get_item_text($LeftPanel/HBoxContainer/SortButtons.selected)
	match sortSelection:
		"By Due Date":
			assignmentNodes.sort_custom(AssignmentNode,"sortByDate")
		"By Class":
			assignmentNodes.sort_custom(AssignmentNode,"sortByClass")
		"By Assignment":
			assignmentNodes.sort_custom(AssignmentNode,"sortByAssignment")
		_:
			pass
	
	for node in assignmentNodes:
		vbox.add_child(node)

func _on_SortButtons_item_selected(index):
	refreshAssignments()

func saveFile():
	var saveFile = ConfigFile.new()
	saveFile.load(FILE_PATH)
	
	var saveClasses = []
	for classObj in classes:
		var saveClass = {
			"className":classObj.className,
			"assignments":null
		}
		var saveAssignments = []
		for assignment in classObj.assignments:
			saveAssignments.append({
				"assignmentName":assignment.assignmentName,
				"dueDate":assignment.dueDate
			})
		saveClass.assignments = saveAssignments
		saveClasses.append(saveClass)
	
	saveFile.set_value("misc","classes",saveClasses)
	
	saveFile.save(FILE_PATH)
	print("saved successfully")

func loadFile():
	var file = File.new()
	if !file.file_exists(FILE_PATH):
		return
	
	var saveFile = ConfigFile.new()
	saveFile.load(FILE_PATH)
	
	var saveClasses = saveFile.get_value("misc","classes",[])
	
	for saveClass in saveClasses:
		addClass(saveClass.className)
		var classObj = classes[classes.size() - 1]
		for saveAssignment in saveClass.assignments:
			addAssignment(classObj.className, saveAssignment.assignmentName, saveAssignment.dueDate)
	
	print("loaded successfully")

func _on_SaveButton_pressed():
	saveFile()

func _on_LoadButton_pressed():
	loadFile()

func _on_ConfirmDeleteClass_confirmed():
	var className:String = $ConfirmDeleteClass.dialog_text.replace("Are you sure you want to delete ","")
	className = className.substr(0, className.length()-1)
	removeClass(className)
