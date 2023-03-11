extends Control

signal selectedAssignmentNodeAltered

const VERSION = "1.3"

const ASSIGNMENT_NODE = preload("res://Scenes/AssignmentNode.tscn")
const CLASS_LABEL = preload("res://Scenes/ClassDisplayName.tscn")

const FILE_PATH = "user://SaveFile.cfg"
const BACKUP_FILE_PATH = "user://SaveFile_Backup.cfg"

# errors
const EMPTY_NAME_ERROR = 1
const ALREADY_EXISTS_ERROR = 2
const COULD_NOT_FIND_ERROR = 3

var classes:Array = []
var loadingThreads:Array = []
var selectedAssignment = null setget setSelectedAssignment

onready var addClassWindow = $AddClassPopup
onready var addAssignmentWindow = $AddAssignmentPopup
onready var assignmentsVBox = $ScrollContainer/VBoxContainer
onready var selectClassNode = $AddAssignmentPopup/VBoxContainer/OptionButton
onready var classDisplay = $LeftPanel/HBoxContainer/ScrollContainer/ClassList
onready var assignmentButtonGroup = ButtonGroup.new()
onready var searchAssignmentsLineEdit = $LeftPanel/HBoxContainer/SearchAssignments

func _ready():
	
	OS.set_window_title("Assignment Manager v" + VERSION)
	updateHelpMenuInfo()
	
	for i in range(10):
		loadingThreads.append(Thread.new())
	
	var sortButtons = $LeftPanel/HBoxContainer/SortButtons
	sortButtons.add_item("By Class")
	sortButtons.add_item("By Assignment")
	sortButtons.add_item("By Due Date")
	sortButtons.select(2)
	
	var ampmOptions = $AddAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions
	ampmOptions.add_item("AM")
	ampmOptions.add_item("PM")
	ampmOptions.select(0)
	
	ampmOptions = $EditAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions
	ampmOptions.add_item("AM")
	ampmOptions.add_item("PM")
	ampmOptions.select(0)
	
	ampmOptions = $AddRecursiveAssignment/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions
	ampmOptions.add_item("AM")
	ampmOptions.add_item("PM")
	ampmOptions.select(0)
	
	var periodType = $AddRecursiveAssignment/VBoxContainer/HBoxContainer3/PeriodType
	periodType.add_item("Hour(s)")
	periodType.add_item("Day(s)")
	periodType.add_item("Week(s)")
	periodType.add_item("Years(s)")
	
	loadFile()
	
	connect("tree_exited", self, "exitedTree")
	
	connect("selectedAssignmentNodeAltered", self, "checkSelectedAssignment")

func checkSelectedAssignment():
	
	print("checking")
	
	$TopPanel/HBoxContainer/ChangeDueDateButton.disabled = true
	$TopPanel/HBoxContainer/DeleteAssignmentButton.disabled = true
	
	if is_instance_valid(selectedAssignment):
		
		print("valid!")
		
		$TopPanel/HBoxContainer/ChangeDueDateButton.disabled = false
		$TopPanel/HBoxContainer/DeleteAssignmentButton.disabled = false

func updateHelpMenuInfo():
	$ProgramInfo/Info/ProgramName.text = "Name : " + "Assignment Manager"
	$ProgramInfo/Info/ProgramVersion.text = "version : " + VERSION
	$ProgramInfo/Info/AuthorName.text = "Author :  Andrew Ingram"
	$ProgramInfo/Info/Contact1.text = "contact 1 : insomniawins.business@gmail.com"
	$ProgramInfo/Info/Contact2.text = "contact 2 : andrewingram.business@gmail.com"

func exitedTree():
	saveFile()

func newClass(className) -> Dictionary:
	return {
		"className":className,
		"assignments":[]
	}

func addAssignmentToClass(classObj:Dictionary, newAssignment:Dictionary, refreshAssignments:bool = true) -> void:
	classObj.assignments.append(newAssignment)
	if refreshAssignments:
		refreshAssignments()

