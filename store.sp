#pragma semicolon 1
#pragma newdecls required

//////////////////////////////
//			INCLUDES		//
//////////////////////////////
#include <sdkhooks>
#include <cg_core>
#include <maoling>
#include <store>
#include <store_stock>

//////////////////////////////
//		DEFINITIONS			//
//////////////////////////////
#define PLUGIN_NAME "Store - The Resurrection [Redux]"
#define PLUGIN_AUTHOR "Zephyrus | Kyle"
#define PLUGIN_DESCRIPTION "ALL REWRITE WITH NEW SYNTAX!!!"
#define PLUGIN_VERSION "1.88 - 2017/06/28 23:27"
#define PLUGIN_URL ""

// Server
//#define GM_TT
//#define GM_ZE //zombie escape server
//#define GM_MG //mini games server
//#define GM_JB //jail break server
//#define GM_KZ //kreedz server
//#define GM_HZ //casual server
#define GM_PR //pure|competitive server
//#define GM_HG //hunger game server
//#define GM_SR //death surf server

// Custom Module
// skin does not match with team
#if defined GM_TT || defined GM_ZE
#define Global_Skin
#endif
//fix arms when client team
#if defined GM_MG
#define TeamArms
#endif
// hide mode
#if defined GM_ZE || defined GM_JB
#define AllowHide
#endif

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////
Handle g_hDatabase = INVALID_HANDLE;
Handle g_hKeyValue = INVALID_HANDLE;
Handle g_ArraySkin = INVALID_HANDLE;

Store_Item g_eItems[STORE_MAX_ITEMS][Store_Item];
Client_Data g_eClients[MAXPLAYERS+1][Client_Data];
Client_Item g_eClientItems[MAXPLAYERS+1][STORE_MAX_ITEMS][Client_Item];
Type_Handler g_eTypeHandlers[STORE_MAX_HANDLERS][Type_Handler];
Menu_Handler g_eMenuHandlers[STORE_MAX_HANDLERS][Menu_Handler];
Item_Plan g_ePlans[STORE_MAX_ITEMS][STORE_MAX_PLANS][Item_Plan];
Compose_Data g_eCompose[MAXPLAYERS+1][Compose_Data];

int g_iItems = 0;
int g_iTypeHandlers = 0;
int g_iMenuHandlers = 0;
int g_iPackageHandler = -1;
int g_iDatabaseRetries = 0;

int g_iClientCase[MAXPLAYERS+1];
int g_iMenuBack[MAXPLAYERS+1];
int g_iLastSelection[MAXPLAYERS+1];
int g_iSelectedItem[MAXPLAYERS+1];
int g_iSelectedPlan[MAXPLAYERS+1];
int g_iMenuNum[MAXPLAYERS+1];
int g_iSpam[MAXPLAYERS+1];
int g_iDataProtect[MAXPLAYERS+1];
int g_iClientTeam[MAXPLAYERS+1];

#if defined AllowHide
bool g_bHideMode[MAXPLAYERS+1];
#endif

bool g_bInvMode[MAXPLAYERS+1];

bool g_bLateLoad;
char g_szLogFile[128];
char g_szTempole[128];
char g_szCase[4][32] = {"", "CG普通皮肤箱", "CG高级皮肤箱", "CG终极皮肤箱"};


//////////////////////////////
//			MODULES			//
//////////////////////////////
// Module Global Module
#include "store/cpsupport.sp"
#include "store/vipadmin.sp"

// Module Hats
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR
#include "store/modules/hats.sp"
#endif
// Module Skin
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ
#include "store/modules/skin.sp"
#endif
// Module Neon
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR
#include "store/modules/neon.sp"
#endif
// Module Aura & Part
#if defined GM_TT || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR
#include "store/modules/aura.sp"
#include "store/modules/part.sp"
#endif
// Module Trail
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR
#include "store/modules/trail.sp"
#endif
// Module PLAYERS
#if defined Module_Hats || defined Module_Skin || defined Module_Neon || defined Module_Aura || defined Module_Part || defined Module_Trail
#include "store/players.sp"
#endif
// Module Grenade
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR
#include "store/grenades.sp"
#endif
// Module Spray
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ
#include "store/sprays.sp"
#endif
// Module FPVMI
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ
#include "store/models.sp"
#endif
// Module Sound
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ
#include "store/sounds.sp"
#endif
// Module TP
#if defined GM_ZE || defined GM_MG || defined GM_HG || defined GM_SR || defined GM_KZ
#include "store/tpmode.sp"
#endif

//////////////////////////////////
//		PLUGIN DEFINITION		//
//////////////////////////////////
public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url			= PLUGIN_URL
};


//////////////////////////////
//		PLUGIN FORWARDS		//
//////////////////////////////
public void OnPluginStart()
{
	// Setting default values
	for(int client = 1; client <= MaxClients; ++client)
	{
		g_eClients[client][iCredits] = -1;
		g_eClients[client][iOriginalCredits] = 0;
		g_eClients[client][iItems] = -1;
	}

	// Register Commands
	RegConsoleCmd("sm_store", Command_Store);
	RegConsoleCmd("buyammo1", Command_Store);
	RegConsoleCmd("sm_shop", Command_Store);
	RegConsoleCmd("sm_inv", Command_Inventory);
	RegConsoleCmd("sm_inventory", Command_Inventory);
	RegConsoleCmd("sm_credits", Command_Credits);

#if defined AllowHide
	RegConsoleCmd("sm_hide", Command_Hide, "Hide Trail and Neon");
	RegConsoleCmd("sm_hidetrail", Command_Hide, "Hide Trail and Neon");
	RegConsoleCmd("sm_hideneon", Command_Hide, "Hide Trail and Neon");
#endif

	// Load the translations file
	LoadTranslations("store.phrases");

	// Connect to the database
	if(g_hDatabase == INVALID_HANDLE)
	{
		SQL_TConnect(SQLCallback_Connect, "csgo");
		CreateTimer(30.0, Timer_DatabaseTimeout);
	}

	// Initiaze the fake package handler
	g_iPackageHandler = Store_RegisterHandler("package", "", INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION);
}

public void OnAllPluginsLoaded()
{
	// Initiaze module
	UTIL_CheckModules();

	// Load configs
	UTIL_ReloadConfig();
}

public void OnPluginEnd()
{
	for(int client = 1; client <= MaxClients; ++client)
		if(IsClientInGame(client))
			if(g_eClients[client][bLoaded])
				OnClientDisconnect(client);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("Store_RegisterHandler", Native_RegisterHandler);
	CreateNative("Store_RegisterMenuHandler", Native_RegisterMenuHandler);
	CreateNative("Store_SetDataIndex", Native_SetDataIndex);
	CreateNative("Store_GetDataIndex", Native_GetDataIndex);
	CreateNative("Store_GetEquippedItem", Native_GetEquippedItem);
	CreateNative("Store_IsClientLoaded", Native_IsClientLoaded);
	CreateNative("Store_DisplayPreviousMenu", Native_DisplayPreviousMenu);
	CreateNative("Store_SetClientMenu", Native_SetClientMenu);
	CreateNative("Store_GetClientCredits", Native_GetClientCredits);
	CreateNative("Store_SetClientCredits", Native_SetClientCredits);
	CreateNative("Store_IsItemInBoughtPackage", Native_IsItemInBoughtPackage);
	CreateNative("Store_DisplayConfirmMenu", Native_DisplayConfirmMenu);
	CreateNative("Store_GiveItem", Native_GiveItem);
	CreateNative("Store_GetItemId", Native_GetItemId);
	CreateNative("Store_RemoveItem", Native_RemoveItem);
	CreateNative("Store_HasClientItem", Native_HasClientItem);
	CreateNative("Store_ExtClientItem", Native_ExtClientItem);
	CreateNative("Store_GetItemExpiration", Native_GetItemExpiration);
	CreateNative("Store_SaveClientAll", Native_SaveClientAll);
	CreateNative("Store_GetClientID", Native_GetClientID);
	CreateNative("Store_IsClientBanned", Native_IsClientBanned);
	CreateNative("Store_ResetPlayerArms", Native_ResetPlayerArms);
	CreateNative("Store_HasPlayerSkin", Native_HasPlayerSkin);
	CreateNative("Store_GetPlayerSkin", Native_GetPlayerSkin);
	CreateNative("Store_GetSkinLevel", Native_GetSkinLevel);

#if defined Module_Model
	MarkNativeAsOptional("FPVMI_SetClientModel");
	MarkNativeAsOptional("FPVMI_RemoveViewModelToClient");
	MarkNativeAsOptional("FPVMI_RemoveWorldModelToClient");
	MarkNativeAsOptional("FPVMI_RemoveDropModelToClient");
#endif

#if defined Module_Skin
	MarkNativeAsOptional("CG_Broadcast");
#endif

#if defined Module_Sound
	MarkNativeAsOptional("RegClientCookie");
	MarkNativeAsOptional("GetClientCookie");
	MarkNativeAsOptional("SetClientCookie");
#endif

	g_bLateLoad = late;

	return APLRes_Success;
}

//////////////////////////////////////
//		REST OF PLUGIN FORWARDS		//
//////////////////////////////////////
public void OnMapStart()
{
	for(int i = 0; i < g_iTypeHandlers; ++i)
	{
		if(g_eTypeHandlers[i][fnMapStart] != INVALID_FUNCTION)
		{
			Call_StartFunction(g_eTypeHandlers[i][hPlugin], g_eTypeHandlers[i][fnMapStart]);
			Call_Finish();
		}
	}
}

//////////////////////////////////////
//		Global API FROM CORE		//
//////////////////////////////////////
public bool CG_APIStoreSetCredits(int client, int credits, const char[] reason, bool immed)
{
	if(!g_eClients[client][bLoaded] || g_eClients[client][bBan] || g_eClients[client][iCredits] == -1)
		return false;

	if(credits < 0)
	{
		int icredits = credits * -1;
		
		if(icredits > g_eClients[client][iCredits])
			return false;
		
		Store_SetClientCredits(client, Store_GetClientCredits(client)-icredits, reason);
		
		if(immed)
			Store_SaveClientAll(client);
		
		return true;
	}
	else
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client)+credits, reason);
		
		if(immed)
			Store_SaveClientAll(client);

		return true;
	}
}

public int CG_APIStoreGetCredits(int client)
{
	if(!g_eClients[client][bLoaded] || g_eClients[client][bBan] || g_eClients[client][iCredits] == -1)
		return -1;
	
	return g_eClients[client][iCredits];
}

//////////////////////////////
//			NATIVES			//
//////////////////////////////
public int Native_GetItemId(Handle myself, int numParams)
{
	char type[32], uid[256];
	if(GetNativeString(1, type, 32) != SP_ERROR_NONE)
		return -1;
	if(GetNativeString(2, uid, 256) != SP_ERROR_NONE)
		return -1;
	
	return UTIL_GetItemId(type, uid, -1);
}

public int Native_SaveClientAll(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    UTIL_SaveClientData(client);
    UTIL_SaveClientInventory(client);
    UTIL_SaveClientEquipment(client);
}

public int Native_GetClientID(Handle myself, int numParams)
{
	return g_eClients[GetNativeCell(1)][iId];
}

public int Native_IsClientBanned(Handle myself, int numParams)
{
	return g_eClients[GetNativeCell(1)][bBan];
}

public int Native_ResetPlayerArms(Handle myself, int numParams)
{
#if defined Module_Skin
	int client = GetNativeCell(1);
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
		CreateTimer(0.5, Timer_FixPlayerArms, GetClientUserId(client));
#endif
}

public int Native_RegisterHandler(Handle plugin, int numParams)
{
	if(g_iTypeHandlers == STORE_MAX_HANDLERS)
		return -1;

	char m_szType[32];
	GetNativeString(1, STRING(m_szType));
	int m_iHandler = UTIL_GetTypeHandler(m_szType);	
	int m_iId = g_iTypeHandlers;
	
	if(m_iHandler != -1)
		m_iId = m_iHandler;
	else
		++g_iTypeHandlers;
	
	g_eTypeHandlers[m_iId][hPlugin] = plugin;
	g_eTypeHandlers[m_iId][fnMapStart] = GetNativeCell(3);
	g_eTypeHandlers[m_iId][fnReset] = GetNativeCell(4);
	g_eTypeHandlers[m_iId][fnConfig] = GetNativeCell(5);
	g_eTypeHandlers[m_iId][fnUse] = GetNativeCell(6);
	g_eTypeHandlers[m_iId][fnRemove] = GetNativeCell(7);
	g_eTypeHandlers[m_iId][bEquipable] = GetNativeCell(8);
	g_eTypeHandlers[m_iId][bRaw] = GetNativeCell(9);
	strcopy(g_eTypeHandlers[m_iId][szType], 32, m_szType);
	GetNativeString(2, g_eTypeHandlers[m_iId][szUniqueKey], 32);

	return m_iId;
}

public int Native_RegisterMenuHandler(Handle plugin, int numParams)
{
	if(g_iMenuHandlers == STORE_MAX_HANDLERS)
		return -1;
		
	char m_szIdentifier[64];
	GetNativeString(1, STRING(m_szIdentifier));
	int m_iHandler = UTIL_GetMenuHandler(m_szIdentifier);	
	int m_iId = g_iMenuHandlers;
	
	if(m_iHandler != -1)
		m_iId = m_iHandler;
	else
		++g_iMenuHandlers;
	
	g_eMenuHandlers[m_iId][hPlugin] = plugin;
	g_eMenuHandlers[m_iId][fnMenu] = GetNativeCell(2);
	g_eMenuHandlers[m_iId][fnHandler] = GetNativeCell(3);
	strcopy(g_eMenuHandlers[m_iId][szIdentifier], 64, m_szIdentifier);

	return m_iId;
}

public int Native_SetDataIndex(Handle myself, int numParams)
{
	g_eItems[GetNativeCell(1)][iData] = GetNativeCell(2);
}

public int Native_GetDataIndex(Handle myself, int numParams)
{
	return g_eItems[GetNativeCell(1)][iData];
}

public int Native_GetEquippedItem(Handle myself, int numParams)
{
	char m_szType[16];
	GetNativeString(2, STRING(m_szType));
	
	int m_iHandler = UTIL_GetTypeHandler(m_szType);
	if(m_iHandler == -1)
		return -1;
	
	return UTIL_GetEquippedItemFromHandler(GetNativeCell(1), m_iHandler, GetNativeCell(3));
}

public int Native_IsClientLoaded(Handle myself, int numParams)
{
	return g_eClients[GetNativeCell(1)][bLoaded];
}

public int Native_DisplayPreviousMenu(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	if(g_iMenuNum[client] == 1)
		DisplayStoreMenu(client, g_iMenuBack[client], g_iLastSelection[client]);
	else if(g_iMenuNum[client] == 2)
		DisplayItemMenu(client, g_iSelectedItem[client]);
	else if(g_iMenuNum[client] == 3)
		DisplayPlayerMenu(client);
	else if(g_iMenuNum[client] == 5)
		DisplayPlanMenu(client, g_iSelectedItem[client]);
	else if(g_iMenuNum[client] == 6)
		DisplayComposeMenu(client, false);
}

