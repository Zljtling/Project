// 动画图集模块：按顺序保存 IMAGE 帧，提供批量加载、取帧和追加接口。
// 图集保存素材，Animation 保存播放进度；同一份图集可供多个动画实例使用。

#ifndef _ATLAS_H_
#define _ATLAS_H_

#include <vector>
#include <graphics.h>

class Atlas
{
public:
	Atlas() = default;
	~Atlas() = default;

	// 按含编号占位符的路径模板加载 1 到 num 帧，重新加载会替换旧图集。
	void load_from_file(LPCTSTR path_template, int num)
	{
		img_list.clear();
		img_list.resize(num);

		TCHAR path_file[256];
		for (int i = 0; i < num; i++)
		{
			_stprintf_s(path_file, path_template, i + 1);
			loadimage(&img_list[i], path_file);
		}
	}

	void clear()
	{
		img_list.clear();
	}

	int get_size()
	{
		return (int)img_list.size();
	}

	// 按从 0 开始的索引取帧，越界时返回空指针。
	IMAGE* get_image(int idx)
	{
		if (idx < 0 || idx >= img_list.size())
			return nullptr;

		return &img_list[idx];
	}

	void add_image(const IMAGE& img)
	{
		img_list.push_back(img);
	}

private:
	std::vector<IMAGE> img_list;
};


#endif // !_ATLAS_H_
