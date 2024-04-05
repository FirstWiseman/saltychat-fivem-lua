fx_version 'adamant'
game 'gta5'

author 'Wiseman'

ui_page 'NUI/SaltyWebSocket.html'

shared_scripts {
 'shared/**/*.*'
}

client_scripts {
  'client/enums/**/*.*',
  'client/models/PlayerPed.lua',
  'client/models/Player.lua',
  'client/models/**/*.*',
  'client/NuiEvent.lua',
  'client/Util.lua',
  'client/VoiceManager.lua',
}

server_scripts {
  'server/Player.lua',
  'server/**/*.*'
}

files {
  'NUI/SaltyWebSocket.html',
  -- 'config.json',
}