public int Native_SetClientMenu(Handle myself, int numParams)
{
	g_iMenuNum[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetClientCredits(Handle myself, int numParams)
{
	return g_eClients[GetNativeCell(1)][iCredits];
}

public int Native_SetClientCredits(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	if(!IsFakeClient(client))
	{
		int m_iCredits = GetNativeCell(2);
		char logMsg[128];
		if(GetNativeString(3, logMsg, 128) != SP_ERROR_NONE)
			UTIL_LogMessage(client, m_iCredits-g_eClients[client][iCredits], false, "未知来源");
		else
			UTIL_LogMessage(client, m_iCredits-g_eClients[client][iCredits], false, logMsg);

		g_eClients[client][iCredits] = m_iCredits;
	}

	return 1;
}

public int Native_IsItemInBoughtPackage(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	int uid = GetNativeCell(3);

	int m_iParent;
	if(itemid<0)
		m_iParent = g_eItems[itemid][iParent];
	else
		m_iParent = g_eItems[itemid][iParent];
		
	while(m_iParent != -1)
	{
		for(int i = 0; i < g_eClients[client][iItems]; ++i)
			if(((uid == -1 && g_eClientItems[client][i][iUniqueId] == m_iParent) || (uid != -1 && g_eClientItems[client][i][iUniqueId] == uid)) && !g_eClientItems[client][i][bDeleted])
				return true;
		m_iParent = g_eItems[m_iParent][iParent];
	}
	return false;
}

public int Native_DisplayConfirmMenu(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	char title[255], m_szCallback[32], m_szData[11];
	GetNativeString(2, STRING(title));

	DataPack pack = CreateDataPack();
	WritePackCell(pack, plugin);
	WritePackCell(pack, GetNativeCell(3));
	ResetPack(pack);

	Handle m_hMenu = CreateMenu(MenuHandler_Confirm);
	SetMenuTitleEx(m_hMenu, title);
	SetMenuExitButton(m_hMenu, false);
	IntToString(view_as<int>(pack), STRING(m_szCallback));
	IntToString(GetNativeCell(4), STRING(m_szData));
	AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szCallback, "%T", "Confirm_Yes", client);
	AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szData, "%T", "Confirm_No", client);
	DisplayMenu(m_hMenu, client, 0);
}

public int Native_GiveItem(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	int purchase = GetNativeCell(3);
	int expiration = GetNativeCell(4);
	int price = GetNativeCell(5);
	
	if(itemid < 0)
	{
		LogToFileEx(g_szLogFile, "Give %N itemid %d purchase %d expiration %d price %d", client, itemid, purchase, expiration, price);
		return;
	}

	if(!Store_HasClientItem(client, itemid))
	{
		int m_iDateOfPurchase = (purchase==0 ? GetTime() : purchase);
		int m_iDateOfExpiration = expiration;

		int m_iId = g_eClients[client][iItems]++;
		g_eClientItems[client][m_iId][iId] = -1;
		g_eClientItems[client][m_iId][iUniqueId] = itemid;
		g_eClientItems[client][m_iId][iDateOfPurchase] = m_iDateOfPurchase;
		g_eClientItems[client][m_iId][iDateOfExpiration] = m_iDateOfExpiration;
		g_eClientItems[client][m_iId][iPriceOfPurchase] = price;
		g_eClientItems[client][m_iId][bSynced] = false;
		g_eClientItems[client][m_iId][bDeleted] = false;
	}
	else
	{
		int exp = Store_GetItemExpiration(client, itemid);
		if(exp > 0 && exp < expiration)
		{
			if(!Store_ExtClientItem(client, itemid, expiration-exp))
				LogToFileEx(g_szLogFile, "Ext %N %s failed. purchase %d expiration %d price %d", client, g_eItems[itemid][szName] , purchase, expiration, price);
		}
	}
}

public int Native_RemoveItem(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	if(itemid > 0 && g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove] != INVALID_FUNCTION)
	{
		Call_StartFunction(g_eTypeHandlers[g_eItems[itemid][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove]);
		Call_PushCell(client);
		Call_PushCell(itemid);
		Call_Finish();
	}
	
	UTIL_UnequipItem(client, itemid, false);

	int m_iId = UTIL_GetClientItemId(client, itemid);
	if(m_iId != -1)
		g_eClientItems[client][m_iId][bDeleted] = true;
}

public int Native_GetItemExpiration(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	
	// Check if item is available?
	if(itemid < 0)
		return -1;
	
	if(!g_eClients[client][bLoaded])
		return -1;
	
	// Can he even have it?	
	if(!GetClientPrivilege(client, g_eItems[itemid][iFlagBits]))
		return -1;

	if(g_eItems[itemid][szSteam][0] != 0)
		return (AllowItemForAuth(client, g_eItems[itemid][szSteam])) ? 0 : -1;

	if(g_eItems[itemid][bVIP])
		return (AllowItemForVIP(client, g_eItems[itemid][bVIP])) ? 0 : -1;
	
	// Is the item free (available for everyone)?
	if(g_eItems[itemid][iPrice] <= 0 && g_eItems[itemid][iPlans]==0)
		return -1;

	for(int i = 0; i < g_eClients[client][iItems]; ++i)
	{
		if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
			return g_eClientItems[client][i][iDateOfExpiration];
	}

	return -1;
}

public int Native_HasClientItem(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	
	// Check if item is available?
	if(itemid < 0)
		return false;

	// Can he even have it?	
	if(!GetClientPrivilege(client, g_eItems[itemid][iFlagBits]))
		return false;
	
	// Personal item?
	if(g_eItems[itemid][szSteam][0] != 0)
		return AllowItemForAuth(client, g_eItems[itemid][szSteam]);

	// VIP item?
	if(g_eItems[itemid][bVIP])
		return AllowItemForVIP(client, g_eItems[itemid][bVIP]);

	// Is the item free (available for everyone)?
	if(!g_eItems[itemid][bIgnore] && !g_eItems[itemid][bCase] && !g_eItems[itemid][bCompose] && g_eItems[itemid][iPrice] <= 0 && g_eItems[itemid][iPlans]==0)
		return true;

	// Check if the client actually has the item
	for(int i = 0; i < g_eClients[client][iItems]; ++i)
	{
		if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
			if(g_eClientItems[client][i][iDateOfExpiration]==0 || (g_eClientItems[client][i][iDateOfExpiration] && GetTime()<g_eClientItems[client][i][iDateOfExpiration]))
				return true;
			else
				return false;
	}

	// Check if the item is part of a group the client already has
	if(Store_IsItemInBoughtPackage(client, itemid))
		return true;

	return false;
}

public int Native_ExtClientItem(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	int extime = GetNativeCell(3);
	
	if(!g_eClients[client][bLoaded])
		return false;

	for(int i = 0; i < g_eClients[client][iItems]; ++i)
		if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
		{
			if(g_eClientItems[client][i][iDateOfExpiration] == 0)
				return true;

			if(extime == 0)
				g_eClientItems[client][i][iDateOfExpiration] = 0;
			else
				g_eClientItems[client][i][iDateOfExpiration] += extime;

			if(g_eClientItems[client][i][iId]==-1 && !g_eClientItems[client][i][bSynced])
				return true;

			char m_szQuery[256];
			Format(STRING(m_szQuery), "UPDATE `store_items` SET `date_of_expiration` = '%d' WHERE `id`=%d AND `player_id`=%d", g_eClientItems[client][i][iDateOfExpiration], g_eClientItems[client][i][iId], g_eClients[client][iId]);
			SQL_TVoid(g_hDatabase, m_szQuery);

			return true;
		}

	return false;
}

public int Native_GetSkinLevel(Handle myself, int numParams)
{
#if defined Module_Skin
	int client = GetNativeCell(1);
	return IsPlayerAlive(client) ? g_iSkinLevel[client] : 0;
#else
	return 0;
#endif
}

public int Native_HasPlayerSkin(Handle myself, int numParams)
{
#if defined Module_Skin
	int client = GetNativeCell(1);
	return (StrContains(g_szSkinModel[client], "maoling") != -1);
#else
	return false;
#endif
}

public int Native_GetPlayerSkin(Handle myself, int numParams)
{
#if defined Module_Skin
	int client = GetNativeCell(1);
	if(StrContains(g_szSkinModel[client], "maoling") == -1)
		return false;

	if(SetNativeString(2, g_szSkinModel[client], GetNativeCell(3)) == SP_ERROR_NONE)
		return true;
#endif
	return false;
}

//////////////////////////////
//		CLIENT FORWARDS		//
//////////////////////////////
public void OnClientConnected(int client)
{
	g_iSpam[client] = 0;
	g_iClientTeam[client] = 0;
	g_iClientCase[client] = 1;
	g_iDataProtect[client] = GetTime()+180;
	g_eClients[client][iUserId] = GetClientUserId(client);
	g_eClients[client][iCredits] = -1;
	g_eClients[client][iOriginalCredits] = 0;
	g_eClients[client][iItems] = -1;
	g_eClients[client][bLoaded] = false;
	
#if defined AllowHide
	g_bHideMode[client] = false;
#endif
	
	g_eCompose[client][item1] = -1;
	g_eCompose[client][item2] = -1;
	g_eCompose[client][types] = -1;

	for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
	{
		for(int a = 0; a < STORE_MAX_SLOTS; ++a)
		{
			g_eClients[client][aEquipment][i*STORE_MAX_SLOTS+a] = -2;
			g_eClients[client][aEquipmentSynced][i*STORE_MAX_SLOTS+a] = -2;
		}
	}

#if defined Module_Spray
	Sprays_OnClientConnected(client);
#endif

#if defined Module_Sound
	Sound_OnClientConnected(client);
#endif

#if defined Module_TPMode
	TPMode_OnClientConnected(client);
#endif
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;

	g_iDataProtect[client] = GetTime()+120;
	UTIL_LoadClientInventory(client);
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;

#if defined Module_Player
	Players_OnClientDisconnect(client);
#endif

	UTIL_SaveClientData(client);
	UTIL_SaveClientInventory(client);
	UTIL_SaveClientEquipment(client);
	UTIL_DisconnectClient(client);
}

//////////////////////////////////
//			COMMANDS	 		//
//////////////////////////////////
public Action Command_Store(int client, int args)
{
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	if((g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1) || !g_eClients[client][bLoaded])
	{
		tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
		return Plugin_Handled;
	}

	if(g_eClients[client][bBan])
	{
		tPrintToChat(client,"[\x02CAT\x01]  %T", "cat banned", client);
		return Plugin_Handled;
	}	

	g_bInvMode[client]=false;
	DisplayStoreMenu(client);

	return Plugin_Handled;
}

public Action Command_Inventory(int client, int args)
{	
	if((g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1) || !g_eClients[client][bLoaded])
	{
		tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
		return Plugin_Handled;
	}
	
	if(g_eClients[client][bBan])
	{
		tPrintToChat(client,"[\x02CAT\x01]  %T", "cat banned", client);
		return Plugin_Handled;
	}	
	
	g_bInvMode[client] = true;
	DisplayStoreMenu(client);

	return Plugin_Handled;
}

public Action Command_Credits(int client, int args)
{	
	if(g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1)
	{
		tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
		return Plugin_Handled;
	}
	
	if(g_eClients[client][bBan])
	{
		tPrintToChat(client,"[\x02CAT\x01]  %T", "cat banned", client);
		return Plugin_Handled;
	}	

	if(g_iSpam[client]<GetTime())
	{
		tPrintToChatAll("%t", "Player Credits", client, g_eClients[client][iCredits]);
		g_iSpam[client] = GetTime()+30;
	}
	
	return Plugin_Handled;
}

#if defined AllowHide
public Action Command_Hide(int client, int args)
{
	if(!IsClientInGame(client))
		return Plugin_Handled;

	g_bHideMode[client] = !g_bHideMode[client];
	tPrintToChat(client, "%T", "hide setting", client, g_bHideMode[client] ? "on" : "off");

	return Plugin_Handled;
}
#endif

