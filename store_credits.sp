#include <store>
#include <steamworks>
#include <cg_core>
#include <cg_ze>
#include <csc>
#include <store.item>

#pragma newdecls required

#define PLUGIN_PREFIX_CREDITS "\x01 \x04[Store]  "
#define PLUGIN_PREFIX "[\x0CCG\x01]  "

Handle g_hTimer[MAXPLAYERS+1];

bool g_bInOfficalGroup[MAXPLAYERS+1];
bool g_bInMimiGameGroup[MAXPLAYERS+1];
bool g_bInOpeatorGroup[MAXPLAYERS+1];
bool g_bInZombieGroup[MAXPLAYERS+1];
bool g_bIsCheck[MAXPLAYERS+1];

int g_iNumPlayers;
bool g_bNightfever;

public Plugin myinfo =
{
	name		= "Store Online Credits/Riffle",
	author		= "maoling ( xQy )",
	description = "",
	version		= "1.1rc2",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("CG_Broadcast");
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_signtest", Command_SignTest, ADMFLAG_ROOT);
	
	CreateTimer(120.0, Timer_Nightfever, _, TIMER_REPEAT);
}

public void OnMapStart()
{
	CreateTimer(300.0, Timer_RaffleItem, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Nightfever(Handle timer)
{
	char time[16];
	FormatTime(time, 16, "%H", GetTime());
	int hour = StringToInt(time);
	if(hour <= 8 || hour >= 23)
		g_bNightfever = true;
	else
		g_bNightfever = false;
	
	if(g_bNightfever)
		PrintToChatAll("[\x02NightFever\x01]   \x04当前为午夜党福利时间,在线获得的信用点+5");
}

public Action Timer_RaffleItem(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client))
			Active_RaffleLimitItem(client);
}

public void OnClientPostAdminCheck(int client)
{
	LookupPlayerGroups(client);
	
	if(g_hTimer[client] != INVALID_HANDLE)
		KillTimer(g_hTimer[client]);
	
	g_hTimer[client] = CreateTimer(300.0, CreditTimer, client, TIMER_REPEAT);
	
	g_iNumPlayers = GetClientCount(true);
}

public void OnClientDisconnect(int client)
{
	g_bInOfficalGroup[client] = false;
	g_bInMimiGameGroup[client] = false;
	g_bInZombieGroup[client] = false;
	g_bInOpeatorGroup[client] = false;
	g_bIsCheck[client] = false;
	
	if(g_hTimer[client] != INVALID_HANDLE)
		KillTimer(g_hTimer[client]);
	
	g_hTimer[client] = INVALID_HANDLE;
	
	g_iNumPlayers = GetClientCount(true);
}

public int ZE_GetClientGroupStats(int client)
{
	if(g_bInZombieGroup[client])
		return 2;
	
	if(g_bInOfficalGroup[client])
		return 1;
	
	return 0;
}

public void LookupPlayerGroups(int client)
{
	g_bIsCheck[client] = true;
	SteamWorks_GetUserGroupStatus(client, 103582791438550612);
	SteamWorks_GetUserGroupStatus(client, 103582791437825710);
	SteamWorks_GetUserGroupStatus(client, 103582791442277011);
	SteamWorks_GetUserGroupStatus(client, 103582791456047719);
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupid, bool isMember, bool isOfficer)
{
	if(isMember || isOfficer) 
	{
		for(int client=1;client<=MAXPLAYERS;++client)
		{
            if(!g_bIsCheck[client])
                continue;
			
            if(!IsClientConnected(client))
                continue;

            char authidb[32];
            GetClientAuthId(client, AuthId_Engine, authidb, 32);
            char part[4];
            SplitString(authidb[8], ":", part, 4);
            if(authid == (StringToInt(authidb[10]) << 1) + StringToInt(part)) 
            {
				if(groupid == 103582791438550612)
					g_bInOfficalGroup[client] = true;
				if(groupid == 103582791437825710)
					g_bInMimiGameGroup[client] = true;
				if(groupid == 103582791442277011)
					g_bInOpeatorGroup[client] = true;
				if(groupid == 103582791456047719)
					g_bInZombieGroup[client] = true;

				break;
			}
		}
	}
}

