extends PanelContainer

signal slot_pressed(slot_id: int)
signal trash_pressed(slot_id: int)

class BiteManager:
  var bite_material: ShaderMaterial
  var bite_tween: Tween
  var target_nodes: Array[CanvasItem] = []
  var cookie_visual: Control

  func init(p_cookie_visual: Control, nodes: Array[CanvasItem]) -> void:
    cookie_visual = p_cookie_visual
    target_nodes = nodes
    _setup_material()

  func _setup_material() -> void:
    var shader_res = load("res://2_general/resources/shaders/gdshader/cookie_bite.gdshader")
    if not shader_res: return
    bite_material = ShaderMaterial.new()
    bite_material.shader = shader_res
    for node in target_nodes: if node: node.material = bite_material

  func play_bite() -> void:
    if not bite_material or not cookie_visual: return
    var corner: int = randi() % 4
    var gpos: Vector2 = cookie_visual.global_position
    var gsize: Vector2 = cookie_visual.size
    var margin: float = 14.0
    var center: Vector2 = Vector2.ZERO
    var dir: Vector2 = Vector2.ZERO
    match corner:
      0:
        center = gpos + Vector2(margin, margin)
        dir = Vector2(1.0, 1.0).normalized()
      1:
        center = gpos + Vector2(gsize.x - margin, margin)
        dir = Vector2(-1.0, 1.0).normalized()
      2:
        center = gpos + Vector2(gsize.x - margin, gsize.y - margin)
        dir = Vector2(-1.0, -1.0).normalized()
      3:
        center = gpos + Vector2(margin, gsize.y - margin)
        dir = Vector2(1.0, -1.0).normalized()
    var radius: float = minf(gsize.x, gsize.y) * 0.46
    bite_material.set_shader_parameter("bite_center_px", center)
    bite_material.set_shader_parameter("bite_dir", dir)
    bite_material.set_shader_parameter("bite_radius_px", radius)
    bite_material.set_shader_parameter("bite_progress", 0.0)
    if bite_tween and bite_tween.is_valid(): bite_tween.kill()
    bite_tween = cookie_visual.create_tween().set_parallel(true)
    bite_tween.tween_property(bite_material, "shader_parameter/bite_progress", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    cookie_visual.pivot_offset = gsize / 2.0
    bite_tween.tween_property(cookie_visual, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    bite_tween.chain().tween_property(cookie_visual, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

  func reset() -> void: if bite_material: bite_material.set_shader_parameter("bite_progress", 0.0)

@export var default_preview: Texture2D

var current_slot_id: int = 1
var has_save: bool = false
var bite_manager: BiteManager = BiteManager.new()
var _hover_tween: Tween

@onready var cookie_visual: Control = $MarginContainer/VBoxContainer/CookieArea/Slot/CookieVisual
@onready var shadow_node: Control = $MarginContainer/VBoxContainer/CookieArea/Slot/Shadow
@onready var bg_rect: TextureRect = $MarginContainer/VBoxContainer/CookieArea/Slot/CookieVisual/bg
@onready var panel_node: Panel = $MarginContainer/VBoxContainer/CookieArea/Slot/CookieVisual/MarginContainer/Panel
@onready var content_rect: TextureRect = %Content
@onready var fg_rect: TextureRect = $MarginContainer/VBoxContainer/CookieArea/Slot/CookieVisual/fg
@onready var main_button: Button = $MarginContainer/VBoxContainer/CookieArea/Slot/Button
@onready var trash_button: Button = $MarginContainer/VBoxContainer/CookieArea/Slot/TrashButton
@onready var slot_title_label: Label = $MarginContainer/VBoxContainer/InfoPlaque/MarginContainer/VBoxContainer/SlotTitle
@onready var slot_date_label: Label = $MarginContainer/VBoxContainer/InfoPlaque/MarginContainer/VBoxContainer/SlotDate
@onready var slot_info_label: Label = $MarginContainer/VBoxContainer/InfoPlaque/MarginContainer/VBoxContainer/SlotInfo

func _ready() -> void:
  _init_shadow()
  _init_bite_manager()
  if main_button: main_button.pressed.connect(_on_button_pressed)
  if main_button: main_button.mouse_entered.connect(_on_mouse_entered)
  if main_button: main_button.mouse_exited.connect(_on_mouse_exited)
  if trash_button: trash_button.pressed.connect(_on_trash_pressed)

func _init_shadow() -> void:
  if shadow_node:
    shadow_node.pivot_offset = shadow_node.size / 2.0
    if not shadow_node.resized.is_connected(_on_shadow_resized): shadow_node.resized.connect(_on_shadow_resized)

func _on_shadow_resized() -> void: if shadow_node: shadow_node.pivot_offset = shadow_node.size / 2.0

func _init_bite_manager() -> void: bite_manager.init(cookie_visual, [bg_rect, panel_node, fg_rect, content_rect])

func set_slot_data(slot_id: int, p_has_save: bool, info: Dictionary) -> void:
  current_slot_id = slot_id
  has_save = p_has_save
  if slot_title_label: slot_title_label.text = tr("SLOT %02d" % slot_id)
  if trash_button: trash_button.visible = has_save
  if has_save:
    if content_rect:
      content_rect.visible = true
      content_rect.modulate = Color.WHITE
      if default_preview and not content_rect.texture: content_rect.texture = default_preview
    if slot_date_label: slot_date_label.text = info.get("timestamp", "")
    if slot_info_label:
      var title = info.get("title", "Save %d" % slot_id)
      var playtime = info.get("playtime", "")
      slot_info_label.text = ("%s  •  %s" % [title, playtime]) if not playtime.is_empty() else title
  else:
    if content_rect:
      content_rect.visible = false
      content_rect.texture = null
    if slot_date_label: slot_date_label.text = tr("Empty_Slot")
    if slot_info_label: slot_info_label.text = "-"

func play_bite_animation() -> void: bite_manager.play_bite()

func reset_bite() -> void: bite_manager.reset()

func _on_button_pressed() -> void:
  play_bite_animation()
  slot_pressed.emit(current_slot_id)

func _on_trash_pressed() -> void: trash_pressed.emit(current_slot_id)

func _on_mouse_entered() -> void:
  if _hover_tween and _hover_tween.is_valid(): _hover_tween.kill()
  _hover_tween = create_tween().set_parallel(true)
  if cookie_visual:
    cookie_visual.pivot_offset = cookie_visual.size / 2.0
    _hover_tween.tween_property(cookie_visual, "position:y", -14.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _hover_tween.tween_property(cookie_visual, "scale", Vector2(1.05, 1.05), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
  if shadow_node:
    shadow_node.pivot_offset = shadow_node.size / 2.0
    _hover_tween.tween_property(shadow_node, "position:y", 8.0, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _hover_tween.tween_property(shadow_node, "scale", Vector2(1.0, 1.08), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _hover_tween.tween_property(shadow_node, "modulate:a", 0.55, 0.18)

func _on_mouse_exited() -> void:
  if _hover_tween and _hover_tween.is_valid(): _hover_tween.kill()
  _hover_tween = create_tween().set_parallel(true)
  if cookie_visual:
    _hover_tween.tween_property(cookie_visual, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _hover_tween.tween_property(cookie_visual, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
  if shadow_node:
    shadow_node.pivot_offset = shadow_node.size / 2.0
    _hover_tween.tween_property(shadow_node, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _hover_tween.tween_property(shadow_node, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    _hover_tween.tween_property(shadow_node, "modulate:a", 0.3, 0.22)