//////////////////////////////
//			MENUS	 		//
//////////////////////////////
int DisplayStoreMenu(int client, int parent = -1, int last = -1)
{
	if(!client || !IsClientInGame(client))
		return;

	g_iMenuNum[client] = 1;

	Handle m_hMenu = CreateMenu(MenuHandler_Store);
	if(parent != -1)
	{
		SetMenuExitBackButton(m_hMenu, true);
		SetMenuTitleEx(m_hMenu, "%s\n%T", g_eItems[parent][szName], "Title Credits", client, g_eClients[client][iCredits]);
		g_iMenuBack[client] = g_eItems[parent][iParent];
	}
	else
		SetMenuTitleEx(m_hMenu, "%T\n%T", "Title Store", client, "Title Credits", client, g_eClients[client][iCredits]);
	
	char m_szId[11];
	int m_iFlags = GetUserFlagBits(client);
	int m_iPosition = 0;
	
	g_iSelectedItem[client] = parent;
	if(parent != -1)
	{
		if(g_eItems[parent][iPrice]>0)
		{
			if(!Store_IsItemInBoughtPackage(client, parent))
			{
				AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "sell_package", "%T", "Package Sell", client, RoundToFloor(g_eItems[parent][iPrice]*0.6));
				++m_iPosition;

				if(g_eItems[parent][bGiftable])
				{
					AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "gift_package", "%T", "Package Gift", client);
					++m_iPosition;
				}

				for(int i = 0; i < g_iMenuHandlers; ++i)
				{
					if(g_eMenuHandlers[i][hPlugin] == INVALID_HANDLE)
						continue;
	
					Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnMenu]);
					Call_PushCellRef(m_hMenu);
					Call_PushCell(client);
					Call_PushCell(parent);
					Call_Finish();
				}
			}
		}
	}

	for(int i = 0; i < g_iItems; ++i)
	{
		if(g_eItems[i][iParent]==parent)
		{
			int m_iPrice = UTIL_GetLowestPrice(i);

			// This is a package
			if(g_eItems[i][iHandler] == g_iPackageHandler)
			{
				if(!UTIL_PackageHasClientItem(client, i, g_bInvMode[client]))
					continue;

				int m_iStyle = ITEMDRAW_DEFAULT;
				if(!GetClientPrivilege(client, g_eItems[i][iFlagBits], m_iFlags) || !AllowItemForAuth(client, g_eItems[i][szSteam]) || !AllowItemForVIP(client, g_eItems[i][bVIP]))
					m_iStyle = ITEMDRAW_DISABLED;

				IntToString(i, STRING(m_szId));
				if(g_eItems[i][iPrice] == -1 || Store_HasClientItem(client, i))
					AddMenuItem(m_hMenu, m_szId, g_eItems[i][szName], m_iStyle);
				else if(!g_bInvMode[client] && g_eItems[i][iPlans]==0 && g_eItems[i][bBuyable])
					InsertMenuItemEx(m_hMenu, m_iPosition, ((m_iPrice<=g_eClients[client][iCredits] && !g_eItems[i][bCompose]) || g_eItems[i][bCompose])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, m_szId, "%T", "Item Available", client, g_eItems[i][szName], g_eItems[i][iPrice]);
				else if(!g_bInvMode[client])
					InsertMenuItemEx(m_hMenu, m_iPosition, ((m_iPrice<=g_eClients[client][iCredits] && !g_eItems[i][bCompose]) || g_eItems[i][bCompose])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, m_szId, "%T", "Item Plan Available", client, g_eItems[i][szName]);
				++m_iPosition;
			}
			// This is a normal item
			else
			{
				IntToString(i, STRING(m_szId));
				if(Store_HasClientItem(client, i))
				{
					if(UTIL_IsEquipped(client, i))
						InsertMenuItemEx(m_hMenu, m_iPosition, ITEMDRAW_DEFAULT, m_szId, "%T", "Item Equipped", client, g_eItems[i][szName]);
					else
						InsertMenuItemEx(m_hMenu, m_iPosition, ITEMDRAW_DEFAULT, m_szId, "%T", "Item Bought", client, g_eItems[i][szName]);
				}
				else if(!g_bInvMode[client])
				{				
					int m_iStyle = ITEMDRAW_DEFAULT;
					if((g_eItems[i][iPlans]==0 && g_eClients[client][iCredits]<m_iPrice) || !GetClientPrivilege(client, g_eItems[i][iFlagBits], m_iFlags) || !AllowItemForAuth(client, g_eItems[i][szSteam]) || !AllowItemForVIP(client, g_eItems[i][bVIP]))
						m_iStyle = ITEMDRAW_DISABLED;

					if(StrEqual(g_eTypeHandlers[g_eItems[i][iHandler]][szType], "playerskin"))
					{
						AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szId, "%T", "Item Preview Available", client, g_eItems[i][szName]);
						continue;
					}

					if(!g_eItems[i][bBuyable])
						continue;

					if(g_eItems[i][iPlans]==0)
						AddMenuItemEx(m_hMenu, m_iStyle, m_szId, "%T", "Item Available", client, g_eItems[i][szName], g_eItems[i][iPrice]);
					else
						AddMenuItemEx(m_hMenu, m_iStyle, m_szId, "%T", "Item Plan Available", client, g_eItems[i][szName], g_eItems[i][iPrice]);
				}
			}
		}
	}
	
	if(last == -1)
		DisplayMenu(m_hMenu, client, 0);
	else
		DisplayMenuAtItem(m_hMenu, client, (last/GetMenuPagination(m_hMenu))*GetMenuPagination(m_hMenu), 0);
}

public int MenuHandler_Store(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Select)
	{
		// Confirmation was given
		if(menu == INVALID_HANDLE)
		{
			if(param2 == 0)
			{
				g_iMenuBack[client]=1;
				int m_iPrice = 0;
				if(g_iSelectedPlan[client]==-1)
					m_iPrice = g_eItems[g_iSelectedItem[client]][iPrice];
				else
					m_iPrice = g_ePlans[g_iSelectedItem[client]][g_iSelectedPlan[client]][iPrice];

				if(g_eClients[client][iCredits]>=m_iPrice && !Store_HasClientItem(client, g_iSelectedItem[client]))
					UTIL_BuyItem(client);
			}
			else if(param2 == 1)
				UTIL_SellItem(client, g_iSelectedItem[client]);
		}
		else
		{
			char m_szId[64];
			GetMenuItem(menu, param2, STRING(m_szId));
			
			g_iLastSelection[client]=param2;
			
			// We are selling a package
			if(strcmp(m_szId, "sell_package")==0)
			{
				char m_szTitle[128];
				Format(STRING(m_szTitle), "%T", "Confirm_Sell", client, g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], RoundToFloor(g_eItems[g_iSelectedItem[client]][iPrice]*0.6));
				Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 1);
				return;
			}
			// We are gifting a package
			else if(strcmp(m_szId, "gift_package")==0)
			{
				DisplayPlayerMenu(client);
			}
			// This is menu handler stuff
			else if(!(48 <= m_szId[0] <= 57))
			{
				int ret;
				for(int i = 0; i < g_iMenuHandlers; ++i)
				{
					Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnHandler]);
					Call_PushCell(client);
					Call_PushString(m_szId);
					Call_PushCell(g_iSelectedItem[client]);
					Call_Finish(ret);

					if(ret)
						break;
				}
			}
			// We are being boring
			else
			{
				int m_iId = StringToInt(m_szId);
				g_iMenuBack[client]=g_eItems[m_iId][iParent];
				g_iSelectedItem[client] = m_iId;
				g_iSelectedPlan[client] = -1;
				
				if(!Store_HasClientItem(client, m_iId))
				{
					if(StrEqual(g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType], "playerskin"))
					{
						DisplayPreviewMenu(client, m_iId);
						return;
					}

					if(g_eItems[m_iId][bCompose])
					{
						if(g_eClients[client][iCredits] >= 10000)
						{
							g_eCompose[client][item1]=-1;
							g_eCompose[client][item2]=-1;
							g_eCompose[client][types]=-1;
							DisplayComposeMenu(client, false);
						}
						else
							tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, 10000);
						return;
					}
					else
					{
						if((g_eClients[client][iCredits]>=g_eItems[m_iId][iPrice] || g_eItems[m_iId][iPlans]>0 && g_eClients[client][iCredits]>=UTIL_GetLowestPrice(m_iId)) && g_eItems[m_iId][iPrice] != -1)
						{
							if(g_eItems[m_iId][iPlans] > 0)
								DisplayPlanMenu(client, m_iId);
							else
							{
								char m_szTitle[128];
								Format(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);
								Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
							}
							return;
						}
					}
				}

				if(g_eItems[m_iId][iHandler] != g_iPackageHandler)
				{
					if(Store_HasClientItem(client, m_iId))
					{
						if(g_eTypeHandlers[g_eItems[m_iId][iHandler]][bRaw])
						{
							Call_StartFunction(g_eTypeHandlers[g_eItems[m_iId][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[m_iId][iHandler]][fnUse]);
							Call_PushCell(client);
							Call_PushCell(m_iId);
							Call_Finish();
						}
						else
							DisplayItemMenu(client, m_iId);
					}
					else
						DisplayStoreMenu(client, g_iMenuBack[client]);					
				}
				else
				{			
					if(Store_HasClientItem(client, m_iId) || g_eItems[m_iId][iPrice] == -1)
						DisplayStoreMenu(client, m_iId);
					else
						DisplayStoreMenu(client, g_eItems[m_iId][iParent]);
				}
			}
		}
	}
	else if(action==MenuAction_Cancel)
		if(param2 == MenuCancel_ExitBack)
			Store_DisplayPreviousMenu(client);
}

void UTIL_GetLevelType(int itemid, char[] buffer, int maxLen)
{
	switch(g_eItems[itemid][iLevels])
	{
		case  2: strcopy(buffer, maxLen, "保密"); //合成
		case  3: strcopy(buffer, maxLen, "隐秘"); //开箱
		case  4: strcopy(buffer, maxLen, "违禁"); //活动
		case  5: strcopy(buffer, maxLen, "史诗"); //专属
		case  6: strcopy(buffer, maxLen, "神圣"); //专属
		default: strcopy(buffer, maxLen, "受限"); //普通
	}
}

public void DisplayPreviewMenu(int client, int itemid)
{
	if(Store_HasClientItem(client, itemid))
		return;
	
	g_iMenuNum[client] = 1;
	g_iMenuBack[client] = g_eItems[itemid][iParent];

	Handle m_hMenu = CreateMenu(MenuHandler_Preview);
	SetMenuExitBackButton(m_hMenu, true);
	
	SetMenuTitleEx(m_hMenu, "%s\n%T", g_eItems[itemid][szName], "Title Credits", client, g_eClients[client][iCredits]);

	AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "3", "%s", g_eItems[itemid][szDesc]);
	
	char leveltype[32];
	UTIL_GetLevelType(itemid, leveltype, 32);
	AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "3", "%T", "Playerskins Level", client, g_eItems[itemid][iLevels], leveltype);

	AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "%T", "Open Case Available", client);

	if(g_eItems[itemid][bCompose])  //合成
		AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%T", "Preview Compose Available", client);
	else if(g_eItems[itemid][szSteam][0] != 0) //专个人属
		AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
	else if(g_eItems[itemid][bIgnore]) //组专属或活动限定
		AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
	else if(g_eItems[itemid][bCase]) //开箱专属
		AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
	else
	{
		if(g_eItems[itemid][bBuyable])
		{
			int m_iStyle = ITEMDRAW_DEFAULT;
			if((g_eItems[itemid][iPlans]==0 && g_eClients[client][iCredits]<UTIL_GetLowestPrice(itemid)) || !GetClientPrivilege(client, g_eItems[itemid][iFlagBits]) || !AllowItemForAuth(client, g_eItems[itemid][szSteam]) || !AllowItemForVIP(client, g_eItems[itemid][bVIP]))
				m_iStyle = ITEMDRAW_DISABLED;
			
			if(g_eItems[itemid][iPlans]==0)
				AddMenuItemEx(m_hMenu, m_iStyle, "1", "%T", "Preview Available", client, g_eItems[itemid][iPrice]);
			else
				AddMenuItemEx(m_hMenu, m_iStyle, "1", "%T", "Preview Plan Available", client);
		}
		else
			AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
	}

	AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "%T", "Item Preview", client);

	DisplayMenu(m_hMenu, client, 0);
}

public int MenuHandler_Preview(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Select)
	{
		char m_szId[64];
		GetMenuItem(menu, param2, STRING(m_szId));
		int selected = StringToInt(m_szId);
		int m_iId = g_iSelectedItem[client];

		if(selected == 0)
		{
			if(g_eClients[client][iCredits] >= 10000)
			{
				g_eCompose[client][item1]=-1;
				g_eCompose[client][item2]=-1;
				g_eCompose[client][types]=-1;
				DisplayComposeMenu(client, false);
			}
			else
				tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, 10000);
		}
		else if(selected == 1)
		{
			if((g_eClients[client][iCredits]>=g_eItems[m_iId][iPrice] || g_eItems[m_iId][iPlans]>0 && g_eClients[client][iCredits]>=UTIL_GetLowestPrice(m_iId)) && g_eItems[m_iId][iPrice] != -1)
			{
				if(g_eItems[m_iId][iPlans] > 0)
					DisplayPlanMenu(client, m_iId);
				else
				{
					char m_szTitle[128];
					Format(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);
					Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
				}
			}
		}
		else if(selected == 2)
		{
#if defined Module_Skin
			if(g_iPreviewTimes[client] <= GetTime())
			{
				Timer_KillPreview(INVALID_HANDLE, client);
				Store_PreviewSkin(client, m_iId);
				DisplayPreviewMenu(client, m_iId);
			}
			else
				tPrintToChat(client, "%T", "Chat Preview Cooldown", client);
#else
			tPrintToChat(client, "%T", "Chat Preview Cooldown", client);
#endif
		}
		else if(selected == 3)
		{
#if defined Module_Skin
			if(g_eClients[client][iCredits] >= 8888)
				UTIL_OpenSkinCase(client);
			else
				tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, 8888);
#else
			tPrintToChat(client, "%T", "Open Case not available", client);
#endif
		}
	}
	else if(action==MenuAction_Cancel)
		if(param2 == MenuCancel_ExitBack)
			Store_DisplayPreviousMenu(client);
}

void UTIL_OpenSkinCase(int client)
{
	if(CG_ClientGetUId(client) < 1)
	{
		tPrintToChat(client, "%T", "Open Case not available", client);
		return;
	}
	
	Handle menu = CreateMenu(MenuHandler_SelectCase);
	SetMenuTitleEx(menu, "选择你要开的箱子\n信用点: %d", g_eClients[client][iCredits]);
	SetMenuExitBackButton(menu, true);

	AddMenuItemEx(menu, g_eClients[client][iCredits] >=  8888 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "1", "%s(8888信用点)\n含有皮肤等级: 保密|隐秘(1天~永久)", g_szCase[1]);
	AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
	AddMenuItemEx(menu, g_eClients[client][iCredits] >= 23333 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "2", "%s(23333信用点)\n含有皮肤等级: 保密|隐秘|违禁(1天~永久)", g_szCase[2]);
	AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
	AddMenuItemEx(menu, g_eClients[client][iCredits] >= 68888 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "3", "%s(68888信用点)\n含有皮肤等级: 保密|隐秘|违禁(#永久#)", g_szCase[3]);

	DisplayMenu(menu, client, 0);
}

public int MenuHandler_SelectCase(Handle menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_Select:
		{
			if(g_iDataProtect[client] > GetTime())
			{
				tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
				UTIL_OpenSkinCase(client);
				return;
			}

			char info[32];
			GetMenuItem(menu, param2, STRING(info));

			g_iClientCase[client] = StringToInt(info);
			
			if(g_eItems[g_iSelectedItem[client]][bIgnore])
			{
				if(g_iClientCase[client] == 1)
					tPrintToChat(client, "%T", "Item not in case", client);
				else if(g_eItems[g_iSelectedItem[client]][szSteam][0] != 0)
					tPrintToChat(client, "%T", "Item not in case", client);
			}

			CreateTimer(0.1, Timer_OpeningCase, client);
		}
		case MenuAction_Cancel:
		{
			if(param2 == MenuCancel_ExitBack)
				DisplayItemMenu(client, g_iSelectedItem[client]);
		}
	}
}

