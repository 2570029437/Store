#define Module_Player

void Players_OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

#if defined Module_Skin
    Skin_OnPluginStart();
#endif

#if defined Module_Hats
    Store_RegisterHandler("hat", "model", Hats_OnMapStart, Hats_Reset, Hats_Config, Hats_Equip, Hats_Remove, true);
#endif

#if defined Module_Neon
    //  neon id -> color
    //  modify in dev1.92
    Store_RegisterHandler("neon", "color", Neon_OnMapStart, Neon_Reset, Neon_Config, Neon_Equip, Neon_Remove, true); 
#endif

#if defined Module_Aura
    Store_RegisterHandler("Aura", "aura", Aura_OnMapStart, Aura_Reset, Aura_Config, Aura_Equip, Aura_Remove, true);
#endif

#if defined Module_Part
    Store_RegisterHandler("Particles", "particle", Part_OnMapStart, Part_Reset, Part_Config, Part_Equip, Part_Remove, true);
#endif

#if defined Module_Trail
    Store_RegisterHandler("trail", "material", Trails_OnMapStart, Trails_Reset, Trails_Config, Trails_Equip, Trails_Remove, true);
#endif
}

void Players_OnClientDisconnect(int client)
{
#if defined Module_Aura
    Aura_OnClientDisconnect(client);
#endif

#if defined Module_Neon
    Neon_OnClientDisconnect(client);
#endif

#if defined Module_Part
    Part_OnClientDisconnect(client);
#endif

#if defined Module_Skin
    Skin_OnClientDisconnect(client);
#endif

#if defined Module_Trail
    Trails_OnClientDisconnect(client);
#endif
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(IsFakeClient(client))
        return Plugin_Continue;

    RequestFrame(OnClientSpawnPost, client);

#if defined Module_Skin
    g_iSkinLevel[client] = 0;
    g_szDeathVoice[client][0] = '\0';
    Store_PreSetClientModel(client);
    CreateTimer(0.1, Timer_ClearCamera, client);
    CreateTimer(1.0, Timer_ClearCamera, client);
    CreateTimer(0.1, Timer_KillPreview, client);
#endif

    return Plugin_Continue;
}

public void OnClientSpawnPost(int client)
{
    if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

#if defined Module_Trail
    Store_SetClientTrail(client);
#endif

#if defined Module_Aura
    Store_SetClientAura(client);
#endif

#if defined Module_Neon
    Store_SetClientNeon(client);
#endif

#if defined Module_Part
    Store_SetClientPart(client);
#endif

#if defined Module_Hats    
    Store_SetClientHat(client);
#endif
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(IsFakeClient(client))
        return Plugin_Continue;

#if defined Module_Skin
    AttemptState(client, false);
    RequestFrame(FirstPersonDeathCamera, client);
#endif

#if defined Module_Aura
    Store_RemoveClientAura(client);
#endif

#if defined Module_Neon
    Store_RemoveClientNeon(client);
#endif

#if defined Module_Part
    Store_RemoveClientPart(client);
#endif

    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
#if defined Module_Hats
        Store_RemoveClientHats(client, i);
#endif

#if defined Module_Trail
        Store_RemoveClientTrail(client, i);
#endif
    }

    return Plugin_Continue;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
    g_iClientTeam[client] = 2;

#if defined Module_Hats
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
        Store_RemoveClientHats(client, i);
#endif

#if defined Module_Skin
    strcopy(g_szSkinModel[client], 256, "zombie");
#endif
}

public void CG_OnClientTeam(int client, int oldteam, int newteam)
{
    g_iClientTeam[client] = newteam;
    
    if(oldteam > 1 && newteam <= 1)
    {
#if defined Module_Aura
        Store_RemoveClientAura(client);
#endif
        
#if defined Module_Neon
        Store_RemoveClientNeon(client);
#endif

#if defined Module_Part
        Store_RemoveClientPart(client);
#endif

#if defined Module_Trail
        for(int i = 0; i < STORE_MAX_SLOTS; ++i)
            Store_RemoveClientTrail(client, i);
#endif

#if defined Module_Hats
        for(int i = 0; i < STORE_MAX_SLOTS; ++i)
            Store_RemoveClientHats(client, i);
#endif
    }
    
#if defined TeamArms
    RequestFrame(OnClientTeamPost, client);
#endif

#if defined Module_Skin
    if(!IsClientInGame(client) || IsFakeClient(client))
        return;

    if(oldteam != newteam && newteam == 1)
        AttemptState(client, true);
#endif
}

#if defined Module_Skin
public void OnClientSettingsChanged(int client)
{
    if(!g_bSpecJoinPending[client])
        return;

    if(!IsClientInGame(client) || g_iClientTeam[client] == 1)
    {
        g_bSpecJoinPending[client] = false;
        return;
    }

    char client_specmode[10];
    GetClientInfo(client, "cl_spec_mode", client_specmode, 9);

    if(StringToInt(client_specmode) > 4)
    {
        g_bSpecJoinPending[client] = false;
        ChangeClientTeam(client, 1);
    }
}
#endif

public void OnClientTeamPost(int client)
{
    if(!IsClientInGame(client) || !IsPlayerAlive(client) || g_iClientTeam[client] > 1)
        return;

    Store_PreSetClientModel(client);
    CreateTimer(0.2, Timer_FixPlayerArms, GetClientUserId(client));
}