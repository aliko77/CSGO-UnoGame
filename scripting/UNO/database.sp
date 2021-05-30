#define SQL_CREATE_CLIENT_TABLE \
    "CREATE TABLE IF NOT EXISTS `uno_players` \
(\
	`steam` varchar(22) NOT NULL PRIMARY KEY, \
	`name` varchar(32) CHARACTER SET utf8 COLLATE utf8_turkish_ci NOT NULL, \
	`total_match` int NOT NULL DEFAULT 0, \
	`total_score` int NOT NULL DEFAULT 0, \
	`total_won_game` int NOT NULL DEFAULT 0, \
	`lastconnect` int NOT NULL DEFAULT 0\
);"
#define SQL_CREATE_MATCHES_TABLE \
    "CREATE TABLE IF NOT EXISTS `uno_matches` \
(\
	`id` int PRIMARY KEY AUTO_INCREMENT, \
	`room_no` int NOT NULL DEFAULT 0, \
    `room_owner` varchar(32) NOT NULL, \
    `room_owner_name` varchar(32) CHARACTER SET utf8 COLLATE utf8_turkish_ci NOT NULL, \
    `room_player_count` int NOT NULL DEFAULT 0, \
    `room_winner` varchar(32) NOT NULL, \
    `room_winner_name` varchar(32) CHARACTER SET utf8 COLLATE utf8_turkish_ci NOT NULL, \
    `room_winner_score` int NOT NULL DEFAULT 0, \
    `match_date` int NOT NULL DEFAULT 0 \
);"
#define SQL_INSERT_MATCH_DEFINE \
    "INSERT INTO `uno_matches` \
    (`room_no`, `room_owner`, `room_owner_name`, `room_player_count`, `room_winner`, `room_winner_name`, `room_winner_score`, `match_date`) \
    VALUES ('%i', '%s', '%s', '%i', '%s', '%s', '%i', '%i') \
;"
#define SQL_INSERT_PLAYER_DEFINE \
    "INSERT INTO `uno_players` \
    (`steam`, `name`, `total_match`, `total_score`, `total_won_game`, `lastconnect`) \
    VALUES ('%s', \"%s\", '0', '0', '0', '%i') \
;" //1
#define SQL_SELECT_PLAYER_DEFINE \
    "SELECT * FROM `uno_players` WHERE `steam` = '%s'\
;"
#define SQL_UPDATE_PLAYER_DEFINE \
    "UPDATE `uno_players` SET `name` = \"%s\", `total_match` = '%i', `total_score` = '%i', `total_won_game` = '%i', `lastconnect` = '%i' \
    WHERE `steam`= '%s' LIMIT 1 \
;"
#define SQL_UPDATE_CLEAN_DAYS \
    "UPDATE `uno_players` SET\
	`lastconnect` = 0 \
WHERE \
	`lastconnect` < %d AND `lastconnect`;"
#define SQL_DELETE_0_DAYS \
    "DELETE FROM `uno_players` WHERE `lastconnect` < 1;"
#define SQL_TOPLIST_DEFINE_SCORE \
    "SELECT * FROM `uno_players` ORDER BY `total_score` DESC LIMIT 5;"
#define SQL_TOPLIST_DEFINE_WONGAME \
    "SELECT * FROM `uno_players` ORDER BY `total_won_game` DESC LIMIT 5;"