public Action Timer_OpeningCase(Handle timer, int client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	switch(g_iClientCase[client])
	{
		case 1: if(g_eClients[client][iCredits] <  8888) return Plugin_Stop;
		case 2: if(g_eClients[client][iCredits] < 23333) return Plugin_Stop;
		case 3: if(g_eClients[client][iCredits] < 68888) return Plugin_Stop;
		default: return Plugin_Stop;
	}

	static int times[MAXPLAYERS+1];
	
	int size = GetArraySize(g_ArraySkin);
	int aid = UTIL_GetRandomInt(0, size-1);
	char modelname[256];
	GetArrayString(g_ArraySkin, aid, modelname, 256);
	
	if(g_iClientCase[client] > 1)
	{
		int rp = (times[client] < 13) ? 750 : 970;
		if(UTIL_GetRandomInt(1, 1000) > rp)
		{
			switch(UTIL_GetRandomInt(1, 5))
			{
				// 夕立
				case 1: strcopy(modelname, 256, "models/player/custom_player/maoling/kantai_collection/yuudachi/yuudachi.mdl");
				// 艾米莉亚
				case 2: strcopy(modelname, 256, "models/player/custom_player/maoling/re0/emilia_v2/emilia.mdl");
				// 普魯魯特
				case 3: strcopy(modelname, 256, "models/player/custom_player/maoling/neptunia/pururut/normal/pururut.mdl");
				// 巡音流歌
				case 4: strcopy(modelname, 256, "models/player/custom_player/maoling/vocaloid/luka/punk/luka.mdl");
				// NextBlack
				case 5: strcopy(modelname, 256, "models/player/custom_player/maoling/neptunia/noire/nextform/nextblack_nothruster.mdl");
			}
		}
	}

	int itemid = UTIL_GetItemId("playerskin", modelname);

	if(itemid < 0)
	{
		LogError("Item Id Error %s", modelname);
		tPrintToChat(client, "\x07发生未知错误,请联系管理员");
		return Plugin_Stop;
	}

	int days;

	int rdm = UTIL_GetRandomInt(1, 1000);

	if(++times[client] < 15)
	{
		if(rdm >= 850)
			days = 0;
		else
			days = UTIL_GetRandomInt(1, 365);

		if(g_iClientCase[client] == 3)
			days = 0;
	}
	else
	{
		if(rdm >= 970)
			days = 0;
		else if(rdm >= 900)
			days = UTIL_GetRandomInt(32, 365);
		else
			days = UTIL_GetRandomInt(1, 31);

		if(g_iClientCase[client] == 3)
			days = 0;

		times[client] = 0;
		EndingCaseMenu(client, days, itemid);
		return Plugin_Stop;
	}

	OpeningCaseMenu(client, days, g_eItems[itemid][szName]);

	if(5 >= times[client]) CreateTimer(0.2, Timer_OpeningCase, client);
	else if(times[client] > 5)  CreateTimer(0.3, Timer_OpeningCase, client);
	else if(times[client] > 10) CreateTimer(0.4, Timer_OpeningCase, client);
	else if(times[client] > 15) CreateTimer(0.5, Timer_OpeningCase, client);
	else CreateTimer(0.6, Timer_OpeningCase, client);

	return Plugin_Stop;
}

void OpeningCaseMenu(int client, int days, const char[] sname)
{
	Handle menu = CreateMenu(MenuHandler_OpeningCase);
	SetMenuTitleEx(menu, "Opening Case...\n%s", g_szCase[g_iClientCase[client]]);
	SetMenuExitButton(menu, false);
	
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "░░░░░░░░░░░░░░░░░░");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "░░░░░░░░░░░░░░░░░░");

	char name[128];
	strcopy(name, 128, sname);
	ReplaceString(name, 128, "[CT] ", "");
	ReplaceString(name, 128, "[TE] ", "");
	ReplaceString(name, 128, "[通用] ", "");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "   %s", name);
	if(days)
	{
		AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "   %d day%s", days, days > 1 ? "s" : "");
		PrintCenterText(client, "<big><u><b><font color='#dd2f2f' size='25'><center>%s</font> <font color='#15fb00' size='25'>%d Day%s</center>", name, days, days > 1 ? "s" : "");
	}
	else
	{
		AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "永久(permanent)");
		PrintCenterText(client, "<big><u><b><font color='#dd2f2f' size='25'><center>%s</font> <font color='#15fb00' size='25'>Permanent</center>", name);
	}

	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "░░░░░░░░░░░░░░░░░░");
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "░░░░░░░░░░░░░░░░░░");
	
	DisplayMenu(menu, client, 1);
	
	ClientCommand(client, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
}

public int MenuHandler_OpeningCase(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
}

int UTIL_GetSkinSellPrice(int client, int days)
{
	if(days == 0)
		return (g_iClientCase[client] == 3) ? 38888 : 50000;

	int buyc = 233;

	if(days > 150)
		buyc = days*200;
	else if(days > 31)
		buyc = days*250;
	else if(days > 7)
		buyc = days*300;
	else
		buyc = days*350;

	if(buyc > 50000)
		buyc = 50000;

	return buyc;
}

void EndingCaseMenu(int client, int days, int itemid)
{
	switch(g_iClientCase[client])
	{
		case 1: Store_SetClientCredits(client, Store_GetClientCredits(client)- 8888, "OpenCase1");
		case 2: Store_SetClientCredits(client, Store_GetClientCredits(client)-23333, "OpenCase2");
		case 3: Store_SetClientCredits(client, Store_GetClientCredits(client)-68888, "OpenCase3");
		default: return;
	}

	Handle menu = CreateMenu(MenuHandler_OpenSuccessful);
	SetMenuTitleEx(menu, "%T\n%s", "Open case successful", client, g_szCase[g_iClientCase[client]]);
	SetMenuExitButton(menu, false);

	char name[128];
	strcopy(name, 128, g_eItems[itemid][szName]);
	ReplaceString(name, 128, "[CT] ", "");
	ReplaceString(name, 128, "[TE] ", "");
	ReplaceString(name, 128, "[通用] ", "");
	
	char leveltype[32];
	UTIL_GetLevelType(itemid, leveltype, 32);
	AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "皮肤: %s - %s", name, leveltype);
	if(days)
	{
		AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "时限: %d day%s", days, days > 1 ? "s" : "");
		PrintCenterText(client, "<big><u><b><font color='#dd2f2f' size='25'><center>%s</font> <font color='#15fb00' size='25'>%d Day%s</center>", name, days, days > 1 ? "s" : "");
		tPrintToChatAll("\x0E%N\x01在\x0C%s\x01中获得了[\x04%s\x01](\x05%d天\x01)", client, g_szCase[g_iClientCase[client]], name, days);
	}
	else
	{
		AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "时限: 永久(permanent)");
		PrintCenterText(client, "<big><u><b><font color='#dd2f2f' size='25'><center>%s</font> <font color='#15fb00' size='25'>Permanent</center>", name);
		tPrintToChatAll("\x0E%N\x01在\x0C%s\x01中获得了[\x04%s\x01](\x05永久\x01)", client, g_szCase[g_iClientCase[client]], name);
		char msg[256];
		Format(msg, 256, "[\x10Store\x01] \x0E%N\x01在\x0C%s\x01中获得了[\x04%s\x01](\x05永久\x01)", client, g_szCase[g_iClientCase[client]], name);
		BroadCastToAll(msg);
	}

	AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
	AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");

	int crd = UTIL_GetSkinSellPrice(client, days);
	char fmt[32];
	Format(fmt, 32, "sell_%d_%d", itemid, days);
	AddMenuItemEx(menu, ITEMDRAW_DEFAULT, fmt, "快速卖出该皮肤(%d)", crd);
	Format(fmt, 32, "add_%d_%d", itemid, days);
	AddMenuItemEx(menu, Store_HasClientItem(client, itemid) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, fmt, "添加到我的库存");
	
	DisplayMenu(menu, client, 0);
	
	ClientCommand(client, "playgamesound ui/item_drop3_rare.wav");
}

public int MenuHandler_OpenSuccessful(Handle menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_End: CloseHandle(menu);
		case MenuAction_Select:
		{
			char info[32];
			GetMenuItem(menu, param2, STRING(info));
			
			char data[3][16];
			ExplodeString(info, "_", data, 3, 16);
			
			int itemid = StringToInt(data[1]);
			int days = StringToInt(data[2]);
			
			char name[128];
			strcopy(name, 128, g_eItems[itemid][szName]);
			ReplaceString(name, 128, "[CT] ", "");
			ReplaceString(name, 128, "[TE] ", "");
			ReplaceString(name, 128, "[通用] ", "");

			char m_szQuery[256];

			if(StrEqual(data[0], "sell"))
			{
				int crd = UTIL_GetSkinSellPrice(client, days);
				Store_SetClientCredits(client, Store_GetClientCredits(client)+crd, "Quick sell case skin Select");
				if(days) tPrintToChat(client, "你出售了[\x04%s\x01](\x05%d天\x01)获得了\x04%d\x01信用点", name, days, crd);
				else tPrintToChat(client, "你出售了[\x04%s\x01](\x05永久\x01)获得了\x04%d\x01信用点", name, crd);
				Format(m_szQuery, 256, "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, %d, 'sell', %d)", g_eClients[client][iId], g_eItems[itemid][szUniqueId], days, GetTime(), g_iClientCase[client]);
				SQL_TVoid(g_hDatabase, m_szQuery);
				g_iDataProtect[client] = GetTime()+5;
				UTIL_OpenSkinCase(client);
				if(g_iClientCase[client] > 1)
				{
					g_iDataProtect[client] = GetTime()+30;
					Store_SaveClientAll(client);
				}
			}
			else if(StrEqual(data[0], "add"))
			{
				Store_GiveItem(client, itemid, GetTime(), (days == 0) ? 0 : GetTime()+days*86400, 233);
				if(days) tPrintToChat(client, "你打开\x0C%s\x01获得了[\x04%s\x01](\x05%d天\x01)", g_szCase[g_iClientCase[client]], name, days);
				else tPrintToChat(client, "你打开\x0C%s\x01获得了[\x04%s\x01](\x05永久\x01)", g_szCase[g_iClientCase[client]], name);			
				Store_SaveClientAll(client);
				Format(m_szQuery, 256, "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, %d, 'add', %d)", g_eClients[client][iId], g_eItems[itemid][szUniqueId], days, GetTime(), g_iClientCase[client]);
				SQL_TVoid(g_hDatabase, m_szQuery);
				g_iDataProtect[client] = GetTime()+30;
				g_iSelectedItem[client] = itemid;
				DisplayItemMenu(client, itemid);
			}
			else
				LogError("%N Open case error: %s", client, info);
		}
		case MenuAction_Cancel:
		{
			if(IsClientInGame(client) && param2 != MenuCancel_Disconnected && param2 != MenuCancel_NoDisplay)
			{
				char info[32];
				GetMenuItem(menu, 5, STRING(info));
				
				char data[3][16];
				ExplodeString(info, "_", data, 3, 16);
				
				int itemid = StringToInt(data[1]);
				int days = StringToInt(data[2]);
				
				char name[128];
				strcopy(name, 128, g_eItems[itemid][szName]);
				ReplaceString(name, 128, "[CT] ", "");
				ReplaceString(name, 128, "[TE] ", "");
				ReplaceString(name, 128, "[通用] ", "");
				
				char m_szQuery[256];
				
				if(Store_HasClientItem(client, itemid))
				{
					int crd = UTIL_GetSkinSellPrice(client, days);
					Store_SetClientCredits(client, Store_GetClientCredits(client)+crd, "Quick sell case skin Exitback");
					if(days) tPrintToChat(client, "你出售了[\x04%s\x01](\x05%d天\x01)获得了\x04%d\x01信用点", name, days, crd);
					else tPrintToChat(client, "你出售了[\x04%s\x01](\x05永久\x01)获得了\x04%d\x01信用点", name, crd);
					if(g_iClientCase[client] > 1)
					{
						g_iDataProtect[client] = GetTime()+30;
						Store_SaveClientAll(client);
					} else g_iDataProtect[client] = GetTime()+5;
					Format(m_szQuery, 256, "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, %d, 'sell', %d)", g_eClients[client][iId], g_eItems[itemid][szUniqueId], days, GetTime(), g_iClientCase[client]);
				}
				else
				{
					Store_GiveItem(client, itemid, GetTime(), (days == 0) ? 0 : GetTime()+days*86400, 233);
					if(days) tPrintToChat(client, "你打开\x0C%s\x01获得了[\x04%s\x01](\x05%d天\x01)", g_szCase[g_iClientCase[client]], name, days);
					else tPrintToChat(client, "你打开\x0C%s\x01获得了[\x04%s\x01](\x05永久\x01)", g_szCase[g_iClientCase[client]], name);			
					Store_SaveClientAll(client);
					g_iDataProtect[client] = GetTime()+30;
					g_iSelectedItem[client] = itemid;
					Format(m_szQuery, 256, "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, %d, 'add', %d)", g_eClients[client][iId], g_eItems[itemid][szUniqueId], days, GetTime(), g_iClientCase[client]);
				}

				SQL_TVoid(g_hDatabase, m_szQuery);
			}
		}
	}
}

public void DisplayItemMenu(int client, int itemid)
{
	if(!Store_HasClientItem(client, itemid))
	{
		if(StrEqual(g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], "playerskin"))
			DisplayPreviewMenu(client, itemid);
		return;
	}

	g_iMenuNum[client] = 1;
	g_iMenuBack[client] = g_eItems[itemid][iParent];

	Handle m_hMenu = CreateMenu(MenuHandler_Item);
	SetMenuExitBackButton(m_hMenu, true);
	
	bool m_bEquipped = UTIL_IsEquipped(client, itemid);
	char m_szTitle[256];
	int idx = 0;
	if(m_bEquipped)
		idx = Format(STRING(m_szTitle), "%T\n%T", "Item Equipped", client, g_eItems[itemid][szName], "Title Credits", client, g_eClients[client][iCredits]);
	else
		idx = Format(STRING(m_szTitle), "%s\n%T", g_eItems[itemid][szName], "Title Credits", client, g_eClients[client][iCredits]);

	int m_iExpiration = UTIL_GetExpiration(client, itemid);
	if(m_iExpiration != 0)
	{
		m_iExpiration = m_iExpiration-GetTime();
		int m_iDays = m_iExpiration/(24*60*60);
		int m_iHours = (m_iExpiration-m_iDays*24*60*60)/(60*60);
		Format(m_szTitle[idx-1], sizeof(m_szTitle)-idx-1, "\n%T", "Title Expiration", client, m_iDays, m_iHours);
	}
	
	SetMenuTitleEx(m_hMenu, m_szTitle);

	if(g_eTypeHandlers[g_eItems[itemid][iHandler]][bEquipable])
	{
		if(StrEqual(g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], "playerskin"))
		{
			AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%s", g_eItems[itemid][szDesc]);
	
			char leveltype[32];
			UTIL_GetLevelType(itemid, leveltype, 32);
			AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%T", "Playerskins Level", client, g_eItems[itemid][iLevels], leveltype);
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "4", "%T", "Open Case Available", client);
		}

		if(!m_bEquipped)
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%T", "Item Equip", client);
		else
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "%T", "Item Unequip", client);
	}
	else
	{
		if(StrEqual(g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], "buyvip"))
		{
			if(CG_ClientIsVIP(client))
				AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%T", "you are already vip", client);
			else
				AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%T", "go to forum to buy vip", client);
		}
		else
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%T", "Item Use", client);
	}

	if(!Store_IsItemInBoughtPackage(client, itemid))
	{
		int m_iCredits = RoundToFloor(UTIL_GetClientItemPrice(client, itemid)*0.6);
		if(m_iCredits!=0)
		{
			int uid = UTIL_GetClientItemId(client, itemid);
			if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
			{
				int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
				int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
				if(m_iLeft < 0)
					m_iLeft = 0;
				m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
			}

			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "1", "%T", "Item Sell", client, m_iCredits);
			if(g_eItems[itemid][bGiftable])
				AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "%T", "Item Gift", client);
		}
	}

	for(int i = 0; i < g_iMenuHandlers; ++i)
	{
		if(g_eMenuHandlers[i][hPlugin] == INVALID_HANDLE)
			continue;
		Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnMenu]);
		Call_PushCellRef(m_hMenu);
		Call_PushCell(client);
		Call_PushCell(itemid);
		Call_Finish();
	}

	DisplayMenu(m_hMenu, client, 0);
}

