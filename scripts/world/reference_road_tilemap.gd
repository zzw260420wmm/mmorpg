@tool
extends TileMap
class_name ReferenceRoadTileMap

@export var atlas_columns := 16
@export var atlas_rows := 16
@export var auto_fill_when_empty := true


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_fill_when_empty")


func _fill_when_empty() -> void:
	if not auto_fill_when_empty:
		return
	if tile_set == null:
		return
	if not get_used_cells(0).is_empty():
		return

	for y in range(atlas_rows):
		for x in range(atlas_columns):
			set_cell(0, Vector2i(x, y), 0, Vector2i(x, y), 0)