func newAssignment(assignmentName:String, dueDate:Dictionary) -> Dictionary:
	return {
		"assignmentName":assignmentName,
		"dueDate":dueDate
	}

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
	
	var newClass = newClass(className)
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
	assignmentNode.get_node("Button").connect("pressed", self, "assignmentSelected", [assignmentNode])
	assignmentNode.get_node("Button").group = assignmentButtonGroup
	return assignmentNode

func assignmentSelected(assignmentNode):
	setSelectedAssignment(assignmentNode)

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
	addAssignmentFromPopup($AddAssignmentPopup)

func addAssignmentFromPopup(popup):
	var classSelected:bool = true
	var addAssignmentSuccess:int = 0
	if popup.get_node("VBoxContainer/OptionButton").selected == -1 or $AddAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions.selected == -1:
		classSelected = false
		addAssignmentSuccess = COULD_NOT_FIND_ERROR
	
	if classSelected:
		var className:String = popup.get_node("VBoxContainer/OptionButton").get_item_text(popup.get_node("VBoxContainer/OptionButton").selected)
		var assignmentName:String = popup.get_node("VBoxContainer/LineEdit").text
		var month:int = popup.get_node("VBoxContainer/HBoxContainer/VBoxContainer/MonthSpin").value
		var day:int = popup.get_node("VBoxContainer/HBoxContainer/VBoxContainer2/DaySpin").value
		var year:int = popup.get_node("VBoxContainer/HBoxContainer/VBoxContainer3/YearSpin").value
		var hour:int = popup.get_node("VBoxContainer/HBoxContainer2/VBoxContainer/HourSpin").value
		var minute:int = popup.get_node("VBoxContainer/HBoxContainer2/VBoxContainer2/MinuteSpin").value
		var ampm:String = "AM" if popup.get_node("VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions").selected == 0 else "PM"
		
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


# faster version of addAssignment
# doesnt go through name checking or error handling
func addLoadedAssignment(classObj, assignmentName, dueDate) -> void:
	addAssignmentToClass(classObj, newAssignment(assignmentName, dueDate), false)

func addAssignment(className, assignmentName, dueDate) -> int:
	
	if assignmentName.empty():
		return EMPTY_NAME_ERROR
	
	if assignmentExists(className, assignmentName):
		return ALREADY_EXISTS_ERROR
	
	var classObj = getClass(className)
	if classObj == null:
		return COULD_NOT_FIND_ERROR
	
	var assignment = newAssignment(assignmentName, dueDate)
	addAssignmentToClass(classObj, assignment)
	
	return 0

func refreshAssignments():
	var vbox = $ScrollContainer/VBoxContainer
	for child in vbox.get_children():
		child.queue_free()
	
	var assignmentNodes = []
	
	for classObj in classes:
		for assignment in classObj.assignments:
			
			var assignmentName:String = assignment.assignmentName
			if searchAssignmentsLineEdit.text.empty() or (searchAssignmentsLineEdit.text in assignmentName.to_lower()):
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

func saveBackupFile():
	saveFile(BACKUP_FILE_PATH)

func saveFile(filePath:String = FILE_PATH):
	var saveFile = ConfigFile.new()
	saveFile.load(filePath)
	
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
	
	var i:int = 0
	var totalClasses = saveClasses.size()
	
	while i < totalClasses:
		var saveClass = saveClasses[i]
		addClass(saveClass.className)
		var classObj = classes[classes.size() - 1]
		
		var j:int = 0
		var assignmentsSize = saveClass.assignments.size()
		while j < assignmentsSize:
			var saveAssignment = saveClass.assignments[j]
			addLoadedAssignment(classObj, saveAssignment.assignmentName, saveAssignment.dueDate)
			j += 1
		
		i += 1
	
	refreshAssignments()
	
	print("loaded successfully")

func _on_SaveButton_pressed():
	saveFile()

func _on_LoadButton_pressed():
	loadFile()

func _on_ConfirmDeleteClass_confirmed():
	var className:String = $ConfirmDeleteClass.dialog_text.replace("Are you sure you want to delete ","")
	className = className.substr(0, className.length()-1)
	removeClass(className)


