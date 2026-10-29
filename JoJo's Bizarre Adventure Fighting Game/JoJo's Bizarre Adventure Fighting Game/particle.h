// 一次性粒子模块：在固定世界位置播放烟尘等短动画，播放完毕后标为无效。
// lifespan 表示每帧时长；粒子的更新和移除由 Player 的粒子列表负责。

#ifndef _PARTICLE_H_
#define _PARTICLE_H_

#include "util.h"
#include "atlas.h"
#include "vector2.h"

#include <cstdint>

class Particle
{
public:
	Particle() = default;
	Particle(const Vector2& position, Atlas* atlas, int lifespan)
		: position(position), atlas(atlas), lifespan(lifespan > 0 ? lifespan : 1) {}
	~Particle() = default;

	void set_atlas(Atlas* new_atlas)
	{
		atlas = new_atlas;
		timer = 0;
		idx_frame = 0;
		valid = true;			// 更换图集时从第一帧重新播放
	}

	void set_position(const Vector2& new_position)
	{
		position = new_position;
	}

	void set_lifespan(int ms)
	{
		lifespan = ms > 0 ? ms : 1;	// 单帧时长至少 1ms，避免除零
	}

	bool check_valid() const
	{
		return valid && atlas && atlas->get_size() > 0;
	}

	// 按累计毫秒数一次推进所需帧数；播放超出末帧后标为无效，供持有者回收。
	void on_update(int delta)
	{
		if (!check_valid() || delta <= 0)
			return;
		timer += delta;
		std::int64_t frames = timer / lifespan;
		timer %= lifespan;		// 保留计时余量，卡顿时也能跨过多个动画帧
		if (frames >= atlas->get_size() - idx_frame)
			valid = false;		// 最后一帧显示完整后回收，不循环播放
		else
			idx_frame += (int)frames;
	}

	void on_draw(const Camera& camera) const
	{
		if (!check_valid())
			return;
		IMAGE* frame = atlas->get_image(idx_frame);
		if (frame)
			putimage_alpha(camera, (int)position.x, (int)position.y, frame);
	}
private:
	std::int64_t timer = 0;	// 粒子动画播放定时器
	int lifespan = 1;		// 单帧粒子动画持续时长
	int idx_frame = 0;		// 当前正在播放的动画帧
	Vector2 position;		// 粒子的世界坐标位置
	bool valid = true;		// 粒子对象是否有效
	Atlas* atlas = nullptr;	//粒子动画所使用的图集
};

#endif // !_PARTICLE_H_
