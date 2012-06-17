-- trans.lua -- VLC extension --
--[[
-- 
INSTALLATION:
Put the file in the VLC subdir /lua/extensions, by default:
* Windows (all users): %ProgramFiles%\VideoLAN\VLC\lua\extensions\
* Windows (current user): %APPDATA%\VLC\lua\extensions\
* Linux (all users): /usr/share/vlc/lua/extensions/
* Linux (current user): ~/.local/share/vlc/lua/extensions/
* Mac OS X (all users): /Applications/VLC.app/Contents/MacOS/share/lua/extensions/
(create directories if they don't exist)
Restart the VLC.
Then you simply use the extension by going to the "View" menu and selecting it.

When in pause press F12 to translate current subtitle. Subtitle file name should be the same as movie name.srt
--]]
--
SOURCE_LANG = "en"  -- source langauge
TARGET_LANG = "ru"  -- target language


translator = "yandex" -- google, yandex
osd_duration = 10   -- messages duration

osd_position = "top-left"


-------------------------------------------------
TAG = "TRANS" -- for debugging purposes

-- storage for parsed subtitles
megatable = {}

-- key bindings
bindings = {
   [3276800] --[[ F12 --> ]] = "showTranslation"
}

-- descripttion
function descriptor()
    return {
        title = "Trans";
        version = "0.1";
        author = "Sergei Pashin";
        shortdesc = "Subtitle Translator";
        capabilities = {"input-listener"}
    }
end

function activate()
    film= vlc.input.item():uri()
    film= vlc.strings.decode_uri( film )

--film = string.gsub(film, "([\(|\)])", "\%1" )

    fileName = string.gsub( string.gsub( string.gsub(film, "^(.+)%.%w+$", "%1") ,"%%20"," "),"file://","")..".srt"

    _log(fileName)

    megatable = load_srt( fileName )
    
    if ( megatable == false  ) then
        vlc.osd.message("Could not load subtitles :( \n Make sure you have ".. fileName, channel1, osd_position,  2*osd_duration*1000*1000)

    elseif (  #megatable > 0 ) then
        vlc.var.add_callback( vlc.object.libvlc(), "key-pressed", key_press )
        vlc.osd.message("press f12 to translate current subtitle", channel1, osd_position, osd_duration*1000*1000 )
    else
        vlc.osd.message("Unknown error: please send bug report", channel1, osd_position)

    end
end

function deactivate()
    _log("========= deactivated")
    vlc.var.del_callback( vlc.object.libvlc(), "key-pressed", key_press ) 
end

function close()
    vlc.deactivate()
end

function key_press( var, old, new, data )
    local key = new
    _log("key_press:",tostring(key))
    if bindings[key] then
        _log("key_press:",tostring(key))

        if ( bindings[key]=="showTranslation" ) then
            showTranslation()
        end
    else
        _log("Key `"..key.."' isn't bound to any action.")
    end
end

-- how translation for current subtitle
function showTranslation()

    times = getCurrentTime()
    sourceSubtitle = string.gsub( getSubtitleForTime(times, megatable) , "\r", "") 

    _log("source subtitle: "..sourceSubtitle)

    if (translator == "google") then
        url = "http://translate.google.com/translate_a/t?client=t&text=".. vlc.strings.encode_uri_component( sourceSubtitle ) .."&sl=".. SOURCE_LANG .."&tl="..TARGET_LANG
    else
        url = "http://translate.yandex.ru/tr.json/translate?lang="..SOURCE_LANG.."-"..TARGET_LANG.."&text=".. vlc.strings.encode_uri_component( sourceSubtitle) .."&srv=tr-text"
    end

    -- Open http request
    local s, msg = vlc.stream(url)
    if not s then
        _log( msg )
        return
    end

    -- Fetch HTML data
    local data = ""..s:readline(8000)
    if not data then
        _log("No data received!")
        return
    end
    _log(  data  )

    -- TODO: parse multiple sentences
    if ( translator == "google" ) then
        out = string.match( data, "\"([^\"]+)\"-" )
        _log(  vlc.strings.from_charset("KOI8-R", out) )
        out = vlc.strings.from_charset("koi8-r", out);
    else
        out = data
    end

    vlc.osd.message( out, channel1, osd_position, osd_duration*1000*1000 )

    --[[
 _log ("-1----")

    local obj, pos, err =json.decode(data)
 _log ("-2----")

    if err then
        _log  ("Error:", err)
    else
         _log ("-3----")

        _log( obj[1][1][1] )
        _log ("-4----")
    end
--]]
   -- _log( out )
 --
end

function action_trigger( action )
     _log("action_trigger:",tostring(action))
     local a = actions[action]
     if a then
         a.func()
     else
         _log("Key `"..key.."' points to unknown action `"..bindings[key].."'.")
    end
end

function load_srt(subfile)
    _log(subfile)

    local f = io.open(subfile, "r")
    if f == nil then
        _log("Could not load : "..subfile )
        return false
    end
    local contents = f:read("*all")

    --_log(contents)

    f:close()

    local line = nil
    local k=0
    local table={}
    local a
    local hasTime
    local sourceSubtitle

    local p1 = 1
    local p2

    while 1 do
        --_log("k="..k)
        p2 = string.find(contents,'\n',p1)
        --_log(p2)
        if p2 == nil then
            --_log("break")
            break
        end

        line = string.sub(contents,p1,p2-1)
        p1 = p2+1
        if line ~= nil then
            -- --> subtitle appear time
            a=string.find(line, "%-%-%>")
        end

        -- body of subtitle
        if a == nil then 
            if tonumber(line)~=nil then 
            elseif line == nil or string.len(line) <= 1 then  -- line vide (caractère de fin de line)
                if hasTime == 1  then
                    if sourceSubtitle ~= nil then
                        --storeSubtitle = chaine2liste(sourceSubtitle)
                        storeSubtitle = sourceSubtitle
                        --_log("sourceSubtitle: "..sourceSubtitle)

                    end

                    -- push subtitle to the table
                    if storeSubtitle ~= nil then
                        --_log("st"..k.."="..storeSubtitle[1])
                        --_log("k:"..k.."="..storeSubtitle)
                        --_log(timeStart.."-->"..timeEnd)


                        table[k] = {timeStart,timeEnd,storeSubtitle}
                    end
                    sourceSubtitle = nil
                    hasTime = 0
                end
            else -- line de sous-titre
                if sourceSubtitle == nil then
                    sourceSubtitle = string.lower(line)
                else
                    sourceSubtitle = sourceSubtitle.." "..string.lower(line)
                end
            end

        -- parse subtitle start/end time
        else
            timeStart, timeEnd = getSubtitleTimes(line)
            k = k + 1
            hasTime = 1
        end

    end
    --push last subtitle to table
    if sourceSubtitle ~= nil then
        storeSubtitle = sourceSubtitle
    end
    if storeSubtitle ~= nil then
        table[k] = {timeStart,timeEnd,storeSubtitle}
    end
    --_log("last k:" .. k)
    _log("size table:".. #table )

    return table
end



--return subtitle start/end time--
function getSubtitleTimes( line )
    local parts = split(line, " --> ")
    local hourStart, minuteStart, secondStart, milliStart = _splitSRTLine( parts[1] )
    local timeStart   = hourStart*3600000 + minuteStart*60000 + secondStart*1000 + milliStart
    local hourEnd, minuteEnd, secondEnd, milliEnd = _splitSRTLine( parts[2] )
    local timeEnd   = hourEnd*3600000 + minuteEnd*60000 + secondEnd*1000 + milliEnd
    return timeStart, timeEnd
end

-- split xx:xx:xx,xx into hours, minutes, seconds, milliseconds
function _splitSRTLine( line )
    local parts = split(line, "," )
    local milli = parts[2]
    --_log( parts[1] )
    parts = split(parts[1], ":" )

    local h = parts[1]
    local m = parts[2]
    local s = parts[3]
    --_log( h .."/" .. m .."/" .. s .."/" .. milli  )

    return tonumber(h), tonumber(m), tonumber(s), tonumber(milli)
end

-- return subtitle by time --
function getSubtitleForTime(temps,table)
    _log(#table .. "   " .. temps)
    for i=1,#table do
        if table[i][1]>temps then
            return nil
        elseif table[i][1] <= temps and table[i][2] >= temps then
            return table[i][3]
        end
    end
    return nil
end

-- return current time
function getCurrentTime()
    local input = vlc.object.input()
    local temps = vlc.var.get( input, "time" )
    return temps*1000
end

-- split string by separator
function split ( self, sSeparator, nMax, bRegexp)
    assert(sSeparator ~= '')
    assert(nMax == nil or nMax >= 1)

    local aRecord = {}

    if self:len() > 0 then
        local bPlain = not bRegexp
        nMax = nMax or -1

        local nField=1 nStart=1
        local nFirst,nLast = self:find(sSeparator, nStart, bPlain)
        while nFirst and nMax ~= 0 do
            aRecord[nField] = self:sub(nStart, nFirst-1)
            nField = nField+1
            nStart = nLast+1
            nFirst,nLast = self:find(sSeparator, nStart, bPlain)
            nMax = nMax-1
        end
        aRecord[nField] = self:sub(nStart)
    end

    return aRecord
end


function test_split(line)
    parts = split(line, " --> " )
    print( parts[1] )
    print( parts[2] )

    parts = split(parts[1], ",")
    print( parts[1] )
    print( parts[2] )

    parts = split(parts[1], ":")
    print( parts[1] )
    print( parts[2] )
    print( parts[3] )

end

function _log(m)
    vlc.msg.info( "[".. TAG .."] ".. m )
end

-- test_split("00:00:23,089 --> 00:00:24,215")


