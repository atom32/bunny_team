# 三种实物改装套件本机证据

正式用法与规则见 ../../docs/FITTING_KITS_IMPLEMENTATION.md。

通过既有item_authoring工厂在隔离工程创建3件定义，审核后复制正式定义/manifest；配置各自SVG图标、掉落、商店与中文，再同步YARD。厂内临时生成脚本与游戏档案全部只运行在仓库外隔离目录，不改个人存档。

本目录.gdignore排除Godot导入；evidence为本机ignored日志/图片。图形样本是真实ContactPanel/SupplyPanel中英购买与安装UI的自动信号/API采样，不是人工鼠标/听感验收。正式源码、SVG、导入配置和资源可由Git可见文件运行。

第一轮冷导入发现新SVG缺少仓库惯用的.svg.import配置，在autoload预载manifest阶段失败；补入原生生成的3个导入配置后用全新副本重跑，未加入错误忽略规则。原日志保留于仓库外证据目录，正式验证记录引用其hash。