public Action CreditTimer(Handle timer, int client)
{
	if(!IsClientInGame(client))
	{
		g_hTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if(!(2 <= GetClientTeam(client) <= 3))
	{
		PrintToChat(client, "%s  \x07观察者无法获得信用点", PLUGIN_PREFIX_CREDITS);
		return Plugin_Continue;
	}

	if(g_iNumPlayers < 6 && !FindPluginByFile("KZTimerGlobal.smx"))
	{
		PrintToChat(client, "%s  \x04玩家人数不足6人,不能获得在线奖励的信用点", PLUGIN_PREFIX_CREDITS);
		return Plugin_Continue;
	}

	int m_iCredits = 0;
	bool m_bGroupCreidts = false;
	char szFrom[128], szReason[128];
	strcopy(szFrom, 128, "\x10[");
	strcopy(szReason, 128, "store_credits[");
	
	m_iCredits += 1;
	StrCat(szFrom, 128, "\x04在线时间+1");
	StrCat(szReason, 128, "在线时间 ");

	int authid = PA_GetGroupID(client);
	
	if(authid > 0)
	{
		int m_iPlus = 0;
		if(authid < 401)
		{
			m_iPlus += 3;
		}
		else if(500 > authid >= 401)
		{
			switch(authid)
			{
				case 401: m_iPlus += 2;
				case 402: m_iPlus += 2;
				case 403: m_iPlus += 3;
				case 404: m_iPlus += 3;
				case 405: m_iPlus += 4;
			}
		}
		else if(9000 > authid >= 500)
		{
			m_iPlus += 3;
		}
		else if(9990 > authid >= 9101)
		{
			m_iPlus += 4;
		}
		else if(authid > 9990)
		{
			m_iPlus += 5;
		}

		m_iCredits += m_iPlus;
		char auname[32];
		PA_GetGroupName(client, auname, 32);
		StrCat(szReason, 128, auname);
		if(authid == 9999)
			Format(auname, 32, "\x0A|\x0E%s+%d", auname, m_iPlus);
		else
			Format(auname, 32, "\x0A|\x0C%s+%d", auname, m_iPlus);
		StrCat(szFrom, 128, auname);
	}
	
	switch(VIP_GetVipType(client))
	{
		case 3:
		{
			m_iCredits += 2;
			StrCat(szFrom, 128, "\x0A|\x07永久VIP+2");
			StrCat(szReason, 128, " SVIP ");
		}
		case 2:
		{
			m_iCredits += 2;
			StrCat(szFrom, 128, "\x0A|\x07年费VIP+2");
			StrCat(szReason, 128, " AVIP ");
		}
		case 1:
		{
			m_iCredits += 1;
			StrCat(szFrom, 128, "\x0A|\x07月费VIP+1");
			StrCat(szReason, 128, " MVIP ");
		}
	}
	
	if(g_bInMimiGameGroup[client] && !m_bGroupCreidts)
	{
		m_iCredits += 3;
		m_bGroupCreidts = true;
		StrCat(szFrom, 128, "\x0A|\x06娱乐挂壁+2");
		StrCat(szReason, 128, "娱乐挂壁");
	}
	
	if(g_bInZombieGroup[client] && !m_bGroupCreidts)
	{
		m_iCredits += 3;
		m_bGroupCreidts = true;
		StrCat(szFrom, 128, "\x0A|\x06祈り~+2");
		StrCat(szReason, 128, "祈り~");
	}
	
	if(g_bInOfficalGroup[client] && !m_bGroupCreidts)
	{				
		m_bGroupCreidts = true;
		m_iCredits += 3;
		StrCat(szFrom, 128, "\x0A|\x06官方组+3");
		StrCat(szReason, 128, "官方组");
	}

	if(g_bInOpeatorGroup[client] && GetUserFlagBits(client) & ADMFLAG_BAN)
	{
		m_iCredits += 3;
		StrCat(szFrom, 128, "\x0A|\x10OP+3");
		StrCat(szReason, 128, "OP");		
	}
	
	int m_iVitality = CG_GetVitality(client);
	if(m_iVitality)
	{
		StrCat(szReason, 128, " 热度");	
		if(100 > m_iVitality >= 60)
		{
			m_iCredits += 2;
			StrCat(szFrom, 128, "\x0A|\x07热度+2");
		}
		else if(200 > m_iVitality >= 100)
		{
			m_iCredits += 3;
			StrCat(szFrom, 128, "\x0A|\x07热度+3");
		}
		else if(400 > m_iVitality >= 200)
		{
			m_iCredits += 4;
			StrCat(szFrom, 128, "\x0A|\x07热度+4");
		}
		else if(700 > m_iVitality >= 400)
		{
			m_iCredits += 5;
			StrCat(szFrom, 128, "\x0A|\x07热度+5");
		}
		else if(m_iVitality >= 700)
		{
			m_iCredits += 6;
			StrCat(szFrom, 128, "\x0A|\x07热度+6");
		}
		else if(m_iVitality == 1000)
		{
			m_iCredits += 10;
			StrCat(szFrom, 128, "\x0A|\x07热度+10");
		}
		else
		{
			m_iCredits += 1;
			StrCat(szFrom, 128, "\x0A|\x07热度+1");
		}
	}
	
	if(g_bNightfever)
	{
		m_iCredits += 5;
		StrCat(szFrom, 128, "\x0A|\x02午夜党福利+5");
		StrCat(szReason, 128, "午夜党福利");		
	}
	
	m_iCredits *= 2;
	
	StrCat(szFrom, 128, "\x0A|\x0C新年加倍\x10]");
	StrCat(szReason, 128, " 新年加倍]");

	Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

	PrintToChat(client, "%s \x10你获得了\x04 %d 信用点", PLUGIN_PREFIX_CREDITS, m_iCredits);
	PrintToChat(client, " \x0A积分来自%s", szFrom);
	
	if(!g_bInOfficalGroup[client])
		PrintToChat(client, " \x04加入官方Steam组即可享受3倍在线积分");

	return Plugin_Continue;
}

public Action Command_SignTest(int client, int args)
{
	if(PA_GetGroupID(client) == 9999)
	{
		Active_GiveSignCredits(client);
		Active_GiveRandomItems(client);
		Active_RaffleLimitItem(client);
	}
}

public void CG_OnClientDailySign(int client)
{
	if(!g_bInOfficalGroup[client])
	{
		PrintToChat(client, "%s  检测到你当前未加入\x0C官方组\x01  你无法获得签到奖励", PLUGIN_PREFIX);
		return;	
	}

	Active_GiveSignCredits(client);
	Active_GiveRandomItems(client);
	//Active_RaffleLimitItem(client);
}

void Active_GiveSignCredits(int client)
{
	int Credits = GetRandomInt(2, 600);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + Credits, "PA-签到");
	PrintToChatAll("%s \x0E%N\x01签到获得\x04 %d\x0F信用点\x01(\x0C新年加倍\x01)", PLUGIN_PREFIX, client, Credits);
	PrintToChat(client,"%s \x10你获得了\x04%d \x0F信用点 \x10来自\x04[签到].", PLUGIN_PREFIX_CREDITS, Credits);
}

