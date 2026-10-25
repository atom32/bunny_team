# 整校园 1:1 地理重建 · 第一阶段

后续更新：[整校园美术细化与游戏风格统一](WEIJIN_ART_2026-10-23.md)。下文保留第一阶段边界；新增细节不使估算变成实测，也不表示主线已迁移。

## 当前交付，不冒充最终复刻

用户选择“整校园按真实比例重建”。已新增完整卫津路校园的**可实走地理底座**，
不是把116米旧关卡放大，也不是只换路线图。**尚未完成真实立面/室内制作和主线任务迁移**。
旧主线仍使用原关卡，旧档和碰撞签名没有改；新模式不会扣补给、发奖励或修改出击档。

入口：源码启动后的主菜单右上角，或基地“Operations / 行动”顶部的
**整校园 1:1 / 地理勘察**。从哪里进入，返回哪里；基地入口返回行动面板。
没有重新导出 Windows EXE。

## 已实现

- 基于 OSM 校界 `way/48165383`，约 **1395.66 × 905.17 米**；WGS84 局部米制坐标，
  正北朝向正确，x东、z南；横向和纵向均无夸张缩放。
- 四湖：青年、敬业、爱晚、友谊，保留原始多边形节点。428个校内/贴边建筑轮廓，
  加39个周边轮廓，保留楼翼、凹角、院落间距，不改成长方块；242条道路way和43个运动场/游乐场轮廓。
- 区域DEM驱动的起伏地面和真实地面碰撞；地面网格在湖泊处切除，湖岸有角色碰撞，
  建筑轮廓有实体墙碰撞；道路与地面高程贴合，周边道路裁到数据覆盖边界，避免悬空延伸。
- 主菜单/行动面板入口、航拍缩放/环绕/平移、8个来源可追溯的地标定位、全校园路线图、
  区域高程图层、东门进入的正常角色步行。定位按钮只移动航拍镜头，不瞬移玩家。
- 3D和2D地图使用同一份离线数据；地图打开后停止勘察角色移动；勘察武器不能射击。
- 运行时直接加载可在Godot编辑的静态场景，不联网、不在运行时随机生成校园。

## 精度限制 / 后续工作

不能把“1:1尺度”混同于“测绘级还原”。当前原始地图仍可能缺路、缺门、缺建筑分部。
455个轮廓缺高度记录，12个有楼层标签。多数高度/路宽、全部立面细节及大部分植被均为估算，
在数据、UI、来源说明中明确标注。高程为约30米级区域数据，经中值/均值处理降低城市建筑伪影，
不是校园台阶、路沿或湖底测量；不加入无依据的噪声山丘。

下一阶段需要逐栋建筑照片或许可明确的测量/模型，以校正楼高、屋顶、门洞、立面、驳岸、
台阶与树种；再按真实路径重设任务区域、敌人密度、室内、导航、撤离距离并验证存档版本。
这不是把旧坐标乘一个系数即可完成的工作。本轮不宣称主线已迁移，也不宣称最终写实美术验收。

## 关键文件

- 数据与许可：`assets/geography/weijin/{campus.json,SOURCE.json,SOURCE.md,TERRAIN_ATTRIBUTION.md}`。
- 原始可复现数据：`art_source/weijin_geography/{campus.osm.gz,N39E117.hgt.gz}`。
- 坐标/高程/几何查询：`scripts/world/geography/campus_geodata.gd`。
- 独立地理场景：`scenes/areas/campus_geography/world.tscn`。
- 勘察模式：`scenes/presentation/campus_survey.tscn`，相关脚本在 `scripts/world/geography/`。
- 导入器：`tools/import_weijin_geography.py`；离线烘焙：`tools/build_weijin_campus.gd`。

重建数据：解压归档OSM到临时目录后运行
`python tools/import_weijin_geography.py --osm <原始.osm> --hgt art_source/weijin_geography/N39E117.hgt.gz`。
烘焙只覆盖新地理场景，不碰旧校园：
`Godot --path D:/bunny_team --rendering-method gl_compatibility --script res://tools/build_weijin_campus.gd`。
**烘焙不能用 `--headless`**：Godot DummyRenderer会丢弃MultiMesh缓冲，导致植被消失；脚本已拒绝此误用。

## 验证

- `tests/test_weijin_geography.py`：5项离线测试，逐个比对全部保留way的源节点、比例、湖名、
  高程数组、估算标识、原始/派生SHA256、许可及离线重建字节一致性。
- `tests/campus_geography_test.tscn`：源几何/烘焙数量、地图真实按键、东门落地、正常移动输入、
  DEM地面贴合、四湖的真实角色胶囊碰撞、地图输入隔离、只读Profile；原生另保留实际渲染截图。
  原生与无界面各31项通过；合成输入实际步行约18.61米。
- `tests/campus_geography_entry_test.tscn`：主菜单→勘察→菜单→基地→行动→勘察→行动，
  通过实际场景过渡和原生鼠标点击，不直接代替入口加载。
  原生18项通过。
- UI和旧校园布局回归分别见 `ui_remake_test.tscn` 与 `streets_layout_test.tscn`。
  UI 26项通过；旧校园包括六出生点、任务与合法撤离的布局测试零失败。

验证是合成控制与几何回归，不是陌生玩家全校园体验、主线迁移验收或全部历史档保证。
证据归档：`docs/weijin_geography_2026-10-23/`。
