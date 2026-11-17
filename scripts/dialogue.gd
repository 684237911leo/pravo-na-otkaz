extends CanvasLayer

signal finished(flags)

var nodes := {}
var flags := {}
var box: VBoxContainer
var speaker_lbl: Label
var text_lbl: Label
var buttons: VBoxContainer


func start(path: String) -> void:
	layer = 10
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	nodes = data["nodes"]
	_build()
	_show(data["start"])


func _build() -> void:
	var panel := PanelContainer.new()
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 20
	panel.offset_right = -20
	panel.offset_bottom = -30
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 18)
	panel.add_child(margin)
	box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)
	speaker_lbl = Label.new()
	speaker_lbl.add_theme_font_size_override("font_size", 34)
	speaker_lbl.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	box.add_child(speaker_lbl)
	text_lbl = Label.new()
	text_lbl.add_theme_font_size_override("font_size", 30)
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_lbl.custom_minimum_size = Vector2(600, 0)
	box.add_child(text_lbl)
	buttons = VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	box.add_child(buttons)


func _show(id: String) -> void:
	if id == "" or not nodes.has(id):
		finished.emit(flags)
		queue_free()
		return
	var n = nodes[id]
	speaker_lbl.text = n.get("speaker", "")
	text_lbl.text = n.get("text", "")
	for c in buttons.get_children():
		c.queue_free()
	if n.has("choices"):
		for ch in n["choices"]:
			_add_button(ch["text"], _choose.bind(ch))
	else:
		_add_button("Далее ▶", _show.bind(n.get("next", "")))


func _add_button(label: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.add_theme_font_size_override("font_size", 30)
	b.custom_minimum_size = Vector2(0, 80)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(cb)
	buttons.add_child(b)


func _choose(ch: Dictionary) -> void:
	var s: Dictionary = ch.get("set", {})
	for k in s:
		flags[k] = s[k]
	_show(ch.get("next", ""))
