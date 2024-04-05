---@enum Command
Command = {
  -- Plugin
  PluginState = 0,

  -- Instance
  Initiate = 1,
  Reset = 2,
  Ping = 3,
  Pong = 4,
  InstanceState = 5,
  SoundState = 6,
  SelfStateUpdate = 7,
  PlayerStateUpdate = 8,
  BulkUpdate = 9,
  RemovePlayer = 10,
  TalkState = 11,
  PlaySound = 18,
  StopSound = 19,

  -- Phone
  PhoneCommunicationUpdate = 20,
  StopPhoneCommunication = 21,

  -- Radio
  RadioCommunicationUpdate = 30,
  StopRadioCommunication = 31,
  RadioTowerUpdate = 32,
  RadioTrafficState = 33,

  AddRadioChannelMember = 37,
  UpdateRadioChannelMembers = 38,
  RemoveRadioChannelMember = 39,

  -- Megaphone
  MegaphoneCommunicationUpdate = 40,
  StopMegaphoneCommunication = 41,
}