void ConnectDB()
{
    Database.Connect(ConnectDataBase, "Uno_DB");
}
public void ConnectDataBase(Database db, const char[] error, any data)
{
    if(error[0])
    {
        bDatabase = false;
        LogError("%s %t", mtag, "DatabaseError", error);
        return;
    }
    bDatabase = true;
    g_hDatabase = db;
    char sQuery[1024];
    SQL_SetCharset(g_hDatabase, "utf8mb4_turkish_ci");
    Format(sQuery, 1024, "%s", SQL_CREATE_MATCHES_TABLE);
    SQL_TQuery(g_hDatabase, SQL_CreateTableCallBack, sQuery);
    Format(sQuery, 1024, "%s", SQL_CREATE_CLIENT_TABLE);
    SQL_TQuery(g_hDatabase, SQL_CreateTableCallBack, sQuery, 1);
}
public void SQL_CreateTableCallBack(Handle owner, Handle hndl, char[] error, any data)
{
    if(hndl == null)
    {
        LogError("%s %t", mtag, "DatabaseError", error);
        bDatabase = false;
        return;
    }
    else
    {
        bDatabase = true;
        if(data == 1)
        {
            for(int i = 1; i <= MaxClients; i++)
            {
                OnClientPutInServer(i);
            }
        }
    }
}
void SQL_LoadClientData(int client)
{
    char sQuery[1024],
      steamid[22];
    GetClientAuthId(client, AuthId_Steam2, steamid, 22);
    FormatEx(sQuery, 1024, SQL_SELECT_PLAYER_DEFINE, steamid);
    g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(client) << 4 | 1);
}
void SQL_InsertPlayer(int client)
{
    char sQuery[1024],
      steamid[22];
    iClientTotalWinGame[client] = 0,
    iClientTotalScore[client] = 0,
    iClientTotalMatch[client] = 0;
    GetClientAuthId(client, AuthId_Steam2, steamid, 22);
    FormatEx(sQuery, 1024, SQL_INSERT_PLAYER_DEFINE, steamid, GetPlayerName(client), GetTime());
    g_hDatabase.Query(SQL_Callback, sQuery);
}
void SQL_UpdateClient(int client)
{
    char sQuery[1024],
      steamid[22];
    GetClientAuthId(client, AuthId_Steam2, steamid, 22);
    FormatEx(sQuery, 1024, SQL_UPDATE_PLAYER_DEFINE, GetPlayerName(client), iClientTotalMatch[client], iClientTotalScore[client], iClientTotalWinGame[client], GetTime(), steamid);
    g_hDatabase.Query(SQL_Callback, sQuery, GetClientUserId(client) << 4 | 2);
}
void SQL_InsertMatch(int iRoomId)
{
    char sQuery[1024],
      sOwnerId[22],
      sOwnerName[32],
      sWinnerId[22],
      sWinnerName[32];
    int iWinnerScore,
      iPlayerCount,
      iRoomWinner;
    Format(sWinnerId, 22, "Undefined");
    Format(sWinnerName, 22, "Undefined");
    iRoomWinner = GetRoomWinner(iRoomId);
    GetClientAuthId(GetClientOfUserId(GetRoomOwner(iRoomId)), AuthId_SteamID64, sOwnerId, 22);
    FormatEx(sOwnerName, 32, GetPlayerName(GetClientOfUserId(GetRoomOwner(iRoomId))));
    if(iRoomWinner != 0)
    {
        GetClientAuthId(GetClientOfUserId(iRoomWinner), AuthId_SteamID64, sWinnerId, 22);
        FormatEx(sWinnerName, 32, GetPlayerName(GetClientOfUserId(iRoomWinner)));
        iWinnerScore = GetClientScore(GetClientOfUserId(iRoomWinner));
    }
    iPlayerCount = GetRoomMembers(iRoomId);
    FormatEx(sQuery, 1024, SQL_INSERT_MATCH_DEFINE, iRoomId, sOwnerId, sOwnerName, iPlayerCount, sWinnerId, sWinnerName, iWinnerScore, GetTime());
    g_hDatabase.Query(SQL_Callback, sQuery);
}
void OnCleanDB()
{
    if(g_hDatabase && bDatabase)
    {
        char sQuery[256];
        FormatEx(sQuery, sizeof(sQuery), SQL_UPDATE_CLEAN_DAYS, GetTime() - 30 * 86400);
        g_hDatabase.Query(SQL_Callback, sQuery);
        FormatEx(sQuery, sizeof(sQuery), SQL_DELETE_0_DAYS);
        g_hDatabase.Query(SQL_Callback, sQuery);
    }
}
public void SQL_Callback(Database hDatabase, DBResultSet hResult, const char[] sError, int iData)
{
    if(!hDatabase || !hResult)
    {
        LogError("%s %t", mtag, "DatabaseError", sError);
    }
    else if(iData != 0)
    {
        int client = GetClientOfUserId(iData >> 4),
            iQueryType = iData & 0xF;
        if(client != 0 && client || iQueryType)
        {
            switch(iQueryType)
            {
            case 1: //Select and detect
            {
                if(hResult.HasResults && hResult.FetchRow())
                {
                    iClientTotalScore[client] = hResult.FetchInt(3);
                    iClientTotalWinGame[client] = hResult.FetchInt(4);
                    iClientTotalMatch[client] = hResult.FetchInt(2);
                }
                else
                {
                    SQL_InsertPlayer(client);
                }
            }
            case 2:
            {
                iClientTotalWinGame[client] = 0,
                iClientTotalScore[client] = 0,
                iClientTotalMatch[client] = 0;
            }
            }
        }
    }
}
void SQL_TopList(int client, int MenuType)
{
    if(g_hDatabase && bDatabase)
    {
        char sQuery[1024];
        FormatEx(sQuery, 1024, (MenuType == 0) ? SQL_TOPLIST_DEFINE_SCORE : SQL_TOPLIST_DEFINE_WONGAME);
        g_hDatabase.Query(SQL_Callback_TopList, sQuery, GetClientUserId(client) << 4 | MenuType);
    }
}
public void SQL_Callback_TopList(Database hDatabase, DBResultSet hResult, const char[] sError, int iData)
{
    if(!hDatabase || !hResult)
    {
        LogError("%s %t", mtag, "DatabaseError", sError);
    }
    else if(iData != 0)
    {
        int client = GetClientOfUserId(iData >> 4),
            iType = iData & 0xF;
        char sTitle[512],
            buf[64];
        FormatEx(sTitle, 512, "%s | %t\n \n", mtag, (iType == 1) ? "TopMenuGame" : "TopMenuScore");
        if(client != 0)
        {
            Menu menu = CreateMenu(MenuHandler_Default2);
            SetMenuExitButton(menu, true);
            if(hResult.RowCount)
            {
                int itotalmatch,
                  itotalscore,
                  itotalwongame;
                for(int i = 1; hResult.FetchRow(); i++)
                {
                    char sName[48];
                    if(hResult.FetchInt(2) == 0)
                        continue;
                    hResult.FetchString(1, sName, sizeof(sName));
                    itotalmatch = hResult.FetchInt(2);
                    itotalscore = hResult.FetchInt(3);
                    itotalwongame = hResult.FetchInt(4);
                    if(iType == 1)
                    {
                        FormatEx(sTitle, 512, "%s%i - %s (%t : %i)\n", sTitle, i, sName, "TotalWin", itotalwongame);
                    }
                    else
                    {
                        FormatEx(sTitle, 512, "%s%i - %s (%t : %i)\n", sTitle, i, sName, "TotalScore", itotalscore);
                    }
                }
                if(itotalmatch == 0)
                    FormatEx(sTitle, 512, "%s - %t", sTitle, "NoData");
            }
            else
            {
                FormatEx(sTitle, 512, "%s - %t", sTitle, "NoData");
            }
            SetMenuTitle(menu, "%s", sTitle);
            FormatEx(buf, 64, "%t", "MenuBack");
            AddMenuItem(menu, "", buf);
            DisplayMenu(menu, client, 20);
        }
    }
}