void Active_GiveRandomItems(int client)
{
	int id = GetRandomInt(1, 31);
	int itemid = Store_GetItem(g_szItemType[id], g_szItemUid[id]);
	if(itemid <= -1)
	{
		PrintToChat(client, "%s  当前服务器不能正常发放新春物品奖励", PLUGIN_PREFIX);
		return;
	}

	int extt = GetRandomInt(1, 48);
	
	PrintToChatAll("%s  \x0C%N\x04签到获得了[%s-%s](%d小时)", PLUGIN_PREFIX, client, g_szItemNick[id], g_szItemName[id], extt);
	PrintToChat(client, "%s  \x04你获得了[%s-%s](%d小时),可以在!store中查看", PLUGIN_PREFIX, g_szItemNick[id], g_szItemName[id], extt);
	
	if(Store_HasClientItem(client, itemid))
	{
		int exp = Store_GetItemExpiration(client, itemid);
		Store_ExtClientItem(client, itemid, exp+(extt*3600));
		if(exp == 0)
			PrintToChat(client, "%s  \x04你已经有用此物品的永久使用权...", PLUGIN_PREFIX);
	}
	else
		Store_GiveItem(client, itemid, GetTime(), GetTime()+(extt*3600), 30);
}

void Active_RaffleLimitItem(int client)
{
	char name[64], type[32], uid[128];
	switch(GetRandomInt(1, 4))
	{
		case 1:
		{
			strcopy(name, 64, "普魯魯特(Pururut)[线下见面会专属]");
			strcopy(type, 32, "playerskin");
			strcopy(uid, 128, "models/player/custom_player/maoling/neptunia/pururut/normal/pururut.mdl");
		}
		case 2:
		{
			strcopy(name, 64, "Re0.艾米莉亚(Emilia)[新年活动专属]");
			strcopy(type, 32, "playerskin");
			strcopy(uid, 128, "models/player/custom_player/maoling/re0/emilia_v2/emilia.mdl");
		}
		case 3:
		{
			strcopy(name, 64, "夕立(Yuudachi)[周年庆专属]");
			strcopy(type, 32, "playerskin");
			strcopy(uid, 128, "models/player/custom_player/maoling/kantai_collection/yuudachi/yuudachi.mdl");
		}
	}
	
	int rdm = GetRandomInt(1, 100000), itemid = Store_GetItem(type, uid);
	if(itemid <= 0) return;

	if(rdm == 1228 || rdm == 416 || rdm == 1018)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, 0);
		else
			Store_GiveItem(client, itemid, GetTime(), 0, 306);
		
		PrintToChatAll("%s  \x0C%N\x04在本轮抽奖中抽中了\x0F%s\x05(永久)", PLUGIN_PREFIX, client, name);
		
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04抽奖中抽中了\x0F%s\x05(永久)", client, name);
		Boradcast(true, fmt);
	}
	else if(233 <= rdm <= 250)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, GetTime()+31536000);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+31536000, 305);

		PrintToChatAll("%s  \x0C%N\x04在本轮抽奖中抽中了\x0F%s\x05(1年)", PLUGIN_PREFIX, client, name);
		
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04抽奖中抽中了\x0F%s\x05(1年)", client, name);
		Boradcast(true, fmt);
	}
	else if(600 <= rdm <= 666)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, GetTime()+2592000);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+2592000, 304);

		PrintToChatAll("%s  \x0C%N\x04在本轮抽奖中抽中了\x0F%s\x05(1月)", PLUGIN_PREFIX, client, name);
		
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04抽奖中抽中了\x0F%s\x05(1月)", client, name);
		Boradcast(true, fmt);
	}
	else if(888 <= rdm <= 999)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, GetTime()+604800);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+604800, 303);

		PrintToChatAll("%s  \x0C%N\x04在本轮抽奖中抽中了\x0F%s\x05(1周)", PLUGIN_PREFIX, client, name);
		
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04抽奖中抽中了\x0F%s\x05(1周)", client, name);
		Boradcast(true, fmt);
	}
	else if(1688 <= rdm <= 1888)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, GetTime()+86400);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+86400, 302);

		PrintToChatAll("%s  \x0C%N\x04在本轮抽奖中抽中了\x0F%s\x05(1天)", PLUGIN_PREFIX, client, name);
	}
	else if(16888 <= rdm <= 18888)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, GetTime()+7200);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+7200, 301);

		PrintToChatAll("%s  \x0C%N\x04在本轮抽奖中抽中了\x0F%s\x05(2小时)", PLUGIN_PREFIX, client, name);
	}
	else
		PrintToChat(client, "%s  \x05嗨呀,本轮抽奖你又没有抽中", PLUGIN_PREFIX);
}

stock void Boradcast(bool db, const char[] content)
{
	if(GetFeatureStatus(FeatureType_Native, "CG_Broadcast") != FeatureStatus_Available)
		return;
	
	CG_Broadcast(db, content);
}