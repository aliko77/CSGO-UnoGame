void SetSettings(){
    Rooms_Array = new ArrayList();
    Rooms_Env = new ArrayList();
    ClientsEnv = new ArrayList();
    Rooms_Spec = new ArrayList();
    m_flProgressBarStartTime = FindSendPropInfo("CCSPlayer", "m_flProgressBarStartTime");
    m_iProgressBarDuration = FindSendPropInfo("CCSPlayer", "m_iProgressBarDuration");
    m_flSimulationTime = FindSendPropInfo("CBaseEntity", "m_flSimulationTime");
    m_iBlockingUseActionInProgress = FindSendPropInfo("CCSPlayer", "m_iBlockingUseActionInProgress");   
}