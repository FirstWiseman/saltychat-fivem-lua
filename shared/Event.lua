---@enum Event
Event = {
  -- #region Plugin
  SaltyChat_Initialize = "SaltyChat_Initialize";
  SaltyChat_CheckVersion = "SaltyChat_CheckVersion";
  SaltyChat_UpdateVoiceRange = "SaltyChat_UpdateVoiceRange";
  SaltyChat_RemoveClient = "SaltyChat_RemoveClient";
  -- #endregion

  --- #region State Change
  SaltyChat_PluginStateChanged = "SaltyChat_PluginStateChanged";
  SaltyChat_TalkStateChanged = "SaltyChat_TalkStateChanged";
  SaltyChat_VoiceRangeChanged = "SaltyChat_VoiceRangeChanged";
  SaltyChat_MicStateChanged = "SaltyChat_MicStateChanged";
  SaltyChat_MicEnabledChanged = "SaltyChat_MicEnabledChanged";
  SaltyChat_SoundStateChanged = "SaltyChat_SoundStateChanged";
  SaltyChat_SoundEnabledChanged = "SaltyChat_SoundEnabledChanged";
  SaltyChat_RadioChannelChanged = "SaltyChat_RadioChannelChanged";
  SaltyChat_RadioTrafficStateChanged = "SaltyChat_RadioTrafficStateChanged";
  --- #endregion

  --- #region Phone
  SaltyChat_EstablishCall = "SaltyChat_EstablishCall";
  SaltyChat_EstablishCallRelayed = "SaltyChat_EstablishCallRelayed";
  SaltyChat_EndCall = "SaltyChat_EndCall";
  --- #endregion

  --- #region Radio
  SaltyChat_SetRadioSpeaker = "SaltyChat_SetRadioSpeaker";
  SaltyChat_ChannelInUse = "SaltyChat_ChannelInUse";
  SaltyChat_IsSending = "SaltyChat_IsSending";
  SaltyChat_SetRadioChannel = "SaltyChat_SetRadioChannel";
  SaltyChat_UpdateRadioTowers = "SaltyChat_UpdateRadioTowers";
  --- #endregion
}