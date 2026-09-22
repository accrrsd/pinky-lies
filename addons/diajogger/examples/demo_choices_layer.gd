extends CanvasLayer
class_name DemoChoicesLayer

signal choice_selected(index: int)

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
    var btn := Button.new()
    btn.text = options[i]
    btn.custom_minimum_size = Vector2(520, 52)
    btn.pressed.connect(_on_choice_clicked.bind(i))
    choices_container.add_child(btn)

  show()

  for child in choices_container.get_children():
    if child is Button:
      child.grab_focus()
      break

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
