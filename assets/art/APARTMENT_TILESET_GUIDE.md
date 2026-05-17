# 出租屋瓦片资源说明

本批资源用于把出租屋迁移为 TileMap 试点场景，保持现代上海合租房的压抑、潮湿、温暖但拮据的生活感。

## 文件

- `res://assets/tiles/apartment_hd_tileset.png`
  - 512x256 PNG。
  - 单格 64x64。
  - 8 列 x 4 行。
  - 用于 TileMap 的地面、墙面、门窗、阴影和覆盖层。
- `res://assets/sprites/apartment_hd_props.png`
  - 512x384 PNG。
  - 单格 128x128。
  - 4 列 x 3 行。
  - 用于床、桌子、冰箱、房租单、晾衣架、鞋架、杂物箱、窗户、水槽、门、地垫等道具。
- `res://assets/art/apartment_hd_tileset_preview.png`
  - 1024x768 PNG。
  - 用于快速查看出租屋瓦片组合效果。

## 瓦片索引

`apartment_hd_tileset.png`

- 第 1 行：旧地砖、磨损地砖、木纹地板、门口水泥、卫生间地砖、潮湿地面、旧地毯、暗角地面。
- 第 2 行：暖灰墙、脱皮墙、潮绿墙、踢脚墙、窗墙、木门墙、裂纹墙、夜色墙。
- 第 3 行：厨房地砖、卫生间墙地、管线地面、门槛、杂物地面、旧布面、深色边角、夜间阴影。
- 第 4 行：透明覆盖层，包括地面阴影、湿气、脏角、晾衣线、窗户、门、纸箱/告示。

## 道具索引

`apartment_hd_props.png`

- 第 1 行：床、书桌和电脑、冰箱、房租单。
- 第 2 行：晾衣架、鞋架、纸箱、窗户。
- 第 3 行：水槽台、房门、地垫、空白预留。

## 使用建议

- 可视化编辑入口：打开 `res://scenes/world/apartment_interior.tscn`，选中 `ApartmentTileMap`，在 Godot 底部的 TileMap 面板里选择 `apartment_hd_tileset` 瓦片后直接绘制。
- `RoomEditGuide` 是出租屋编辑参考底框，帮助你对刷瓦片区域；它只是可视化参考，不负责碰撞和交互。
- 主游戏已经改为实例化 `apartment_interior.tscn`，所以你在 `ApartmentTileMap` 里刷出的瓦片会被实际游戏使用。
- TileMap 先使用 64x64 单格，后续如果角色比例偏小，可以在 Godot 内用最近邻缩放到 32x32 或 48x48。
- 地形碰撞不要直接跟每个瓦片绑定，先沿用出租屋当前的矩形碰撞，稳定后再把墙体碰撞迁移到 TileSet。
- 床、冰箱、房租单继续作为可交互节点，道具图集只负责视觉表现。
- 夜晚和雨天可以叠加第 4 行的阴影、湿气或夜色瓦片，先做静态氛围，不急着做动态光照。
