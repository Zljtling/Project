// 计时器模块：由游戏每帧传入 delta 累计时间，到达等待时长后调用回调。
// 支持暂停、恢复和单次触发；用于攻击冷却、无敌闪烁、粒子生成及结算动画。

#ifndef _TIMER_H_
#define _TIMER_H_

#include <functional>

class Timer {
public:
	Timer() = default;
	~Timer() = default;

	// 重新计时并解除已触发标记；暂停状态保持不变，需要调用 resume 才继续。
	void restart()
	{
		pass_time = 0;
		shotted = false;
	}

	void set_wait_time(int val)
	{
		wait_time = val;
	}

	void set_one_shot(bool flag)
	{
		one_shot = flag;
	}

	void set_callback(std::function<void()> callback)
	{
		this->callback = callback;
	}

	void pause()
	{
		paused = true;
	}

	void resume()
	{
		paused = false;
	}

	// 达到等待时间时触发回调；单次模式只触发一次，重复模式每次到时再次触发。
	void on_update(int delta)
	{
		if (paused)
			return;
		
		pass_time += delta;
		if (pass_time >= wait_time)
		{
			if ((!one_shot || (one_shot && !shotted)) && callback)
				callback();
			shotted = true;	
			pass_time = 0;
		}
	}

private:
	int pass_time = 0;				//已过时间
	int wait_time = 0;				//等待时间
	bool paused = false;			//是否暂停
	bool shotted = false;			//是否触发
	bool one_shot = false;			//单次触发
	std::function<void()> callback;	//回调函数
};

#endif // !_TIMER_H_
