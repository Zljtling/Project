// 场景接口：统一约定进入、更新、绘制、输入和退出五个生命周期回调。
// MenuScene、SelectorScene 和 GameScene 提供具体行为，SceneManager 负责转发调用。

#ifndef _SCENE_H_
#define _SCENE_H_

#include "camera.h"

#include <graphics.h>

class Scene
{
public:
	Scene() = default;
	~Scene() = default;

	// 生命周期依次覆盖进入初始化、逐帧更新、绘制、输入处理和离场清理。
	virtual void on_enter() {}
	virtual void on_update(int delta) {}
	virtual void on_draw(const Camera& camera) {}
	virtual void on_input(const ExMessage& msg){}
	virtual void on_exit() {}

private:

};


#endif // !_SCENE_H_
