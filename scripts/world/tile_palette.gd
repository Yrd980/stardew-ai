class_name TilePalette
extends RefCounted

const TILE_SIZE := 16
const SOURCE_ID := 0
const GRASS := Vector2i(0, 0)
const PATH := Vector2i(1, 0)
const SOIL_DRY := Vector2i(2, 0)
const SOIL_WATERED := Vector2i(3, 0)
const HOUSE_FLOOR := Vector2i(0, 1)
const WALL := Vector2i(1, 1)
const HOUSE_ACCENT := Vector2i(2, 1)
const WATER := Vector2i(3, 1)
const CROP_STAGE_1 := Vector2i(0, 2)
const CROP_STAGE_2 := Vector2i(1, 2)
const CROP_STAGE_3 := Vector2i(2, 2)
const CROP_STAGE_4 := Vector2i(3, 2)
const BIN := Vector2i(0, 3)
const BED := Vector2i(1, 3)
const DOOR := Vector2i(2, 3)
const ROOF := Vector2i(3, 3)

static var _tile_set: TileSet


static func get_tile_set() -> TileSet:
	if _tile_set == null:
		_tile_set = _build_tile_set()
	return _tile_set


static func get_crop_stage_coords(stage: int) -> Vector2i:
	var stages := [CROP_STAGE_1, CROP_STAGE_2, CROP_STAGE_3, CROP_STAGE_4]
	return stages[clamp(stage, 0, stages.size() - 1)]


static func _build_tile_set() -> TileSet:
	var image := Image.create(TILE_SIZE * 4, TILE_SIZE * 4, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	_fill_tile(image, GRASS, Color("5da24d"), Color("3e6d32"))
	_fill_tile(image, PATH, Color("cfb178"), Color("88653c"))
	_fill_tile(image, SOIL_DRY, Color("7d5433"), Color("50311a"))
	_fill_tile(image, SOIL_WATERED, Color("5076a8"), Color("314d72"))
	_fill_tile(image, HOUSE_FLOOR, Color("c59c69"), Color("8b663f"))
	_fill_tile(image, WALL, Color("7f4b31"), Color("492715"))
	_fill_tile(image, HOUSE_ACCENT, Color("d6bf95"), Color("927a55"))
	_fill_tile(image, WATER, Color("3f8fd1"), Color("225174"))
	_fill_tile(image, CROP_STAGE_1, Color("5c8f3c"), Color("355624"))
	_fill_tile(image, CROP_STAGE_2, Color("74ad45"), Color("41642a"))
	_fill_tile(image, CROP_STAGE_3, Color("92c94c"), Color("5d7f31"))
	_fill_tile(image, CROP_STAGE_4, Color("e8cb57"), Color("9f7d23"))
	_fill_tile(image, BIN, Color("9a5a2c"), Color("5b3112"))
	_fill_tile(image, BED, Color("cb7070"), Color("7c3333"))
	_fill_tile(image, DOOR, Color("6f3d25"), Color("3c1b10"))
	_fill_tile(image, ROOF, Color("995546"), Color("5e3027"))
	var texture := ImageTexture.create_from_image(image)
	var atlas := TileSetAtlasSource.new()
	atlas.texture = texture
	atlas.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	for y in range(4):
		for x in range(4):
			atlas.create_tile(Vector2i(x, y))
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(atlas, SOURCE_ID)
	return tile_set


static func _fill_tile(image: Image, atlas_coords: Vector2i, fill_color: Color, border_color: Color) -> void:
	var origin := atlas_coords * TILE_SIZE
	image.fill_rect(Rect2i(origin, Vector2i(TILE_SIZE, TILE_SIZE)), fill_color)
	for x in range(TILE_SIZE):
		image.set_pixel(origin.x + x, origin.y, border_color)
		image.set_pixel(origin.x + x, origin.y + TILE_SIZE - 1, border_color)
	for y in range(TILE_SIZE):
		image.set_pixel(origin.x, origin.y + y, border_color)
		image.set_pixel(origin.x + TILE_SIZE - 1, origin.y + y, border_color)

