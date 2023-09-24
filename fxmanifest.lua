fx_version 'cerulean'

games { 'gta5' }

author 'ZOBYETEAM'

client_scripts {
    'client/lib.lua',
    'client/main.lua'
}

ui_page 'interface/index.html'

files {
    'interface/**'
}

exports {
    'play',
    'stop',
    'isPlaying'
}