public void DisplayPlanMenu(int client, int itemid)
{
	g_iMenuNum[client] = 1;

	Handle m_hMenu = CreateMenu(MenuHandler_Plan);
	SetMenuExitBackButton(m_hMenu, true);
	
	SetMenuTitleEx(m_hMenu, "%s\n%T", g_eItems[itemid][szName], "Title Credits", client, g_eClients[client][iCredits]);
	
	for(int i = 0; i < g_eItems[itemid][iPlans]; ++i)
	{
		AddMenuItemEx(m_hMenu, (g_eClients[client][iCredits]>=g_ePlans[itemid][i][iPrice]?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED), "", "%T",  "Item Available", client, g_ePlans[itemid][i][szName], g_ePlans[itemid][i][iPrice]);
	}
	
	DisplayMenu(m_hMenu, client, 0);
}

public void DisplayComposeMenu(int client, bool last)
{
	if(g_iDataProtect[client] > GetTime())
	{
		tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
		DisplayPreviewMenu(client, g_iSelectedItem[client]);
		return;
	}
	
	g_iMenuNum[client] = 1;
	Handle m_hMenu = CreateMenu(MenuHandler_Compose);
	SetMenuExitBackButton(m_hMenu, true);
	
	char sitem1[64];
	if(g_eCompose[client][item1] >= 0)
		strcopy(sitem1, 64, g_eItems[g_eCompose[client][item1]][szName]);
	else
		Format(sitem1, 64, "%T", "unselect", client);
	
	char sitem2[64];
	if(g_eCompose[client][item2] >= 0)
		strcopy(sitem2, 64, g_eItems[g_eCompose[client][item2]][szName]);
	else
		Format(sitem2, 64, "%T", "unselect", client);

	SetMenuTitleEx(m_hMenu, "%T", "Title Compose", client, g_eItems[g_iSelectedItem[client]][szName], sitem1, sitem2);

	int num=0;

	if(!last)
	{
		char m_szId[8];
		for(int i = 0; i < g_iItems; ++i)
		{
			if(g_eItems[i][iHandler] == g_iPackageHandler)
				continue;
			
			if(!Store_HasClientItem(client, i))
				continue;

			if(i == g_eCompose[client][item1] || i == g_eCompose[client][item2])
				continue;

			if(!StrEqual(g_eTypeHandlers[g_eItems[i][iHandler]][szType], "playerskin"))
				continue;
			
			if(!g_eItems[i][bGiftable] || g_eItems[i][bCompose])
				continue;

			int uid = UTIL_GetClientItemId(client, i);
			
			if(uid < 0 || g_eClientItems[client][uid][iDateOfExpiration] != 0 || g_eClientItems[client][uid][iPriceOfPurchase] < 1)
				continue;

			num++;
			IntToString(i, m_szId, 8);
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szId, g_eItems[i][szName]);
		}
	}
	else
	{
		AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "合成模式① [60%%成功率]");
		AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "1", "合成模式② [65%%成功率]");
		AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "合成模式③ [70%%成功率]");
		AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "合成模式④ [75%%成功率]");
		AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "4", "合成模式⑤ [80%%成功率]");
		AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "5", "合成模式⑥ [99%%成功率]");
		num=6;
	}

	if(num > 0)
		DisplayMenu(m_hMenu, client, 0);
	else
	{
		CloseHandle(m_hMenu);
		tPrintToChat(client, "%T", "Compose no material", client);
		Store_DisplayPreviousMenu(client);
	}
}

public int MenuHandler_Compose(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Select)
	{
		// Confirmation was sent
		if(menu == INVALID_HANDLE)
		{
			if(param2 == 0)
			{
				UTIL_ComposeItem(client);
			}
		}
		else
		{
			char m_szId[64];
			GetMenuItem(menu, param2, STRING(m_szId));
			int itemid = StringToInt(m_szId);
			g_iMenuNum[client] = 6;
			if(g_eCompose[client][item1]==-1)
			{
				g_eCompose[client][item1]=itemid;
				DisplayComposeMenu(client, false);
			}
			else if(g_eCompose[client][item2]==-1)
			{
				g_eCompose[client][item2]=itemid;
				DisplayComposeMenu(client, true);
			}
			else if(0 <= itemid <= 5 && g_eCompose[client][item1] >= 0 && g_eCompose[client][item2] >= 0 && Store_HasClientItem(client, g_eCompose[client][item1]) && Store_HasClientItem(client, g_eCompose[client][item2]))
			{
				g_eCompose[client][types]=itemid;
				char m_szTitle[256], m_szTypes[32];
				switch(itemid)
				{
					case 0: strcopy(m_szTypes, 32,  "5000");
					case 1: strcopy(m_szTypes, 32, "10000");
					case 2: strcopy(m_szTypes, 32, "15000");
					case 3: strcopy(m_szTypes, 32, "20000");
					case 4: strcopy(m_szTypes, 32, "25000");
					case 5: strcopy(m_szTypes, 32, "88888");
				}
				Format(m_szTitle, 256, "%T", "Confirm_Compose", client, g_eItems[g_iSelectedItem[client]][szName], g_eItems[g_eCompose[client][item1]][szName], g_eItems[g_eCompose[client][item2]][szName], m_szTypes);
				Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Compose, 0);
			}
		}
	}
	else if(action==MenuAction_Cancel)
		if(param2 == MenuCancel_ExitBack)
		{
			g_eCompose[client][item1] = -1;
			g_eCompose[client][item2] = -1;
			g_eCompose[client][types] = -1;
			Store_DisplayPreviousMenu(client);
		}
}

public int MenuHandler_Plan(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Select)
	{
		g_iSelectedPlan[client]=param2;
		g_iMenuNum[client]=5;

		char m_szTitle[128];
		Format(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType]);
		Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
		return;
	}
	else if(action==MenuAction_Cancel)
		if(param2 == MenuCancel_ExitBack)
			Store_DisplayPreviousMenu(client);
}

public int MenuHandler_Item(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Select)
	{
		// Confirmation was sent
		if(menu == INVALID_HANDLE)
		{
			if(param2 == 0)
			{
				g_iMenuNum[client] = 1;
				UTIL_SellItem(client, g_iSelectedItem[client]);
			}
		}
		else
		{
			char m_szId[64];
			GetMenuItem(menu, param2, STRING(m_szId));
			
			int m_iId = StringToInt(m_szId);
			
			// Menu handlers
			if(!(48 <= m_szId[0] <= 57))
			{
				int ret;
				for(int i=0;i<g_iMenuHandlers;++i)
				{
					if(g_eMenuHandlers[i][hPlugin] == INVALID_HANDLE)
						continue;
					Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnHandler]);
					Call_PushCell(client);
					Call_PushString(m_szId);
					Call_PushCell(g_iSelectedItem[client]);
					Call_Finish(ret);

					if(ret)
						break;
				}
			}
			// Player wants to equip this item
			else if(m_iId == 0)
			{
				int m_iRet = UTIL_UseItem(client, g_iSelectedItem[client]);
				if(GetClientMenu(client)==MenuSource_None && m_iRet == 0)
					DisplayItemMenu(client, g_iSelectedItem[client]);
			}
			// Player wants to sell this item
			else if(m_iId == 1)
			{
				int m_iCredits = RoundToFloor(UTIL_GetClientItemPrice(client, g_iSelectedItem[client])*0.6);
				int uid = UTIL_GetClientItemId(client, g_iSelectedItem[client]);
				if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
				{
					int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
					int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
					if(m_iLeft < 0)
						m_iLeft = 0;
					m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
				}

				char m_szTitle[128];
				Format(STRING(m_szTitle), "%T", "Confirm_Sell", client, g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], m_iCredits);
				g_iMenuNum[client] = 2;
				Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Item, 0);
			}
			// Player wants to gift this item
			else if(m_iId == 2)
			{
				g_iMenuNum[client] = 2;
				DisplayPlayerMenu(client);
			}
			// Player wants to unequip this item
			else if(m_iId == 3)
			{
				UTIL_UnequipItem(client, g_iSelectedItem[client]);
				DisplayItemMenu(client, g_iSelectedItem[client]);
			}
			// Player want to open case
			else if(m_iId == 4)
			{
#if defined Module_Skin
				if(g_eClients[client][iCredits] >= 8888)
					UTIL_OpenSkinCase(client);
				else
					tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, 8888);
#else
				tPrintToChat(client, "%T", "Open Case not available", client);
#endif
			}
		}
	}
	else if(action==MenuAction_Cancel)
		if(param2 == MenuCancel_ExitBack)
			Store_DisplayPreviousMenu(client);
}

public void DisplayPlayerMenu(int client)
{
	g_iMenuNum[client] = 3;

	int m_iCount = 0;
	Handle m_hMenu = CreateMenu(MenuHandler_Gift);
	SetMenuExitBackButton(m_hMenu, true);
	SetMenuTitleEx(m_hMenu, "%T\n%T", "Title Gift", client, "Title Credits", client, g_eClients[client][iCredits]);
	
	char m_szID[11];
	int m_iFlags;
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(!IsClientInGame(i))
			continue;

		m_iFlags = GetUserFlagBits(i);
		if(!GetClientPrivilege(i, g_eItems[g_iSelectedItem[client]][iFlagBits], m_iFlags) || !AllowItemForAuth(client, g_eItems[g_iSelectedItem[client]][szSteam]) || !AllowItemForVIP(client, g_eItems[g_iSelectedItem[client]][bVIP]))
			continue;
		if(i != client && IsClientInGame(i) && !Store_HasClientItem(i, g_iSelectedItem[client]))
		{
			IntToString(g_eClients[i][iUserId], STRING(m_szID));
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szID, "%N", i);
			++m_iCount;
		}
	}
	
	if(m_iCount == 0)
	{
		CloseHandle(m_hMenu);
		g_iMenuNum[client] = 1;
		DisplayItemMenu(client, g_iSelectedItem[client]);
		tPrintToChat(client, "%T", "Gift No Players", client);
	}
	else
		DisplayMenu(m_hMenu, client, 0);
}

public int MenuHandler_Gift(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Select)
	{
		int m_iItem, m_iReceiver;
	
		// Confirmation was given
		if(menu == INVALID_HANDLE)
		{
			m_iItem = UTIL_GetClientItemId(client, g_iSelectedItem[client]);
			m_iReceiver = GetClientOfUserId(param2);
			if(!m_iReceiver)
			{
				tPrintToChat(client, "%T", "Gift Player Left", client);
				return;
			}
			UTIL_GiftItem(client, m_iReceiver, m_iItem);
			g_iMenuNum[client] = 1;
			Store_DisplayPreviousMenu(client);
		}
		else
		{
			char m_szId[11];
			GetMenuItem(menu, param2, STRING(m_szId));
			
			int m_iId = StringToInt(m_szId);
			m_iReceiver = GetClientOfUserId(m_iId);
			if(!m_iReceiver)
			{
				tPrintToChat(client, "%T", "Gift Player Left", client);
				return;
			}

			m_iItem = UTIL_GetClientItemId(client, g_iSelectedItem[client]);
			
			char m_szTitle[128];
			int m_iFees = UTIL_GetClientHandleFees(client, g_iSelectedItem[client]);
			if(m_iFees > 0)
			{
				Format(STRING(m_szTitle), "%T\n%T", "Confirm_Gift", client, g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], m_iReceiver, "Gift_Handing", client, m_iFees);
				Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Gift, m_iId);
			}
			else
				tPrintToChat(client, " \x02UNKNOWN ERROR\x01 :  \x07%d", UTIL_GetRandomInt(100000, 999999));
		}
	}
	else if(action==MenuAction_Cancel)
		if(param2 == MenuCancel_ExitBack)
			DisplayItemMenu(client, g_iSelectedItem[client]);
}

public int MenuHandler_Confirm(Handle menu, MenuAction action, int client, int param2)
{
	if(action == MenuAction_End)
		CloseHandle(menu);
	else if(action == MenuAction_Select)
	{		
		if(param2 == 0)
		{
			char m_szCallback[32];
			char m_szData[11];
			GetMenuItem(menu, 0, STRING(m_szCallback));
			GetMenuItem(menu, 1, STRING(m_szData));
			Handle pack = view_as<Handle>(StringToInt(m_szCallback));
			Handle m_hPlugin = ReadPackCell(pack);
			Function fnMenuCallback = ReadPackCell(pack);
			CloseHandle(pack);
			if(m_hPlugin != INVALID_HANDLE && fnMenuCallback != INVALID_FUNCTION)
			{
				Call_StartFunction(m_hPlugin, fnMenuCallback);
				Call_PushCell(INVALID_HANDLE);
				Call_PushCell(MenuAction_Select);
				Call_PushCell(client);
				Call_PushCell(StringToInt(m_szData));
				Call_Finish();
			}
			else
				Store_DisplayPreviousMenu(client);
		}
		else
		{
			Store_DisplayPreviousMenu(client);
		}
	}
}

//////////////////////////////
//			TIMERS	 		//
//////////////////////////////
public Action Timer_DatabaseTimeout(Handle timer, int userid)
{
	// Database is connected successfully
	if(g_hDatabase != INVALID_HANDLE)
		return Plugin_Stop;

	if(g_iDatabaseRetries < 100)
	{
		SQL_TConnect(SQLCallback_Connect, "store");
		CreateTimer(30.0, Timer_DatabaseTimeout);
		++g_iDatabaseRetries;
	}
	else
	{
		SetFailState("Database connection failed to initialize after 100 retrie");
	}

	return Plugin_Stop;
}

//////////////////////////////
//		SQL CALLBACKS		//
//////////////////////////////
public void SQLCallback_Connect(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl==INVALID_HANDLE)
		LogError("Failed to connect to SQL database. Error: %s", error);
	else
	{
		// If it's already connected we are good to go
		if(g_hDatabase != INVALID_HANDLE)
			return;

		g_hDatabase = hndl;

		// Do some housekeeping
		SQL_SetCharset(g_hDatabase, "utf8");
		
		char m_szQuery[256];
		Format(STRING(m_szQuery), "DELETE FROM store_items WHERE `date_of_expiration` <> 0 AND `date_of_expiration` < %d", GetTime());
		SQL_TVoid(g_hDatabase, m_szQuery);
		
		// if Loaded late.
		if(g_bLateLoad)
		{
			for(int client = 1; client <= MaxClients; ++client)
			{
				if(!IsClientInGame(client))
					continue;

				OnClientConnected(client);
				OnClientPostAdminCheck(client);
			}
		}

		// Build Log Path
		UTIL_BuildTempLogFile();
	}
}

