fx_version 'cerulean'
game 'gta5'

author 'T5.Prime'
description 'Pig Farming Job for QBCore'
version '1.0.0'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/app.js',
    'html/style.css'
}

lua54 'yes'
