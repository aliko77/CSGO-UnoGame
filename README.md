# UNO

## Description ##
- Sunucunuzda oyuncuların kendi aralarında kurduğu takımlarla Uno kart oyununu oynamasına olanak sağlar.
- It allows players to play the Uno card game on your server with the teams they have formed among themselves.

## Requirements ##
- Sourcemod and Metamod

## Installation ##
1. Dosyaları sunucunuza yükleyin.
2. Sunucuyu yeniden başlatın veya eklentiyi yüklemek için konsolda `sm plugins load uno` yazın.
-
1. Grab the latest release from the release page and unzip it in your sourcemod folder.
2. Restart the server or type `sm plugins load uno` in the console to load the plugin.

## Configuration ##
- addons/sourcemod/translations/UNO.phrases.txt içindeki ifadeleri değiştirebilirsiniz.
- You can modify the phrases in addons/sourcemod/translations/UNO.phrases.txt.
-
-  Veritabanı kurulumu : addons/sourcemod/configs/databases.cfg :
    "Uno_DB"{
        "driver"	"mysql"
        "host"		""
        "database"	""
        "user"		""
        "pass"		""
    }

## Usage ##
- sm_uno (Uno menüsü açar. / The Uno menu opens.)
- sm_ayril & sm_leave (Oyundan ayrılmanızı sağlar. / Allows you to leave the game.)
