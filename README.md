vlc-trans-lua
=============

VLC Lua extension for translating subtitles in realtime via online translators.
The purpose of this extension is to enforce learning of foreign languages, helping me to watch movies in their original language,
 providing the ability to the meaning on the fly.

===Requirements:

The only supported format is SRT subtitle.
The subtitle file name should be the same as movie filename but with ".srt" extension. This is due to the lack of VLC API, sorry.
Internet connection.


===Install

Put the file in the VLC subdir /lua/extensions, by default:

* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\VLC\lua\extensions\
* Linux (all users): /usr/share/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/ 

Create directories if they don't exist.

Restart the VLC.

Enable the extension by going to the "View" menu and selecting it.


===How to use

When in pause press F12 to translate current subtitle.

===Tweaking

SOURCE_LANG = "en"  -- source langauge
TARGET_LANG = "ru"  -- target language

translator = "yandex" -- google, yandex
osd_duration = 10   -- messages duration

osd_position = "top-left"

