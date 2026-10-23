extends PanelContainer

signal slot_pressed(slot_id: int)
signal trash_pressed(slot_id: int)

@export var default_preview: Texture2D

@export var hover_chain:TweenChainRes
@export var hover_out_chain: TweenChainRes

var current_slot_id: int = 1
var has_save: bool = false
var bite_manager: BiteManager = BiteManager.new()
var _hover_tween: Tween

@onready var bite_handler: Control = %BiteHandler
@onready var content_rect: TextureRect = %Content

@onready var cookie_visual: Control = %CookieVisual
@onready var shadow_node: Control = %Shadow
@onready var main_button: Button = %Button
@onready var trash_button: Button = %TrashButton

# slot data
@onready var slot_title_label: Label = $MarginContainer/VBoxContainer/InfoPlaque/MarginContainer/VBoxContainer/SlotTitle
@onready var slot_date_label: Label = $MarginContainer/VBoxContainer/InfoPlaque/MarginContainer/VBoxContainer/SlotDate
@onready var slot_info_label: Label = $MarginContainer/VBoxContainer/InfoPlaque/MarginContainer/VBoxContainer/SlotInfo

func _ready() -> void:
  bite_manager.init(bite_handler)

  if main_button:
    main_button.pressed.connect(_on_button_pressed)
    main_button.mouse_entered.connect(_on_mouse_entered)
    main_button.mouse_exited.connect(_on_mouse_exited)

  if trash_button: trash_button.pressed.connect(_on_trash_pressed)

  
class BiteManager:
  var bite_material:ShaderMaterial
  var bite_tween: Tween
  var bite_handler: Control

  func init(_bite_handler: Control) -> void:
    bite_handler = _bite_handler
    bite_material = bite_handler.material

  func play_bite(local_click_pos: Vector2 = Vector2.ZERO) -> void:
    if not bite_handler: return
    var gsize: Vector2 = bite_handler.size
    var corner: int = 1
    if local_click_pos != Vector2.ZERO:
      var is_left: bool = local_click_pos.x < gsize.x * 0.5
      var is_top: bool = local_click_pos.y < gsize.y * 0.5
      if is_left and is_top: corner = 0
      elif not is_left and is_top: corner = 1
      elif not is_left and not is_top: corner = 2
      else: corner = 3
    else: corner = randi() % 4

    var gpos: Vector2 = bite_handler.global_position
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
    bite_tween = bite_handler.create_tween().set_parallel(true)
    bite_tween.tween_property(bite_material, "shader_parameter/bite_progress", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    bite_handler.pivot_offset = gsize / 2.0
    bite_tween.tween_property(bite_handler, "scale", Vector2(0.92, 0.92), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    bite_tween.chain().tween_property(bite_handler, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

  func reset() -> void:
    if bite_material: bite_material.set_shader_parameter("bite_progress", 0.0)

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

func play_bite_animation(local_click_pos: Vector2 = Vector2.ZERO) -> void: bite_manager.play_bite(local_click_pos)

func reset_bite() -> void: bite_manager.reset()

func _on_button_pressed() -> void:
  var click_pos: Vector2 = main_button.get_local_mouse_position() if main_button else Vector2.ZERO
  play_bite_animation(click_pos)
  slot_pressed.emit(current_slot_id)

func _on_trash_pressed() -> void: trash_pressed.emit(current_slot_id)

func _on_mouse_entered() -> void:
  if not hover_chain: return
  if _hover_tween and _hover_tween.is_valid(): _hover_tween.kill()
  _hover_tween = hover_chain.create_tween(self)
  if not _hover_tween: return
  _hover_tween.play()

func _on_mouse_exited() -> void:
  if not hover_out_chain: return
  if _hover_tween and _hover_tween.is_valid(): _hover_tween.kill()
  _hover_tween = hover_out_chain.create_tween(self)
  if not _hover_tween: return
  _hover_tween.play()