public void SQLCallback_LoadClientInventory_Credits(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
		LogError("Error happened. Error: %s", error);
	else
	{
		int client = GetClientOfUserId(userid);
		if(!client)
			return;
		
		char m_szQuery[512], m_szSteamID[32];
		int m_iTime = GetTime();
		g_eClients[client][iUserId] = userid;
		g_eClients[client][iItems] = -1;
		GetClientAuthId(client, AuthId_Steam2, STRING(m_szSteamID), true);
		strcopy(g_eClients[client][szAuthId], 32, m_szSteamID[8]);
		if(KvJumpToKey(g_hKeyValue, m_szSteamID, true))
		{
			KvSetNum(g_hKeyValue, "Connect", GetTime());
			KvRewind(g_hKeyValue);
			KeyValuesToFile(g_hKeyValue, g_szLogFile);
		}
		
		if(SQL_FetchRow(hndl))
		{
			g_eClients[client][iId] = SQL_FetchInt(hndl, 0);
			g_eClients[client][iCredits] = SQL_FetchInt(hndl, 3);
			g_eClients[client][iOriginalCredits] = SQL_FetchInt(hndl, 3);
			g_eClients[client][iDateOfJoin] = SQL_FetchInt(hndl, 4);
			g_eClients[client][iDateOfLastJoin] = m_iTime;
			g_eClients[client][bBan] = (SQL_FetchInt(hndl, 6) == 1 || g_eClients[client][iCredits] < 0) ? true : false;
			
			if(g_eClients[client][iId] == 1 && !StrEqual(m_szSteamID, "STEAM_1:1:44083262"))
			{
				g_eClients[client][bBan] = true;
				return;
			}

			Format(STRING(m_szQuery), "SELECT * FROM store_items WHERE `player_id`=%d", g_eClients[client][iId]);
			SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Items, m_szQuery, userid);

			UTIL_LogMessage(client, g_eClients[client][iCredits], true, "本次进入服务器时的Credits");
		}
		else
		{
			char m_szName[64], m_szEName[128];
			GetClientName(client, m_szName, 64);
			SQL_EscapeString(g_hDatabase, m_szName, m_szEName, 128);
			Format(STRING(m_szQuery), "INSERT INTO store_players (`authid`, `name`, `credits`, `date_of_join`, `date_of_last_join`, `ban`) VALUES(\"%s\", '%s', 300, %d, %d, '0')", g_eClients[client][szAuthId], m_szEName, m_iTime, m_iTime);
			SQL_TQuery(g_hDatabase, SQLCallback_InsertClient, m_szQuery, userid);
			g_eClients[client][iCredits] = 0;
			g_eClients[client][iOriginalCredits] = 0;
			g_eClients[client][iDateOfJoin] = m_iTime;
			g_eClients[client][iDateOfLastJoin] = m_iTime;
			g_eClients[client][bLoaded] = true;
			g_eClients[client][iItems] = 0;
			
			g_eClients[client][hTimer] = CreateTimer(300.0, Timer_OnlineCredit, client, TIMER_REPEAT);
		}
	}
}

public void SQLCallback_LoadClientInventory_Items(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
		LogError("Error happened. Error: %s", error);
	else
	{	
		int client = GetClientOfUserId(userid);
		if(!client)
			return;

		if(g_eClients[client][bBan])
		{
			g_eClients[client][bLoaded] = true;
			g_eClients[client][iItems] = 0;
			return;
		}

		if(!SQL_GetRowCount(hndl))
		{
			g_eClients[client][bLoaded] = true;
			g_eClients[client][iItems] = 0;
			return;
		}
		
		char m_szQuery[512];
		Format(STRING(m_szQuery), "SELECT * FROM store_equipment WHERE `player_id`=%d", g_eClients[client][iId]);
		SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Equipment, m_szQuery, userid);

		char m_szUniqueId[PLATFORM_MAX_PATH];
		char m_szType[16];
		int m_iExpiration;
		int m_iUniqueId;
		int m_iTime = GetTime();
		
		int i = 0;
		while(SQL_FetchRow(hndl))
		{
			m_iUniqueId = -1;
			m_iExpiration = SQL_FetchInt(hndl, 5);
			if(m_iExpiration && m_iExpiration<=m_iTime)
				continue;
			
			SQL_FetchString(hndl, 2, STRING(m_szType));
			SQL_FetchString(hndl, 3, STRING(m_szUniqueId));

			while((m_iUniqueId = UTIL_GetItemId(m_szType, m_szUniqueId, m_iUniqueId))!=-1)
			{
				g_eClientItems[client][i][iId] = SQL_FetchInt(hndl, 0);
				g_eClientItems[client][i][iUniqueId] = m_iUniqueId;
				g_eClientItems[client][i][bSynced] = true;
				g_eClientItems[client][i][bDeleted] = false;
				g_eClientItems[client][i][iDateOfPurchase] = SQL_FetchInt(hndl, 4);
				g_eClientItems[client][i][iDateOfExpiration] = m_iExpiration;
				g_eClientItems[client][i][iPriceOfPurchase] = SQL_FetchInt(hndl, 6);
				++i;
			}
		}
		g_eClients[client][iItems] = i;
	}
}

public void SQLCallback_LoadClientInventory_Equipment(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
		LogError("Error happened. Error: %s", error);
	else
	{
		int client = GetClientOfUserId(userid);
		if(!client)
			return;
		
		char m_szUniqueId[PLATFORM_MAX_PATH];
		char m_szType[16];
		int m_iUniqueId, m_iSlot;

		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 1, STRING(m_szType));
			SQL_FetchString(hndl, 2, STRING(m_szUniqueId));
			m_iUniqueId = UTIL_GetItemId(m_szType, m_szUniqueId);
			if(m_iUniqueId == -1)
				continue;

			m_iSlot = SQL_FetchInt(hndl, 3);

			if(StrEqual(m_szType, "playerskin"))
			{
#if defined Global_Skin
				if(m_iSlot != 2)
					continue;
#else
				if(m_iSlot >= 2)
					continue;
#endif
			}

			if(Store_HasClientItem(client, m_iUniqueId))
				UTIL_UseItem(client, m_iUniqueId, true, m_iSlot);
			else
				UTIL_UnequipItem(client, m_iUniqueId);
		}
		g_eClients[client][bLoaded] = true;
		g_eClients[client][hTimer] = CreateTimer(300.0, Timer_OnlineCredit, client, TIMER_REPEAT);
	}
}

public void SQLCallback_InsertClient(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
		LogError("Error happened. Error: %s", error);
	else
	{
		int client = GetClientOfUserId(userid);
		if(!client)
			return;
			
		g_eClients[client][iId] = SQL_GetInsertId(hndl);
	}
}

//////////////////////////////
//			STOCKS			//
//////////////////////////////
void UTIL_LoadClientInventory(int client)
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		LogError("Database connection is lost or not yet initialized.");
		return;
	}
	
	char m_szQuery[512];
	char m_szAuthId[32];

	GetClientAuthId(client, AuthId_Steam2, STRING(m_szAuthId), true);
	if(m_szAuthId[0] == 0)
		return;

	Format(STRING(m_szQuery), "SELECT * FROM store_players WHERE `authid`=\"%s\"", m_szAuthId[8]);

	SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Credits, m_szQuery, g_eClients[client][iUserId]);
}

void UTIL_SaveClientInventory(int client)
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		LogError("Database connection is lost or not yet initialized.");
		return;
	}
	
	// Player disconnected before his inventory was even fetched
	if(g_eClients[client][iCredits]==-1 && g_eClients[client][iItems]==-1)
		return;
	
	char m_szQuery[512];
	char m_szType[16];
	char m_szUniqueId[PLATFORM_MAX_PATH];

	for(int i = 0; i < g_eClients[client][iItems]; ++i)
	{
		strcopy(STRING(m_szType), g_eTypeHandlers[g_eItems[g_eClientItems[client][i][iUniqueId]][iHandler]][szType]);
		strcopy(STRING(m_szUniqueId), g_eItems[g_eClientItems[client][i][iUniqueId]][szUniqueId]);
	
		if(!g_eClientItems[client][i][bSynced] && !g_eClientItems[client][i][bDeleted])
		{
			g_eClientItems[client][i][bSynced] = true;
			Format(STRING(m_szQuery), "INSERT INTO store_items (`player_id`, `type`, `unique_id`, `date_of_purchase`, `date_of_expiration`, `price_of_purchase`) VALUES(%d, \"%s\", \"%s\", %d, %d, %d)", g_eClients[client][iId], m_szType, m_szUniqueId, g_eClientItems[client][i][iDateOfPurchase], g_eClientItems[client][i][iDateOfExpiration], g_eClientItems[client][i][iPriceOfPurchase]);
			SQL_TVoid(g_hDatabase, m_szQuery);
		}
		else if(g_eClientItems[client][i][bSynced] && g_eClientItems[client][i][bDeleted])
		{
			// Might have been synced already but ID wasn't acquired
			if(g_eClientItems[client][i][iId]==-1)
				Format(STRING(m_szQuery), "DELETE FROM store_items WHERE `player_id`=%d AND `type`=\"%s\" AND `unique_id`=\"%s\"", g_eClients[client][iId], m_szType, m_szUniqueId);
			else
				Format(STRING(m_szQuery), "DELETE FROM store_items WHERE `id`=%d", g_eClientItems[client][i][iId]);
			SQL_TVoid(g_hDatabase, m_szQuery);
			g_eClientItems[client][i][bSynced] = false;
		}
	}
}

void UTIL_SaveClientEquipment(int client)
{
	char m_szQuery[512];
	int m_iId;
	for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
	{
		for(int a = 0; a < STORE_MAX_SLOTS; ++a)
		{
			m_iId = i*STORE_MAX_SLOTS+a;
			if(g_eClients[client][aEquipmentSynced][m_iId] == g_eClients[client][aEquipment][m_iId])
				continue;
			else if(g_eClients[client][aEquipmentSynced][m_iId] != -2)
			{
				if(g_eClients[client][aEquipment][m_iId]==-1)
					Format(STRING(m_szQuery), "DELETE FROM store_equipment WHERE `player_id`=%d AND `type`=\"%s\" AND `slot`=%d", g_eClients[client][iId], g_eTypeHandlers[i][szType], a);
				else
					Format(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d) ON DUPLICATE KEY UPDATE `unique_id` = VALUES(`unique_id`)", g_eClients[client][iId], g_eTypeHandlers[i][szType], g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], a);

				//Format(STRING(m_szQuery), "UPDATE store_equipment SET `unique_id`=\"%s\" WHERE `player_id`=%d AND `type`=\"%s\" AND `slot`=%d", g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], g_eClients[client][iId], g_eTypeHandlers[i][szType], a);
			}
			else
				Format(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d) ON DUPLICATE KEY UPDATE `unique_id` = VALUES(`unique_id`)", g_eClients[client][iId], g_eTypeHandlers[i][szType], g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], a);
			
			//Format(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d)", g_eClients[client][iId], g_eTypeHandlers[i][szType], g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], a);

			SQL_TVoid(g_hDatabase, m_szQuery);
			g_eClients[client][aEquipmentSynced][m_iId] = g_eClients[client][aEquipment][m_iId];
		}
	}
}

void UTIL_SaveClientData(int client)
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		LogError("Database connection is lost or not yet initialized.");
		return;
	}
	
	if((g_eClients[client][iCredits]==-1 && g_eClients[client][iItems]==-1) || !g_eClients[client][bLoaded])
		return;
	
	char m_szQuery[512], m_szName[64], m_szEName[128];
	GetClientName(client, m_szName, 64);
	SQL_EscapeString(g_hDatabase, m_szName, m_szEName, 128);
	Format(STRING(m_szQuery), "UPDATE store_players SET `credits`=`credits`+%d, `date_of_last_join`=%d, `name`='%s' WHERE `id`=%d", g_eClients[client][iCredits]-g_eClients[client][iOriginalCredits], g_eClients[client][iDateOfLastJoin], m_szEName, g_eClients[client][iId]);

	g_eClients[client][iOriginalCredits] = g_eClients[client][iCredits];

	SQL_TVoid(g_hDatabase, m_szQuery);
	
	char m_szAuthId[32];
	GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32, true);
	if(KvJumpToKey(g_hKeyValue, m_szAuthId))
	{
		int connect = KvGetNum(g_hKeyValue, "Connect", 0);
		
		while(KvGotoFirstSubKey(g_hKeyValue, true))
		{
			char m_szReason[128];
			KvGetSectionName(g_hKeyValue, m_szReason, 128);

			if(StrEqual(m_szReason, "Connect"))
			{
				KvDeleteThis(g_hKeyValue);
				KvGetSectionName(g_hKeyValue, m_szReason, 128);
			}
			
			int credits = KvGetNum(g_hKeyValue, "Credits", 0);
			int endtime = KvGetNum(g_hKeyValue, "LastTime", 0);
			int Counts = KvGetNum(g_hKeyValue, "Counts", 1);

			char m_szEreason[192];
			SQL_EscapeString(g_hDatabase, m_szReason, m_szEreason, 192);
			Format(STRING(m_szQuery), "INSERT INTO store_logs (player_id, credits, reason, date) VALUES(%d, %d, \"%d_%d_%s\", %d)", g_eClients[client][iId], credits, connect, Counts, m_szEreason, endtime);
			SQL_TVoid(g_hDatabase, m_szQuery);
			
			if(KvDeleteThis(g_hKeyValue))
			{
				char m_szAfter[32];
				KvGetSectionName(g_hKeyValue, m_szAfter, 32);
				if(StrContains(m_szAfter, "STEAM", false) != -1)
					break;
				else
					KvGoBack(g_hKeyValue);
			}
		}

		KvDeleteThis(g_hKeyValue);
		KvRewind(g_hKeyValue);
		KeyValuesToFile(g_hKeyValue, g_szLogFile);
	}
}

void UTIL_DisconnectClient(int client)
{
	ClearTimer(g_eClients[client][hTimer]);
	UTIL_LogMessage(client, g_eClients[client][iCredits], true, "离开服务器时");
	g_eClients[client][iCredits] = -1;
	g_eClients[client][iOriginalCredits] = -1;
	g_eClients[client][iItems] = -1;
	g_eClients[client][bLoaded] = false;
}

int UTIL_GetItemId(char[] type, char[] uid, int start = -1)
{
	for(int i = start+1; i < g_iItems; ++i)
		if(strcmp(g_eTypeHandlers[g_eItems[i][iHandler]][szType], type)==0 && strcmp(g_eItems[i][szUniqueId], uid)==0 && g_eItems[i][iPrice] >= 0)
			return i;
	return -1;
}

