// 二维向量模块：表示位置、速度与尺寸，提供加减、点积、数乘、长度和归一化。
// 移动代码使用 速度 × 毫秒数 得到位移；向量与向量相乘返回点积。

#ifndef _VECTOR2_H_
#define _VECTOR2_H_

#include <cmath>

class Vector2
{
public:
	float x = 0;
	float y = 0;

public:
	Vector2() = default;
	~Vector2() = default;

	Vector2(float x, float y)
		: x(x), y(y) { }

	Vector2 operator+(const Vector2& vec) const
	{
		return Vector2(x + vec.x, y + vec.y);
	}

	void operator+=(const Vector2& vec)
	{
		x += vec.x,	y += vec.y;
	}

	void operator-=(const Vector2& vec)
	{
		x -= vec.x, y -= vec.y;
	}

	Vector2 operator-(const Vector2& vec) const
	{
		return Vector2(x - vec.x, y - vec.y);
	}

	// 向量点积返回标量，与下方“向量乘浮点数”的数乘重载不同。
	float operator*(const Vector2& vec) const
	{
		return x * vec.x + y * vec.y;
	}

	Vector2 operator*(float scalar) const
	{
		return Vector2(x * scalar, y * scalar);
	}

	void operator*=(float scalar)
	{
		x *= scalar, y *= scalar;
	}

	float Length() 
	{
		return sqrt(x * x + y * y);
	}

	// 返回同方向单位向量；零向量保持为零，避免除零。
	Vector2 Normalize()
	{
		float len = Length();

		if (len == 0) 
			return Vector2(0, 0);
		
		return Vector2(x / len, y / len);
	}
};

#endif // !_VECTOR2_H_
