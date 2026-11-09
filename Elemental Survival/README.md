# Elemental Survival

Windows 单人 2.5D 生存逃离游戏，Godot 4.7.2。打开 project.godot 按 F5。

恢复任务先读 [任务进展](docs/任务进展.md)，当前规则只读 [游戏设定](docs/游戏设定.md)，工程职责见 [架构与目录](docs/架构与目录.md)。旧文档在 docs/archive，仅为历史证据。

开始游戏 → 选三个技能和一把武器 → 开始逃离 → 暂停地图选择安全出生点 → 确认出生。

WASD移动、Space冲刺、1/2/3技能、E交互、R载具、右键集火、M地图、Tab装备、Esc暂停、滚轮缩放。管理界面暂停整个模拟。

本轮地图16000×12000，六处聚落44栋房屋，同时3毒区和3火区，周期中重新选点；角色/敌人采用原创卡通造型，武器在身侧分槽显示。主入口 scenes/game_run.tscn，二维回归入口 scenes/validation/planar_run.tscn。

运行 tools/check_project.ps1 执行回归；tools/profile_runtime.gd 为无渲染模拟基准。用户原图在 references/art_direction/2026-11-02，最终美术待完整功能后统一打磨。