func _on_SearchAssignments_text_changed(new_text):
	refreshAssignments()


func _on_DeleteAssignmentButton_pressed():
	if !is_instance_valid(selectedAssignment):
		$Error.dialog_text = "No assignment selected!"
		$Error.popup_centered()
		return
	
	$ConfirmDeleteAssignment.dialog_text = "Are you sure you want to delete: \n\n" + selectedAssignment.assignment.assignmentName
	$ConfirmDeleteAssignment.popup_centered()

func _on_ConfirmDeleteAssignment_confirmed():
	removeAssignment(selectedAssignment)

# pressed signal for EditButton, too lazy to rename
func _on_ChangeDueDateButton_pressed():
	if !is_instance_valid(selectedAssignment):
		$Error.dialog_text = "No assignment selected!"
		$Error.popup_centered()
		return
	
	
	var possibleClassesNode = $EditAssignmentPopup/VBoxContainer/OptionButton
	
	for i in possibleClassesNode.items.size():
		if possibleClassesNode.items.size() == 0:
			break
		possibleClassesNode.remove_item(0)
	
	if possibleClassesNode.items.size() != classes.size():
		possibleClassesNode.items.clear()
		for i in classes.size():
			var classObj = classes[i]
			possibleClassesNode.add_item(classObj.className)
	
	var selectedClass = possibleClassesNode.items.find(selectedAssignment.className) / 5
	if selectedClass < possibleClassesNode.items.size():
		possibleClassesNode.select(selectedClass)
	
	$EditAssignmentPopup/VBoxContainer/LineEdit.text = selectedAssignment.assignment.assignmentName
	
	var dueDate = selectedAssignment.assignment.dueDate
	$EditAssignmentPopup/VBoxContainer/HBoxContainer/VBoxContainer/MonthSpin.value = dueDate.month
	$EditAssignmentPopup/VBoxContainer/HBoxContainer/VBoxContainer2/DaySpin.value = dueDate.day
	$EditAssignmentPopup/VBoxContainer/HBoxContainer/VBoxContainer3/YearSpin.value = dueDate.year
	$EditAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer2/MinuteSpin.value = dueDate.minute
	
	var ampm = 0
	var hour = dueDate.hour
	if hour >= 12:
		ampm = 1
		hour -= 12
	if hour == 0:
		hour = 12
	
	$EditAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer/HourSpin.value = hour
	$EditAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions.select(ampm)
	
	$EditAssignmentPopup.popup_centered()

func _on_CancelEditAssignment_pressed():
	$EditAssignmentPopup.visible = false

func _on_SaveAssignmentEditButton_pressed():
	removeAssignment(selectedAssignment)
	addAssignmentFromPopup($EditAssignmentPopup)
	$EditAssignmentPopup.visible = false


func _on_HelpButton_pressed():
	$ProgramInfo.popup_centered()


func _on_ItchPage_pressed():
	var url = "https://andrew-ingram.itch.io/assignment-manager"
	OS.shell_open(url)

func _on_RecursiveAddButton_pressed():
	var possibleClassesNode = $AddRecursiveAssignment/VBoxContainer/OptionButton
	
	var selectedClass = possibleClassesNode.selected
	
	for i in possibleClassesNode.items.size():
		if possibleClassesNode.items.size() == 0:
			break
		possibleClassesNode.remove_item(0)
	
	if possibleClassesNode.items.size() != classes.size():
		possibleClassesNode.items.clear()
		for i in classes.size():
			var classObj = classes[i]
			possibleClassesNode.add_item(classObj.className)
	
	if selectedClass < possibleClassesNode.items.size():
		possibleClassesNode.select(selectedClass)
	
	$AddRecursiveAssignment.popup_centered()


func _on_CancelAddRecursiveAssignment_pressed():
	$AddRecursiveAssignment.hide()

