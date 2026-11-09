# 依据与依赖
## 2026-11-03 当前视觉迭代
用户七张新参考原图归档于 references/ui_forest/2026-11-02，附SHA256；提取暖纸、木边、森林绿、低饱和物件插图，不复制参考中的羊IP或整页布局。原有石板蓝规范被此次明确要求替换。
按 game-ui-workflow 的最小充分路径更新共享契约并修改真实 Godot 控件，不执行整页生图/图集拆分审批链。scenario-game-assets已读取，Scenario MCP未连接，未调用外部生成。GodotPrompter补充安装并读取animation-system、particles-vfx；采用独立视觉状态与有界批绘制，避免给每颗弹丸创建独立粒子节点。
主要输出：原创SVG物件图标、四方向角色图集、纸面主题、左右分栏锻造；工具脚本可复建。风格状态仍为implemented-pending-user-review，工程测试不代替用户审美验收。

用户要求使用 Scenario、GodotPrompter、game-ui-design-workflow。已安装并读取相关技能。Scenario MCP未连接，因此没有调用其生成服务。采用总控的最小规范路径＋Godot原生实现，没有声称通过未执行的页面生图/Atlas审批。

来源：
- https://github.com/scenario-labs/skills
- https://github.com/jame581/GodotPrompter
- https://github.com/guiguiyan930-source/game-ui-design-workflow
- 敌人职责、预警与阶段变化参考研究：https://brotato.wiki.spellsandguns.com/Enemies （社区资料，自己的行为与数值单独设计）
- 古桥形态参考：https://www.asce.org/about-civil-engineering/history-and-heritage/historic-landmarks/zhaozhou-bridge
- 热液矿物沉积形态参考：https://pubs.usgs.gov/sir/2017/5022/p/sir20175022_p.pdf

不复制游戏素材；采用原创SVG及本地程序模型。详细参考图待完整功能后继续打磨。
