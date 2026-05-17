# 主场景规整瓦片说明

当前主场景使用 `assets/tiles/polished_city_tileset_64.tres`，图集文件为 `assets/tiles/polished_city_tileset_64.png`。每个瓦片为 64x64 像素，主地图现在是 `99 x 57` 的大网格，是上一版 `33 x 19` 的三倍。

## 使用方式

1. 在 Godot 编辑器中打开 `scenes/world/city_map.tscn`。
2. 选中 `RoadElementTileMap`。
3. 在 TileSet 面板中选择 `polished_city_tileset_64.tres` 的瓦片进行绘制。
4. `PixelTileMap` 是旧的 16x16 后备层，当前保持隐藏，不建议继续在主场景上使用它做新地图。

## 美术约束

- 街道、建筑、道具都使用 64x64 网格，不再使用截图碎片直接拼贴。
- 道路只占 1 个 64x64 格子，优先保持直线、十字路口和斑马线对齐，避免半格偏移。
- 建筑物应按照原交互点落在完整网格上，门面朝向玩家可交互区域。
- 后续新增建筑时，优先扩展这张图集，避免混入不同透视或像素密度的资源。
- 东方明珠使用 `assets/ui/dfmz_stylized.png`，不要再直接使用照片质感或过度写实的单体建筑图。
