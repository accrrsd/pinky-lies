extends CanvasLayer
class_name NovelChoices

signal choice_selected(index: int)

const PANEL_BUTTON_SCENE = preload("res://3_scenes/ui_kit/PanelButton/PanelButton.tscn")

@export var choices_container: VBoxContainer
@export var timer_bar: ProgressBar
@export var timer_label: Label

var _selected_index: int = -1
var _is_waiting: bool = false

func _ready() -> void:
  layer = 110
  hide()
  if not choices_container: choices_container = find_child("ChoicesContainer", true, false) as VBoxContainer
  if not timer_bar: timer_bar = find_child("ChoiceTimerBar", true, false) as ProgressBar
  if not timer_label: timer_label = find_child("ChoiceTimerLabel", true, false) as Label

func display_choices(options: Array[String]) -> int:
  if not choices_container: return -1
  _clear_buttons()
  _selected_index = -1
  _is_waiting = true

  for i in range(options.size()):
    var opt_text := options[i]
    var btn_instance = PANEL_BUTTON_SCENE.instantiate()
    if "text" in btn_instance: btn_instance.text = opt_text
    choices_container.add_child(btn_instance)

    var click_btn: Button = btn_instance as Button
    if not click_btn and "button" in btn_instance and btn_instance.button is Button:
      click_btn = btn_instance.button
    elif not click_btn:
      click_btn = btn_instance.get_node_or_null("Button") as Button

    if click_btn: click_btn.pressed.connect(_on_choice_clicked.bind(i))
    elif btn_instance.has_signal("pressed"): btn_instance.pressed.connect(_on_choice_clicked.bind(i))

  show()

  if choices_container.get_child_count() > 0:
    var first_child = choices_container.get_child(0)
    var btn = first_child.get_node_or_null("Button") as Control
    if btn: btn.grab_focus()
    elif first_child is Control: (first_child as Control).grab_focus()

  while _is_waiting and _selected_index == -1: await choice_selected
  _is_waiting = false
  hide()
  _clear_buttons()
  set_timer_visual(0.0, 0.0)
  return _selected_index

func set_timer_visual(time_left: float, max_time: float) -> void:
  if timer_bar:
    timer_bar.max_value = max_time
    timer_bar.value = maxf(time_left, 0.0)
    timer_bar.visible = time_left > 0.0
  if timer_label:
    timer_label.text = "⏱️ Время на выбор: %.1fс" % maxf(time_left, 0.0)
    timer_label.visible = time_left > 0.0

func _on_choice_clicked(index: int) -> void:
  _selected_index = index
  choice_selected.emit(index)

func _clear_buttons() -> void:
  if not choices_container: return
  for child in choices_container.get_children():
    if child == timer_bar or child == timer_label: continue
    choices_container.remove_child(child)
    child.queue_free()
