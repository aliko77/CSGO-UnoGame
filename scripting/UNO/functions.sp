void ReloadMenuForRoomClients(int iRoomId)
{
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int clients[10],
          iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] == 0)
                continue;
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            Menu_ClientCurrentRoom(target, iRoomId);
        }
        break;
    }
}
stock void CreateNewRoom(int client, int rPassword = -1)
{
    if(rPassword == -1)
        return;
    int Players[10];
    Players[0] = GetClientUserId(client);
    int iRoomId = RandomRoomId();
    Handle trie = CreateTrie(),
           EnvTrie = CreateTrie(),
           REnvTrie = CreateTrie(),
           SpecTrie = CreateTrie();
    SetTrieValue(trie, "RoomId", iRoomId);
    SetTrieValue(trie, "Password", rPassword);
    SetTrieValue(trie, "GameStart", 0);
    SetTrieValue(trie, "Owner", GetClientUserId(client));
    SetTrieArray(trie, "Players", Players, sizeof(Players));
    PushArrayCell(Rooms_Array, trie);

    SetTrieValue(EnvTrie, "UserId", GetClientUserId(client));
    SetTrieValue(EnvTrie, "KartSayisi", 0);
    SetTrieValue(EnvTrie, "TotalScore", 0);
    PushArrayCell(ClientsEnv, EnvTrie);

    SetTrieValue(REnvTrie, "RoomId", iRoomId);
    PushArrayCell(Rooms_Env, REnvTrie);

    SetTrieValue(SpecTrie, "RoomId", iRoomId);
    PushArrayCell(Rooms_Spec, SpecTrie);

    bClientInRoom[client] = true;
    iClientRoomId[client] = iRoomId;
    CPrintToChat(client, "%s %t", ptag, "PrintCreatedNewRoom", iRoomId);
    Menu_ClientCurrentRoom(client, iClientRoomId[client]);
}
void StartNewUnoGame(int iRoomId)
{
    if(SetRoomGameStart(iRoomId, 1))
    {
        SetNextPlayer(iRoomId, 1);
        CardDistribution(iRoomId);
    }
}
stock void TakeCard(int client, int iRoomId, int specialEffect = 0)
{
    if(!ClientStatus(client))
        return;
    int iKartlar[14] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13};
    SortIntegers(iKartlar, sizeof(iKartlar), Sort_Random);
    char RandomKart[11];
    bool btw = false;
    while(btw == false)
    {
        int irandom1 = GetRandomInt(0, 3),
            irandom2 = GetRandomInt(0, 13);
        char SonKartt[11],
          sInt[11];
        Format(SonKartt, 11, GetRoomSonKart(iRoomId, 1));
        IntToString(iKartlar[irandom2], sInt, 11);
        Format(RandomKart, 11, "%s%i", sRenkler[irandom1], iKartlar[irandom2]);
        if(!CheckRoomEnv(iRoomId, RandomKart))
        {
            btw = true;
            if(GetRoomTKartSayisi(iRoomId) >= 107)
            {
                EndGame(iRoomId);
                break;
            }
            else
            {
                PushRoomEnv(iRoomId, RandomKart);
                ReplaceClientEnv(client, RandomKart);
                if(specialEffect == 0)
                {
                    OdadakilereDuyuru(iRoomId, "%t", "DuyuruClientTakeCard", client);
                    CPrintToChat(client, "%s %t", ptag, "PrintClientTakeCard", GetKartDisplayInfo(RandomKart));
                    bClientTakeCard[client] = true;
                    ClientTimerReload(client);
                    if(StrContains(SonKartt, sRenkler[irandom1]) == -1 && !StrEqual(SonKartt[1], sInt))
                    {
                        hPlayedTimer[client] = null;
                        bClientPlayed[client] = true;
                        bClientTakeCard[client] = false;
                        SetNextPlayer(iRoomId);
                    }
                }
                if(specialEffect == 0)
                    ReloadMenuForRoomClients(iRoomId);
            }
        }
    }
}
stock char[] GetKartDisplayInfo(const char[] RandomKart)
{
    char bfr[32],
      buffer[48];
    Format(bfr, 32, RandomKart);
    if(StrContains(RandomKart, "K") != -1)
    {
        FormatEx(buffer, 48, "%t", "KirmiziKart");
        ReplaceString(bfr, 32, "K", buffer);
    }
    else if(StrContains(RandomKart, "S") != -1)
    {
        FormatEx(buffer, 48, "%t", "SariKart");
        ReplaceString(bfr, 32, "S", buffer);
    }
    else if(StrContains(RandomKart, "Y") != -1)
    {
        FormatEx(buffer, 48, "%t", "YesilKart");
        ReplaceString(bfr, 32, "Y", buffer);
    }
    else if(StrContains(RandomKart, "M") != -1)
    {
        FormatEx(buffer, 48, "%t", "MaviKart");
        ReplaceString(bfr, 32, "M", buffer);
    }
    if(StringToInt(RandomKart[1]) > 9)
    {
        if(StringToInt(RandomKart[1]) == 10)
        {
            FormatEx(buffer, 48, "%t", "PasKart");
            ReplaceString(bfr, 32, "10", buffer);
        }
        else if(StringToInt(RandomKart[1]) == 11)
        {
            FormatEx(buffer, 48, "%t", "PasKart");
            ReplaceString(bfr, 32, "11", buffer);
        }
        else if(StringToInt(RandomKart[1]) == 12)
        {
            ReplaceString(bfr, 32, "12", "(+2)");
        }
        else if(StringToInt(RandomKart[1]) == 13)
        {
            ReplaceString(bfr, 32, "13", "(+4)");
        }
    }
    return bfr;
}
stock bool CheckCardSpecial(const char[] Kart)
{
    if(StringToInt(Kart[1]) > 9)
        return true;
    return false;
}
stock void PutaCard(int client, int iRoomId, const char[] infoKart, const char[] displayKart)
{
    if(!ClientStatus(client))
        return;
    char cut[64];
    if(bClientTakeCard[client])
        bClientTakeCard[client] = false;
    hPlayedTimer[client] = null;
    bClientPlayed[client] = true;
    Format(cut, 64, displayKart);
    strcopy(cut[strlen(cut) - 4], 64, "");
    SetRoomSonKart(iRoomId, infoKart);
    RemoveUsedCardFromEnv(client, infoKart);
    OdadakilereDuyuru(iRoomId, "%t", "DuyuruPutaCard", client, cut);
    SetNextPlayer(iRoomId);
    if(CheckCardSpecial(GetRoomSonKart(iRoomId, 1)))
    {
        GetSpecialCardEffect(iRoomId, GetClientOfUserId(GetNowPlaying(iRoomId)), GetRoomSonKart(iRoomId, 1));
    }
    if(GetClientKartSayisi(client) == 0)
    {
        PlayerWonGame(client, iRoomId);
        EndGame(iRoomId);
    }
    ReloadMenuForRoomClients(iRoomId);
}
stock void RemoveUsedCardFromEnv(int client, const char[] Kart)
{
    if(!ClientStatus(client))
        return;
    for(int a = 0; a < GetArraySize(ClientsEnv); a++)
    {
        int iUserId;
        Handle trie = GetArrayCell(ClientsEnv, a);
        GetTrieValue(trie, "UserId", iUserId);
        if(iUserId != GetClientUserId(client))
            continue;
        int iKartSayisi,
          iTotalScore;
        GetTrieValue(trie, Kart, iKartSayisi);
        GetTrieValue(trie, "TotalScore", iTotalScore);
        SetTrieValue(trie, Kart, iKartSayisi - 1);
        SetTrieValue(trie, "KartSayisi", GetClientKartSayisi(client) - 1);
        SetTrieValue(trie, "TotalScore", iTotalScore + GetCardScore(Kart));
        if((iKartSayisi - 1) == 0)
            RemoveFromTrie(trie, Kart);
        SetArrayCell(ClientsEnv, a, trie);
        break;
    }
}
stock void EndGame(int iRoomId)
{
    int clients[10];
    if(bDatabase && GetRoomGameStart(iRoomId) == 1)
    {
        SQL_InsertMatch(iRoomId);
    }
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] == 0)
                continue;
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            ClearClientEnv(target);
            bClientInRoom[target] = false;
            iClientRoomId[target] = 0;
            bClientTakeCard[target] = false;
            hPlayedTimer[target] = null;
            bClientPlayed[target] = false;
            bClientSpecRoom[target] = false;
        }
        DeleteRoom(iRoomId);
        break;
    }
}
stock void DisplayRoomTop(int iRoomId, int Kazanan)
{
    int clients[10],
      iSonPuan;
    Menu TopMenuu = CreateMenu(MenuHandler_TopMenu);
    SetMenuTitle(TopMenuu, "%s | %t\n", mtag, "MenuTitleTop");
    SetMenuExitButton(TopMenuu, true);
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        char buf[64];
        int iTargetScore;
        GetClientName(Kazanan, buf, 64);
        iTargetScore = GetClientScore(Kazanan);
        Format(buf, 64, "%t", "MenuItemTopWinner", buf, iTargetScore);
        AddMenuItem(TopMenuu, "", buf, ITEMDRAW_DEFAULT);
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            GetClientName(target, buf, 64);
            iTargetScore = GetClientScore(target);
            Format(buf, 64, "%t", "MenuItemTop", buf, iTargetScore);
            if(GetClientUserId(target) == GetClientUserId(Kazanan))
            {
                iClientTotalScore[target] += iTargetScore;
                iClientTotalWinGame[target]++;
                iClientTotalMatch[target]++;
                continue;
            }
            iClientTotalScore[target] += iTargetScore;
            iClientTotalMatch[target]++;
            if(iSonPuan == 0)
            {
                AddMenuItem(TopMenuu, "", buf, ITEMDRAW_DEFAULT);
            }
            else if(iTargetScore > iSonPuan)
            {
                InsertMenuItem(TopMenuu, 1, "", buf, ITEMDRAW_DEFAULT);
            }
            else
            {
                AddMenuItem(TopMenuu, "", buf, ITEMDRAW_DEFAULT);
            }
            iSonPuan = iTargetScore;
        }
        break;
    }
    for(int a = 1; a <= MaxClients; a++)
    {
        if(!ClientStatus(a) || iClientRoomId[a] == 0 && !bClientInRoom[a] || iClientRoomId[a] != iRoomId)
            continue;
        DisplayMenu(TopMenuu, a, 30);
    }
}
stock void PlayerWonGame(int client, int iRoomId)
{
    CPrintToChatAll("%s %t", ptag, "PrintPlayerWonGame", iRoomId, GetClientScore(client), client);
    SetRoomWinner(iRoomId, client);
    DisplayRoomTop(iRoomId, client);
}
stock void SetRoomWinner(int iRoomId, int client)
{
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        SetTrieValue(trie, "Winner", GetClientUserId(client));
        SetArrayCell(Rooms_Array, i, trie);
        break;
    }
}
stock int GetRoomWinner(int iRoomId)
{
    int iWinner;
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieValue(trie, "Winner", iWinner);
        break;
    }
    return iWinner;
}
stock int GetClientScore(int client)
{
    int iScore;
    for(int i = 0; i < GetArraySize(ClientsEnv); i++)
    {
        int iUserId;
        Handle trie = GetArrayCell(ClientsEnv, i);
        GetTrieValue(trie, "UserId", iUserId);
        if(iUserId != GetClientUserId(client))
            continue;
        GetTrieValue(trie, "TotalScore", iScore);
        break;
    }
    return iScore;
}
stock void ClearClientEnv(int client)
{
    for(int i = 0; i < GetArraySize(ClientsEnv); i++)
    {
        int iUserId;
        Handle trie = GetArrayCell(ClientsEnv, i);
        GetTrieValue(trie, "UserId", iUserId);
        if(iUserId != GetClientUserId(client))
            continue;
        RemoveFromArray(ClientsEnv, i);
    }
}
stock void SetRoomSonKart(int iRoomId, const char[] Kart)
{
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        SetTrieString(trie, "LastCard", Kart);
        SetArrayCell(Rooms_Array, i, trie);
        break;
    }
}
stock void SetNextPlayer(int iRoomId, int NewG = -1)
{
    int clients[10];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt,
          iOynayanlar;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, 10);
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] == 0)
                continue;
            if(NewG == 1)
            {
                SetTrieValue(trie, "NextPlayer", clients[ii]);
                SetArrayCell(Rooms_Array, i, trie);
                ClientTimerReload(GetClientOfUserId(clients[ii]));
                break;
            }
            if(bClientPlayed[GetClientOfUserId(clients[ii])])
            {
                iOynayanlar++;
                if(GetRoomMembers(iRoomId) <= iOynayanlar)
                {
                    ResetOynayanlar(iRoomId);
                    ii = -1;
                }
                continue;
            }
            SetTrieValue(trie, "NextPlayer", clients[ii]);
            SetArrayCell(Rooms_Array, i, trie);
            ClientTimerReload(GetClientOfUserId(clients[ii]));
            OdadakilereDuyuru(iRoomId, "%t", "DuyuruNextPlayer", GetClientOfUserId(clients[ii]));
            break;
        }
        break;
    }
}
stock void ClientTimerReload(int client)
{
    hPlayedTimer[client] = CreateTimer(1.0, timer_KartAttimi, client, TIMER_REPEAT);
}
stock void GetSpecialCardEffect(int iRoomId, int client, const char[] Kart)
{
    bClientPlayed[client] = true;
    if(StringToInt(Kart[1]) == 10)
    {
        OdadakilereDuyuru(iRoomId, "%t", "CardEffect10", client);
        SetNextPlayer(iRoomId);
        return;
    }
    else if(StringToInt(Kart[1]) == 11)
    {
        int clients[10],
          newClients[10];
        for(int i = 0; i < GetArraySize(Rooms_Array); i++)
        {
            int iRoomIdAlt,
              iNowPlaying = GetNowPlaying(iRoomId);
            Handle trie = GetArrayCell(Rooms_Array, i);
            GetTrieValue(trie, "RoomId", iRoomIdAlt);
            if(iRoomIdAlt != iRoomId)
                continue;
            GetTrieArray(trie, "Players", clients, 10);
            int aa,
              bb = 1;
            for(int ii = 0; ii < sizeof(clients); ii++)
            {
                if(clients[ii] == iNowPlaying)
                {
                    if(ii - bb >= 0)
                    {
                        newClients[aa] = clients[ii - bb];
                    }
                    else
                    {
                        int cc = 10 + (ii - bb);
                        newClients[aa] = clients[cc];
                    }
                    aa++;
                    bb++;
                    ii = -1;
                    if(aa > 9)
                    {
                        break;
                    }
                }
            }
            SetTrieArray(trie, "Players", newClients, 10);
            SetArrayCell(Rooms_Array, i, trie);
            break;
        }
        OdadakilereDuyuru(iRoomId, "%t", "CardEffect11", client);
        SetNextPlayer(iRoomId);
        return;
    }
    else if(StringToInt(Kart[1]) == 12)
    {
        TakeCard(client, iRoomId, 1);
        TakeCard(client, iRoomId);
        OdadakilereDuyuru(iRoomId, "%t", "CardEffect12", client);
        SetNextPlayer(iRoomId);
        return;
    }
    else if(StringToInt(Kart[1]) == 13)
    {
        TakeCard(client, iRoomId, 1);
        TakeCard(client, iRoomId, 1);
        TakeCard(client, iRoomId, 1);
        TakeCard(client, iRoomId);
        OdadakilereDuyuru(iRoomId, "%t", "CardEffect13", client);
        SetNextPlayer(iRoomId);
        return;
    }
}
stock void ResetOynayanlar(int iRoomId)
{
    int clients[10];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] == 0)
                continue;
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            bClientPlayed[GetClientOfUserId(clients[ii])] = false;
        }
        break;
    }
}
stock char[] GetRoomSonKart(int iRoomId, int info = 0)
{
    char SonKart[32];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieString(trie, "LastCard", SonKart, 32);
        if(info == 0)
            Format(SonKart, 32, "%s", GetKartDisplayInfo(SonKart));
        break;
    }
    return SonKart;
}
stock void DrawClientCards(int client, Menu hM)
{
    char info[32],
      buf[48],
      display[32],
      tittle[512];
    for(int a = 0; a < GetArraySize(ClientsEnv); a++)
    {
        Handle trie = GetArrayCell(ClientsEnv, a);
        int iUserId = 0,
            ToplamKartSayisi = 0,
            itemSayisi = 0;
        GetTrieValue(trie, "UserId", iUserId);
        if(iUserId != GetClientUserId(client))
            continue;
        GetTrieValue(trie, "KartSayisi", ToplamKartSayisi);
        Format(info, 32, "%t", "YourTotalCard", ToplamKartSayisi);
        GetMenuTitle(hM, tittle, 512);
        Format(tittle, 512, "%s%s", tittle, info);
        SetMenuTitle(hM, tittle);
        for(int i = 0; i < 4; i++)
        {
            for(int ii = 0; ii <= 13; ii++)
            {
                int kartsayisi;
                Format(info, 32, "%s%i", sRenkler[i], ii);
                GetTrieValue(trie, info, kartsayisi);
                if(kartsayisi > 0)
                {
                    int style = ITEMDRAW_DISABLED;
                    Format(display, 32, "%s (%i)", GetKartDisplayInfo(info), kartsayisi);
                    if(GetNowPlaying(iClientRoomId[client]) == -1 || GetNowPlaying(iClientRoomId[client]) == GetClientUserId(client))
                    {
                        char SonKart[32], sInt[11];
                        IntToString(ii, sInt, 11);
                        Format(SonKart, 32, "%s", GetRoomSonKart(iClientRoomId[client], 1));
                        TrimString(SonKart);
                        if(StrContains(SonKart, sRenkler[i]) != -1 || StrEqual(SonKart[1], sInt))
                        {
                            style = ITEMDRAW_DEFAULT;
                            itemSayisi++;
                            if(GetMenuItemCount(hM) == 0)
                                AddMenuItem(hM, info, display, style);
                            else
                                InsertMenuItem(hM, 0, info, display, style);
                            continue;
                        }
                    }
                    AddMenuItem(hM, info, display, style);
                }
            }
        }
        if(itemSayisi == 0 && GetNowPlaying(iClientRoomId[client]) == GetClientUserId(client))
        {
            if(!bClientTakeCard[client])
            {
                FormatEx(buf, 48, "%t", "TakeACard");
                InsertMenuItem(hM, 0, "TakeCard", buf, ITEMDRAW_DEFAULT);
            }
        }
        break;
    }
}
stock int GetNowPlaying(int iRoomId)
{
    int iNextP;
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieValue(trie, "NextPlayer", iNextP);
        break;
    }
    return iNextP;
}
stock void CardDistribution(int iRoomId)
{
    if(GetRoomGameStart(iRoomId) != 1 || GetRoomMembers(iRoomId) < 1)
        return; // < 2 YAPMAYI UNUTMA
    int clients[10];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        char RandomKart[11];
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        int iKartlar[14] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13};
        SortIntegers(iKartlar, sizeof(iKartlar), Sort_Random);
        Format(RandomKart, 11, "%s%i", sRenkler[GetRandomInt(0, 3)], iKartlar[GetRandomInt(0, 13)]);
        SetRoomSonKart(iRoomId, RandomKart);
        PushRoomEnv(iRoomId, RandomKart);
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] == 0)
                continue;
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            bool btw = false;
            while(btw == false)
            {
                Format(RandomKart, 11, "%s%i", sRenkler[GetRandomInt(0, 3)], iKartlar[GetRandomInt(0, 13)]);
                if(GetClientKartSayisi(target) == 7)
                {
                    btw = true;
                }
                else
                {
                    if(!CheckRoomEnv(iRoomId, RandomKart))
                    {
                        PushRoomEnv(iRoomId, RandomKart);
                        ReplaceClientEnv(target, RandomKart);
                    }
                }
            }
            Menu_ClientCurrentRoom(target, iRoomId);
        }
        OdadakilereDuyuru(iRoomId, "%t", "DuyuruKartDagitimBitti");
        OdadakilereDuyuru(iRoomId, "%t", "DuyuruBolSans");
        CPrintToChat(GetClientOfUserId(GetNowPlaying(iRoomId)), "%s %t", ptag, "PrintGameStartFirstyou");
        break;
    }
}
stock void PushRoomEnv(int iRoomId, const char[] RandomKart)
{
    for(int i = 0; i < GetArraySize(Rooms_Env); i++)
    {
        int iRoomIdAlt,
          iKartSayisi,
          iTKartSayisi;
        Handle trie = GetArrayCell(Rooms_Env, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomId != iRoomIdAlt)
            continue;
        GetTrieValue(trie, RandomKart, iKartSayisi);
        GetTrieValue(trie, "ToplamKartSayisi", iTKartSayisi);
        SetTrieValue(trie, RandomKart, iKartSayisi + 1);
        SetTrieValue(trie, "ToplamKartSayisi", iTKartSayisi + 1);
        SetArrayCell(Rooms_Env, i, trie);
        break;
    }
}
stock bool CheckRoomEnv(int iRoomId, const char[] RandomKart)
{
    if(GetRoomTKartSayisi(iRoomId) >= 107)
    {
        int iBestPlayer = GetClientOfUserId(GetRoomBestPlayer(iRoomId));
        OdadakilereDuyuru(iRoomId, "%t", "DuyuruGameOver107");
        CPrintToChatAll("%s %t ", ptag, "PrintPlayerWonGame", iRoomId, GetClientScore(iBestPlayer), iBestPlayer);
        SetRoomWinner(iRoomId, iBestPlayer);
        DisplayRoomTop(iRoomId, iBestPlayer);
        return false;
    }
    for(int i = 0; i < GetArraySize(Rooms_Env); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Env, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        int iKartSayisi,
          iTKartSayisi;
        GetTrieValue(trie, "ToplamKartSayisi", iTKartSayisi);
        GetTrieValue(trie, RandomKart, iKartSayisi);
        if(StrEqual(RandomKart, "K0") || StrEqual(RandomKart, "M0") || StrEqual(RandomKart, "Y0") || StrEqual(RandomKart, "S0"))
        {
            if(iKartSayisi == 0)
                return false;
            return true;
        }
        if(iKartSayisi < 2)
            return false;
        return true;
    }
    return true;
}
stock int GetRoomTKartSayisi(int iRoomId)
{
    int iTKartSayisi;
    for(int i = 0; i < GetArraySize(Rooms_Env); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Env, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieValue(trie, "ToplamKartSayisi", iTKartSayisi);
        break;
    }
    return iTKartSayisi;
}
stock int GetRoomBestPlayer(int iRoomId)
{
    int clients[10],
      iBestScore,
      iBestPlayer = -1;
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            int iScore = GetClientScore(target);
            if(iScore > iBestScore)
            {
                iBestScore = iScore;
                iBestPlayer = clients[ii];
            }
        }
        break;
    }
    return iBestPlayer;
}
stock void ReplaceClientEnv(int client, char[] RandomKart)
{
    if(!ClientStatus(client))
        return;
    for(int i = 0; i < GetArraySize(ClientsEnv); i++)
    {
        int iUserId;
        Handle trie = GetArrayCell(ClientsEnv, i);
        GetTrieValue(trie, "UserId", iUserId);
        if(iUserId != GetClientUserId(client))
            continue;
        int kartsayisi,
          iTKartSayisi;
        GetTrieValue(trie, RandomKart, kartsayisi);
        GetTrieValue(trie, "KartSayisi", iTKartSayisi);

        SetTrieValue(trie, RandomKart, kartsayisi + 1);
        SetTrieValue(trie, "KartSayisi", iTKartSayisi + 1);
        SetArrayCell(ClientsEnv, i, trie);
        break;
    }
}
stock int GetCardScore(const char[] Kart)
{
    if(StringToInt(Kart[1]) > 9)
    {
        if(StringToInt(Kart[1]) == 13)
            return 50;
        return 20;
    }
    return StringToInt(Kart[1]);
}
stock int GetClientKartSayisi(int client)
{
    if(!ClientStatus(client))
        return 0;
    for(int i = 0; i < GetArraySize(ClientsEnv); i++)
    {
        int iUserId;
        Handle trie = GetArrayCell(ClientsEnv, i);
        GetTrieValue(trie, "UserId", iUserId);
        if(iUserId != GetClientUserId(client))
            continue;
        int iTKartSayisi;
        GetTrieValue(trie, "KartSayisi", iTKartSayisi);
        return iTKartSayisi;
    }
    return 0;
}
stock void RemoveClientFromRoom(int client, int iRoomId)
{
    if(!bClientInRoom[client] || iClientRoomId[client] == 0)
    {
        if(!bClientSpecRoom[client])
        {
            CPrintToChat(client, "%s %t", ptag, "PrintErrorRoomLeave");
            return;
        }
        int clients[MAXPLAYERS + 1];
        for(int i = 0; i < GetArraySize(Rooms_Spec); i++)
        {
            int iRoomIdAlt;
            Handle trie = GetArrayCell(Rooms_Spec, i);
            GetTrieValue(trie, "RoomId", iRoomIdAlt);
            if(iRoomIdAlt != iRoomId)
                continue;
            GetTrieArray(trie, "Izleyiciler", clients, sizeof(clients));
            for(int ii = 0; ii < sizeof(clients); ii++)
            {
                if(clients[ii] == 0)
                    continue;
                if(GetClientUserId(client) != clients[ii])
                {
                    continue;
                }
                clients[ii] = 0;
                bClientSpecRoom[client] = false;
                SetTrieArray(trie, "Izleyiciler", clients, sizeof(clients));
                SetArrayCell(Rooms_Spec, i, trie);
                CPrintToChat(client, "%s %t", ptag, "PrintLeaveSpec");
            }
            break;
        }
        return;
    }
    int clients[10];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] == 0)
                continue;
            if(client != GetClientOfUserId(clients[ii]))
                continue;
            clients[ii] = 0;
            bClientInRoom[client] = false;
            iClientRoomId[client] = 0;
            bClientTakeCard[client] = false;
            bClientPlayed[client] = false;
            hPlayedTimer[client] = null;
            bClientSpecRoom[client] = false;
            SetTrieArray(trie, "Players", clients, sizeof(clients));
            SetArrayCell(Rooms_Array, i, trie);
            CPrintToChat(client, "%s %t", ptag, "PrintLeaveRoom", iRoomId);
            ClearClientEnv(client);
            MainMenu(client);
            if(GetRoomOwner(iRoomId) == GetClientUserId(client))
            {
                int iBestPlayer = GetClientOfUserId(GetRoomBestPlayer(iRoomId));
                OdadakilereDuyuru(iRoomId, "%t", "DuyuruDeleteRoomOwner");
                CPrintToChat(client, "%s %t", ptag, "PrintDeleteRoomOwner");
                if(iBestPlayer > 0)
                {
                    CPrintToChatAll("%s %t", ptag, "PrintPlayerWonGame", iRoomId, GetClientScore(iBestPlayer), iBestPlayer);
                    DisplayRoomTop(iRoomId, iBestPlayer);
                }
                EndGame(iRoomId);
            }
            else if(GetRoomMembers(iRoomId) <= 1 && GetRoomGameStart(iRoomId) == 1)
            {
                int iBestPlayer = GetClientOfUserId(GetRoomBestPlayer(iRoomId));
                CPrintToChat(client, "%s %t", ptag, "DuyuruDeleteNoPlayer");
                if(iBestPlayer > 0)
                {
                    CPrintToChatAll("%s %t", ptag, "PrintPlayerWonGame", iRoomId, GetClientScore(iBestPlayer), iBestPlayer);
                    DisplayRoomTop(iRoomId, iBestPlayer);
                }
                EndGame(iRoomId);
            }
            else
                OdadakilereDuyuru(iRoomId, "%t", client, "DuyuruRoomLeave");
            if(GetNowPlaying(iRoomId) == GetClientUserId(client))
                SetNextPlayer(iRoomId);
            break;
        }
        break;
    }
    ReloadMenuForRoomClients(iRoomId);
}
stock void OdadakilereDuyuru(int iRoomId, char[] Bildiri, any...)
{
    int clients[10],
      SpecList[MAXPLAYERS + 1];
    char buffer[512];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        Handle specTrie = GetArrayCell(Rooms_Spec, i);
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        GetTrieArray(specTrie, "Izleyiciler", SpecList, sizeof(SpecList));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            int target = GetClientOfUserId(clients[ii]);
            int targetSpec = GetClientOfUserId(SpecList[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            VFormat(buffer, 512, Bildiri, 3);
            CPrintToChat(target, "%s %s", ptag, buffer);
            if(targetSpec > 0 && ClientStatus(targetSpec))
                CPrintToChat(targetSpec, "%s %s", ptag, buffer);
        }
        break;
    }
}
stock int GetRoomGameStart(int iRoomId)
{
    int iGameStartId;
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieValue(trie, "GameStart", iGameStartId);
        break;
    }
    return iGameStartId;
}
stock bool SetRoomGameStart(int iRoomId, int value = 0)
{
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        SetTrieValue(trie, "GameStart", value);
        SetArrayCell(Rooms_Array, i, trie);
        return true;
    }
    return false;
}
stock void DeleteRoom(int iRoomId)
{
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        RemoveFromArray(Rooms_Array, i);
        break;
    }
    for(int i = 0; i < GetArraySize(Rooms_Env); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Env, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        RemoveFromArray(Rooms_Env, i);
        break;
    }
    for(int i = 0; i < GetArraySize(Rooms_Spec); i++)
    {
        int iRoomIdAlt,
          clients[MAXPLAYERS + 1];
        Handle trie = GetArrayCell(Rooms_Spec, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Izleyiciler", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            bClientSpecRoom[target] = false;
        }
        RemoveFromArray(Rooms_Spec, i);
        break;
    }
}
stock char[] GetRoomMembersName(int iRoomId)
{
    char buffer[512];
    int clients[10];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target))
                continue;
            char Name[MAX_NAME_LENGTH];
            GetClientName(target, Name, sizeof(Name));
            Format(buffer, 512, "%s%i- %N\n", buffer, ii + 1, target);
        }
        break;
    }
    return buffer;
}
stock int GetRoomOwner(int iRoomId)
{
    int iOwnerId;
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieValue(trie, "Owner", iOwnerId);
        break;
    }
    return iOwnerId;
}
stock int GetRoomPassword(int iRoomId)
{
    int iRoomPass;
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieValue(trie, "Password", iRoomPass);
        break;
    }
    return iRoomPass;
}
stock int GetRoomMembers(int iRoomId)
{
    int clients[10];
    int RlyClient;
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < 10; ii++)
        {
            if(clients[ii] == 0)
                continue;
            RlyClient++;
        }
        break;
    }
    return RlyClient;
}
stock int RandomRoomId()
{
    int id = GetRandomInt(11, 99);
    int mevcut_ids;
    if(GetArraySize(Rooms_Array) > 0)
    {
        for(int i = 0; i < GetArraySize(Rooms_Array); i++)
        {
            Handle trie = GetArrayCell(Rooms_Array, i);
            GetTrieValue(trie, "RoomId", mevcut_ids);
            if(mevcut_ids == id)
            {
                id = GetRandomInt(11, 99);
                i = -1;
            }
        }
    }
    return id;
}
stock void ClientPushAnyRoom(int client, int iRoomId)
{
    if(!ClientStatus(client))
        return;
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        int Players[10];
        GetTrieArray(trie, "Players", Players, sizeof(Players));
        for(int ii = 0; ii < sizeof(Players); ii++)
        {
            if(Players[ii] != 0)
                continue;
            Players[ii] = GetClientUserId(client);
            SetTrieArray(trie, "Players", Players, sizeof(Players));
            SetArrayCell(Rooms_Array, i, trie);
            bClientInRoom[client] = true;
            iClientRoomId[client] = iRoomId;
            break;
        }
        break;
    }
}
stock bool ClientStatus(int client)
{
    return (client && IsClientInGame(client) && !IsFakeClient(client));
}
stock bool CheckRoomStat(int iRoomId, int client)
{
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        if(GetRoomMembers(iRoomId) == 10)
        {
            CPrintToChat(client, "%s %t", ptag, "PrintFullRoomStat");
            return false;
        }
        if(GetRoomGameStart(iRoomId) == 1)
        {
            CPrintToChat(client, "%s %t", ptag, "PrintStartRoomStat");
            return false;
        }
        break;
    }
    return true;
}
void Hooks()
{
    HookEvent("round_end", HookEvent_RoundEnd);
    AddCommandListener(HookPlayerChat, "say");
}
//Timers
public Action Timer_WritingPassControl(Handle timer, int client)
{
    if(!ClientStatus(client))
        return Plugin_Continue;
    if(!bClientWritingPass[client] || iClientRoomId[client] == 0)
        return Plugin_Continue;
    bClientWritingPass[client] = false;
    iClientRoomId[client] = 0;
    CPrintToChat(client, "%s %t", ptag, "PrintTimeoutPass");
    return Plugin_Continue;
}
public Action timer_KartAttimi(Handle timer, int client)
{
    static int surem = 20;
    if(!ClientStatus(client) || hPlayedTimer[client] != timer || !hPlayedTimer[client] || !bClientInRoom[client] || iClientRoomId[client] == 0 || GetNowPlaying(iClientRoomId[client]) != GetClientUserId(client))
    {
        surem = 20;
        ResetProgressBar(client);
        return Plugin_Stop;
    }
    if(surem >= 0)
    {
        surem--;
        if(surem == 5)
        {
            Menu_ClientCurrentRoom(client, iClientRoomId[client]);
            SetProgressBarFloat(client, float(surem));
        }
        if(surem <= 0)
        {
            surem = 20;
            bClientTakeCard[client] = false;
            bClientPlayed[client] = true;
            OdadakilereDuyuru(iClientRoomId[client], "%t", "DuyuruTimeOutPlay", client);
            SetNextPlayer(iClientRoomId[client]);
            ReloadMenuForRoomClients(iClientRoomId[client]);
            ResetProgressBar(client);
            return Plugin_Stop;
        }
    }
    return Plugin_Continue;
}
void SetProgressBarFloat(int iClient, float flProgressTime)
{
    if(!ClientStatus(iClient))
        return;
    int iProgressTime = RoundToCeil(flProgressTime);
    float flGameTime = GetGameTime();
    SetEntData(iClient, m_iProgressBarDuration, iProgressTime, 4, true);
    SetEntDataFloat(iClient, m_flProgressBarStartTime, flGameTime - (float(iProgressTime) - flProgressTime), true);
    SetEntDataFloat(iClient, m_flSimulationTime, flGameTime + flProgressTime, true);
    SetEntData(iClient, m_iBlockingUseActionInProgress, 0, 4, true);
}
void ResetProgressBar(int iClient)
{
    if(!ClientStatus(iClient))
        return;
    SetEntDataFloat(iClient, m_flProgressBarStartTime, 0.0, true);
    SetEntData(iClient, m_iProgressBarDuration, 0, 1, true);
}
char[] GetPlayerName(int iClient)
{
    char sName[MAX_NAME_LENGTH * 2 + 1];
    GetClientName(iClient, sName, MAX_NAME_LENGTH);
    g_hDatabase.Escape(sName, sName, sizeof(sName));
    GetFixNamePlayer(sName);
    return sName;
}
void GetFixNamePlayer(char[] sName)
{
    for(int i = 0, iLen = strlen(sName), iCharBytes; i < iLen;)
    {
        if((iCharBytes = GetCharBytes(sName[i])) == 4)
        {
            iLen -= iCharBytes;

            for(int j = i; j <= iLen; j++)
            {
                sName[j] = sName[j + iCharBytes];
            }
        }
        else
        {
            i += iCharBytes;
        }
    }
}
stock void ClearClientVariable(int UserId, int iRoomId)
{
    int clients[10];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] == 0)
                continue;
            if(clients[ii] != UserId)
                continue;
            clients[ii] = 0;
            SetTrieArray(trie, "Players", clients, sizeof(clients));
            if(GetRoomOwner(iRoomId) == UserId)
            {
                int iBestPlayer = GetClientOfUserId(GetRoomBestPlayer(iRoomId));
                OdadakilereDuyuru(iRoomId, "%t", "PrintDeleteRoomOwner");
                if(iBestPlayer > 0)
                {
                    CPrintToChatAll("%s %t", ptag, "PrintPlayerWonGame", iRoomId, GetClientScore(iBestPlayer), iBestPlayer);
                    DisplayRoomTop(iRoomId, iBestPlayer);
                }
                EndGame(iRoomId);
            }
            else if(GetRoomMembers(iRoomId) <= 1 && GetRoomGameStart(iRoomId) == 1)
            {
                int iBestPlayer = GetClientOfUserId(GetRoomBestPlayer(iRoomId));
                if(iBestPlayer > 0)
                {
                    CPrintToChatAll("%s %t", ptag, "PrintPlayerWonGame", iRoomId, GetClientScore(iBestPlayer), iBestPlayer);
                    DisplayRoomTop(iRoomId, iBestPlayer);
                }
                EndGame(iRoomId);
            }
            if(GetNowPlaying(iRoomId) == UserId)
                SetNextPlayer(iRoomId);
            SetArrayCell(Rooms_Array, i, trie);
            break;
        }
        break;
    }
    ReloadMenuForRoomClients(iRoomId);
}
stock void SetClientSpecRoom(int client, int iRoomId)
{
    int clients[MAXPLAYERS + 1];
    for(int i = 0; i < GetArraySize(Rooms_Spec); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Spec, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Izleyiciler", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] != 0)
                continue;
            clients[ii] = GetClientUserId(client);
            SetTrieArray(trie, "Izleyiciler", clients, sizeof(clients));
            SetArrayCell(Rooms_Spec, i, trie);
            bClientSpecRoom[client] = true;
            CPrintToChat(client, "%s %t", ptag, "PrintJoinSpec", iRoomId);
            break;
        }
    }
}
stock void DrawSpecMenu(int iRoomId, const char[] title)
{
    int clients[MAXPLAYERS + 1];
    for(int i = 0; i < GetArraySize(Rooms_Spec); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Spec, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        char buf[1024],
          buffer[48],
          sI[11];
        Format(buf, 1024, "%s\n %t", title, "MenuTitleSpec", GetRoomSpecMember(iRoomId));
        Menu menu = CreateMenu(MenuHandler_Spec);
        SetMenuTitle(menu, buf);
        SetMenuExitButton(menu, true);
        GetTrieArray(trie, "Izleyiciler", clients, sizeof(clients));
        IntToString(iRoomId, sI, 11);
        FormatEx(buffer, 48, "%t", "LeaveButton");
        AddMenuItem(menu, sI, buffer);
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target) || !bClientSpecRoom[target])
            {
                clients[ii] = 0;
                continue;
            }
            DisplayMenu(menu, target, 20);
        }
        break;
    }
}
stock int GetRoomSpecMember(int iRoomId)
{
    int clients[MAXPLAYERS + 1],
      iToplamizleyen;
    for(int i = 0; i < GetArraySize(Rooms_Spec); i++)
    {
        int iRoomIdAlt;
        Handle trie = GetArrayCell(Rooms_Spec, i);
        GetTrieValue(trie, "RoomId", iRoomIdAlt);
        if(iRoomIdAlt != iRoomId)
            continue;
        GetTrieArray(trie, "Izleyiciler", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            int target = GetClientOfUserId(clients[ii]);
            if(target < 1 || !ClientStatus(target) || !bClientSpecRoom[target])
            {
                clients[ii] = 0;
                continue;
            }
            iToplamizleyen++;
        }
        break;
    }
    return iToplamizleyen;
}