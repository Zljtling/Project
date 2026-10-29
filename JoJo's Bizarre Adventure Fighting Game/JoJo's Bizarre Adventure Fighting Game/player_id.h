// 玩家身份模块：区分 1P 与 2P，用于输入键位、攻击来源与目标、音效设备别名。
// 玩家身份与角色类型独立，因此双方可以选择同一个角色。

#ifndef _PLAYER_ID_H_
#define _PLAYER_ID_H_

enum class PlayerID
{	
	P1,
	P2
};

#endif // !_PLAYER_ID_H_
