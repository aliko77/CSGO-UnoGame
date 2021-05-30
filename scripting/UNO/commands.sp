public Action Command_Uno(int client, int args)
{
    MainMenu(client);
    return Plugin_Handled;
}
public Action Command_Ayril(int client, int args)
{
    RemoveClientFromRoom(client, iClientRoomId[client]);
    return Plugin_Handled;
}