public void SQLCallback_BuyItem(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogError("Error happened. Error: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hndl))
		{
			int dbCredits = SQL_FetchInt(hndl, 0);
			int itemid = g_iSelectedItem[client];
			int plan = g_iSelectedPlan[client];

			int m_iPrice = 0;
			if(plan==-1)
				m_iPrice = g_eItems[itemid][iPrice];
			else
				m_iPrice = g_ePlans[itemid][plan][iPrice];	
			
			if(dbCredits != g_eClients[client][iOriginalCredits])
			{
				int diff = g_eClients[client][iOriginalCredits] - dbCredits;
				g_eClients[client][iOriginalCredits] = dbCredits;
				g_eClients[client][iCredits] -= diff;
			}
			
			if(g_eClients[client][iCredits]<m_iPrice || g_eItems[itemid][bCompose])
			{
				DisplayItemMenu(client, g_iSelectedItem[client]);
				return;
			}

			int m_iId = g_eClients[client][iItems]++;
			g_eClientItems[client][m_iId][iId] = -1;
			g_eClientItems[client][m_iId][iUniqueId] = itemid;
			g_eClientItems[client][m_iId][iDateOfPurchase] = GetTime();
			g_eClientItems[client][m_iId][iDateOfExpiration] = (plan==-1?0:(g_ePlans[itemid][plan][iTime]?GetTime()+g_ePlans[itemid][plan][iTime]:0));
			g_eClientItems[client][m_iId][iPriceOfPurchase] = m_iPrice;
			g_eClientItems[client][m_iId][bSynced] = false; //true
			g_eClientItems[client][m_iId][bDeleted] = false;

			g_eClients[client][iCredits] -= m_iPrice;

			UTIL_LogMessage(client, -m_iPrice, true, "购买了 %s %s", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
			LogToFileEx(g_szTempole, "%N 购买了 %s %s[%d]", client, g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], m_iPrice);

			Store_SaveClientAll(client);

			tPrintToChat(client, "%T", "Chat Bought Item", client, g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
			
			DisplayItemMenu(client, g_iSelectedItem[client]);
		}
	}
}

void UTIL_ComposeItem(int client)
{
	if(g_eCompose[client][item2] < 0 || g_eCompose[client][item1] < 0 || g_eCompose[client][types] < 0 || g_iSelectedItem[client] < 0)
		return;
	
	if(!Store_HasClientItem(client, g_eCompose[client][item2]) || !Store_HasClientItem(client, g_eCompose[client][item1]) || Store_HasClientItem(client, g_iSelectedItem[client]))
		return;
	
	int m_iFees;
	switch(g_eCompose[client][types])
	{
		case 0 : m_iFees =  5000;
		case 1 : m_iFees = 10000;
		case 2 : m_iFees = 15000;
		case 3 : m_iFees = 20000;
		case 4 : m_iFees = 25000;
		case 5 : m_iFees = 88888;
		default: m_iFees = 999999;
	}

	if(Store_GetClientCredits(client) < m_iFees || m_iFees < 0)
	{
		tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, m_iFees);
		return;
	}

	Store_RemoveItem(client, g_eCompose[client][item2]);
	Store_RemoveItem(client, g_eCompose[client][item1]);
	
	Store_SetClientCredits(client, Store_GetClientCredits(client)-m_iFees, "合成手续费");
	
	int probability = 0;
	switch(g_eCompose[client][types])
	{
		case 0 : probability = 600000;
		case 1 : probability = 650000;
		case 2 : probability = 700000;
		case 3 : probability = 750000;
		case 4 : probability = 800000;
		case 5 : probability = 999999;
		default: probability = 0;
	}

	if(UTIL_GetRandomInt(0, 1000000) > probability)
	{
		tPrintToChat(client, "Compose Failed", client);
		return;
	}

	Store_GiveItem(client, g_iSelectedItem[client], GetTime(), 0, 99999);
	
	Store_SaveClientAll(client);
	
	g_iDataProtect[client] = GetTime()+120;

	tPrintToChat(client, "Compose successfully", client, g_eItems[g_iSelectedItem[client]][szName]);
	
	tPrintToChatAll("\x0C%N\x04成功合成了皮肤\x10%s", client, g_eItems[g_iSelectedItem[client]][szName]);
	
	CG_ShowHiddenMotd(client, "https://csgogamers.com/music/voices.php?volume=100");       
}

void UTIL_BuyItem(int client)
{
#if defined Module_Skin
	Timer_KillPreview(INVALID_HANDLE, client);
#endif

	if(g_eItems[g_iSelectedItem[client]][iHandler] == g_iPackageHandler)
		return;

	if(Store_HasClientItem(client, g_iSelectedItem[client]))
	{
		DisplayItemMenu(client, g_iSelectedItem[client]);
		return;
	}

	if(g_iDataProtect[client] > GetTime())
	{
		tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
		DisplayItemMenu(client, g_iSelectedItem[client]);
		return;
	}
	g_iDataProtect[client] = GetTime()+30;
	char m_szQuery[255];
	Format(STRING(m_szQuery), "SELECT credits FROM store_players WHERE `id`=%d", g_eClients[client][iId]);
	SQL_TQuery(g_hDatabase, SQLCallback_BuyItem, m_szQuery, g_eClients[client][iUserId]);
}

void UTIL_SellItem(int client, int itemid)
{
	if(g_iDataProtect[client] > GetTime())
	{
		tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
		DisplayItemMenu(client, itemid);
		return;
	}

	g_iDataProtect[client] = GetTime()+30;
	int m_iCredits = RoundToFloor(UTIL_GetClientItemPrice(client, itemid)*0.6);
	int uid = UTIL_GetClientItemId(client, itemid);
	if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
	{
		int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
		int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
		if(m_iLeft<0)
			m_iLeft = 0;
		m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
	}
	g_eClients[client][iCredits] += m_iCredits;
	tPrintToChat(client, "%T", "Chat Sold Item", client, g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);

	UTIL_LogMessage(client, m_iCredits, false, "卖掉了 %s %s", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
	LogToFileEx(g_szTempole, "%N 卖掉了 %s %s", client, g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);

	Store_RemoveItem(client, itemid);

	Store_SaveClientAll(client);
	
	Store_DisplayPreviousMenu(client);
}

void UTIL_GiftItem(int client, int receiver, int item)
{
	int m_iId = g_eClientItems[client][item][iUniqueId];

	if((g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1) || !g_eClients[client][bLoaded]
		|| (g_eClients[receiver][iCredits] == -1 && g_eClients[receiver][iItems] == -1) || !g_eClients[receiver][bLoaded]) {
		return;
	}

	if(g_iDataProtect[client] > GetTime())
	{
		tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
		DisplayItemMenu(client, m_iId);
		return;
	}

	g_iDataProtect[client] = GetTime()+30;
	g_iDataProtect[receiver] = GetTime()+30;

	int m_iFees = UTIL_GetClientHandleFees(client, m_iId);
	
	if(m_iFees < 0)
	{
		tPrintToChat(client, " \x02UNKNOWN ERROR\x01 :  \x07%d", UTIL_GetRandomInt(100000, 999999));
		return;
	}

	if(m_iFees > g_eClients[client][iCredits])
	{
		tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, m_iFees);
		return;
	}
	Store_SetClientCredits(client, Store_GetClientCredits(client)-m_iFees, "赠送物品_手续费");

	g_eClientItems[client][item][bDeleted] = true;
	UTIL_UnequipItem(client, m_iId);

	g_eClientItems[receiver][g_eClients[receiver][iItems]][iId] = -1;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iUniqueId] = m_iId;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][bSynced] = false;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][bDeleted] = false;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iDateOfPurchase] = g_eClientItems[client][item][iDateOfPurchase];
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iDateOfExpiration] = g_eClientItems[client][item][iDateOfExpiration];
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iPriceOfPurchase] = g_eClientItems[client][item][iPriceOfPurchase];

	++g_eClients[receiver][iItems];

	tPrintToChat(client, "%T", "Chat Gift Item Sent", client, receiver, g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);
	tPrintToChat(receiver, "%T", "Chat Gift Item Received", receiver, client, g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);

	UTIL_LogMessage(client, 0, true, "赠送了 %s 给 %N[%s]", g_eItems[m_iId][szName], receiver, g_eClients[receiver][szAuthId]);
	UTIL_LogMessage(receiver, 0, true, "收到了 %s 来自 %N[%s]", g_eItems[m_iId][szName], client, g_eClients[client][szAuthId]);
	
	Store_SaveClientAll(client);
	Store_SaveClientAll(receiver);
}

int UTIL_GetClientItemId(int client, int itemid)
{
	for(int i = 0; i < g_eClients[client][iItems]; ++i)
	{
		if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
			return i;
	}

	return -1;
}

void UTIL_ReloadConfig()
{
	g_iItems = 0;
	
	for(int i = 0; i < g_iTypeHandlers; ++i)
	{
		if(g_eTypeHandlers[i][fnReset] != INVALID_FUNCTION)
		{
			Call_StartFunction(g_eTypeHandlers[i][hPlugin], g_eTypeHandlers[i][fnReset]);
			Call_Finish();
		}
	}

	char m_szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, STRING(m_szFile), "configs/store/items.txt");
	Handle m_hKV = CreateKeyValues("Store");
	FileToKeyValues(m_hKV, m_szFile);
	if(!KvGotoFirstSubKey(m_hKV))
	{
		SetFailState("Failed to read configs/store/items.txt");
	}
	UTIL_WalkConfig(m_hKV);
	CloseHandle(m_hKV);

	OnMapStart();
}

void UTIL_WalkConfig(Handle &kv, int parent = -1)
{
	char m_szType[32];
	char m_szFlags[64];
	char m_szDesc[128];
	char m_szAuth[256];
	int m_iHandler;
	bool m_bSuccess;

	do
	{
		if(g_iItems == STORE_MAX_ITEMS)
			continue;
		if(KvGetNum(kv, "enabled", 1) && KvGetNum(kv, "type", -1) == -1 && KvGotoFirstSubKey(kv))
		{
			KvGoBack(kv);
			KvGetSectionName(kv, g_eItems[g_iItems][szName], 64);
			KvGetSectionName(kv, g_eItems[g_iItems][szUniqueId], 64);
			ReplaceString(g_eItems[g_iItems][szName], 64, "\\n", "\n");
			KvGetString(kv, "shortcut", g_eItems[g_iItems][szShortcut], 64);
			KvGetString(kv, "flag", STRING(m_szFlags));
			g_eItems[g_iItems][iFlagBits] = ReadFlagString(m_szFlags);
			g_eItems[g_iItems][iPrice] = KvGetNum(kv, "price", -1);
			g_eItems[g_iItems][bBuyable] = (KvGetNum(kv, "buyable", 1)?true:false);
			g_eItems[g_iItems][bGiftable] = (KvGetNum(kv, "giftable", 1)?true:false);
			g_eItems[g_iItems][bCompose] = (KvGetNum(kv, "compose", 0)?true:false);
			g_eItems[g_iItems][bVIP] = (KvGetNum(kv, "vip", 0)?true:false);
			g_eItems[g_iItems][iHandler] = g_iPackageHandler;
			
			KvGotoFirstSubKey(kv);
			
			g_eItems[g_iItems][iParent] = parent;
			
			UTIL_WalkConfig(kv, g_iItems++);
			KvGoBack(kv);
		}
		else
		{
			if(!KvGetNum(kv, "enabled", 1))
				continue;
			
			KvGetString(kv, "type", STRING(m_szType));
			m_iHandler = UTIL_GetTypeHandler(m_szType);
			if(m_iHandler == -1)
				continue;
			
			m_bSuccess = true;
			if(g_eTypeHandlers[m_iHandler][fnConfig]!=INVALID_FUNCTION)
			{
				Call_StartFunction(g_eTypeHandlers[m_iHandler][hPlugin], g_eTypeHandlers[m_iHandler][fnConfig]);
				Call_PushCellRef(kv);
				Call_PushCell(g_iItems);
				Call_Finish(m_bSuccess); 
			}
			
			if(!m_bSuccess)
				continue;

			g_eItems[g_iItems][iParent] = parent;
			KvGetSectionName(kv, g_eItems[g_iItems][szName], ITEM_NAME_LENGTH);
			g_eItems[g_iItems][iPrice] = KvGetNum(kv, "price");
			g_eItems[g_iItems][iLevels] = KvGetNum(kv, "lvls", 0)+1;
			g_eItems[g_iItems][bBuyable] = KvGetNum(kv, "buyable", 1)?true:false;
			g_eItems[g_iItems][bGiftable] = KvGetNum(kv, "giftable", 1)?true:false;
			g_eItems[g_iItems][bCompose] = (KvGetNum(kv, "compose", 0)?true:false);
			g_eItems[g_iItems][bVIP] = (KvGetNum(kv, "vip", 0)?true:false);
			g_eItems[g_iItems][bCase] = (KvGetNum(kv, "case", 0)?true:false);
			g_eItems[g_iItems][bIgnore] = (KvGetNum(kv, "only", 0)?true:false);

			if(StrEqual(m_szType, "playerskin"))
			{
#if defined Global_Skin
				Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[通用] %s", g_eItems[g_iItems][szName]);
#else
				int team = KvGetNum(kv, "team", 0);

				if(team == 2)
					Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[TE] %s", g_eItems[g_iItems][szName]);
				if(team == 3)
					Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[CT] %s", g_eItems[g_iItems][szName]);
#endif

				if(!g_eItems[g_iItems][bIgnore])
				{
					char model[128];
					KvGetString(kv, "model", STRING(model));
					PushArrayString(g_ArraySkin, model);
					//LogMessage("Push ->  [%s] %s", g_eItems[g_iItems][szName], model);
				}
			}

			KvGetString(kv, "desc", STRING(m_szDesc));
			KvGetString(kv, "auth", STRING(m_szAuth));
			KvGetString(kv, "flag", STRING(m_szFlags));
			g_eItems[g_iItems][iFlagBits] = ReadFlagString(m_szFlags);
			g_eItems[g_iItems][iHandler] = m_iHandler;
			
			if(m_szDesc[0] != 0)
				strcopy(g_eItems[g_iItems][szDesc], 128, m_szDesc);
			
			if(m_szAuth[0] != 0)
				strcopy(g_eItems[g_iItems][szSteam], 256, m_szAuth);

			if(KvGetNum(kv, "unique_id", -1)==-1)
				KvGetString(kv, g_eTypeHandlers[m_iHandler][szUniqueKey], g_eItems[g_iItems][szUniqueId], PLATFORM_MAX_PATH);
			else
				KvGetString(kv, "unique_id", g_eItems[g_iItems][szUniqueId], PLATFORM_MAX_PATH);

			if(KvJumpToKey(kv, "Plans"))
			{
				KvGotoFirstSubKey(kv);
				int index=0;
				do
				{
					KvGetSectionName(kv, g_ePlans[g_iItems][index][szName], ITEM_NAME_LENGTH);
					g_ePlans[g_iItems][index][iPrice] = KvGetNum(kv, "price");
					g_ePlans[g_iItems][index][iTime] = KvGetNum(kv, "time");
					++index;
				} while (KvGotoNextKey(kv));

				g_eItems[g_iItems][iPlans]=index;

				KvGoBack(kv);
				KvGoBack(kv);
			}
			
			++g_iItems;
		}
	} while (KvGotoNextKey(kv));
}

