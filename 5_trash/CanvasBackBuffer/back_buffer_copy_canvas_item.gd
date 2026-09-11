@tool
extends CanvasItem

@export_enum("disabled:0", "rect:1", "viewport:2", "auto_rect:3") 
var copy_mode: int = 0:
	get: return copy_mode
	set(val):
		if copy_mode == val: return
		var node: CanvasItem = self
		if val == 3 and not node is Control:
			push_warning("Auto Rect mode is only supported in Control nodes")
			return
		
		copy_mode = val
		update_back_buffer()

@export 
var copy_rect: Rect2 = Rect2(-100, -100, 200, 200):
	get: return copy_rect
	set(val):
		if copy_rect == val: return
		copy_rect = val
		update_back_buffer()

@export 
var copy_auto_rect_margin: float = 0.0:
	get: return copy_auto_rect_margin
	set(val):
		if copy_auto_rect_margin == val: return
		copy_auto_rect_margin = val
		update_back_buffer()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE:
			set_notify_transform(true)
			update_back_buffer()

			RenderingServer.frame_pre_draw.connect(on_frame_pre_draw)

		NOTIFICATION_EXIT_TREE:
			set_notify_transform(false)
			RenderingServer.frame_pre_draw.disconnect(on_frame_pre_draw)

		NOTIFICATION_TRANSFORM_CHANGED:
			update_back_buffer()

func update_back_buffer() -> void:
	match copy_mode:
		0:
			RenderingServer.canvas_item_set_copy_to_backbuffer(get_canvas_item(), false, Rect2())
		1:
			RenderingServer.canvas_item_set_copy_to_backbuffer(get_canvas_item(), true, copy_rect)
		2:
			RenderingServer.canvas_item_set_copy_to_backbuffer(get_canvas_item(), true, Rect2())

func on_frame_pre_draw() -> void:
	if not is_visible_in_tree(): return
	if copy_mode == 3:
		var node: CanvasItem = self
		var control: Control = node as Control
		if control == null:
			copy_mode = 0
			return
		
		var rect: Rect2 = Rect2(Vector2(), control.size)
		rect = control.get_global_transform_with_canvas() * rect
		if Engine.is_editor_hint():
			rect = get_viewport().get_final_transform() * rect
		rect = rect.grow(copy_auto_rect_margin)

		RenderingServer.canvas_item_set_copy_to_backbuffer(get_canvas_item(), true, rect)
