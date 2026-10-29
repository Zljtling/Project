// 角色数值读取模块：首次查询时加载并缓存 resources/character_stats.csv，按“角色.字段”查值。
// 缺失或无效记录使用调用方默认值；配置在进程内只读取一次，修改表格后需重启游戏。

#ifndef _CHARACTER_STATS_H_
#define _CHARACTER_STATS_H_

#include <fstream>
#include <cmath>
#include <string>
#include <unordered_map>
#include <algorithm>
#include <cstdint>

// resources/character_stats.csv is the live balance table. Missing entries keep
// the code defaults so an incomplete or older table cannot prevent a match.
inline double character_stat(const char* character, const char* key, double fallback)
{
	static const std::unordered_map<std::string, double> values = []
	{
		std::unordered_map<std::string, double> result;
		std::ifstream file("resources/character_stats.csv");
		std::string line;
		while (std::getline(file, line))
		{
			const size_t first = line.find(',');
			if (first == std::string::npos) continue;
			const size_t second = line.find(',', first + 1);
			if (second == std::string::npos) continue;
			try
			{
				const double value = std::stod(line.substr(second + 1));
				if (std::isfinite(value) && value >= 0)
					result[line.substr(0, first) + "." + line.substr(first + 1, second - first - 1)] = value;
			}
			catch (...) {} // Header and malformed rows use the compiled fallback.
		}
		return result;
	}();
	const auto found = values.find(std::string(character) + "." + key);
	return found == values.end() ? fallback : found->second;
}

inline int character_stat_int(const char* character, const char* key, int fallback)
{
	return (int)character_stat(character, key, fallback);
}

// 将动作时长限制在有效毫秒范围内；允许为零的前摇或后摇可显式放行。
inline int character_duration_ms(const char* character, const char* key, int fallback, bool allow_zero = false)
{
	return (std::clamp)(character_stat_int(character, key, fallback), allow_zero ? 0 : 1, 60000);
}

// 将实际动作进度映射到素材参考时长，使调整施法时长后仍按相同比例播放动画。
inline std::int64_t animation_time(std::int64_t elapsed, int duration, int reference_duration)
{
	return elapsed * reference_duration / (std::max)(1, duration);
}

#endif