int UTIL_GetTypeHandler(char[] type)
{
	for(int i = 0; i < g_iTypeHandlers; ++i)
	{
		if(strcmp(g_eTypeHandlers[i][szType], type)==0)
			return i;
	}
	return -1;
}

int UTIL_GetMenuHandler(char[] id)
{
	for(int i = 0; i < g_iMenuHandlers; ++i)
	{
		if(strcmp(g_eMenuHandlers[i][szIdentifier], id)==0)
			return i;
	}
	return -1;
}

bool UTIL_IsEquipped(int client, int itemid)
{
	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
		if(g_eClients[client][aEquipment][g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+i] == itemid)
			return true;
	return false;
}

int UTIL_GetExpiration(int client, int itemid)
{
	int uid = UTIL_GetClientItemId(client, itemid);
	if(uid<0)
		return 0;
	return g_eClientItems[client][uid][iDateOfExpiration];
}

int UTIL_UseItem(int client, int itemid, bool synced = false, int slot = 0)
{
	int m_iSlot = slot;
	if(g_eTypeHandlers[g_eItems[itemid][iHandler]][fnUse] != INVALID_FUNCTION)
	{
		int m_iReturn = -1;
		Call_StartFunction(g_eTypeHandlers[g_eItems[itemid][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[itemid][iHandler]][fnUse]);
		Call_PushCell(client);
		Call_PushCell(itemid);
		Call_Finish(m_iReturn);
		
		if(m_iReturn != -1)
			m_iSlot = m_iReturn;
	}

	if(g_eTypeHandlers[g_eItems[itemid][iHandler]][bEquipable])
	{
		g_eClients[client][aEquipment][g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+m_iSlot]=itemid;
		if(synced)
			g_eClients[client][aEquipmentSynced][g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+m_iSlot]=itemid;
	}
	else if(m_iSlot == 0)
	{
		Store_RemoveItem(client, itemid);
		return 1;
	}
	return 0;
}

int UTIL_UnequipItem(int client, int itemid, bool fn = true)
{
	int m_iSlot = 0;
	if(fn && itemid > 0 && g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove] != INVALID_FUNCTION)
	{
		Call_StartFunction(g_eTypeHandlers[g_eItems[itemid][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove]);
		Call_PushCell(client);
		Call_PushCell(itemid);
		Call_Finish(m_iSlot);
	}

	int m_iId;
	if(g_eItems[itemid][iHandler] != g_iPackageHandler)
	{
		m_iId = g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+m_iSlot;
		if(g_eClients[client][aEquipmentSynced][m_iId]==-2)
			g_eClients[client][aEquipment][m_iId]=-2;
		else
			g_eClients[client][aEquipment][m_iId]=-1;
	}
	else
	{
		for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
		{
			for(int a = 0; i < STORE_MAX_SLOTS; ++i)
			{
				if(g_eClients[client][aEquipment][i+a] < 0)
					continue;
				m_iId = i*STORE_MAX_SLOTS+a;
				if(Store_IsItemInBoughtPackage(client, g_eClients[client][aEquipment][m_iId], itemid))
					if(g_eClients[client][aEquipmentSynced][m_iId]==-2)
						g_eClients[client][aEquipment][m_iId]=-2;
					else
						g_eClients[client][aEquipment][m_iId]=-1;
			}
		}
	}
}

int UTIL_GetEquippedItemFromHandler(int client, int handler, int slot = 0)
{
	return g_eClients[client][aEquipment][handler*STORE_MAX_SLOTS+slot];
}

bool UTIL_PackageHasClientItem(int client, int packageid, bool invmode = false)
{
	int m_iFlags = GetUserFlagBits(client);
	for(int i =0;i<g_iItems;++i)
		if(g_eItems[i][iParent] == packageid && GetClientPrivilege(client, g_eItems[i][iFlagBits], m_iFlags) && (invmode && Store_HasClientItem(client, i) || !invmode) && AllowItemForAuth(client, g_eItems[i][szSteam]) && AllowItemForVIP(client, g_eItems[i][bVIP]))
			if((g_eItems[i][iHandler] == g_iPackageHandler && UTIL_PackageHasClientItem(client, i, invmode)) || g_eItems[i][iHandler] != g_iPackageHandler)
				return true;
	return false;
}

void UTIL_LogMessage(int client, int credits, bool immediately = false, const char[] message, any ...)
{
	if(IsFakeClient(client))
		return;

	char m_szReason[256];
	VFormat(STRING(m_szReason), message, 5);

	if(!immediately)
	{
		StripQuotes(m_szReason);
		
		char m_szAuthId[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32, true);

		KvJumpToKey(g_hKeyValue, m_szAuthId, true);
		KvJumpToKey(g_hKeyValue, m_szReason, true);

		KvSetNum(g_hKeyValue, "Credits", KvGetNum(g_hKeyValue, "Credits", 0)+credits);
		KvSetNum(g_hKeyValue, "LastTime", GetTime());
		KvSetNum(g_hKeyValue, "Counts", KvGetNum(g_hKeyValue, "Counts", 0)+1);

		KvRewind(g_hKeyValue);

		KeyValuesToFile(g_hKeyValue, g_szLogFile);
	}
	else
	{
		char m_szQuery[512], EszReason[513];
		SQL_EscapeString(g_hDatabase, m_szReason, EszReason, 513);
		Format(STRING(m_szQuery), "INSERT INTO store_logs (player_id, credits, reason, date) VALUES(%d, %d, \"%s\", %d)", g_eClients[client][iId], credits, EszReason, GetTime());
		SQL_TVoid(g_hDatabase, m_szQuery);
	}
}

int UTIL_GetLowestPrice(int itemid)
{
	if(g_eItems[itemid][iPlans]==0)
		return g_eItems[itemid][iPrice];

	int m_iLowest=g_ePlans[itemid][0][iPrice];
	for(int i = 1; i < g_eItems[itemid][iPlans]; ++i)
	{
		if(m_iLowest>g_ePlans[itemid][i][iPrice])
			m_iLowest = g_ePlans[itemid][i][iPrice];
	}

	return m_iLowest;
}

int UTIL_GetHighestPrice(int itemid)
{
	if(g_eItems[itemid][iPlans]==0)
		return g_eItems[itemid][iPrice];

	int m_iHighest=g_ePlans[itemid][0][iPrice];
	for(int i = 1; i < g_eItems[itemid][iPlans]; ++i)
	{
		if(m_iHighest<g_ePlans[itemid][i][iPrice])
			m_iHighest = g_ePlans[itemid][i][iPrice];
	}

	return m_iHighest;
}

int UTIL_GetClientItemPrice(int client, int itemid)
{
	int uid = UTIL_GetClientItemId(client, itemid);
	if(uid<0)
		return 0;
		
	if(g_eClientItems[client][uid][iPriceOfPurchase] == 0)
		return g_eItems[itemid][iPrice];

	return g_eClientItems[client][uid][iPriceOfPurchase];
}

int UTIL_GetClientHandleFees(int client, int itemid)
{
	int uid = UTIL_GetClientItemId(client, itemid);
	if(uid<0)
		return 9999999;

	if(g_eClientItems[client][uid][iDateOfExpiration] == 0)
	{
		if(!g_eItems[itemid][bBuyable])
		{
			if(g_eItems[itemid][bCompose])
				return 50000;
			else
				return 20000;
		}
		else
		{
			if(g_eClientItems[client][uid][iPriceOfPurchase] < 1000)
				return RoundToFloor(UTIL_GetHighestPrice(itemid)*0.15);
			else
				return RoundToFloor(g_eClientItems[client][uid][iPriceOfPurchase]*0.15);
		}
	}

	if(g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase] <= 2678400)
		return 100;

	if(g_eClientItems[client][uid][iPriceOfPurchase] < 1000)
		return RoundToFloor(UTIL_GetHighestPrice(itemid)*0.2);
	else
		return RoundToFloor(g_eClientItems[client][uid][iPriceOfPurchase]*0.2);
}

void UTIL_CheckModules()
{
#if defined Module_Chat
	CPSupport_OnPluginStart();
#endif

#if defined Module_Grenade
	Grenades_OnPluginStart();
#endif

#if defined Module_Spray
	Sprays_OnPluginStart();
#endif

#if defined Module_Model
	Models_OnPluginStart();
#endif

#if defined Module_Sound
	Sounds_OnPluginStart();
#endif

#if defined Module_TPMode
	TPMode_OnPluginStart();
#endif

#if defined Module_Player
	Players_OnPluginStart();
#endif

#if defined Module_VIP
	VIP_OnPluginStart();
#endif
}

void UTIL_BuildTempLogFile()
{
	BuildPath(Path_SM, g_szLogFile, 128, "data/store.log.kv.txt");
	BuildPath(Path_SM, g_szTempole, 128, "data/store.buy.sell.txt");

	if(g_hKeyValue != INVALID_HANDLE)
		CloseHandle(g_hKeyValue);
	
	g_hKeyValue = CreateKeyValues("store_logs", "", "");

	KeyValuesToFile(g_hKeyValue, g_szLogFile);
}

public void CG_OnClientDeath(int client, int attacker, int assister, bool headshot, const char[] weapon)
{
#if defined Module_TPMode
	CheckClientTP(client);
#endif

#if defined Module_Skin
	if(IsValidClient(attacker))
	{
		Handle pack;
		CreateDataTimer(0.5, Timer_DeathModel, pack, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(pack, client);
		WritePackCell(pack, CG_ClientGetPId(client));
		WritePackCell(pack, CG_ClientGetPId(attacker));
		WritePackCell(pack, headshot);
		WritePackString(pack, weapon);
		ResetPack(pack);
	}
#endif

#if defined Module_Spray
	Spray_OnClientDeath(attacker);
#endif

#if defined Module_Sound
	Sound_OnClientDeath(client, attacker);
#endif
}

public void CG_OnRoundStart()
{
	for(int client = 1; client <= MAXPLAYERS; ++client)
	{
#if defined Module_Spray
		Spray_OnClientDeath(client);
#endif

#if defined Module_Sound
		Sound_OnClientDeath(client, client);
#endif
	}
}

stock bool UTIL_IsPlayerTP(int client)
{
#if defined Module_TPMode
	if(g_bThirdperson[client])
		return true;

	if(g_bMirror[client])
		return true;
#endif
	return false;
}

#define SIZE_OF_INT 2147483647
int UTIL_GetRandomInt(int min, int max)
{
	int random = GetURandomInt();
	
	if(random == 0)
		random++;

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

public void BroadCastToAll(const char[] msg)
{
	if(GetFeatureStatus(FeatureType_Native, "CG_Broadcast") != FeatureStatus_Available)
		return;
#if defined Module_Skin
	CG_Broadcast(true, msg);
#endif
}

public Action Timer_OnlineCredit(Handle timer, int client)
{
	if(!IsClientInGame(client))
	{
		g_eClients[client][hTimer] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if(!CG_ClientInGroup(client))
	{
		tPrintToChat(client, "\x07你尚未加入官方Steam组,不能通过游戏在线获得信用点");
		tPrintToChat(client, "\x04按Y输入\x07!group\x04即可加入官方组");
		g_eClients[client][hTimer] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int m_iCredits = 0;
	char szFrom[128], szReason[128];
	strcopy(szFrom, 128, "\x10[");
	strcopy(szReason, 128, "store_credits[");

	int m_iVitality = CG_ClientGetVitality(client);
	if(m_iVitality)
	{
		StrCat(szReason, 128, " 热度");	
		if(200 > m_iVitality >= 100)
		{
			m_iCredits += 2;
			StrCat(szFrom, 128, "\x07热度+2");
		}
		else if(400 > m_iVitality >= 200)
		{
			m_iCredits += 3;
			StrCat(szFrom, 128, "\x07热度+3");
		}
		else if(700 > m_iVitality >= 400)
		{
			m_iCredits += 4;
			StrCat(szFrom, 128, "\x07热度+4");
		}
		else if(m_iVitality >= 700)
		{
			m_iCredits += 5;
			StrCat(szFrom, 128, "\x07热度+5");
		}
		else if(m_iVitality >= 999)
		{
			m_iCredits += 6;
			StrCat(szFrom, 128, "\x07热度+6");
		}
		else
		{
			m_iCredits += 1;
			StrCat(szFrom, 128, "\x07热度+1");
		}
	}

	int authid = CG_ClientGetGId(client);
	if(authid)
	{
		int m_iPlus = 0;
		if(authid < 401)
		{
			m_iPlus += 2;
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
			m_iPlus += 2;
		}
		else if(authid >= 9101)
		{
			m_iPlus += 3;
		}

		m_iCredits += m_iPlus;
		char auname[32];
		CG_ClientGetGroupName(client, auname, 32);
		StrCat(szReason, 128, auname);
		if(authid == 9999)
			Format(auname, 32, "\x0A|\x0E%s+%d", auname, m_iPlus);
		else
			Format(auname, 32, "\x0A|\x0C%s+%d", auname, m_iPlus);
		StrCat(szFrom, 128, auname);
	}
	else tPrintToChat(client, "\x07输入!auth申请\x04玩家认证\x07享受更多加成");

	if(CG_ClientIsVIP(client))
	{
		m_iCredits += 2;
		StrCat(szFrom, 128, "\x0A|\x0EVIP+2");
		StrCat(szReason, 128, " VIP ");
	}
	else tPrintToChat(client, "\x07登录论坛开通\x04VIP\x07享受更多加成");

	if(CG_ClientIsRealName(client))
	{
		m_iCredits += 2;
		StrCat(szFrom, 128, "\x0A|\x0E实名认证+2");
		StrCat(szReason, 128, " 实名认证 ");
	}
	else tPrintToChat(client, "\x07登录论坛完成\x04实名认证\x07享受更多加成");

	StrCat(szFrom, 128, "\x10]");
	StrCat(szReason, 128, "]");

	if(!m_iCredits)
		return Plugin_Continue;

	Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

	tPrintToChat(client, "\x10你获得了\x04 %d 信用点", m_iCredits);
	PrintToChat(client, " \x0A积分来自%s", szFrom);

	return Plugin_Continue;
}

public void CG_OnDailySigned(int client)
{
	if(!CG_ClientInGroup(client))
	{
		tPrintToChat(client, "检测到你当前未加入\x0C官方组\x01,你无法获得签到奖励");
		return;	
	}

	int m_iCredits = UTIL_GetRandomInt(1, 500);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, "每日签到");
	tPrintToChatAll("\x0E%N\x01签到获得\x04%d信用点\x01.", client, m_iCredits);
}