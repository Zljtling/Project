// 场景调度模块：保存当前场景，并向它转发每帧更新、绘制与输入事件。
// 切换顺序为旧场景 on_exit → 更换指针 → 新场景 on_enter；场景对象在 main.cpp 创建。

#ifndef _SCENE_MANAGER_H_
#define _SCENE_MANAGER_H_

#include "scene.h"

extern Scene* menu_scene;
extern Scene* game_scene;
extern Scene* selector_scene;

class SceneManager
{
public:
	enum class SceneType
	{
		Menu,
		Game,
		Selector
	};

public:
	SceneManager() = default;
	~SceneManager() = default;

	// 首次指定场景时直接进入；后续切换使用 switch_to 执行离场清理。
	void set_current_scene(Scene* scene)
	{
		current_scene = scene;
		current_scene->on_enter();
	}

	// 旧场景退出会创建或释放玩家等对象，必须先完成退出再初始化新场景。
	void switch_to(SceneType type)
	{
		current_scene->on_exit();
		switch (type)
		{
		case SceneType::Menu:
			current_scene = menu_scene;
			break;
		case SceneType::Game:
			current_scene = game_scene;
			break;
		case SceneType::Selector:
			current_scene = selector_scene;
			break;
		default:
			break;
		}
		current_scene->on_enter();
	}

	// 以下三个接口仅转发给当前场景，让 main.cpp 不必判断菜单、选角或战斗。
	void on_update(int delta)
	{
		current_scene->on_update(delta);
	}

	void on_draw(const Camera& camera)
	{
		current_scene->on_draw(camera);
	}

	void on_input(const ExMessage& msg) 
	{
		current_scene->on_input(msg);
	}


private:
	Scene* current_scene = nullptr;
};

#endif // !_SCENE_MANAGER_H_
