# Godot AI 与特效库怎么用

## Godot AI 什么时候用

Godot AI 是编辑器与 AI 客户端之间的 MCP 连接桥梁，不是安装后就在 Godot 内独立运行的聊天模型。Codex、Claude Code 等客户端连接它后，可以读取当前场景、操作节点与脚本，以及配置 UI、材质和粒子等内容。见 [官方说明](https://github.com/hi-godot/godot-ai)。

它现在就能用，后续改美术和加特效时也能用，取决于任务：

| 任务 | 合适方式 |
| --- | --- |
| 批量编写脚本、资源配置、运行检查 | 直接修改项目文件并调用 Godot |
| 查看正在编辑的场景、修改当前节点、配置某个可见效果 | 打开 Godot 编辑器，通过 Godot AI 操作当前工程 |
| 替换角色素材或添加已有特效 | 可以手动拖入 Godot，也可以在聊天中说明目标，由我读取场景后接入 |

你继续在桌面端当前聊天描述需求即可，不必先去终端输入 Codex 命令。需要操作编辑器状态时，打开本项目并保持 Godot AI 插件启用；直接编辑文件的任务不要求编辑器一直运行。

如果希望客户端原生列出 Godot AI 的工具，在 Godot AI 面板中找到对应客户端并点击 Configure，再按客户端要求重新加载或重启。面板里的“Server connected”首先表示编辑器已连上后台服务，还需要客户端接入才能调用工具。

本轮已实际通过官方 `godot-ai attach` 桥接调用 `editor_state`，确认工程名为 Elemental Survival、场景为 `res://scenes/validation/planar_run.tscn`、Godot 为 4.7.2，编辑器 readiness 为 ready。只做了读取，没有修改客户端全局配置。开发诊断脚本为 `tools/godot_bridge_probe.py`，不是启动游戏的必要步骤。

## Jeff FX 与 PixelFX 的区别

- Jeff FX 是已启用的 Godot 编辑器特效工坊，可以在编辑器内制作、调整和导出效果。
- PixelFX 是代码生成的像素特效库。本项目保留源码，并把效果导出为 Godot 可直接使用的资源，不作为编辑器插件启用。

两者都负责表现，攻击命中、伤害和机关时机继续由玩法系统判断。

## PixelFX 已安装内容

来源：[patch-gg/pixelfx](https://github.com/patch-gg/pixelfx)，版本 0.3.0，固定提交 `a84159688af3ca37a4be05a0d422b94451b2e24e`。

- `third_party/pixelfx/`：244 个特效的源码、核心库、导出工具和相关文档，共 300 个上游文件，已逐个校验 Git blob 哈希。
- `third_party/pixelfx/UPSTREAM.json`：来源、提交与文件哈希清单。
- `assets/pixelfx/`：244 套透明 PNG 精灵图、JSON 动画数据和原生 `SpriteFrames` `.tres` 资源。
- `assets/pixelfx/catalog.json`：效果名称、分类、帧率、尺寸、锚点与资源路径索引。
- MIT 许可与上游 NOTICE 同时保留在源码目录和导出目录。

本项目没有复制仓库中另有许可的 gallery 字体。上游源码在 Godot 文件浏览器中被 `.gdignore` 排除；实际可使用的效果在 `assets/pixelfx/` 中。

## 在 Godot 中使用一个效果

1. 在文件系统中打开 `assets/pixelfx/`，按类别选择效果。
2. 添加 `AnimatedSprite2D` 节点，将该效果目录下的 `.tres` 资源拖到 `Sprite Frames` 属性。
3. 播放 `default` 动画。一次性效果结束后按需要删除节点；循环效果按场景用途停止。
4. 若需要与生成时的落点对齐，参考 JSON 中的 `meta.pixelfx.pivot`：关闭 centered，并把 offset 设为锚点的负值。

当前已将部分命中、消失、拾取、冲刺和技能反馈接入 `scripts/presentation/pixel_fx_player.gd`。运行时按需加载动画，并限制同时播放的数量；视觉调用延后处理，不参与技能冷却和伤害结算。

重新导出全部资源可运行 `node tools/build_pixelfx.mjs`。导出只使用本地源码，不需要 npm 安装，也不需要联网。整个精灵图库约 172 MiB，运行时只加载用到的效果；以后打包正式版时可按使用清单裁剪未用资源。
