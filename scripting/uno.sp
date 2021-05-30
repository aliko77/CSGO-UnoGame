#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "alispw77"
#define PLUGIN_VERSION "1.00"
#define mtag "[UNO]"
#define ptag "{darkred}[UNO]{green}"

#include <basecomm>
#include <multicolors>
#include <sdktools>
#include <sourcemod>

#pragma newdecls required

ArrayList Rooms_Array,
  Rooms_Env,
  ClientsEnv,
  Rooms_Spec;

bool bClientInRoom[MAXPLAYERS + 1],
  bClientWritingPass[MAXPLAYERS + 1],
  bClientTakeCard[MAXPLAYERS + 1],
  bClientPlayed[MAXPLAYERS + 1],
  bClientSpecRoom[MAXPLAYERS + 1],
  bDatabase;

int iClientRoomId[MAXPLAYERS + 1],
  m_flSimulationTime = -1,
  m_flProgressBarStartTime = -1,
  m_iProgressBarDuration = -1,
  m_iBlockingUseActionInProgress = -1,
  iClientTotalWinGame[MAXPLAYERS + 1],
  iClientTotalScore[MAXPLAYERS + 1],
  iClientTotalMatch[MAXPLAYERS + 1];

char sRenkler[4][11] = {"K", "S", "Y", "M"};

enum struct eUno_Menu
{
    Menu Uno_Menu;
}
Handle hPlayedTimer[MAXPLAYERS + 1];
eUno_Menu gUno_Menu[MAXPLAYERS + 1];
Database g_hDatabase = null;

#include "scripting/UNO/commands.sp"
#include "scripting/UNO/database.sp"
#include "scripting/UNO/events.sp"
#include "scripting/UNO/functions.sp"
#include "scripting/UNO/menus.sp"
#include "scripting/UNO/settings.sp"

public Plugin myinfo =
{
    name = "UNO",
    author = PLUGIN_AUTHOR,
    description = "Uno Csgo version",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/id/alikoc77"
}

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("Uno.phrases");
    RegConsoleCmd("sm_uno", Command_Uno, "UNO Komutu");
    RegConsoleCmd("sm_ayril", Command_Ayril, "Uno odadan ayrılma komutu");
    RegConsoleCmd("sm_leave", Command_Ayril, "Uno odadan ayrılma komutu");
    Hooks();
    SetSettings();
    ConnectDB();
}
public void OnMapStart()
{
    OnCleanDB();
}
public void OnClientPutInServer(int client)
{
    if(!ClientStatus(client))
        return;
    SQL_LoadClientData(client);
}
public void OnPluginEnd()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!ClientStatus(i))
            continue;
        OnClientDisconnect(i);
    }
}
public void OnClientDisconnect(int client)
{
    SQL_UpdateClient(client);
    if(bClientInRoom[client] || iClientRoomId[client] != 0)
    {
        bClientInRoom[client] = false;
        iClientRoomId[client] = 0;
        bClientTakeCard[client] = false;
        bClientPlayed[client] = false;
        hPlayedTimer[client] = null;
        bClientSpecRoom[client] = false;
        OdadakilereDuyuru(iClientRoomId[client], "%N %t", client, "ClientLeaveRoom");
        for(int i = 0; i < GetArraySize(ClientsEnv); i++)
        {
            int iUserId;
            Handle trie = GetArrayCell(ClientsEnv, i);
            GetTrieValue(trie, "UserId", iUserId);
            if(iUserId != GetClientUserId(client))
                continue;
            RemoveFromArray(ClientsEnv, i);
        }
        ClearClientVariable(GetClientUserId(client), iClientRoomId[client]);
    }
}