// 全局尺寸配置：统一窗口分辨率、世界边界和街道地面高度，供镜头、地图与移动模块共用。
// 窗口尺寸用于最终显示，世界尺寸用于角色位置、平台布局和攻击越界判定。

#ifndef _GAME_CONFIG_H_
#define _GAME_CONFIG_H_

inline constexpr int GAME_WINDOW_WIDTH = 1600;
inline constexpr int GAME_WINDOW_HEIGHT = 900;
inline constexpr int GAME_WORLD_WIDTH = 3200;
inline constexpr int GAME_WORLD_HEIGHT = 1800;
inline constexpr int GAME_STREET_FLOOR_Y = 1540;

#endif
