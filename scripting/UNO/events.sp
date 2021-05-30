public Action HookPlayerChat(int client, const char[] command, int args)
{
    if(ClientStatus(client) && client != 0 && !BaseComm_IsClientGagged(client))
    {
        char szText[256];
        GetCmdArg(1, szText, sizeof(szText));
        if(szText[0] == '/' || szText[0] == '@')
        {
            return Plugin_Handled;
        }
        if(bClientWritingPass[client])
        {
            char sPass[11];
            IntToString(GetRoomPassword(iClientRoomId[client]), sPass, 11);
            if(!StrEqual(szText, sPass))
            {
                CPrintToChat(client, "%s %t", ptag, "PrintErrorPass");
                return Plugin_Handled;
            }
            bClientWritingPass[client] = false;
            if(!CheckRoomStat(iClientRoomId[client], client)){
                bClientWritingPass[client] = false;
                iClientRoomId[client] = 0;
                return Plugin_Handled;
            }
            Handle EnvTrie = CreateTrie();
            SetTrieValue(EnvTrie, "UserId", GetClientUserId(client));
            SetTrieValue(EnvTrie, "KartSayisi", 0);
            PushArrayCell(ClientsEnv, EnvTrie);
            CPrintToChat(client, "%s %t", ptag, "PrintJoinRoom", iClientRoomId[client]);
            ClientPushAnyRoom(client, iClientRoomId[client]);
            ReloadMenuForRoomClients(iClientRoomId[client]);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}
public Action HookEvent_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    int clients[10];
    int RlyClient;
    char buf[48];
    for(int i = 0; i < GetArraySize(Rooms_Array); i++)
    {
        int iRoomId;
        Handle trie = GetArrayCell(Rooms_Array, i);
        GetTrieValue(trie, "RoomId", iRoomId);
        GetTrieArray(trie, "Players", clients, sizeof(clients));
        for(int ii = 0; ii < sizeof(clients); ii++)
        {
            if(clients[ii] == 0)
                continue;
            RlyClient++;
        }
        if(RlyClient < 2)
        {
            if(RlyClient > 0){
                FormatEx(buf, 48, "%t", "DuyuruDeleteRoom");
                OdadakilereDuyuru(iRoomId, buf);
            }
            EndGame(iRoomId);
        }
    }
}