func _on_AddRecursiveAssignment_pressed():
	var popup = $AddRecursiveAssignment
	var classSelected:bool = true
	var addAssignmentSuccess:int = 0
	if popup.get_node("VBoxContainer/OptionButton").selected == -1 or $AddAssignmentPopup/VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions.selected == -1:
		classSelected = false
		addAssignmentSuccess = COULD_NOT_FIND_ERROR
	
	if classSelected:
		var className:String = popup.get_node("VBoxContainer/OptionButton").get_item_text(popup.get_node("VBoxContainer/OptionButton").selected)
		var assignmentName:String = popup.get_node("VBoxContainer/LineEdit").text
		
		if !("_x_" in assignmentName):
			$AddRecursiveAssignment.hide()
			$Error.dialog_text = "Must Include \"_x_\" in assignment name when using recursive method!"
			$Error.show()
			return
		
		var month:int = popup.get_node("VBoxContainer/HBoxContainer/VBoxContainer/MonthSpin").value
		var day:int = popup.get_node("VBoxContainer/HBoxContainer/VBoxContainer2/DaySpin").value
		var year:int = popup.get_node("VBoxContainer/HBoxContainer/VBoxContainer3/YearSpin").value
		var hour:int = popup.get_node("VBoxContainer/HBoxContainer2/VBoxContainer/HourSpin").value
		var minute:int = popup.get_node("VBoxContainer/HBoxContainer2/VBoxContainer2/MinuteSpin").value
		var ampm:String = "AM" if popup.get_node("VBoxContainer/HBoxContainer2/VBoxContainer3/AMPMOptions").selected == 0 else "PM"
		
		match ampm:
			"AM":
				if hour == 12:
					hour = 0
			"PM":
				
				if hour == 12:
					hour = 0
				
				hour += 12
		
		var dueDate = newDate(month, day, year, hour, minute)
		
		var periodAmount = $AddRecursiveAssignment/VBoxContainer/HBoxContainer3/PeriodAmount.value
		var periodType = $AddRecursiveAssignment/VBoxContainer/HBoxContainer3/PeriodType.get_item_text($AddRecursiveAssignment/VBoxContainer/HBoxContainer3/PeriodType.selected)
		var periodSeconds:int = 0
		match periodType:
			"Hour(s)":
				periodSeconds = 3600
			"Day(s)":
				periodSeconds = 86400
			"Week(s)":
				periodSeconds = 604800
			_: # default to years (because why not?) :)
				periodSeconds = 31536000
		
		dueDate = Time.get_unix_time_from_datetime_dict(dueDate)
		
		var assignmentCount = popup.get_node("VBoxContainer/HBoxContainer4/VBoxContainer/SpinBox").value
		
		if assignmentName.empty():
			addAssignmentSuccess = EMPTY_NAME_ERROR
		
		var classObj = getClass(className)
		if classObj == null:
			addAssignmentSuccess = COULD_NOT_FIND_ERROR
		
		var i = 0
		while i < assignmentCount and addAssignmentSuccess == 0:
			var newAssignmentName = assignmentName.replace("_x_", str(i+1))
			var newDueDate = Time.get_datetime_dict_from_unix_time(dueDate)
			
			if assignmentExists(className, assignmentName):
				addAssignmentSuccess = ALREADY_EXISTS_ERROR
				break
			
			var assignment = newAssignment(newAssignmentName, newDueDate)
			addAssignmentToClass(classObj, assignment, false)
			
			dueDate += periodSeconds
			i += 1
		
		refreshAssignments()
	$AddRecursiveAssignment.hide()
	
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

func setSelectedAssignment(assignmentNode):
	if is_instance_valid(selectedAssignment):
		selectedAssignment.disconnect("tree_exited",self,"selectedAssignmentExitedTree")
	selectedAssignment = assignmentNode
	selectedAssignment.connect("tree_exited",self,"selectedAssignmentExitedTree")
	emit_signal("selectedAssignmentNodeAltered")

func selectedAssignmentExitedTree():
	selectedAssignment = null
	checkSelectedAssignment()

func _on_OpenSaveFolder_pressed():
	OS.shell_open(str("file://", ProjectSettings.globalize_path("user://")))


func _on_MakeBackupButton_pressed():
	saveFile()
	saveBackupFile()
