@tool
extends ConfirmationDialog
const AUTHOR := preload("res://addons/neon_content/item_authoring.gd")
const AUDIT := preload("res://addons/neon_content/content_audit.gd")
var fields := {}
var template: OptionButton
var preview: TextEdit
var proposal: Dictionary = {}
var confirm: ConfirmationDialog
var on_published: Callable

func _ready() -> void:
	title = "Neon / 创建物品"
	size = Vector2i(760, 680)
	get_ok_button().text = "预览变更"
	var column := VBoxContainer.new()
	add_child(column)
	template = OptionButton.new()
	for name in AUTHOR.TEMPLATES: template.add_item(name)
	column.add_child(template)
	var grid := GridContainer.new(); grid.columns = 2; column.add_child(grid)
	for entry in [["id", "Stable ID"], ["name", "显示名 / 英文翻译键"], ["description", "用途说明"], ["source", "来源或模板路径"], ["license_ref", "许可记录路径"]]:
		var label := Label.new(); label.text = entry[1]; grid.add_child(label)
		var input := LineEdit.new(); input.custom_minimum_size.x = 480; input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(input); fields[entry[0]] = input
	for entry in [["weight", "重量 kg", 0.0, 1000.0, .001], ["value", "基础售价", 0.0, 1000000.0, 1.0], ["width", "仓库宽格", 1.0, 32.0, 1.0], ["height", "仓库高格", 1.0, 32.0, 1.0], ["max_stack", "最大堆叠", 1.0, 10000.0, 1.0]]:
		var label := Label.new(); label.text = entry[1]; grid.add_child(label)
		var input := SpinBox.new(); input.min_value = entry[2]; input.max_value = entry[3]; input.step = entry[4]
		grid.add_child(input); fields[entry[0]] = input
	var stack := CheckBox.new(); stack.text = "可堆叠"; column.add_child(stack); fields.stackable = stack
	stack.toggled.connect(func(enabled: bool):
		fields.max_stack.editable = enabled
		if not enabled: fields.max_stack.value = 1
	)
	var notice := Label.new()
	notice.text = "图标与场景继承所选模板；先预览，再明确确认创建。\n注册不等于可获得：仍需配置掉落/商店/制作及中文翻译。"
	column.add_child(notice)
	preview = TextEdit.new(); preview.editable = false; preview.custom_minimum_size = Vector2(700, 180); column.add_child(preview)
	confirm = ConfirmationDialog.new(); confirm.title = "确认发布新物品"; confirm.get_ok_button().text = "创建并注册"
	add_child(confirm); confirm.confirmed.connect(_publish)
	confirmed.connect(_review)
	template.item_selected.connect(_template_changed)
	dialog_hide_on_ok = false
	_template_changed(0)

func _template_changed(index: int) -> void:
	var kind := template.get_item_text(index)
	var path: String = AUTHOR.TEMPLATES[kind]
	var source: ItemDefinition = load(path)
	fields.id.text = String(source.id).get_slice(".", 0) + ".new_content"
	fields.name.text = ""
	fields.description.text = ""
	fields.description.placeholder_text = "说明获取地点与实际用途"
	fields.source.text = path
	fields.license_ref.text = "res://THIRD_PARTY_ASSETS.md"
	fields.weight.value = source.weight; fields.value.value = source.base_value
	fields.width.value = source.stash_size.x; fields.height.value = source.stash_size.y
	fields.stackable.button_pressed = source.stackable; fields.max_stack.value = source.max_stack
	proposal.clear(); preview.text = "请填写唯一 ID、显示名和实际用途。不会覆盖已有资源。"

func options() -> Dictionary:
	return {"template": template.get_item_text(template.selected), "id": fields.id.text, "name": fields.name.text, "description": fields.description.text, "source": fields.source.text, "license_ref": fields.license_ref.text, "weight": fields.weight.value, "value": int(fields.value.value), "stash_size": Vector2i(int(fields.width.value), int(fields.height.value)), "stackable": fields.stackable.button_pressed, "max_stack": int(fields.max_stack.value)}

func _review() -> void:
	var manifest := ResourceLoader.load(AUTHOR.MANIFEST, "", ResourceLoader.CACHE_MODE_IGNORE) as ContentManifest
	proposal = AUTHOR.plan(manifest, options())
	if not proposal.pass:
		preview.text = "拒绝发布：\n" + "\n".join(proposal.errors)
		return
	var item: ItemDefinition = proposal.definition
	preview.text = "新增：%s\nID：%s\n类型：%s\nManifest：definitions +1，原定义不变\n图标：%s\n来源：%s\n许可：%s\n尚未增加获取渠道或翻译。" % [proposal.definition_path, item.id, item.get_script().get_global_name(), item.icon.resource_path if item.icon else "未设置", item.get_meta("authoring_source"), item.get_meta("license_ref")]
	confirm.dialog_text = preview.text
	confirm.popup_centered(Vector2i(720, 360))

func _publish() -> void:
	var result: Dictionary = AUTHOR.publish(proposal)
	preview.text = result.message
	proposal.clear()
	if result.error == OK:
		EditorInterface.get_resource_filesystem().scan()
		EditorInterface.edit_resource(load(result.path))
		if on_published.is_valid(): on_published.call()
