# Salty Chat in Lua for [FiveM](https://fivem.net/)

[![Hits](https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2FFirstWiseman%2Fsaltychat-fivem-lua&count_bg=%239B0000&title_bg=%23202020&icon=lua.svg&icon_color=%23E7E7E7&title=Lua+Lovers&edge_flat=false)](https://hits.seeyoufarm.com)

An example implementation of Salty Chat for [FiveM](https://fivem.net/) OneSync and OneSync Infinity.  
  
Join the [Discord](https://gaming.v10networks.com/Discord) of @v10networkscom and start with [Salty Chat](https://gaming.v10networks.com/SaltyChat)!

Also checkout my [Discord](https://wise-scripts.vip/discord) for any questions about the Saltychat Lua Version or if you have found any Bugs.
You can report bugs or make sugguestions via issues, or contribute via pull requests - we appreciate any contribution.

# Setup Steps
Before starting with the setup, make sure you have OneSync enabled and your server artifacts are up to date.

1. Download the latest [release](https://github.com/FirstWiseman/saltychat-fivem-lua/releases) and extract it into your resources
2. Add `start saltychat` in your `server.cfg`
3. Open `shared/Configuration.lua` and adjust the [variables](https://github.com/v10networkscom/saltychat-docs/blob/master/setup.md#config-variables)
```
  "VoiceEnabled": true,
  "ServerUniqueIdentifier": "NMjxHW5psWaLNmFh0+kjnQik7Qc=",
  "MinimumPluginVersion": "",
  "SoundPack": "default",
  "IngameChannelId" : 25,
  "IngameChannelPassword": "5V88FWWME615",
  "SwissChannelIds": [ 61, 62 ],
```
4. (Optional) Change keybinds in `shared/Configuration.lua`, see [default values](https://github.com/FirstWiseman/saltychat-fivem-lua#keybinds) below
5. (Optional) Look into our recommended [TeamSpeak server settings](https://github.com/v10networkscom/saltychat-docs#teamspeak-server-settings)

**Attantion**: CFX team implemented a NUI blacklist and blocked local (`127.0.0.1` and `localhost`) WebSocket connections.
If the clientside can't connect to the WebSocket, make sure that you can resolve `lh.v10.network`:
1. Open `Windows Command Prompt` by searching `cmd`
2. Execute `nslookup lh.v10.network`

If it resolved to `127.0.0.1` then your issue is probably somewhere else, if not then you can use e.g. [Google DNS servers](https://developers.google.com/speed/public-dns/docs/using#addresses).

# Config
Variable | Type | Description
------------- | ------------- | -------------
VoiceRanges | `float[]` | Array of possible voice ranges
EnableVoiceRangeNotification | `bool` | Enables/disables a notification when chaning the voice range
VoiceRangeNotification | `string` | Text of the notification when changing the voice range, `{voicerange}` will be replaced by the voice range
IgnoreInvisiblePlayers | `bool` | Sets invisible players as distance culled to ignore them in proximity calculations
RadioType | `int` | Radio type which will be used for radio communication - [see possible values](https://github.com/v10networkscom/saltychat-docs/blob/master/enums.md#radio-type)
EnableRadioHardcoreMode | `bool` | Limits some radio functions like using the radio while swimming/diving and allows only one sender at a time
UltraShortRangeDistance | `float` | Maximum range of USR radio mode
ShortRangeDistance | `float` | Maximum range of SR radio mode
LongRangeDistace | `float` | Maximum range of LR radio mode
MegaphoneRange | `float` | Range of the megaphone (only available while driving a police car)
VariablePhoneDistortion | `bool` | Enables/disables variable phone distortion based on position of players
NamePattern | `string` | Naming schema of TeamSpeak clients, `{serverid}` will be replaced by the FiveM server ID of the client, `{playername}` by the name of the client and `{guid}` by a generated GUID
RequestTalkStates | `bool` | Enables/disables [TalkState's](https://github.com/v10networkscom/saltychat-docs/blob/master/commands.md#11--talkstate)
RequestRadioTrafficStates | `bool` | Enables/disables [RadioTrafficState's](https://github.com/v10networkscom/saltychat-docs/blob/master/commands.md#33--radiotrafficstate)

# Keybinds
Below are the default keybinds which will be written to your client config (`%appdata%\CitizenFX\fivem.cfg`).  
Changing the default values wont change the values saved to your config.  
Keybinds can be changed in game through the keybinding options of GTA V (`ESC` > `Settings` > `Key Bindings` > `FiveM`).
Default keybinds can be changed in `shared/Configuration.lua`, see [FiveM docs](https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/) for possible values.

Variable | Description | Default
:---: | :---: | :---:
ToggleRange | Toggles voice range | F1
TalkPrimary | Talk on primary radio | N
TalkSecondary | Talk on secondary radio | Caps
TalkMegaphone | Use the Megaphone (only in police vehicles) | B

# Events
## Client
### SaltyChat_PluginStateChanged
Parameter | Type | Description
------------ | ------------- | -------------
pluginState | `int` | Current state of the plugin (e.g. client is in a swiss channel), see [GameInstanceState](https://github.com/v10networkscom/saltychat-docs/blob/master/enums.md#game-instance-state) for possible values

### SaltyChat_TalkStateChanged
Parameter | Type | Description
------------ | ------------- | -------------
isTalking | `bool` | `true` when player starts talking, `false` when the player stops talking

### SaltyChat_VoiceRangeChanged
Parameter | Type | Description
------------ | ------------- | -------------
voiceRange | `float` | current voice range
index | `int` | index of the current voice range (starts at `0`)
availableVoiceRanges | `int` | count of available voice ranges

### SaltyChat_MicStateChanged
Parameter | Type | Description
------------ | ------------- | -------------
isMicrophoneMuted | `bool` | `true` when player mutes mic, `false` when the player unmutes mic

### SaltyChat_MicEnabledChanged
Parameter | Type | Description
------------ | ------------- | -------------
isMicrophoneEnabled | `bool` | `false` when player disabled mic, `true` when the player enabled mic

### SaltyChat_SoundStateChanged
Parameter | Type | Description
------------ | ------------- | -------------
isSoundMuted | `bool` | `true` when player mutes sound, `false` when the player unmutes sound

### SaltyChat_SoundEnabledChanged
Parameter | Type | Description
------------ | ------------- | -------------
isSoundEnabled | `bool` | `false` when player disabled sound, `true` when the player enabled sound

### SaltyChat_RadioChannelChanged
Parameter | Type | Description
------------ | ------------- | -------------
radioChannel | `string` | Name of the radio channel, `null` if channel was left
isPrimaryChannel | `bool` | `true` when chanel is primary, `false` when secondary

### SaltyChat_RadioTrafficStateChanged
Parameter | Type | Description
------------ | ------------- | -------------
primaryReceive | `bool` | `true` when radio traffic is received on primary radio channel
primaryTransmit | `bool` | `true` when radio traffic is transmitted on primary radio channel
secondaryReceive | `bool` | `true` when radio traffic is received on secondary radio channel
secondaryTransmit | `bool` | `true` when radio traffic is transmitted on secondary radio channel

# Exports
## Client
### GetVoiceRange
Returns the current voice range as float.

### GetRadioChannel
Get the current radio channel.

Parameter | Type | Description
------------ | ------------- | -------------
primary | `bool` | Whether to get the primary or secondary channel

### GetRadioVolume
Returns the current radio volume as float (0.0f - 1.6f).

### GetRadioSpeaker
Returns the current state of the radio speaker as bool (`true` speaker on, `false` speaker off).

### GetMicClick
Returns the current state of radio mic clicks as bool (`true` enabled, `false` disabled).

### SetRadioChannel
Set the current radio channel.

Parameter | Type | Description
------------ | ------------- | -------------
radioChannelName | `string` | Name of the radio channel
primary | `bool` | Whether to set the primary or secondary channel

### SetRadioVolume
Adjust the radio's volume

Parameter | Type | Description
------------ | ------------- | -------------
volumeLevel | `float` | Overrides the volume in percent (0f - 1.6f / 0 - 160%)

### SetRadioSpeaker
Turn the radio speaker on (`true`) or off (`false`).

Parameter | Type | Description
------------ | ------------- | -------------
isRadioSpeakEnabled | `bool` | `true` to enable speaker, `false` to disable speaker

### SetMicClick
Turn radio mic clicks on (`true`) or off (`false`).

Parameter | Type | Description
------------ | ------------- | -------------
isMicClickEnabled | `bool` | `true` to enable mic clicks, `false` to disable mic clicks

## Server
### GetPlayerAlive
Returns player `IsAlive` flag as `bool`.

Parameter | Type | Description
------------ | ------------- | -------------
netId | `int` | Server ID of the player

### SetPlayerAlive
Sets player `IsAlive` flag.

Parameter | Type | Description
------------ | ------------- | -------------
netId | `int` | Server ID of the player
isAlive | `bool` | `true` if player is alive, otherwise `false`

### GetPlayerVoiceRange
Returns player voice range as `float`.

Parameter | Type | Description
------------ | ------------- | -------------
netId | `int` | Server ID of the player

### SetPlayerVoiceRange
Sets player voice range.

Parameter | Type | Description
------------ | ------------- | -------------
netId | `int` | Server ID of the player
voiceRange | `float` | Voice range that should be set

### AddPlayerToCall
Adds a player to a call, creates call if it doesn't exist.

Parameter | Type | Description
------------ | ------------- | -------------
callIdentifier | `string` | Identifier of the call
playerHandle | `int` | Server ID of the player

### AddPlayersToCall
Adds an array of players to a call, creates call if it doesn't exist.

Parameter | Type | Description
------------ | ------------- | -------------
callIdentifier | `string` | Identifier of the call
playerHandles | `int[]` | Server IDs of the players

### RemovePlayerFromCall
Removes a player from a call.

Parameter | Type | Description
------------ | ------------- | -------------
callIdentifier | `string` | Identifier of the call
playerHandle | `int` | Server ID of the player

### RemovePlayersFromCall
Removes an array of players from a call.

Parameter | Type | Description
------------ | ------------- | -------------
callIdentifier | `string` | Identifier of the call
playerHandles | `int[]` | Server IDs of the players

### SetPhoneSpeaker
Turns phone speaker of an player on/off.

Parameter | Type | Description
------------ | ------------- | -------------
playerHandle | `int` | Server ID of the player
toggle | `bool` | `true` to turn on speaker, `false` to turn it off

### SetPlayerRadioSpeaker
Turns radio speaker of an player on/off.

Parameter | Type | Description
------------ | ------------- | -------------
netId | `int` | Server ID of the player
toggle | `bool` | `true` to turn on speaker, `false` to turn it off

### GetPlayersInRadioChannel
Returns an `int` array with all player handles that are members of the specified radio channel.

Parameter | Type | Description
------------ | ------------- | -------------
radioChannelName | `string` | Name of the radio channel

### SetPlayerRadioChannel
Sets a player's radio channel.

Parameter | Type | Description
------------ | ------------- | -------------
netId | `int` | Server ID of the player
radioChannelName | `string` | Name of the radio channel
isPrimary | `bool` | `true` to set the channel as primary, `false` to set it as secondary

### RemovePlayerRadioChannel
Removes a player from the radio channel.

Parameter | Type | Description
------------ | ------------- | -------------
netId | `int` | Server ID of the player
radioChannelName | `string` | Name of the radio channel

### SetRadioTowers
Sets the radio towers.

Parameter | Type | Description
------------ | ------------- | -------------
towers | `float[][]` | Array with radio tower positions and ranges (X, Y, Z, range)
