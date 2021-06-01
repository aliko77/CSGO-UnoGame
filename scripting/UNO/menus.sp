void MainMenu(int client)
{
    int iFlags = GetUserFlagBits(client);
    bool bFlag = (iFlags & ADMFLAG_CUSTOM1 || iFlags & ADMFLAG_ROOT) ? true : false;
    Menu menu = CreateMenu(MenuHandler_MainMenu);
    char buffer[64];
    if(bClientSpecRoom[client] || bClientInRoom[client] && iClientRoomId[client] != 0)
        Format(buffer, 32, "%t\n", "LeaveInfo");
    SetMenuTitle(menu, "%s\n%s", mtag, buffer);
    SetMenuExitButton(menu, true);
    FormatEx(buffer, 64, "%t", "MenuCurrentRooms");
    AddMenuItem(menu, "", buffer, (bClientSpecRoom[client] || bClientInRoom[client] && iClientRoomId[client] != 0) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    FormatEx(buffer, 64, "%t", "MenuCreateNewRoom");
    AddMenuItem(menu, "", buffer, (!bFlag || bClientSpecRoom[client] || bClientInRoom[client] && iClientRoomId[client] != 0) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    FormatEx(buffer, 64, "%t", "MenuClientCurrentRoom");
    AddMenuItem(menu, "", buffer, (!bClientInRoom[client] && iClientRoomId[client] == 0) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
    FormatEx(buffer, 64, "%t", "MenuStatistics");
    AddMenuItem(menu, "", buffer, (g_hDatabase && bDatabase) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    FormatEx(buffer, 64, "%t", "MenuHowtoPlay");
    AddMenuItem(menu, "", buffer);
    DisplayMenu(menu, client, 15);
}
public int MenuHandler_MainMenu(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        switch(item)
        {
        case 0:
        {
            Menu_CurrentRooms(client);
        }
        case 1:
        {
            Menu_CreateNewRoom(client);
        }
        case 2:
        {
            Menu_ClientCurrentRoom(client, iClientRoomId[client]);
        }
        case 3:
        {
            Menu_Statistics(client);
        }
        case 4:
        {
            Panel_GameInfo(client);
        }
        }
    }
    case MenuAction_End:
        delete menu;
    }
}
void Menu_CurrentRooms(int client)
{
    if(GetArraySize(Rooms_Array) == 0)
    {
        CPrintToChat(client, "%s %t", ptag, "NoCurrentRoom");
        MainMenu(client);
        return;
    }
    Menu menu = CreateMenu(MenuHandler_CurrentRooms);
    SetMenuTitle(menu, "%s %t", mtag, "MenuCurrentRooms");
    SetMenuExitButton(menu, true);
    SetMenuExitBackButton(menu, true);
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomId,
          iRoomPass,
          iGameStart,
          iStyle = ITEMDRAW_DEFAULT,
          RoomClients[10];
        char sRoomId[11],
          sDisplay[32],
          sGameStart[32];
        FormatEx(sGameStart, 32, "%t", "Looking");
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomId);
        GetTrieValue(trie, "Password", iRoomPass);
        GetTrieValue(trie, "GameStart", iGameStart);
        GetTrieArray(trie, "Players", RoomClients, sizeof(RoomClients));
        IntToString(iRoomId, sRoomId, 11);
        if(iGameStart == 1)
        {
            FormatEx(sGameStart, 32, "%t", "Started");
        }
        if(GetRoomMembers(iRoomId) == 10)
        {
            iStyle = ITEMDRAW_DISABLED;
            FormatEx(sGameStart, 32, "%t", "Full");
        }
        Format(sDisplay, 32, "%t", "MenuRoomInfoItem", iRoomId, GetRoomMembers(iRoomId), sGameStart);
        AddMenuItem(menu, sRoomId, sDisplay, iStyle);
    }
    DisplayMenu(menu, client, 20);
}
public int MenuHandler_CurrentRooms(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        char ItemInfo[11];
        GetMenuItem(menu, item, ItemInfo, 11);
        if(GetRoomGameStart(StringToInt(ItemInfo)) == 1)
        {
            SetClientSpecRoom(client, StringToInt(ItemInfo));
            return;
        }
        Menu_AskPassword(client, StringToInt(ItemInfo));
    }
    case MenuAction_End:
        delete menu;
    case MenuAction_Cancel:
        if(item == MenuCancel_ExitBack)
            MainMenu(client);
    }
}
void Menu_AskPassword(int client, int iRoomId)
{
    iClientRoomId[client] = iRoomId;
    bClientWritingPass[client] = true;
    char buf[48];
    CreateTimer(12.0, Timer_WritingPassControl, client);
    Menu menu = CreateMenu(MenuHandler_AskPassword);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "%s %t", mtag, "MenuPassTitle");
    FormatEx(buf, 48, "%t", "BackAndCancel");
    AddMenuItem(menu, "", buf);
    DisplayMenu(menu, client, 12);
}
public int MenuHandler_AskPassword(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        Menu_CurrentRooms(client);
        bClientWritingPass[client] = false;
        iClientRoomId[client] = 0;
    }
    case MenuAction_End:
        delete menu;
    }
}
void Menu_CreateNewRoom(int client)
{
    int iPass = GetRandomInt(1111, 9999);
    char buf[48],
      sPass[11];
    Menu menu = CreateMenu(MenuHandler_CreateNewRoom);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "%s %t", mtag, "MenuNewRoomTitle", iPass);
    FormatEx(buf, 48, "%t", "MenuItemCreateRoom");
    FormatEx(sPass, 11, "%i", iPass);
    AddMenuItem(menu, sPass, buf);
    FormatEx(buf, 48, "%t", "MenuItemRenounce");
    AddMenuItem(menu, "", buf);
    FormatEx(buf, 48, "%t", "BackAndCancel");
    AddMenuItem(menu, "", buf);
    DisplayMenu(menu, client, 15);
}
public int MenuHandler_CreateNewRoom(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        switch(item)
        {
        case 0:
        {
            char ItemInfo[11];
            GetMenuItem(menu, item, ItemInfo, 11);
            CreateNewRoom(client, StringToInt(ItemInfo));
        }
        case 1:
        {
            MainMenu(client);
        }
        case 2:
        {
            MainMenu(client);
        }
        }
    }
    case MenuAction_End:
        delete menu;
    }
}
void Menu_ClientCurrentRoom(int client, int iRoomId = -1)
{
    if(!ClientStatus(client) || !bClientInRoom[client] || iRoomId == -1)
    {
        MainMenu(client);
        return;
    }
    Menu UnoMenu = CreateMenu(MenuHandler_UnoMenu);
    char buffer[512],
      buf[48];
    int iMember = GetRoomMembers(iRoomId);
    if(GetRoomGameStart(iRoomId) == 0)
    {
        Format(buffer, 512, "%s\n%t", mtag, "MenuTitleCurrentRooms", iRoomId, GetRoomPassword(iRoomId), GetRoomMembersName(iRoomId));
        if(iMember < 2)
        {
            Format(buffer, 512, "%s\n%t", buffer, "MenuWarningCurrentRooms", iMember);
        }
        Format(buffer, 512, "%s\n—><—", buffer);
        SetMenuTitle(UnoMenu, buffer);
        FormatEx(buf, 48, "%t", "MenuItemStartGame");
        AddMenuItem(UnoMenu, "", buf, (GetRoomOwner(iRoomId) == GetClientUserId(client) && iMember > 1) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED); // 1 yapmayı unutma
        FormatEx(buf, 48, "%t", "MenuItemLeaveRoom");
        AddMenuItem(UnoMenu, "", buf);
    }
    else
    {
        Format(buffer, 512, "%s\n%t\n", mtag, "MenuTitleClientCurrentRoom", iRoomId, GetRoomPassword(iRoomId), iMember, GetRoomSonKart(iRoomId), GetClientOfUserId(GetNowPlaying(iRoomId)));
        SetMenuTitle(UnoMenu, buffer);
        DrawClientCards(client, UnoMenu);
        SetMenuExitButton(UnoMenu, false);
    }
    DisplayMenu(UnoMenu, client, 20);
    if(GetRoomSpecMember(iRoomId) > 0)
        DrawSpecMenu(iRoomId, buffer);
}
public int MenuHandler_UnoMenu(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        if(GetRoomGameStart(iClientRoomId[client]) == 0)
        {
            switch(item)
            {
            case 0:
            {
                StartNewUnoGame(iClientRoomId[client]);
            }
            case 1:
            {
                RemoveClientFromRoom(client, iClientRoomId[client]);
            }
            }
        }
        else if(bClientInRoom[client] && iClientRoomId[client] != 0)
        {
            char info[11],
              display[32];
            GetMenuItem(menu, item, info, 11, _, display, 32);
            if(StrEqual(info, "TakeCard"))
                TakeCard(client, iClientRoomId[client]);
            else
                PutaCard(client, iClientRoomId[client], info, display);
        }
    }
    case MenuAction_End:
    {
        delete menu;
    }
    }
}
void Panel_GameInfo(int client)
{
    char buf[48];
    Menu InfoPanel = new Menu(MenuHandler_Default);
    SetMenuTitle(InfoPanel, "[UNO]\n%t", "HowToPlayInfo");
    FormatEx(buf, 48, "%t", "MenuBack");
    AddMenuItem(InfoPanel, "", buf);
    DisplayMenu(InfoPanel, client, 30);
}
public int MenuHandler_Default(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        MainMenu(client);
    }
    case MenuAction_End:
        delete menu;
    }
}
public int MenuHandler_Spec(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        char ItemInfo[11];
        GetMenuItem(menu, item, ItemInfo, 11);
        RemoveClientFromRoom(client, StringToInt(ItemInfo));
    }
    case MenuAction_End:
        delete menu;
    }
}
void Menu_Statistics(int client)
{
    char buf[48];
    Menu menu = CreateMenu(MenuHandler_Statistics);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "%s | %t", mtag, "MenuStatistics");
    FormatEx(buf, 48, "%t", "MyStatistics");
    AddMenuItem(menu, "", buf);
    FormatEx(buf, 48, "%t", "TopMenuGame");
    AddMenuItem(menu, "", buf);
    FormatEx(buf, 48, "%t", "TopMenuScore");
    AddMenuItem(menu, "", buf);
    FormatEx(buf, 48, "%t", "MenuBack");
    AddMenuItem(menu, "", buf);
    DisplayMenu(menu, client, 30);
}
public int MenuHandler_Statistics(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        switch(item)
        {
        case 0:
        {
            Menu_MyStatistics(client);
        }
        case 1:
        {
            SQL_TopList(client, 1); //Oyun kazanma
        }
        case 2:
        {
            SQL_TopList(client, 2); //Skor
        }
        case 3:
        {
            MainMenu(client);
        }
        }
    }
    case MenuAction_End:
    {
        delete menu;
    }
    }
}
void Menu_MyStatistics(int client)
{
    char buf[48];
    Menu menu = CreateMenu(MenuHandler_Default2);
    SetMenuExitButton(menu, true);
    SetMenuTitle(menu, "%s | %t", mtag, "MenuInfoStatistic", iClientTotalMatch[client], iClientTotalScore[client], iClientTotalWinGame[client]);
    FormatEx(buf, 48, "%t", "MenuBack");
    AddMenuItem(menu, "", buf);
    DisplayMenu(menu, client, 30);
}
public int MenuHandler_Default2(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        Menu_Statistics(client);
    }
    case MenuAction_End:
        delete menu;
    }
}
public int MenuHandler_TopMenu(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
    case MenuAction_Select:
    {
        MainMenu(client);
    }
    case MenuAction_End:
    {
        delete menu;
    }
    }
}