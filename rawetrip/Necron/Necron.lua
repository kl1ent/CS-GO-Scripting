--@region: script information
    -- @name: necron
    -- @created by: Klient#1690
    -- @version: 3.1.1 [beta]
--@endregion

local __debug = true
--@region: auxiliary functions
math.round = function(num, numDecimalPlaces)local mult = 10 ^ (numDecimalPlaces or 0);return math.floor(num * mult + 0.5) / mult;end
table.length = function(tbl)local count = 0;for _ in pairs(tbl) do count = count + 1;end;return count;end
local round = function(x)return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5);end
local clamp = function(value, min, max) return math.min(math.max(value, min), max) end
local lerp = function(start, end_pos, time)if time == nil then time = 0.095;end;time = clamp(time, 0, 1)local delta = end_pos - start;delta = delta * time; delta = delta + start; if end_pos == 0 and delta < 0.01 and delta > -0.01 then delta = 0;elseif end_pos == 1 and delta < 1.01 and delta > 0.99 then delta = 1;end;return delta;end
local lerp_color = function(color1, color2, speed)local t = speed;local color = {};color[1] = color1[1] + ((color2[1] - color1[1]) * t);color[2] = color1[2] + ((color2[2] - color1[2]) * t);color[3] = color1[3] + ((color2[3] - color1[3]) * t);color[4] = color1[4] + ((color2[4] - color1[4]) * t);return color;end
local get_closest_point = function(A, B, P)local a_to_p = { P[1] - A[1], P[2] - A[2] };local a_to_b = { B[1] - A[1], B[2] - A[2] };local atb2 = a_to_b[1] ^ 2 + a_to_b[2] ^ 2;local atp_dot_atb = a_to_p[1] * a_to_b[1] + a_to_p[2] * a_to_b[2];local t = atp_dot_atb / atb2;return { A[1] + a_to_b[1] * t, A[2] + a_to_b[2] * t };end
local print = function(...) for i, data in pairs({...}) do if i < 2 then console.print_color(string.format("%s", "\n[necron] "), color.new(183, 150, 255, 255));end;console.print(string.format("%s%s", tostring(data), i > 0 and "," or ""):gsub(i == #{...} and "," or "", ""));end;end
local debug = function(...) if not __debug then return end return print(...) end
local render_gradient_text = function(font, x, y, first_color, second_color, text, shadow, outline)local len = #text-1;local rinc, ginc, binc, ainc = (second_color[1] - first_color[1]) / len, (second_color[2] - first_color[2]) / len, (second_color[3] - first_color[3]) / len, (second_color[4] - first_color[4]) / len;local offset = 0;for i = 1, len+1 do render.text(font, x + offset, y, color.new(first_color[1], first_color[2], first_color[3], first_color[4]), text:sub(i, i), shadow, outline);first_color[1] = first_color[1] + rinc;first_color[2] = first_color[2] + ginc;first_color[3] = first_color[3] + binc;first_color[4] = first_color[4] + ainc;offset = offset + render.get_text_width(font, text:sub(i, i));end;end
local json = {_version = "0.1.2"}; local encode; local escape_char_map = {[ "\\" ] = "\\",[ "\"" ] = "\"",[ "\b" ] = "b",[ "\f" ] = "f",[ "\n" ] = "n",[ "\r" ] = "r",[ "\t" ] = "t",}; local escape_char_map_inv = { [ "/" ] = "/" }; for k, v in pairs(escape_char_map) do escape_char_map_inv[v] = k; end; local function escape_char(c) return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte())); end; local function encode_nil(val) return "null"; end; local function encode_table(val, stack) local res = {}; stack = stack or {}; if stack[val] then error("circular reference") end; stack[val] = true; if rawget(val, 1) ~= nil or next(val) == nil then local n = 0; for k in pairs(val) do if type(k) ~= "number" then error("invalid table: mixed or invalid key types"); end; n = n + 1; end; if n ~= #val then error("invalid table: sparse array"); end; for i, v in ipairs(val) do table.insert(res, encode(v, stack)); end; stack[val] = nil; return "[" .. table.concat(res, ",") .. "]"; else for k, v in pairs(val) do if type(k) ~= "string" then error("invalid table: mixed or invalid key types"); end; table.insert(res, encode(k, stack) .. ":" .. encode(v, stack)); end; stack[val] = nil; return "{" .. table.concat(res, ",") .. "}"; end; end; local function encode_string(val) return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'; end local function encode_number(val) if val ~= val or val <= -math.huge or val >= math.huge then error("unexpected number value '" .. tostring(val) .. "'"); end; return string.format("%.14g", val); end; local type_func_map = {[ "nil" ] = encode_nil,[ "table" ] = encode_table,[ "string" ] = encode_string,[ "number" ] = encode_number,[ "boolean" ] = tostring,}; encode = function(val, stack) local t = type(val); local f = type_func_map[t]; if f then return f(val, stack); end; error("unexpected type '" .. t .. "'"); end; function json.encode(val) return ( encode(val) ); end; local parse; local function create_set(...) local res = {}; for i = 1, select("#", ...) do res[ select(i, ...) ] = true; end; return res; end; local space_chars = create_set(" ", "\t", "\r", "\n"); local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ","); local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u"); local literals = create_set("true", "false", "null"); local literal_map = {[ "true" ] = true,[ "false" ] = false,[ "null" ] = nil,}; local function next_char(str, idx, set, negate) for i = idx, #str do if set[str:sub(i, i)] ~= negate then return i; end; end; return #str + 1; end; local function decode_error(str, idx, msg) local line_count = 1; local col_count = 1; for i = 1, idx - 1 do col_count = col_count + 1; if str:sub(i, i) == "\n" then line_count = line_count + 1; col_count = 1; end; end; error( string.format("%s at line %d col %d", msg, line_count, col_count) ); end; local function codepoint_to_utf8(n) local f = math.floor; if n <= 0x7f then return string.char(n); elseif n <= 0x7ff then return string.char(f(n / 64) + 192, n % 64 + 128); elseif n <= 0xffff then return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128); elseif n <= 0x10ffff then return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128); end; error( string.format("invalid unicode codepoint '%x'", n) ); end; local function parse_unicode_escape(s) local n1 = tonumber( s:sub(1, 4), 16 ); local n2 = tonumber( s:sub(7, 10), 16 ); if n2 then return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000); else return codepoint_to_utf8(n1); end; end; local function parse_string(str, i) local res = ""; local j = i + 1; local k = j; while j <= #str do local x = str:byte(j); if x < 32 then decode_error(str, j, "control character in string"); elseif x == 92 then res = res .. str:sub(k, j - 1); j = j + 1; local c = str:sub(j, j); if c == "u" then local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1) or str:match("^%x%x%x%x", j + 1) or decode_error(str, j - 1, "invalid unicode escape in string"); res = res .. parse_unicode_escape(hex); j = j + #hex; else if not escape_chars[c] then decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string"); end; res = res .. escape_char_map_inv[c]; end; k = j + 1; elseif x == 34 then res = res .. str:sub(k, j - 1); return res, j + 1; end; j = j + 1; end; decode_error(str, i, "expected closing quote for string"); end; local function parse_number(str, i) local x = next_char(str, i, delim_chars); local s = str:sub(i, x - 1); local n = tonumber(s); if not n then decode_error(str, i, "invalid number '" .. s .. "'"); end; return n, x; end; local function parse_literal(str, i) local x = next_char(str, i, delim_chars); local word = str:sub(i, x - 1); if not literals[word] then decode_error(str, i, "invalid literal '" .. word .. "'"); end; return literal_map[word], x; end; local function parse_array(str, i) local res = {}; local n = 1; i = i + 1; while 1 do local x; i = next_char(str, i, space_chars, true); if str:sub(i, i) == "]" then i = i + 1; break; end; x, i = parse(str, i); res[n] = x; n = n + 1; i = next_char(str, i, space_chars, true); local chr = str:sub(i, i); i = i + 1; if chr == "]" then break end; if chr ~= "," then decode_error(str, i, "expected ']' or ','") end; end; return res, i; end; local function parse_object(str, i) local res = {}; i = i + 1; while 1 do local key, val; i = next_char(str, i, space_chars, true); if str:sub(i, i) == "}" then i = i + 1; break; end; if str:sub(i, i) ~= '"' then decode_error(str, i, "expected string for key"); end; key, i = parse(str, i); i = next_char(str, i, space_chars, true); if str:sub(i, i) ~= ":" then decode_error(str, i, "expected ':' after key"); end; i = next_char(str, i + 1, space_chars, true); val, i = parse(str, i); res[key] = val; i = next_char(str, i, space_chars, true); local chr = str:sub(i, i); i = i + 1; if chr == "}" then break end; if chr ~= "," then decode_error(str, i, "expected '}' or ','") end; end; return res, i; end; local char_func_map = {[ '"' ] = parse_string,[ "0" ] = parse_number,[ "1" ] = parse_number,[ "2" ] = parse_number,[ "3" ] = parse_number,[ "4" ] = parse_number,[ "5" ] = parse_number,[ "6" ] = parse_number,[ "7" ] = parse_number,[ "8" ] = parse_number,[ "9" ] = parse_number,[ "-" ] = parse_number,[ "t" ] = parse_literal,[ "f" ] = parse_literal,[ "n" ] = parse_literal,[ "[" ] = parse_array,[ "{" ] = parse_object,}; parse = function(str, idx) local chr = str:sub(idx, idx); local f = char_func_map[chr]; if f then return f(str, idx); end; decode_error(str, idx, "unexpected character '" .. chr .. "'"); end; function json.decode(str) if type(str) ~= "string" then error("expected argument of type string, got " .. type(str)); end; local res, idx = parse(str, next_char(str, 1, space_chars, true)); idx = next_char(str, idx, space_chars, true); if idx <= #str then decode_error(str, idx, "trailing garbage"); end; return res; end;
local config = {_version = "0.0.1"}; function config:write(name, Table)local Path = engine.get_winpath("appdata").."\\rawetripp\\"..name..".cfg";local DatabaseValue = json.encode(Table);file.write(Path, DatabaseValue);end;function config:read(name) local Path = engine.get_winpath("appdata").."\\rawetripp\\"..name..".cfg";local file_c = file.read(Path);local Content = json.decode(file_c or "{}");return Content;end
local getKeys = function(tbl) local keys = {}; for k in pairs(tbl) do keys[#keys + 1] = k;end return keys;end
local random_int = function(min, max) min = math.ceil(min); max = math.floor(max); return math.floor(math.random() * (max - min + 1)) + min; end
--@endregion

--@region: locals
-- Creating tables in which all data will be stored
local window, menu, handlers, tabs, defines, bit = {}, {}, {}, {}, {}, {}

local player_states = {"Shared", "Standing", "Moving", "Slow motion", "Air", "On-key"}
local active_i = 1
local p_state = 0

--Creating tables for functions
local visual_controller, anti_bruteforce, visible_controller, configs, conditional_anti_aim, conditional_hitchance, freestand_on_key, clan_tag, anti_aim_controller, leg_spammer, anti_backstab, hitsound, entity_helpers = {},  {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}

--Creating tables for input library
local pressed_keys, last_pressed_keys, input_system = {}, {}, {}

-- Creating all the necessary variables for the "defines" table
defines.setup = {}
defines.weapons_id = {["DEAGLE"] = 0, ["REVOLVER"] = 0, ["P2000"] = 1, ["GLOCK 18"] = 1, ["CZ75-AUTO"] = 1, ["P250"] = 1, ["DUAL BERETTAS"] = 1, ["USP-S"] = 1, ["FIVE-SEVEN"] = 1, ["TEC-9"] = 1, ["MAC-10"] = 2, ["UMP-45"] = 2, ["MP7"] = 2, ["MP9"] = 2, ["P90"] = 2, ["PP-BIZON"] = 2, ["AK-47"] = 3, ["M4A4"] = 3, ["M4A1-S"] = 3, ["SG 553"] = 3, ["AUG"] = 3, ["GALIL AR"] = 3, ["FAMAS"] = 3, ["SCAR-20"] = 4, ["G3SG1"] = 4, ["SSG 08"] = 5, ["AWP"] = 6, ["NOVA"] = 7, ["XM1014"] = 7, ["SAWED-OFF"] = 7, ["MAG-7"] = 7, ["M249"] = 7, ["NEGEV"] = 7, }

defines.noscope_weapons = {
    ["SCAR-20"] = true,
    ["G3SG1"] = true,
    ["SSG 08"] = true,
    ["AWP"] = true
}

defines.hitchance_cache = {
    ui.get_int("4Ragebot.hitchance_amount"),
    ui.get_int("5Ragebot.hitchance_amount"),
    ui.get_int("6Ragebot.hitchance_amount")
}

local tag_index, tag_reverse = 0, 0
defines.clantag_animations = {
    ["Static"] = function(clantag)
        return clantag.text
    end,

    ["Default"] = function(clantag)
        return tag_index == 0 and "\0" or clantag.text:sub(1, tag_index)
    end,

    ["Reverse"] = function(clantag)
        local tag = clantag.text
        local tag_length = clantag.text:len()
        return tag_reverse <= tag_length and tag:sub(1, tag_index) or (tag_length - tag_index == 0 and "\0" or tag:sub(1, tag_length - tag_index))
    end,

    ["Loop"] = function(clantag)
        local loop_tag = clantag.text
        for _ = 1, tag_index do
            loop_tag = loop_tag .. loop_tag:sub(1, 1)
            loop_tag = loop_tag:sub(2, loop_tag:len())
        end
        return loop_tag
    end
}

-- Creating all the necessary variables for the "tabs" table
tabs.active = "Configs"

-- Creating all the necessary variables for the "window" table
window.alpha = 0
window.setup = {style = {width = 554, height = 488}, animation = {width = 0, height = 0}, dragging = {0, 0, 0}}
window.is_open = false
window.click = globalvars.get_curtime()

-- Creating a variable in which there will be variables to set the position for the window
window.pos = {x = 0, y = 0}

-- Creating all the necessary fonts
local fonts = {default = render.setup_font("Verdana", 14), default_big = render.setup_font("Verdana", 18), default_bold = render.setup_font("Verdanab", 14), small = render.setup_font("Verdana", 13), bold = render.setup_font("Verdanab", 12)}
--@endregion

--@region: input functions
input_system.update = function() for i = 1, 255 do last_pressed_keys[i] = pressed_keys[i];pressed_keys[i] = engine.get_active_key(i);end;end
input_system.is_key_down = function(key) return pressed_keys[key];end
input_system.is_key_pressed = function(key) return pressed_keys[key] and not last_pressed_keys[key];end
input_system.is_key_released = function(key) return not pressed_keys[key] and last_pressed_keys[key];end
input_system.cursor_in_bounds = function(x, y, w, h) local mouse_pos = {x = engine.get_cursor_position().x, y = engine.get_cursor_position().y}; return ((mouse_pos.x >= x and mouse_pos.x < x + w and mouse_pos.y >= y and mouse_pos.y < y + h) and window.is_open) end
input_system.keys = {["MOUSE1"] = 0x01,["MOUSE2"] = 0x02,["CANCEL"] = 0x03,["MOUSE3"] = 0x04,["MOUSE4"] = 0x05,["MOUSE5"] = 0x06,["BACK"] = 0x08,["TAB"] = 0x09,["CLEAR"] = 0x0C,["RETURN"] = 0x0D,["SHIFT"] = 0x10,["CTRL"] = 0x11,["MENU"] = 0x12,["PAUSE"] = 0x13,["CAPS"] = 0x14,["KANA"] = 0x15,["HANGUEL"] = 0x15,["HANGUL"] = 0x15,["IME_ON"] = 0x16,["JUNJA"] = 0x17,["FINAL"] = 0x18,["HANJA"] = 0x19,["KANJI"] = 0x19,["IME_OFF"] = 0x1A,["Disabled"] = 0x1B,["CONVERT"] = 0x1C,["NONCONVERT"] = 0x1D,["ACCEPT"] = 0x1E,["MODECHANGE"] = 0x1F,["SPACE"] = 0x20,["PRIOR"] = 0x21,["NEXT"] = 0x22,["END"] = 0x23,["HOME"] = 0x24,["LEFT"] = 0x25,["UP"] = 0x26,["RIGHT"] = 0x27,["DOWN"] = 0x28,["SELECT"] = 0x29,["PRINT"] = 0x2A,["EXECUTE"] = 0x2B, ["SNAPSHOT"] = 0x2C,["INSERT"] = 0x2D,["DELETE"] = 0x2E,["HELP"] = 0x2F,["0"] = 0x30,["1"] = 0x31,["2"] = 0x32,["3"] = 0x33,["4"] = 0x34,["5"] = 0x35,["6"] = 0x36,["7"] = 0x37,["8"] = 0x38,["9"] = 0x39,["A"] = 0x41,["B"] = 0x42,["C"] = 0x43,["D"] = 0x44,["E"] = 0x45,["F"] = 0x46,["G"] = 0x47,["H"] = 0x48,["I"] = 0x49,["J"] = 0x4A,["K"] = 0x4B,["L"] = 0x4C,["M"] = 0x4D,["N"] = 0x4E,["O"] = 0x4F,["P"] = 0x50,["Q"] = 0x51,["R"] = 0x52,["S"] = 0x53,["T"] = 0x54,["U"] = 0x55,["V"] = 0x56,["W"] = 0x57,["X"] = 0x58,["Y"] = 0x59,["Z"] = 0x5A,["LWIN"] = 0x5B,["RWIN"] = 0x5C,["APPS"] = 0x5D,["SLEEP"] = 0x5F,["NUM0"] = 0x60,["NUMP1"] = 0x61,["NUM2"] = 0x62,["NUM3"] = 0x63,["NUM4"] = 0x64,["NUM5"] = 0x65,["NUM6"] = 0x66,["NUM7"] = 0x67,["NUM8"] = 0x68,["NUM9"] = 0x69,["MULTIPLY"] = 0x6A,["ADD"] = 0x6B,["SEPARATOR"] = 0x6C,["SUBTR"] = 0x6D,["DECIMAL"] = 0x6E,["DIVIDE"] = 0x6F,["F1"] = 0x70,["F2"] = 0x71,["F3"] = 0x72,["F4"] = 0x73,["F5"] = 0x74,["F6"] = 0x75,["F7"] = 0x76,["F8"] = 0x77,["F9"] = 0x78,["F10"] = 0x79,["F11"] = 0x7A,["F12"] = 0x7B,["F13"] = 0x7C,["F14"] = 0x7D,["F15"] = 0x7E,["F16"] = 0x7F,["F17"] = 0x80,["F18"] = 0x81,["F19"] = 0x82,["F20"] = 0x83,["F21"] = 0x84,["F22"] = 0x85,["F23"] = 0x86,["F24"] = 0x87,["NUMLCK"] = 0x90,["SCROLL"] = 0x91,["LSHIFT"] = 0xA0,["RSHIFT"] = 0xA1,["LCONTROL"] = 0xA2,["RCONTROL"] = 0xA3,["LMENU"] = 0xA4,["RMENU"] = 0xA5,["BROWSER_BACK"] = 0xA6,["BROWSER_FORWARD"] = 0xA7,["BROWSER_REFRESH"] = 0xA8,["BROWSER_STOP"] = 0xA9,["BROWSER_SEARCH"] = 0xAA,["BROWSER_FAVORITES"] = 0xAB,["BROWSER_HOME"] = 0xAC,["VOLUME_MUTE"] = 0xAD,["VOLUME_DOWN"] = 0xAE,["VOLUME_UP"] = 0xAF,["MEDIA_NEXT_TRACK"] = 0xB0,["MEDIA_PREV_TRACK"] = 0xB1,["MEDIA_STOP"] = 0xB2,["MEDIA_PLAY_PAUSE"] = 0xB3,["LAUNCH_MAIL"] = 0xB4,["LAUNCH_MEDIA_SELECT"] = 0xB5,["LAUNCH_APP1"] = 0xB6,["LAUNCH_APP2"] = 0xB7,["OEM_1"] = 0xBA,["OEM_PLUS"] = 0xBB,["OEM_COMMA"] = 0xBC,["OEM_MINUS"] = 0xBD,["OEM_PERIOD"] = 0xBE,["OEM_2"] = 0xBF,["OEM_3"] = 0xC0,["OEM_4"] = 0xDB,["OEM_5"] = 0xDC,["OEM_6"] = 0xDD,["OEM_7"] = 0xDE,["OEM_8"] = 0xDF,["OEM_102"] = 0xE2,["PROCESSKEY"] = 0xE5,["PACKET"] = 0xE7,["ATTN"] = 0xF6,["CRSEL"] = 0xF7,["EXSEL"] = 0xF8,["EREOF"] = 0xF9,["PLAY"] = 0xFA,["ZOOM"] = 0xFB,["NONAME"] = 0xFC,["PA1"] = 0xFD,["OEM_CLEAR"] = 0xFE}
input_system.state = {["Disabled"] = 0, ["Always"] = 1, ["Toggle"] = 2, ["Hold"] = 3}
--@endregion

--@region: bit functions
bit.band = function(a, b) return a & b end
bit.bor = function(a, b) return a | b end
bit.bxor = function(a, b) return a ~ b end
bit.bnot = function(a) return ~a end
bit.rshift = function(a, b) return a >> b end
bit.lshift = function(a, b) return a << b end
--@endregion

--@region: entity_helpers functions
entity_helpers.is_enemy = function(player, target)
    if player == nil then
        debug("[entity_helpers.is_enemy | ERROR] Player equals nil")
        return
    end

    if target == nil then
        debug("[entity_helpers.is_enemy | ERROR] Target equals nil")
        return
    end

    if target:get_team() ~= player:get_team() then
        return true
    end

    return false
end

entity_helpers.local_player = {}

entity_helpers.local_player.last_time = -1
entity_helpers.local_player.cached = {ptr = nil, index = -1}
entity_helpers.local_player.pointer = function()
    if entity_helpers.local_player.last_time == globalvars.get_tickcount() then
        return entity_helpers.local_player.cached.ptr
    end

    entity_helpers.local_player.cached.ptr = entitylist.get_local_player()

    if entity_helpers.local_player.cached.ptr then
        entity_helpers.local_player.cached.index = entity_helpers.local_player.cached.ptr:get_index()
    else
        entity_helpers.local_player.cached.index = -1
    end

    entity_helpers.local_player.last_time = globalvars.get_tickcount()

    return entity_helpers.local_player.cached.ptr
end

entity_helpers.get_eye_position = function(player)
    if player == nil then
        debug("[entity_helpers.get_eye_position | ERROR] Player equals nil")
        return
    end

    local head = player:get_player_hitbox_pos(0)
    local position = player:get_absorigin()

    return {x = position.x, y = position.y, z = head.z}
end
--@endregion

--@region: functions for configuring menu items
--[[
--
--  Automatically sets the settings for child.
--  @param: table {table}
--
]]--
menu.child_auto_setup = function(array)
    -- Checking if the table is empty
    array = array == nil and {x = 0, y = 0, right = false, middle = false, offset = 0} or array

    -- Creating a variable for positioning
    -- And we do a check, if there is no specific element in the table, then we output a different value
    local x = array.x or 0; local y = array.y or 0
    local right = array.right or false; local middle = array.middle or false; local offset = array.offset or 0
    local add_y = array.add_y or 0

    -- Creating other necessary variables for child
    local height = array.height or 0; local alpha = array.alpha or 0

    local is_scrolling = array.is_scrolling or _; local scroll_cache = array.scroll_cache or 0; local scroll_value = array.scroll_value or 0

    local anim_scroll = array.anim_scroll or 0; local cursor_on_scroll = array.cursor_on_scroll or false

    -- We are returning a table with the variables created above
    return {add_y = add_y, cursor_on_scroll = cursor_on_scroll, anim_scroll = anim_scroll, x = x, y = y, right = right, middle = middle, offset = offset, height = height, alpha = alpha, is_scrolling = is_scrolling, scroll_cache = scroll_cache, scroll_value = scroll_value}
end

--[[
--
--  Automatically sets the settings for elements.
--  @param: table {table}
--
]]--

menu.elements_auto_setup = function(array)
    -- Creating the necessary variables there
    -- And we do a check, if there is no specific element in the table, then we output a different value
    local type = array.type or nil; local value = array.value or 1
    local state = array.state or false
    local description = array.description or nil; local name = array.name or "nil"; local text = array.text or ""
    local visible = array.visible or true; local callback = array.callback or nil
    local float = array.float or false; local min = array.min or 0; local max = array.max or 0; local tooltips = array.tooltips or {}; local tooltip = array.tooltip or ""
    local key = array.key or "Disabled"; local key_state = array.key_state or input_system.state["Disabled"]; local active = array.active or false
    local elements = array.elements or {}
    local right = array.right or false
    local text_right = array.text_right or ""

    -- Create a variable "setup" in order to set the values of the elements
    local setup = array.setup or {}

    -- Check if the variable "type" is not null, then return the table
    -- We are returning a table with the variables created above
    return {text_right = text_right, right = right, type = type, value = value, state = state, description = description, name = name, text = text, visible = visible, callback = callback, float = float, min = min, max = max, tooltips = tooltips, tooltip = tooltip, key = key, key_state = key_state, active = active, elements = elements, setup = setup}
end
--@endregion

--@region: menu items
menu.tabs = {{name = "Rage", icon = "4", second_name = "Ragebot"}, {name = "Brute", icon = "4", second_name = "Anti-Bruteforce"}, {name = "Visuals", icon = "2"}, {name = "Misc", icon = "0"}, {name = "Configs", icon = "0"}}

local binds = 0

menu.items = {
    ["Rage"] = {
        ["General"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({height = 410}),

            -- Creating elements for the menu
            g_Elements = {
                { menu.elements_auto_setup({name = "Enable Ragebot Elements", type = "switch"}) },
                { menu.elements_auto_setup({name = "Custom Air Hitchance", type = "switch"}) },
                { menu.elements_auto_setup({name = "Air Hitchance", type = "slider", min = 0, max = 100, value = 50}) },
                { menu.elements_auto_setup({name = "Freestand on key", type = "binder"}) },
            }
        },

        ["Anti-Aim"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({middle = true, height = 410}),

            -- Creating elements for the menu
            g_Elements = {
                { menu.elements_auto_setup({name = "Enable Anti-Aim Elements", type = "switch"}) },
                { menu.elements_auto_setup({name = "Enable Leg Spammer", type = "switch"}) },
                { menu.elements_auto_setup({name = "Leg Spammer Type", type = "dropdown", elements = {"Backward slide", "Force slide"}}) },
                { menu.elements_auto_setup({name = "Enable Anti-Backstab", type = "switch"}) },
                { menu.elements_auto_setup({name = "Anti-Backstab Distance", type = "slider", min = 0, max = 2000, value = 200}) },
                { menu.elements_auto_setup({name = "Anti-Aim preset", type = "dropdown", elements = {"none", "Tank", "Default", "Conditional", "Alternative"}}) },

                { menu.elements_auto_setup({name = "Trigger", type = "dropdown", elements = player_states}) },
            }
        }
    },

    ["Brute"] = {
        ["General"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({height = 410}),

            -- Creating elements for the menu
            g_Elements = {
                { menu.elements_auto_setup({name = "Anti Bruteforce", type = "switch"}) },
                { menu.elements_auto_setup({name = "phases (not vis)", type = "slider", value = 2, min = 2, max = 20}) },
            }
        },

        ["Phases"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({middle = true, height = 410}),

            -- Creating elements for the menu
            g_Elements = {}
        }
    },

    ["Visuals"] = {
        ["General"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({height = 410}),

            -- Creating elements for the menu
            g_Elements = {
                { menu.elements_auto_setup({name = "Enable Watermark", type = "switch"}) },
                { menu.elements_auto_setup({name = "Enable Fake Indication", type = "switch"}) },
                { menu.elements_auto_setup({name = "Enable Keybinds", type = "switch"}) },
                { menu.elements_auto_setup({name = "Anti-Backstab Radius", type = "switch"}) },
                { menu.elements_auto_setup({name = "On-Screen Indicators", type = "dropdown", elements = {"Disabled", "Default"}}) },
                { menu.elements_auto_setup({name = "Windows Style", type = "dropdown", elements = {"Default", "Alternative"}}) },
            }
        }
    },
    
    ["Misc"] = {
        ["General"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({height = 410}),

            -- Creating elements for the menu
            g_Elements = {
                { menu.elements_auto_setup({name = "Keys x", type = "slider", min = 0, max = 10000}) },
                { menu.elements_auto_setup({name = "Keys y", type = "slider", min = 0, max = 10000}) },

                { menu.elements_auto_setup({name = "Menu x", type = "slider", min = 0, max = 10000}) },
                { menu.elements_auto_setup({name = "Menu y", type = "slider", min = 0, max = 10000}) },
                
                { menu.elements_auto_setup({name = "Clantag", type = "dropdown", elements = {"None", "Necron", "Custom"}}) },
                { menu.elements_auto_setup({name = "Clantag Text", type = "textbox", text = ""}) },
                { menu.elements_auto_setup({name = "Clantag Animation", type = "dropdown", elements = getKeys(defines.clantag_animations)}) },
                { menu.elements_auto_setup({name = "Clantag Speed", type = "slider", min = 0, max = 100, value = 30}) },
                { menu.elements_auto_setup({name = "Clantag Reset", type = "button", function() engine.set_clantag("\0") end}) },

                { menu.elements_auto_setup({name = "Enable Custom Hitsound", type = "switch"}) },
                { menu.elements_auto_setup({name = "Hitsound Name", type = "textbox", text = ""}) },
                { menu.elements_auto_setup({name = "Hitsound Volume", type = "slider", min = 0, max = 100}) }
            } 
        }
    },

    ["Configs"] = {
        ["Name"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({height = 110}),     
            
            g_Elements = {
                { menu.elements_auto_setup({name = "Config name", type = "textbox", text = ""}) }
            }
        },

        --[[["Configs"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({height = 285, add_y = 125}),

            -- Creating elements for the menu
            g_Elements = {
                { menu.elements_auto_setup({name = "Configs", type = "dropdown", elements = f_cfg}) }
            }
        },]]

        ["..."] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({middle = true, height = 130}),

            -- Creating elements for the menu
            g_Elements = {
                { menu.elements_auto_setup({name = "Author", type = "label", right = true, text_right = "none"}) },
                { menu.elements_auto_setup({name = "1", type = "divider"}) },
                { menu.elements_auto_setup({name = "Modified at", type = "label", right = true, text_right = "none"}) },
            }  
        },

        ["Actions"] = {
            -- Setting the value of the variable "g_Settings" using the function
            g_Settings = menu.child_auto_setup({height = 285, add_y = 125}),--menu.child_auto_setup({middle = true, height = 250, add_y = 160}),

            -- Creating elements for the menu
            g_Elements = {} 
        }
    }
}
--@endregion

--@region: render menu items
--[[
--
--  Creating a child element for the menu.
--  @param: check {bool}
--  @param: child name {string}
--  @param: child settings {table}
--
]]--
menu.create_child = function(check, elems, name, setup)
    -- Getting the child position
    local x, y = setup.x + 3, setup.y

    -- Creating a variable for positioning child element
    local value = 0

    -- Creating a "self" variable for convenience
    local self = setup

    -- Updating the values that were set in "menu.items"
    -- Updating the "alpha" variable for the smooth appearance of child
    self.alpha = lerp(self.alpha, check and 1 or 0, globalvars.get_frametime() * 8)

    local c_height = elems + 40
    local vRatio = self.height / c_height
    local s_height = self.height * vRatio
    local scrollY = ( vRatio * self.scroll_cache ) + 5

    self.anim_scroll = lerp(self.anim_scroll, scrollY, globalvars.get_frametime() * 8)

    if self.alpha > 0 then
        --@region: render
        render.rect_filled_rounded(x, y, 240, self.height, 10, 4, color.new(21, 21, 21, window.alpha*255*self.alpha))

        render.rect_filled_rounded(x, y, 240, 35, 10, 4, color.new(26, 26, 26, window.alpha*255*self.alpha))
        render.rect_filled_rounded(x, y + 34, 240, 2, 10, 4, color.new(39, 39, 39, window.alpha*255*self.alpha))

        if (self.offset + 40) > self.height then
            render.rect_filled(x + 240 - 9, y + 40 + self.anim_scroll, 3, s_height - 55, color.new(44, 44, 44, window.alpha*255*self.alpha))
        end

        render.text(fonts.default_bold, x + 15, y + 10, color.new(255, 255, 255, window.alpha*255*self.alpha), name)
        --@endregion
    end

    if (self.offset + 40) > self.height then
        if input_system.cursor_in_bounds(x + 240 - 9, y + scrollY + 40, 3, s_height - 55) then
            self.cursor_on_scroll = true
            if input_system.is_key_down(0x01) then
                self.is_scrolling = not self.is_scrolling and engine.get_cursor_position().y - scrollY + 5 or self.is_scrolling
            end
        elseif not input_system.is_key_down(0x01) then
            self.is_scrolling = nil
        else
            self.cursor_on_scroll = false
        end

        if self.is_scrolling then
            self.scroll_cache = math.min(math.max((engine.get_cursor_position().y - self.is_scrolling) / vRatio, 0), c_height - self.height)
        end
    else
        self.scroll_cache = 0
    end

    -- Adding a check, if the variable "middle", which was set above in "menu.items", is true, then child changes its position
    value = self.middle and value + 270 or value

    -- Adding a check, if the variable "right", which was set above in "menu.items", is true, then child changes its position
    --value = self.right and value + 500 or value

    -- Updating the items that were installed above in "menu.items"
    self.x, self.y = window.pos.x + 240 + value, window.pos.y + 60 + setup.add_y
    self.offset = 0
    self.check = check

    self.scroll_value = self.scroll_cache
end

--[[
--
--  Creating a button element for the menu.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: subtab setup {table}
--  @param: element setup {table}
--
]]--
menu.create_button = function(tab_name, subtab_name, subtab_element, setup)
    -- Creating a table in which we create the variables we need
    local table_name = string.format("%s_%s_%s_button", tab_name, subtab_name, setup.name)
    if defines.setup[table_name] == nil then defines.setup[table_name] = {colors = {default = {33, 33, 33, 255}}, alpha = {visible = 0, default = 0}, offset = 0} end

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Creating a "self" variable for convenience
    local self = defines.setup[table_name]

    -- We get the values of "setup" in the function
    local data = setup
    
    -- Getting the switch position  
    local x, y = subtab_element.x + 23, subtab_element.y + 50 + self.offset - subtab_element.scroll_value
    
    -- Getting the element width, height
    local w, h = 200, 30

    -- Updating the values that were set in "defines.setup"
    -- Updating the "offset" value so that it is smooth
    self.offset = lerp(self.offset, subtab_element.check and subtab_element.offset or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "alpha.visible", for a smooth appearance of the element
    self.alpha.visible = lerp(self.alpha.visible, subtab_element.check and (setup.visible and 1 or 0) or 0, globalvars.get_frametime() * 20)

    -- Updating the variable "alpha.default", for a smooth appearance of the background
    self.alpha.default = lerp(self.alpha.default, input_system.cursor_in_bounds(x, y, w, h) and input_system.is_key_down(0x01) and 1 or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "colors.default", for a smooth color change
    self.colors.default = lerp_color(self.colors.default, input_system.cursor_in_bounds(x, y, w, h) and {r, g, b, 100} or {33, 33, 33, 255}, globalvars.get_frametime() * 12)

    -- We get the colors of the updated variables above
    local dr, dg, db, da = table.unpack(self.colors.default)

    --@region: render
    render.rect_filled_rounded(x, y, w, 32, 10, 4, color.new(26, 26, 26, window.alpha*255*self.alpha.visible))
    render.rect_filled_rounded(x, y, w, 32, 10, 4, color.new(255, 255, 255, window.alpha*150*self.alpha.visible*self.alpha.default))
    render.text(fonts.default, x + (w / 2) - (render.get_text_width(fonts.default, setup.name) / 2), y + (32 / 2) - (13 / 2) , color.new(255, 255, 255, window.alpha*200*self.alpha.visible), setup.name)
    --@endregion

    -- Making a click check
    if input_system.cursor_in_bounds(x, y, w, h) and input_system.is_key_pressed(0x01) and setup.visible and subtab_element.check then 
        -- Check if the variable "callback" is not equal to nil, then call it
        data.state = true

        if data.callback ~= nil then
            setup.callback() 
        end
    end

    -- Setting the positioning for the remaining elements
    subtab_element.offset = subtab_element.offset + 50
    subtab_element.offset = not setup.visible and subtab_element.offset - 50 or subtab_element.offset

    return data
end

--[[
--
--  Creating a switch element for the menu.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: subtab setup {table}
--  @param: element setup {table}
--
]]--
menu.create_switch = function(tab_name, subtab_name, subtab_element, setup)
    -- Creating a table in which we create the variables we need
    local table_name = string.format("%s_%s_%s_switch", tab_name, subtab_name, setup.name)
    if defines.setup[table_name] == nil then defines.setup[table_name] = {colors = {default = {88, 88, 88, 255}, second = {36, 36, 36, 255}}, alpha = {visible = 0, default = 0}, divider = 0, offset = 0} end

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Creating a "self" variable for convenience
    local self = defines.setup[table_name]

    -- We get the values of "setup" in the function
    local data = setup

    -- Getting the switch position
    local x, y = subtab_element.x + 23, subtab_element.y + 50 + self.offset - subtab_element.scroll_value

    -- Updating the values that were set in "defines.setup"
    -- Updating the "offset" value so that it is smooth
    self.offset = lerp(self.offset, subtab_element.check and subtab_element.offset or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "alpha.visible", for a smooth appearance of the element
    self.alpha.visible = lerp(self.alpha.visible, subtab_element.check and (setup.visible and 1 or 0) or 0, globalvars.get_frametime() * 20)

    -- Updating the variable "alpha.default", for a smooth appearance of the background
    self.alpha.default = lerp(self.alpha.default, input_system.cursor_in_bounds(x - 5, y - 5, 210, 35) and 1 or 0, globalvars.get_frametime() * 12)

    -- Updating the "divider" variable, for smoothness
    self.divider = lerp(self.divider, setup.state and 17 or 0, globalvars.get_frametime() * 8)

    -- Updating the variable "colors.default", for a smooth color change
    self.colors.default = lerp_color(self.colors.default, setup.state and {r, g, b, 255} or {15, 15, 15, 0}, globalvars.get_frametime() * 12)

    -- Updating the variable "colors.second", for a smooth color change
    self.colors.second = lerp_color(self.colors.second, setup.state and {255, 255, 255, 0} or {80, 80, 80, 255}, globalvars.get_frametime() * 12)

    -- We get the colors of the updated variables above
    local dr, dg, db, da = table.unpack(self.colors.default)
    local sr, sg, sb, sa = table.unpack(self.colors.second)

    --@region: render
    render.rect_filled_rounded(x, y, 18, 18, 10, 3, color.new(dr, dg, db, window.alpha*255*self.alpha.visible))

    local add_x, add_y = -1, 1
    render.line(x + 5 + add_x, y + 8 + add_y, x + 8 + add_x, y + 11 + add_y, color.new(255, 255, 255, window.alpha*da*self.alpha.visible))
    render.line(x + 8 + add_x, y + 11 + add_y, x + 13 + add_x, y + 5 + add_y, color.new(255, 255, 255, window.alpha*da*self.alpha.visible))

    render.rect_rounded(x, y, 18, 18, color.new(26, 26, 26, window.alpha*sa*self.alpha.visible), 3)

    render.text(fonts.default, x + 25, y + 1, color.new(sr, sg, sb, window.alpha*255*self.alpha.visible), setup.name)
    --@endregion

    -- Making a click check
    if setup.visible and subtab_element.check and input_system.cursor_in_bounds(x - 5, y - 5, 210, 35) and input_system.is_key_pressed(0x01) and globalvars.get_curtime() > window.click then
        -- We set the variable "data.state", the value we need
        data.state = not data.state

        -- Updating the click with a delay
        window.click = globalvars.get_curtime() + 0.22
    end

    -- Setting the positioning for the remaining elements
    subtab_element.offset = subtab_element.offset + 40
    subtab_element.offset = not setup.visible and subtab_element.offset - 40 or subtab_element.offset

    return data
end

--[[
--
--  Creating a slider element for the menu.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: subtab setup {table}
--  @param: element setup {table}
--
]]--
menu.create_slider = function(tab_name, subtab_name, subtab_element, setup)
    -- Creating a table in which we create the variables we need
    local table_name = string.format("%s_%s_%s_slider%s", tab_name, subtab_name, setup.name, setup.float and "_float" or "_int")
    if defines.setup[table_name] == nil then defines.setup[table_name] = {alpha = {visible = 0}, divider = 0, offset = 0, value = 0} end

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Creating a "self" variable for convenience
    local self = defines.setup[table_name]

    -- We get the values of "setup" in the function
    local data = setup

    -- Getting the switch position
    local x, y = subtab_element.x + 23, subtab_element.y + 70 + self.offset - subtab_element.scroll_value

    -- Getting the element width, height
    local w, h = 140, 3

    -- Variables that are better not to touch
    local fraction = (setup.value - setup.min) / (setup.max - setup.min)
    self.value = fraction * w

    -- Updating the values that were set in "defines.setup"
    -- Updating the "offset" value so that it is smooth
    self.offset = lerp(self.offset, subtab_element.check and subtab_element.offset or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "alpha.visible", for a smooth appearance of the element
    self.alpha.visible = lerp(self.alpha.visible, subtab_element.check and (setup.visible and 1 or 0) or 0, globalvars.get_frametime() * 20)

    -- Updating the "divider" value so that it is smooth
    self.divider = lerp(self.divider, self.value, globalvars.get_frametime() * 12)

    -- Making a hover check
    if (input_system.is_key_down(0x01)) and input_system.cursor_in_bounds(x + 30, y, w, 18) and setup.visible and subtab_element.check then
        self.value = clamp(engine.get_cursor_position().x - (x + 30), 0, w)
        data.value = data.float and (self.value * ((setup.max - setup.min) / (w)) + setup.min) or round(self.value * ((setup.max - setup.min) / (w)) + setup.min)
    end

    if input_system.is_key_down(0x01) and input_system.cursor_in_bounds(x, y, 18, 18) and setup.visible and subtab_element.check and globalvars.get_curtime() > window.click then
        data.value = data.value - 1

        window.click = globalvars.get_curtime() + 0.4
    elseif input_system.is_key_down(0x01) and input_system.cursor_in_bounds(x + (w + 60) - 18, y, 18, 18) and setup.visible and subtab_element.check and globalvars.get_curtime() > window.click then
        data.value = data.value + 1

        window.click = globalvars.get_curtime() + 0.4
    end

    -- Updating the values of the "value" variable
    data.value = clamp(setup.value, setup.min, setup.max)
    local values = setup.float and string.format("%.1f", setup.value) or setup.value
    values = table.length(setup.tooltips) > 0 and setup.tooltips[setup.value] or values

    --@region: render
    render.rect_filled_rounded(x, y, 18, 18, 10, 3, color.new(26, 26, 26, window.alpha*255*self.alpha.visible))

    render.rect_filled_rounded(x + 30, y + 7, w, 6, 10, 3, color.new(15, 15, 15, window.alpha*255*self.alpha.visible))
    render.rect_filled_rounded(x + 30, y + 7, self.divider, 6, 10, 3, color.new(r, g, b, window.alpha*255*self.alpha.visible))

    render.rect_filled_rounded(x + (w + 60) - 18, y, 18, 18, 10, 3, color.new(26, 26, 26, window.alpha*255*self.alpha.visible))

    render.circle_filled(x + 30 + self.divider, y + 10, 50, 7, color.new(255, 255, 255, window.alpha*255*self.alpha.visible))

    render.text(fonts.default, x + 7, y + 1, color.new(255, 255, 255, window.alpha*255*self.alpha.visible), "-")
    render.text(fonts.default, x + (w + 60) - 18 + 5, y + 1, color.new(255, 255, 255, window.alpha*255*self.alpha.visible), "+")

    render.text(fonts.default, x, y - 20, color.new(80, 80, 80, window.alpha*255*self.alpha.visible), setup.name)
    render.text(fonts.default, x + (w + 60) - render.get_text_width(fonts.default, string.format("(%s)", values .. setup.tooltip)), y - 20, color.new(255, 255, 255, window.alpha*255*self.alpha.visible), string.format("(%s)", values .. setup.tooltip))
    --@endregion

    -- Setting the positioning for the remaining elements
    subtab_element.offset = subtab_element.offset + 55
    subtab_element.offset = not setup.visible and subtab_element.offset - 55 or subtab_element.offset

    return data
end

--[[
--
--  Creating a text input element for the menu.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: subtab setup {table}    
--  @param: element setup {table}
--
]]--
menu.create_textbox = function(tab_name, subtab_name, subtab_element, setup)
    -- Creating a table in which we create the variables we need
    local table_name = string.format("%s_%s_%s_textbox", tab_name, subtab_name, setup.name)
    if defines.setup[table_name] == nil then defines.setup[table_name] = {colors = {default = {33, 33, 33, 255}}, alpha = {visible = 0, default = 0, stick = 0}, divider = 0, offset = 0, listening = false} end

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Creating a "self" variable for convenience
    local self = defines.setup[table_name]

    -- We get the values of "setup" in the function
    local data = setup

    -- Getting the switch position
    local x, y = subtab_element.x + 23, subtab_element.y + 65 + self.offset - subtab_element.scroll_value

    -- Getting the element width, height
    local w, h = 200, 30

    -- Updating the values that were set in "defines.setup"
    -- Updating the "offset" value so that it is smooth
    self.offset = lerp(self.offset, subtab_element.check and subtab_element.offset or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "alpha.visible", for a smooth appearance of the element
    self.alpha.visible = lerp(self.alpha.visible, subtab_element.check and (setup.visible and 1 or 0) or 0, globalvars.get_frametime() * 20)

    -- We get the colors of the updated variables above
    local dr, dg, db, da = table.unpack(self.colors.default)

    -- Making a click check
    if input_system.cursor_in_bounds(x, y, w, 32) and window.is_open then
        if input_system.is_key_pressed(0x01) and globalvars.get_curtime() > window.click and setup.visible and subtab_element.check then
            -- We set the variable "self.listening", the value we need
            self.listening = not self.listening

            -- Updating the click with a delay
            window.click = globalvars.get_curtime() + 0.22
        end
    else
        if input_system.is_key_pressed(0x01) and setup.visible and subtab_element.check or not window.is_open then
            self.listening = false
        end
    end

    self.alpha.stick = math.sin(math.abs((math.pi * -1) + (globalvars.get_curtime() * 2) % (math.pi * 2)))
    self.alpha.default = lerp(self.alpha.default, self.alpha.stick, globalvars.get_frametime() * 12)

    if self.listening and window.is_open then
        if input_system.is_key_pressed(0x08) then
            data.text = data.text:sub(1, -2)
        end

        for k, v in pairs(input_system.keys) do
            if ((v ~= 0x20 and v ~= 0x08) and v < 0x30) or v > 0x5A then goto continue end
            if input_system.is_key_pressed(v) then
                --[[if v == 0x20 and #data.text < 25 then
                    data.text = data.text .. " "
                elseif v == 0x08 then
                    data.text = data.text:sub(0, #data.text - 1)
                elseif #data.text < 25 and input_system.is_key_down(0x10) then
                    data.text = data.text:gsub(tostring(k), tostring(k):upper())
                else
                    data.text = data.text .. tostring(k):lower()
                end]]

                if v == 0x20 and #data.text < 25 then
                    data.text = data.text .. " "
                end

                if input_system.is_key_down(0x10) then
                    if #data.text <= 25 then
                        data.text = data.text .. tostring(k):upper():gsub("SPACE", ""):gsub("BACK", "")
                    end
                else
                    if #data.text <= 25 then
                        data.text = data.text .. tostring(k):lower():gsub("space", ""):gsub("back", "")
                    end            
                end
            end
            ::continue:: 
        end
    end

    --@region: render
    render.rect_filled_rounded(x, y, w, 32, 10, 3, color.new(15, 15, 15, window.alpha*255*self.alpha.visible))
    render.rect_rounded(x, y, w, 32, color.new(26, 26, 26, window.alpha*255*self.alpha.visible), 3)

    render.text(fonts.default, x, y - 20, color.new(80, 80, 80, window.alpha*255*self.alpha.visible), setup.name)

    render.text(fonts.default, x + 10, y + 10, color.new(255, 255, 255, window.alpha*(#setup.text > 0 and 255 or 100)*self.alpha.visible), (#setup.text > 0 and setup.text or (self.listening and "" or "...")))
    if self.listening and window.is_open then
        self.divider = lerp(self.divider, render.get_text_width(fonts.default, setup.text), globalvars.get_frametime() * 20)

        render.rect_filled_rounded(x + 10 + self.divider + 2, y + 11, 1, 12, 10, 3, color.new(255, 255, 255, window.alpha*255*self.alpha.visible*self.alpha.stick))
    end
    --@endregion

    -- Setting the positioning for the remaining elements
    subtab_element.offset = subtab_element.offset + 60
    subtab_element.offset = not setup.visible and subtab_element.offset - 60 or subtab_element.offset

    return data
end

--[[
--
--  Creating a key binder element for the menu.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: subtab setup {table}
--  @param: element setup {table}
--
]]--
menu.create_binder = function(tab_name, subtab_name, subtab_element, setup)
    -- Creating a table in which we create the variables we need
    local table_name = string.format("%s_%s_%s_binder", tab_name, subtab_name, setup.name)
    if defines.setup[table_name] == nil then defines.setup[table_name] = {alpha = {visible = 0, default = 0}, divider = 0, offset = 0, listening = false, changingstate = false} end

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Creating a "self" variable for convenience
    local self = defines.setup[table_name]

    -- We get the values of "setup" in the function
    local data = setup

    -- Getting the switch position
    local x, y = subtab_element.x + 23, subtab_element.y + 50 + self.offset - subtab_element.scroll_value

    -- Updating the values that were set in "defines.setup"
    -- Updating the "offset" value so that it is smooth
    self.offset = lerp(self.offset, subtab_element.check and subtab_element.offset or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "alpha.visible", for a smooth appearance of the element
    self.alpha.visible = lerp(self.alpha.visible, subtab_element.check and (setup.visible and 1 or 0) or 0, globalvars.get_frametime() * 20)

    if setup.visible and subtab_element.check then
        if input_system.cursor_in_bounds(x - 5, y - 5, 210, 35) then
            if input_system.is_key_pressed(2) and not self.listening then
                self.changingstate = not self.changingstate
            end
            if input_system.is_key_pressed(1) and not self.listening then
                self.listening = true
            end
        else
            if input_system.is_key_pressed(2) then
                self.changingstate = false
            end
        end
    end

    if self.listening then
        for k, v in pairs(input_system.keys) do
            if input_system.is_key_pressed(v) and not input_system.is_key_pressed(1) then
                data.key = tostring(k)
                self.listening = false
            end
        end
    end

    local text = (self.listening) and "..." or (data.key_state == input_system.state["Always"]) and "on" or (data.key_state == input_system.state["Disabled"]) and "none" or data.key
    local size = render.get_text_width(fonts.default, text)

    --@region: render
    render.rect_filled_rounded(x + 200 - (size + 10), y + 5, (size + 10), 25, 10, 3, color.new(16, 16, 16, window.alpha*self.alpha.visible*255))
    render.rect_rounded(x + 200 - (size + 10), y + 5, (size + 10), 25, color.new(26, 26, 26, window.alpha*self.alpha.visible*255), 3)
    render.text(fonts.default, x + 200 - size - 5, y + 9, color.new(255, 255, 255, window.alpha*self.alpha.visible*255), text:lower())

    render.text(fonts.default, x, y + 11, color.new(255, 255, 255, window.alpha*255*self.alpha.visible), setup.name)

    if self.changingstate then
        render.rect_filled_rounded(x + 140 - (size + 10) - 35, y + 5, 75, (table.length(input_system.state) * 25) + 10, 10, 3, color.new(26, 26, 26, window.alpha*255*self.alpha.visible))

        local offset = 0
        for k, v in pairs(input_system.state) do
            local hovered = input_system.cursor_in_bounds(x + 140 - (size + 10) - 35, y + 10 + offset, 75, 20) 
            if hovered and input_system.is_key_down(0x01) then
                data.key_state = v
                self.changingstate = false
            end

            render.text(fonts.default, x + 140 - (render.get_text_width(fonts.default, k) / 2) - (size + 6), y + 10 + offset, (data.key_state == v or hovered) and color.new(r, g, b, window.alpha*255*self.alpha.visible) or color.new(255, 255, 255,  window.alpha*55*self.alpha.visible), k)
            offset = offset + 25
        end
    end
    --@endregion

    -- Setting the positioning for the remaining elements
    subtab_element.offset = subtab_element.offset + (self.changingstate and setup.visible and (table.length(input_system.state) * 25) + 10 or 0)
    subtab_element.offset = subtab_element.offset + 40
    subtab_element.offset = not setup.visible and subtab_element.offset - 40 or subtab_element.offset

    return data
end

menu.create_divider = function(tab_name, subtab_name, subtab_element, setup)
    -- Creating a table in which we create the variables we need
    local table_name = string.format("%s_%s_%s_divider", tab_name, subtab_name, setup.name)
    if defines.setup[table_name] == nil then defines.setup[table_name] = {offset = 0, alpha = {visible = 0}} end

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Creating a "self" variable for convenience
    local self = defines.setup[table_name]

    -- We get the values of "setup" in the function
    local data = setup

    -- Getting the switch position
    local x, y = subtab_element.x + 4, subtab_element.y + 50 + self.offset - subtab_element.scroll_value

    -- Getting the element width, height
    local w, h = 200, 30

    -- Updating the values that were set in "defines.setup"
    -- Updating the "offset" value so that it is smooth
    self.offset = lerp(self.offset, subtab_element.check and subtab_element.offset or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "alpha.visible", for a smooth appearance of the element
    self.alpha.visible = lerp(self.alpha.visible, subtab_element.check and (setup.visible and 1 or 0) or 0, globalvars.get_frametime() * 20)
    
    render.rect_filled(x + 20, y, 200, 2, color.new(26, 26, 26, window.alpha*255*self.alpha.visible))

    -- Setting the positioning for the remaining elements
    subtab_element.offset = subtab_element.offset + 20
    subtab_element.offset = not setup.visible and subtab_element.offset - 20 or subtab_element.offset

    return data
end

menu.create_label = function(tab_name, subtab_name, subtab_element, setup)
    -- Creating a table in which we create the variables we need
    local table_name = string.format("%s_%s_%s_label", tab_name, subtab_name, setup.name)
    if defines.setup[table_name] == nil then defines.setup[table_name] = {offset = 0, alpha = {visible = 0}} end

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Creating a "self" variable for convenience
    local self = defines.setup[table_name]

    -- We get the values of "setup" in the function
    local data = setup

    -- Getting the switch position
    local x, y = subtab_element.x + 24, subtab_element.y + 50 + self.offset - subtab_element.scroll_value

    -- Getting the element width, height
    local w, h = 200, 30

    -- Updating the values that were set in "defines.setup"
    -- Updating the "offset" value so that it is smooth
    self.offset = lerp(self.offset, subtab_element.check and subtab_element.offset or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "alpha.visible", for a smooth appearance of the element
    self.alpha.visible = lerp(self.alpha.visible, subtab_element.check and (setup.visible and 1 or 0) or 0, globalvars.get_frametime() * 20)
    
    --render.rect_filled(x, y, 50, 10, color.new(84, 84, 84, window.alpha*255*self.alpha.visible))
    render.text(fonts.default, x, y, color.new(84, 84, 84, window.alpha*255*self.alpha.visible), setup.name)

    if setup.right then
        local size = render.get_text_width(fonts.default, setup.text_right)
        --render.rect_filled(x + (240 - 41) - size, y, size, 10, color.new(255, 255, 255, window.alpha*255*self.alpha.visible))
        render.text(fonts.default, x + (240 - 41) - size, y, color.new(255, 255, 255, window.alpha*255*self.alpha.visible), setup.text_right)
    end

    -- Setting the positioning for the remaining elements
    subtab_element.offset = subtab_element.offset + 30
    subtab_element.offset = not setup.visible and subtab_element.offset - 30 or subtab_element.offset

    return data
end

--[[
--
--  Creating a dropdown element for the menu.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: subtab setup {table}
--  @param: element setup {table}
--
]]--
menu.create_dropdown = function(tab_name, subtab_name, subtab_element, setup)
    -- Creating a table in which we create the variables we need
    local table_name = string.format("%s_%s_%s_dropdown", tab_name, subtab_name, setup.name)
    if defines.setup[table_name] == nil then defines.setup[table_name] = {colors = {default = {33, 33, 33, 255}}, alpha = {visible = 0}, divider = 0, offset = 0, open = false, items = {}} end

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Creating a "self" variable for convenience
    local self = defines.setup[table_name]

    -- We get the values of "setup" in the function
    local data = setup

    -- Getting the switch position
    local x, y = subtab_element.x + 23, subtab_element.y + 50 + self.offset - subtab_element.scroll_value

    -- Getting the element width, height
    local w, h = 200, 30

    -- Updating the values that were set in "defines.setup"
    -- Updating the "offset" value so that it is smooth
    self.offset = lerp(self.offset, subtab_element.check and subtab_element.offset or 0, globalvars.get_frametime() * 12)

    -- Updating the variable "alpha.visible", for a smooth appearance of the element
    self.alpha.visible = lerp(self.alpha.visible, subtab_element.check and (setup.visible and 1 or 0) or 0, globalvars.get_frametime() * 20)

    -- Updating the variable "colors.default", for a smooth color change
    self.colors.default = lerp_color(self.colors.default, not self.open and input_system.cursor_in_bounds(x, y + 20, w, h) and {55, 55, 55, 255} or {33, 33, 33, 255}, globalvars.get_frametime() * 12)

    -- We get the colors of the updated variables above
    local dr, dg, db, da = table.unpack(self.colors.default)

    --@region: render
    if self.open and setup.visible and subtab_element.check then
        self.divider = lerp(self.divider, #setup.elements * 27, globalvars.get_frametime() * 8)
        render.rect_filled_rounded(x, y + 50, w, self.divider, 10, 3, color.new(15, 15, 15, window.alpha*255*self.alpha.visible))
        render.rect_rounded(x, y + 50, w, self.divider, color.new(26, 26, 26, window.alpha*255*self.alpha.visible), 3)

        local offset = 0

        for i = 1, #setup.elements do
            local index = setup.elements[i]
            if self.items[index] == nil then self.items[index] = {alpha = 0, color = {255, 255, 255, 80}} end

            self.items[index].alpha = lerp(self.items[index].alpha, setup.value == i and 1 or 0, globalvars.get_frametime() * 12)
            self.items[index].color = lerp_color(self.items[index].color, setup.value == i and {r, g, b, 255} or {255, 255, 255, 60}, globalvars.get_frametime() * 12)

            if input_system.cursor_in_bounds(x + 1, y + 35 + offset + 20, w, 20) then
                if input_system.is_key_pressed(0x01) then
                    setup.value = i
                end
            end

            local scr, scb, scg, sca = table.unpack(self.items[index].color)

            render.rect_filled(x + 1, y + 35 + offset + 20, 2, 20, color.new(r, g, b, window.alpha*255*self.alpha.visible*self.items[index].alpha))
            render.text(fonts.default, x + 10, y + 35 + offset + 22, color.new(scr, scb, scg, window.alpha*sca*self.alpha.visible), index)
            offset = offset + 25
        end
    end

    render.text(fonts.default, x, y, color.new(80, 80, 80, window.alpha*255*self.alpha.visible), setup.name)
    render.rect_filled_rounded(x, y + 20, w, 32, 10, 4, color.new(26, 26, 26, window.alpha*255*self.alpha.visible))
    render.rect_filled_rounded(x + (w - 36), y + 20, 2, 32, 10, 4, color.new(20, 20, 20, window.alpha*255*self.alpha.visible))

    render.text(fonts.default, x + 10, y + 28, color.new(255, 255, 255, window.alpha*255*self.alpha.visible), setup.elements[setup.value])
    render.text(fonts.default_big, x + (w - 36) + (self.open and 15 or 12), y + 26, color.new(80, 80, 80, window.alpha*255*self.alpha.visible), self.open and "-" or "+")
    --@endregion

    if input_system.cursor_in_bounds(x, y + 20, w, h) and input_system.is_key_pressed(0x01) and globalvars.get_curtime() > window.click and setup.visible and subtab_element.check then
        self.open = not self.open;
        window.click = globalvars.get_curtime() + 0.22
    elseif not input_system.cursor_in_bounds(x, y + 20, w, h) and subtab_element.check and setup.visible and not input_system.cursor_in_bounds(x, y + 50, w, (#setup.elements * 25) + 10) and input_system.is_key_pressed(0x01) and not subtab_element.cursor_on_scroll then
        self.open = false
    end

    -- Setting the positioning for the remaining elements
    subtab_element.offset = subtab_element.offset + (self.open and (#setup.elements * 25) + 50 or 40)
    subtab_element.offset = subtab_element.offset + 30
    subtab_element.offset = not setup.visible and subtab_element.offset - 35 * 2 or subtab_element.offset

    return data
end
--@endregion

--@region: auxiliary functions for the menu
--[[
--
--  Function for getting the values of the elements.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: element name {string}
--
]]--
menu.update_binder = function(setup)
    -- We get the values of "setup" in the function
    local data = setup

    if setup.key == nil then
        return false
    else
        if setup.key_state == input_system.state["Disabled"] then
            data.active = false
        elseif setup.key_state == input_system.state["Always"] then
            data.active = true
        elseif setup.key_state == input_system.state["Toggle"] then
            if input_system.is_key_pressed(input_system.keys[setup.key]) then
                data.active = not data.active
            end
        elseif setup.key_state == input_system.state["Hold"] then
            data.active = input_system.is_key_down(input_system.keys[setup.key])
        end
    end

    return data.active
end

--[[
--
--  Function for getting the values of the elements.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: element name {string}
--
]]--
menu.get_value = function(tab, subtab, name, is_hotkey)
    -- We get data from the table "menu.items", which was created above
    -- We get a list of all tabs in the table
    for i = 1, #menu.items[tab][subtab].g_Elements do
        -- Creating a "data" variable for convenience
        local data = menu.items[tab][subtab].g_Elements[i][1]

        -- We make checks for the type of elements
        if data.name == name then
            if data.type == "switch" then
                return data.state
            elseif data.type == "slider" then
                return data.value
            elseif data.type == "textbox" then
                return data.text
            elseif data.type == "dropdown" then
                return data.value
            elseif data.type == "binder" then
                if not is_hotkey then
                    return data.active
                else
                    return {data.key, data.key_state, data.active}
                end
            end
        end
    end
end
        
--[[
--
--  Function for setting values for elements.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: element name {string}
--  @param: value {any value}
--
]]--
menu.set_value = function(tab, subtab, name, value, is_hotkey)
    -- We get data from the table "menu.items", which was created above
    -- We get a list of all tabs in the table
    for i = 1, #menu.items[tab][subtab].g_Elements do
        -- Creating a "data" variable for convenience
        local data = menu.items[tab][subtab].g_Elements[i][1]

        -- We make checks for the type of elements
        if data.name == name then
            if data.type == "switch" then
                data.state = value
            elseif data.type == "slider" then
                data.value = value
            elseif data.type == "textbox" then
                data.text = value
            elseif data.type == "dropdown" then
                data.value = value
            elseif data.type == "label" then
                data.text_right = value
            elseif data.type == "binder" then
                if not is_hotkey then
                    data.active = value
                else
                    data.key = value[1]
                    data.key_state = value[2]
                    data.active = value[3]
                end
            end
        end
    end
end

--[[
--
--  Function for setting visibility for elements.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: element name {string}
--  @param: value {bool}
--
]]--
menu.set_visible = function(tab, subtab, name, value)
    -- We get data from the table "menu.items", which was created above
    -- We get a list of all tabs in the table
    for i = 1, #menu.items[tab][subtab].g_Elements do
        -- Creating a "data" variable for convenience
        local data = menu.items[tab][subtab].g_Elements[i][1]

        -- We make checks for the type of elements
        if data.name == name then
            data.visible = value
        end
    end
end

--[[
--
--  Function for adding items without affecting "menu.items".
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: table {table}
--
]]--
menu.create_new_element = function(tab, subtab, array)
    table.insert(menu.items[tab][subtab].g_Elements, {menu.elements_auto_setup(array)})

    return {tab, subtab, array.name}
end

--[[
--
--  Function for remove items without affecting "menu.items".
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: table index {int}
--
]]--
menu.remove_new_element = function(tab, subtab, index)
    table.remove(menu.items[tab][subtab].g_Elements, index)
end

--[[
--
--  Function for getting the elements of the dropdowns.
--  @param: tab name {string}
--  @param: subtab name {string}
--  @param: element name {string}
--
]]--
menu.get_elements = function(tab, subtab, name)
    -- We get data from the table "menu.items", which was created above
    -- We get a list of all tabs in the table
    for i = 1, #menu.items[tab][subtab].g_Elements do
        -- Creating a "data" variable for convenience
        local data = menu.items[tab][subtab].g_Elements[i][1]

        -- We make checks for the type of elements
        if data.name == name then
            if data.type == "dropdown" then
                return data.elements
            end
        end
    end
end

menu.unpack_value = function(array, is_hotkey)
    return menu.get_value(array[1], array[2], array[3], is_hotkey == nil and false or is_hotkey)
end
--@endregion

--@region: render tabs
--[[
--
--  Function for rendering tabs.
--  @param: x position {int/float}
--  @param: y position {int/float}
--
]]--
tabs.controller = function(x, y)
    -- Creating a variable for easy positioning
    local offset = 0

    -- We get the entire list of tabs from the "menu.tabs" table
    for i = 1, #menu.tabs do
        -- Creating a "data" variable for convenience
        local data = menu.tabs[i]

        -- Creating a table in which we create the variables we need
        local table_name = string.format("%s_tab", data.name)
        if defines.setup[table_name] == nil then defines.setup[table_name] = {colors = {default = {33, 33, 33, 255}, second = {33, 33, 33, 255}}} end

        -- Creating a variable with the main color
        local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

        -- Creating a "self" variable for convenience
        local self = defines.setup[table_name]

        -- Get the name of all tabs
        local name = data.name
        if data.second_name ~= nil then
            name = data.second_name
        end

        -- We make the necessary checks for us
        -- Checking whether the cursor is hovered over a certain area
        -- Checking whether the active tab is equal to the tab from the "menu.tabs" table
        if input_system.cursor_in_bounds(x - 10, y + offset - 10, 210, 39) or tabs.active == data.name then
            -- Making a click check
            if input_system.is_key_pressed(0x01) then
                -- Setting the active tab
                tabs.active = data.name
            end
        end

        -- Updating the variable "colors.default", for a smooth color change
        self.colors.default = lerp_color(self.colors.default, (tabs.active == data.name or input_system.cursor_in_bounds(x - 10, y + offset - 10, 210, 39)) and {255, 255, 255, 100} or {88, 88, 88, 255}, globalvars.get_frametime() * 12)

        -- Updating the variable "colors.second", for a smooth color change
        self.colors.second = lerp_color(self.colors.second, tabs.active == data.name and {33, 33, 33, 150} or {33, 33, 33, 0}, globalvars.get_frametime() * 12)

        -- We get the colors of the updated variables above
        local dr, dg, db, da = table.unpack(self.colors.default)
        local sr, sg, sb, sa = table.unpack(self.colors.second)

        --@region: render
        render.text(fonts.default, x + 10, y + offset + 3, color.new(dr, dg, db, window.alpha*255), name)

        if i ~= #menu.tabs then
            render.rect_filled(x - 10, y + 30 + offset, 210, 1, color.new(44, 44, 44, window.alpha*255))
        end
        --@endregion

        -- Setting the positioning for the remaining tabs
        offset = offset + 40
    end
end
--@endregion

--@region: render window
menu.set_visible("Misc", "General", "Menu x", false); menu.set_visible("Misc", "General", "Menu y", false)
window.render = function()
    -- Creating a "self" variable for convenience
    local self = window.setup

    -- Updating the values that were set in "window.setup"
    -- Updating the "width" variable for a smooth width
    self.animation.width = lerp(self.animation.width, self.style.width, globalvars.get_frametime() * 20)
    -- Updating the "height" variable for a smooth height
    self.animation.height = lerp(self.animation.height, self.style.height, globalvars.get_frametime() * 20)

    -- Creating a variable with the main color
    local r, g, b, a = 183, 150, 255, 255 -- (red, green, blue, transparency(alpha))

    -- Getting the window position
    local x, y = menu.get_value("Misc", "General", "Menu x"), menu.get_value("Misc", "General", "Menu y")

    -- Getting the window width, height
    local w, h = self.animation.width, self.animation.height

    --@region: render
    
    render.blur(x, y, 210, h, window.alpha*255)
    render.rect_filled_rounded(x, y, 210, h, 10, 5, color.new(13, 13, 13, window.alpha*215))
    render.rect_filled_rounded(x, y, 210, 40, 10, 5, color.new(20, 20, 20, window.alpha*255))
    render.rect_filled_rounded(x, y + 39, 210, 2, 10, 5, color.new(r, g, b, window.alpha*255))
    render.rect_filled_rounded(x, y + h - 40, 210, 40, 10, 5, color.new(20, 20, 20, window.alpha*255))
    render.rect_filled_rounded(x, y + h - 40, 210, 2, 10, 5, color.new(44, 44, 44, window.alpha*255))

    render.text(fonts.default_bold, x + (210 / 2) - (render.get_text_width(fonts.default_bold, "NC") / 2), y + 10, color.new(r, g, b, window.alpha*255), "NC")
    render.text(fonts.default, x + 10, y + h - 27, color.new(255, 255, 255, window.alpha*255), globalvars.get_winuser())
    
    render.blur(x + 220, y, w, h, window.alpha*255)
    render.rect_filled_rounded(x + 220, y, w, h, 10, 5, color.new(16, 16, 16, window.alpha*255))
    render.rect_filled_rounded(x + 220, y, w, 40, 10, 5, color.new(20, 20, 20, window.alpha*255))
    render.rect_filled_rounded(x + 220, y + 39, w, 2, 10, 5, color.new(r, g, b, window.alpha*255))

    render.begin_cliprect(x, y, 210, h)
        tabs.controller(x + 10, y + 50)
    render.end_cliprect()

    --@endregion

    -- We get data from the table "menu.items", which was created above
    -- We get a list of all tabs in the table
    for i, d in pairs(menu.items) do
        -- Getting a list of all subtabs in the table
        for k, v in pairs(d) do
            -- Check whether the active tab is equal to the tabs that are in the table
            -- Check if the menu is open
            if tabs.active == i and window.is_open then
                -- Check if the length of childs is greater than 2, then the length increases
                --self.style.width = table.length(d) > 2 and 770 or self.style.width

                -- Check if the childs height is greater than the value set below, then it increases
               -- self.style.height = v.g_Settings.height > 420 and v.g_Settings.height + 80 or self.style.height

                -- Render the child element that was created above
                render.begin_cliprect(x + 220, y, w, h)
                    menu.create_child(tabs.active == i and true or false, v.g_Settings.offset, k, v.g_Settings)
                render.end_cliprect()
                
                -- Getting a list of all elements in the table
                render.begin_cliprect(v.g_Settings.x, v.g_Settings.y + 36, 242, v.g_Settings.height - 36)
                for c = 1, #v.g_Elements do
                    -- Creating a "data" variable for convenience
                    local data = v.g_Elements[c][1]

                    -- We make checks for the type of elements
                    if data.type == "switch" then
                        data.setup = menu.create_switch(i, k, v.g_Settings, data)
                    end
                    if data.type == "slider" then
                        data.setup = menu.create_slider(i, k, v.g_Settings, data)
                    end
                    if data.type == "button" then
                        data.setup = menu.create_button(i, k, v.g_Settings, data)
                    end
                    if data.type == "textbox" then
                        data.setup = menu.create_textbox(i, k, v.g_Settings, data)
                    end
                    if data.type == "binder" then
                        data.setup = menu.create_binder(i, k, v.g_Settings, data)
                    end
                    if data.type == "dropdown" then
                        data.setup = menu.create_dropdown(i, k, v.g_Settings, data)
                    end
                    if data.type == "divider" then
                        data.setup = menu.create_divider(i, k, v.g_Settings, data)
                    end
                    if data.type == "label" then
                        data.setup = menu.create_label(i, k, v.g_Settings, data)
                    end
                end 
                render.end_cliprect()
            end
            -- Getting a list of all elements in the table
            for c = 1, #v.g_Elements do
                -- Creating a "data" variable for convenience
                local data = v.g_Elements[c][1]

                -- We make checks for the type of elements
                if data.type == "binder" then
                    menu.update_binder(data)
                end
            end
        end
    end

    local mouse = {x = engine.get_cursor_position().x, y = engine.get_cursor_position().y}
    if input_system.cursor_in_bounds(x, y, w, 35) then
        if (input_system.is_key_down(0x01)) and (self.dragging[1] == 0) then
            self.dragging[1] = 1;
            self.dragging[2] = menu.get_vlaue("Misc", "General", "Menu x") - mouse.x;
            self.dragging[3] = menu.get_vlaue("Misc", "General", "Menu y") - mouse.y;
        end
    end
    if not input_system.is_key_down(0x01) then self.dragging[1] = 0; end
    if self.dragging[1] == 1 and window.is_open then
        local q = math.max(0, math.min(engine.get_screen_width() - w, mouse.x + self.dragging[2]));
        local r = math.max(0, math.min(engine.get_screen_height() - h, mouse.y + self.dragging[3]));
        menu.set_value("Misc", "General", "Menu x", q)
        menu.set_value("Misc", "General", "Menu y", r)

        window.pos.x = menu.get_value("Misc", "General", "Menu x")
        window.pos.y = menu.get_value("Misc", "General", "Menu y")
    end
end
--@endregion

--@region: rage
-- Conditiona hitchance
conditional_hitchance.air = function()
    if not menu.get_value("Rage", "General", "Enable Ragebot Elements") then
        return
    end

    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    local flags = player:get_prop_int("CBasePlayer", "m_fFlags")
    local is_on_ground = bit.band(flags, bit.lshift(1, 0)) == 0

    ui.set_int("4Ragebot.hitchance_amount", (is_on_ground and menu.get_value("Rage", "General", "Custom Air Hitchance")) and menu.get_value("Rage", "General", "Air Hitchance") or defines.hitchance_cache[1])
    ui.set_int("5Ragebot.hitchance_amount", (is_on_ground and menu.get_value("Rage", "General", "Custom Air Hitchance")) and menu.get_value("Rage", "General", "Air Hitchance") or defines.hitchance_cache[2])
    ui.set_int("6Ragebot.hitchance_amount", (is_on_ground and menu.get_value("Rage", "General", "Custom Air Hitchance")) and menu.get_value("Rage", "General", "Air Hitchance") or defines.hitchance_cache[3])
end

-- Freestand on key
freestand_on_key.cache = ui.get_bool("Antiaim.freestand")
freestand_on_key.handle = function()
    ui.set_bool("Antiaim.freestand", menu.get_value("Rage", "General", "Freestand on key") or freestand_on_key.cache)
end

--@region: anti-aim
-- Tank AA
anti_aim_controller.tank = function()
    if not menu.get_value("Rage", "Anti-Aim", "Enable Anti-Aim Elements") then
        return
    end

    if menu.get_value("Rage", "Anti-Aim", "Anti-Aim preset") ~= 2 then
        return
    end

    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    local flags = player:get_prop_int("CBasePlayer", "m_fFlags")

    local is_crouching = bit.band(flags, bit.lshift(1, 1)) ~= 0
    local on_ground = bit.band(flags, bit.lshift(1, 0)) ~= 0

    local brute_time_remains = clamp((anti_bruteforce.reset_time - globalvars.get_realtime()) / anti_bruteforce.timer, 0, 1)

    if ui.get_keybind_state(keybinds.slowwalk) then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 3)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 60)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 58)
            ui.set_int("0Antiaim.inverted_desync_range", 58)
        end
    elseif on_ground and is_crouching then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 3)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 42)
        ui.set_int("0Antiaim.desync", 1)
        ui.set_int("0Antiaim.body_lean", 23)
        ui.set_int("0Antiaim.inverted_body_lean", 23)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", math.random(8, 12))
            ui.set_int("0Antiaim.inverted_desync_range", math.random(8, 12))
        end
    elseif not on_ground then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 25)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    elseif not is_crouching and on_ground and player:get_velocity():length_2d() > 10 then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 79)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    else
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 0)
        ui.set_int("0Antiaim.range", 25)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    end
end

-- Default
anti_aim_controller.type_1 = function()
    if not menu.get_value("Rage", "Anti-Aim", "Enable Anti-Aim Elements") then
        return
    end

    if menu.get_value("Rage", "Anti-Aim", "Anti-Aim preset") ~= 3 then
        return
    end

    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    local flags = player:get_prop_int("CBasePlayer", "m_fFlags")

    local is_crouching = bit.band(flags, bit.lshift(1, 1)) ~= 0
    local on_ground = bit.band(flags, bit.lshift(1, 0)) ~= 0

    local brute_time_remains = clamp((anti_bruteforce.reset_time - globalvars.get_realtime()) / anti_bruteforce.timer, 0, 1)

    if ui.get_keybind_state(keybinds.slowwalk) then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", -10)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 58)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    elseif on_ground and is_crouching then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 0)
        ui.set_int("0Antiaim.range", 60)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    elseif not on_ground then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", -10)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 10)
        ui.set_int("0Antiaim.desync", 2)

        ui.set_int("0Antiaim.body_lean", 41)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    elseif not is_crouching and on_ground and player:get_velocity():length_2d() > 10 then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 58)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 41)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 1)
            ui.set_int("0Antiaim.inverted_desync_range", 1)
        end
    else
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 60)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    end
end

-- Alternative
anti_aim_controller.alternative = function()
    if not menu.get_value("Rage", "Anti-Aim", "Enable Anti-Aim Elements") then
        return
    end

    if menu.get_value("Rage", "Anti-Aim", "Anti-Aim preset") ~= 5 then
        return
    end

    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    local flags = player:get_prop_int("CBasePlayer", "m_fFlags")

    local is_crouching = bit.band(flags, bit.lshift(1, 1)) ~= 0
    local on_ground = bit.band(flags, bit.lshift(1, 0)) ~= 0

    local brute_time_remains = clamp((anti_bruteforce.reset_time - globalvars.get_realtime()) / anti_bruteforce.timer, 0, 1)

    if ui.get_keybind_state(keybinds.slowwalk) then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 5)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 0)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 79)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", math.random(30, 45))
            ui.set_int("0Antiaim.inverted_desync_range", math.random(30, 45))
        end
    elseif on_ground and is_crouching then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", math.random(5, -10))
        ui.set_int("0Antiaim.yaw", 0)
        ui.set_int("0Antiaim.range", 0)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 79)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", math.random(30, 45))
            ui.set_int("0Antiaim.inverted_desync_range", math.random(30, 45))
        end
    elseif not on_ground then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 25)
        ui.set_int("0Antiaim.desync", 2)

        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    elseif not is_crouching and on_ground and player:get_velocity():length_2d() > 10 then
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 79)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    else
        ui.set_int("0Antiaim.pitch", 1)
        ui.set_int("0Antiaim.base_angle", 1)
        ui.set_int("Antiaim.yaw_offset", 0)
        ui.set_int("0Antiaim.yaw", 1)
        ui.set_int("0Antiaim.range", 25)
        ui.set_int("0Antiaim.desync", 2)
        ui.set_int("0Antiaim.body_lean", 0)
        ui.set_int("0Antiaim.inverted_body_lean", 0)

        if brute_time_remains <= 0 then
            ui.set_int("0Antiaim.desync_range", 60)
            ui.set_int("0Antiaim.inverted_desync_range", 60)
        end
    end
end

--conditional aa
local anti_aim = {}

for i = 1, #player_states do
    anti_aim[i] = {
        enable = i == 6 and menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Enable", type = "binder"}) or menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]) .."] Enable", type = "switch"}),
        
        pitch = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Pitch", type = "dropdown", elements = {"None", "Minimal", "Maximal"}}),
        target_yaw = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Target yaw", type = "dropdown", elements = {"Local view", "At targets"}}),
        yaw_offset = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Yaw offset", type = "slider", min = -180, max = 180}),
        yaw_modifier = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Yaw modifier", type = "dropdown", elements = {"Static", "Jitter", "Spin"}}),
        jitter_range = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Jitter range", type = "slider", min = 1, max = 180}),
        spin_range = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Spin range", type = "slider", min = 1, max = 180}),
        spin_speed = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Spin speed", type = "slider", min = 1, max = 15}),

        desync_type = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Desync type", type = "dropdown", elements = {"None", "Static", "Jitter"}}),
        desync_range = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Desync range", type = "slider", min = 1, max = 60}),
        inv_desync_range = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Inverted desync range", type = "slider", min = 1, max = 60}),
        body_lean = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Body lean", type = "slider", min = 0, max = 100}),
        inv_body_lean = menu.create_new_element("Rage", "Anti-Aim", {name = "[".. string.lower(player_states[i]):sub(1, 2):upper() .."] Inverted body lean", type = "slider", min = 0, max = 100}),
    }
end

conditional_anti_aim.handle = function()
    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    local velocity = player:get_velocity():length_2d()
    local p_still = velocity < 2
    
    local flags = player:get_prop_int("CBasePlayer", "m_fFlags")
    
    local is_crouching = bit.band(flags, bit.lshift(1, 1)) ~= 0
    local on_ground = bit.band(flags, bit.lshift(1, 0)) == 0

    local brute_time_remains = clamp((anti_bruteforce.reset_time - globalvars.get_realtime()) / anti_bruteforce.timer, 0, 1)

    local p_slow = ui.get_keybind_state(keybinds.slowwalk)
    local p_key = menu.get_value(anti_aim[6].enable[1], anti_aim[6].enable[2], anti_aim[6].enable[3])

    p_state = 1
    if p_key then
        p_state = 6
    else
        if on_ground and menu.unpack_value(anti_aim[5].enable) then
            p_state = 5
        else
            if p_slow and menu.unpack_value(anti_aim[4].enable) then
                p_state = 4
            else
                if p_still and menu.unpack_value(anti_aim[2].enable) then
                    p_state = 2
                elseif not p_still and menu.unpack_value(anti_aim[3].enable) then
                    p_state = 3
                end
            end
        end
    end

    if menu.get_value("Rage", "Anti-Aim", "Anti-Aim preset") == 4 then
        if menu.unpack_value(anti_aim[p_state].enable) then
            ui.set_bool("Antiaim.enable", menu.unpack_value(anti_aim[p_state].enable))
            ui.set_int("0Antiaim.pitch", menu.unpack_value(anti_aim[p_state].pitch) - 1)
            ui.set_int("0Antiaim.base_angle", menu.unpack_value(anti_aim[p_state].target_yaw) - 1)
            ui.set_int("Antiaim.yaw_offset", menu.unpack_value(anti_aim[p_state].yaw_offset))
            ui.set_int("0Antiaim.yaw", menu.unpack_value(anti_aim[p_state].yaw_modifier) - 1)

            if menu.unpack_value(anti_aim[p_state].yaw_modifier) == 2 then
                ui.set_int("0Antiaim.range", menu.unpack_value(anti_aim[p_state].jitter_range))
            elseif menu.unpack_value(anti_aim[p_state].yaw_modifier) == 3 then
                ui.set_int("0Antiaim.range", menu.unpack_value(anti_aim[p_state].spin_range))
                ui.set_int("0Antiaim.speed", menu.unpack_value(anti_aim[p_state].spin_speed))
            end

            ui.set_int("0Antiaim.desync", menu.unpack_value(anti_aim[p_state].desync_type) - 1)

            if brute_time_remains <= 0 then
                ui.set_int("0Antiaim.desync_range", menu.unpack_value(anti_aim[p_state].desync_range))
                ui.set_int("0Antiaim.inverted_desync_range", menu.unpack_value(anti_aim[p_state].inv_desync_range))
            end

            ui.set_int("0Antiaim.body_lean", menu.unpack_value(anti_aim[p_state].body_lean))
            ui.set_int("0Antiaim.inverted_body_lean", menu.unpack_value(anti_aim[p_state].inv_body_lean))
        end
    end
end

-- Legspammer
leg_spammer.speed = 2
leg_spammer.tick = globalvars.get_tickcount()

leg_spammer.handle = function()
    if not menu.get_value("Rage", "Anti-Aim", "Enable Anti-Aim Elements") then
        return
    end

    if not menu.get_value("Rage", "Anti-Aim", "Enable Leg Spammer") then
        return
    end
    
    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    if (globalvars.get_tickcount() - leg_spammer.tick) > leg_spammer.speed then
        if ui.get_int("Misc.leg_movement") ~= 0 then
            ui.set_int("Misc.leg_movement", 0)
        else
            ui.set_int("Misc.leg_movement", menu.get_value("Rage", "Anti-Aim", "Leg Spammer Type"))
        end

        leg_spammer.tick = globalvars.get_tickcount()
    end
end

-- Anti-Backstab
anti_backstab.get_players_with_knife = function()
    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    local is_enemy = function(entity) if entity:get_team() ~= player:get_team() then return true; end; return false; end
    local ret = {}

    for i = 1, globalvars.get_maxclients() do
        local players = entitylist.get_player_by_index(engine.get_player_for_user_id(i))
        local player_active_weapon = entitylist.get_weapon_by_player(players)
        if is_enemy(players) and players:is_alive() and weapon.get_name(player_active_weapon) == "KNIFE" then
            table.insert(ret, players)
        end
    end

    return ret
end

anti_backstab.cache = {
    pitch = ui.get_int("0Antiaim.pitch"), 
    yaw_offset = ui.get_int("Antiaim.yaw_offset"), 
    base_angle = ui.get_int("0Antiaim.base_angle")
}

anti_backstab.handle = function()
    if not menu.get_value("Rage", "Anti-Aim", "Enable Anti-Aim Elements") then
        return
    end

    if not menu.get_value("Rage", "Anti-Aim", "Enable Anti-Backstab") then
        return
    end
    
    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    local enemies = anti_backstab.get_players_with_knife()

    if #enemies < 1 then
        ui.set_int("Antiaim.yaw_offset", anti_backstab.cache.yaw_offset)
        ui.set_int("0Antiaim.pitch", anti_backstab.cache.pitch)
        ui.set_int("0Antiaim.base_angle", anti_backstab.cache.base_angle)
    end

    if not enemies or #enemies < 0 then 
        return 
    end

    local min_dist = menu.get_value("Rage", "Anti-Aim", "Anti-Backstab Distance")
    for i = 1, #enemies do
        local enemy = enemies[i]

        local pos = enemy:get_absorigin()
        local l_pos = player:get_absorigin()
        local dist = pos:dist_to(l_pos)

        if min_dist >= dist then
            ui.set_int("Antiaim.yaw_offset", 180)
            ui.set_int("0Antiaim.pitch", 0)
            ui.set_int("0Antiaim.base_angle", 0)
        else
            ui.set_int("Antiaim.yaw_offset", anti_backstab.cache.yaw_offset)
            ui.set_int("0Antiaim.pitch", anti_backstab.cache.pitch)
            ui.set_int("0Antiaim.base_angle", anti_backstab.cache.base_angle)
        end
    end
end
--@endregion
--@endregion

--@region: visuals
visual_controller.create_window = function(x, y, w, h, color)
    local r, g, b, a = color:r(), color:g(), color:b(), color:a()

    render.blur(x, y, w, h, (255 / 255) * a)
    render.rect_filled_rounded(x, y, w, h, 10, 5, color.new(0, 0, 0, (50 / 255) * a))
    render.rect_rounded(x, y, w, h, color.new(r, g, b, (50 / 255) * a), 5)
    render.rect_filled(x + 3, y, w - 6, 1, color.new(r, g, b, (255 / 255) * a))

    render.line(x + 3, y, x, y + 2, color.new(r, g, b, (255 / 255) * a))
    render.line(x + (w - 5), y, x + (w - 1), y + 1, color.new(r, g, b, (255 / 255) * a))

    render.gradient(x, y + 2, 1, h - 5, color.new(r, g, b, a), color.new(r, g, b, 0), 1)
    render.gradient(x + w - 1, y + 2, 1, h - 5, color.new(r, g, b, a), color.new(r, g, b, 0), 1)

    render.rect_shadow(x + 2, y + 2, w - 4, h - 4, (5 / 255) * a, color.new(r, g, b, (255 / 255) * a))
end

-- Watermark
visual_controller.watermark = {alpha = 0, width = 0}
visual_controller.watermark.handle = function()
    local self = visual_controller.watermark
    self.alpha = lerp(self.alpha, menu.get_value("Visuals", "General", "Enable Watermark") and 1 or 0, globalvars.get_frametime() * 12)
    if self.alpha < 0.2 then return end

    local r, g, b, a = 183, 150, 255, 255

    local data_nickname = engine.get_gamename()
    local text = string.format("necron %s %s", data_nickname, globalvars.get_time())
    if engine.is_in_game() then
        local latency = globalvars.get_ping()
        local latency_text = latency > 5 and ("delay: %dms "):format(latency) or ""

        text = string.format("necron %s %s%s", data_nickname, latency_text, globalvars.get_time())
    end

    self.width = lerp(self.width, render.get_text_width(fonts.small, text) + 10, globalvars.get_frametime() * 12)
    local h, w = 22, self.width
    local x, y = engine.get_screen_width(), 8
    x = x - w - 10

    --@region: render
    if menu.get_value("Visuals", "General", "Windows Style") == 1 then
        visual_controller.create_window(x, y, w, h, color.new(r, g, b, self.alpha*255))
    elseif menu.get_value("Visuals", "General", "Windows Style") == 2 then
        render.rect_filled_rounded(x, y, w, 25, 10, 3, color.new(20, 16, 16, self.alpha*255))
        render.rect_filled(x, y + 23, w, 3, color.new(20, 16, 16, self.alpha*255))
    end

    y = menu.get_value("Visuals", "General", "Windows Style") == 2 and y + 2 or y

    render.text(fonts.small, x + 5, y + 3, color.new(255, 255, 255, self.alpha*255), "nec")
    render.text(fonts.small, x + 5 + render.get_text_width(fonts.small, "nec"), y + 3, menu.get_value("Visuals", "General", "Windows Style") == 2 and color.new(255, 255, 255, self.alpha*255) or color.new(r, g, b, self.alpha*255), "ron")
    render.text(fonts.small, x + 5 + render.get_text_width(fonts.small, "necron"), y + 3, color.new(255, 255, 255, self.alpha*255), text:gsub("necron", ""), false, false)
    --@endregion
end

-- Fake indication
visual_controller.fake = {alpha = 0, width = 0, offset = 0, fake_value = 0}
visual_controller.fake.handle = function()
    local self = visual_controller.fake

    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    self.alpha = lerp(self.alpha, menu.get_value("Visuals", "General", "Enable Fake Indication") and 1 or 0, globalvars.get_frametime() * 12)

    if self.alpha <= 0.2 then 
        return 
    end

    local r, g, b, a = 183, 150, 255, 255

    local body_yaw = antiaim.get_body_yaw(ui.get_keybind_state(keybinds.flip_desync))
    local body_yaw_aa = math.max(-60, math.min(60, math.round(body_yaw, 1)))
    local body_yaw_abs = math.abs(body_yaw_aa)

    self.fake_value = lerp(self.fake_value, math.floor(math.round(body_yaw_abs, 0)), globalvars.get_frametime() * 2)
    self.offset = lerp(self.offset, menu.get_value("Visuals", "General", "Enable Watermark") and 28 or 0, globalvars.get_frametime() * 12)

    local text = string.format("%sFAKE (%.1f°)", "\x20\x20\x20\x20\x20", self.fake_value)

    self.width = lerp(self.width, render.get_text_width(fonts.small, text) + 10, globalvars.get_frametime() * 12)

    local w, h = self.width, 22
    local x, y = engine.get_screen_width(), 8 + self.offset
    x = x - w - 10
    y = menu.get_value("Visuals", "General", "Windows Style") == 2 and y + 3 or y

    --@region: render
    if menu.get_value("Visuals", "General", "Windows Style") == 1 then
        visual_controller.create_window(x, y, w, h, color.new(r, g, b, self.alpha*255))
    elseif menu.get_value("Visuals", "General", "Windows Style") == 2 then
        render.rect_filled_rounded(x, y, w, h, 10, 3, color.new(20, 16, 16, self.alpha*150))
    end

    render.text(fonts.small, x + 5, y + 4, color.new(255, 255, 255, self.alpha*255), text)

    render.arc(x + 13, y + 10, 4, 6, 0, self.fake_value / 58 * 360, color.new(r, g, b, self.alpha*255))
    --@endregion
end

-- Keybinds
visual_controller.keybinds = {height = 0, width = 0, alpha = 0, modes = {"always", "holding", "toggled", "disabled"}, active = {}, dragging = {0, 0, 0},
    list = {
        {name = "Minimum damage", key = keybinds.damage_override},
        {name = "Double tap", key = keybinds.double_tap},
        {name = "On shot anti-aim", key = keybinds.hide_shots},
        {name = "Slow motion", key = keybinds.slowwalk},
        {name = "Anti-aim inverter", key = keybinds.flip_desync},
        {name = "Duck peek assist", key = keybinds.fakeduck},
        {name = "Quick peek assist", key = keybinds.automatic_peek},
        {name = "Body aim", key = keybinds.body_aim},
        {name = "Freestand", path = {"Rage", "General", "Freestand on key"}},
    }
}

menu.set_visible("Misc", "General", "Keys x", false)
menu.set_visible("Misc", "General", "Keys y", false)

visual_controller.keybinds.handle = function()
    local self = visual_controller.keybinds

    self.alpha = lerp(self.alpha, menu.get_value("Visuals", "General", "Enable Keybinds") and 1 or 0, globalvars.get_frametime() * 12)

    if self.alpha <= 0.2 then 
        return 
    end

    local maximum_offset = 66
    local elems = 0
    
    for c_id, c_data in pairs(self.list) do
        local item_active = ui.get_keybind_state(c_data.key)
        item_active = (c_data.key == nil and c_data.path ~= nil) and menu.get_value(c_data.path[1], c_data.path[2], c_data.path[3]) or item_active

        if item_active then
            elems = elems + 20
            if self.active[c_id] == nil then
                self.active[c_id] = {
                    mode = "", alpha = 0, offset = 0, active = true, name = ""
                }
            end

            local text_width = render.get_text_width(fonts.small, c_data.name)
            
            self.active[c_id].name = c_data.name
            self.active[c_id].active = true
            self.active[c_id].offset = text_width
            self.active[c_id].mode = self.modes[(c_data.key == nil and c_data.path ~= nil) and menu.get_value(c_data.path[1], c_data.path[2], c_data.path[3], true)[2] or (ui.get_keybind_mode(c_data.key) + 2)]
            self.active[c_id].alpha = lerp(self.active[c_id].alpha, 1, globalvars.get_frametime() * 12)

            if self.active[c_id].alpha > 1 then
                self.active[c_id].alpha = 1
            end
        elseif self.active[c_id] ~= nil then
            self.active[c_id].active = false
            self.active[c_id].alpha = lerp(self.active[c_id].alpha, 0, globalvars.get_frametime() * 12)

            if self.active[c_id].alpha < 0.1 then
                self.active[c_id] = nil
                elems = elems - 1
            end
        end

        if self.active[c_id] ~= nil and self.active[c_id].offset > maximum_offset then
            maximum_offset = self.active[c_id].offset
        end
    end

    local text = "keybinds"
    local x, y = menu.get_value("Misc", "General", "Keys x"), menu.get_value("Misc", "General", "Keys y")
    local r, g, b, a = 183, 150, 255, 255

    local height_offset = 23; self.width = lerp(self.width, 75 + maximum_offset, globalvars.get_frametime() * 12)
    local w, h = self.width, 22
    self.height = lerp(self.height, elems, globalvars.get_frametime() * 12)

    if menu.get_value("Visuals", "General", "Windows Style") == 1 then
        visual_controller.create_window(x, y, w, h, color.new(r, g, b, self.alpha*255))
        render.text(fonts.small, x - render.get_text_width(fonts.small, text) / 2 + w/2, y + 4, color.new(255, 255, 255, self.alpha*255), text)

    elseif menu.get_value("Visuals", "General", "Windows Style") == 2 then

        render.rect_filled_rounded(x, y, w, 25, 10, 3, color.new(20, 16, 16, self.alpha*255))
        render.rect_filled(x, y + 23, w, 3, color.new(20, 16, 16, self.alpha*255))
        render.text(fonts.small, x + 15, y + 5, color.new(255, 255, 255, self.alpha*255), text)

        render.rect_filled_rounded(x, y + 25, w, self.height, 10, 3, color.new(20, 16, 16, self.alpha*150))
    end

    for c_name, c_ref in pairs(self.active) do
        local key_type = "[" .. (c_ref.mode or "?") .. "]"
        key_type = menu.get_value("Visuals", "General", "Windows Style") == 2 and (c_ref.mode or "?") or key_type

        if menu.get_value("Visuals", "General", "Windows Style") == 1 then
            render.text(fonts.small, x + 5, y + height_offset + 2, color.new(255, 255, 255, self.alpha*c_ref.alpha*255), c_ref.name, true)
            render.text(fonts.small, x + w - render.get_text_width(fonts.small, key_type) - 5, y + height_offset + 2, color.new(255, 255, 255, self.alpha*c_ref.alpha*255), key_type, true)
        elseif menu.get_value("Visuals", "General", "Windows Style") == 2 then
            render.begin_cliprect(x, y + 25, w, self.height)
                render.text(fonts.small, x + 5, y + height_offset + 5, color.new(255, 255, 255, self.alpha*c_ref.alpha*255), c_ref.name)
                render.text(fonts.small, x + w - render.get_text_width(fonts.small, key_type) - 5, y + height_offset + 5, color.new(255, 255, 255, self.alpha*c_ref.alpha*255), key_type)
            render.end_cliprect()
        end

        height_offset = height_offset + (menu.get_value("Visuals", "General", "Windows Style") == 2 and 20 or 15) * c_ref.alpha
    end

    local mouse = {x = engine.get_cursor_position().x, y = engine.get_cursor_position().y}
    if input_system.cursor_in_bounds(x, y, w, 20) then
        if (input_system.is_key_down(0x01)) and (self.dragging[1] == 0) then
            self.dragging[1] = 1;
            self.dragging[2] = menu.get_value("Misc", "General", "Keys x") - mouse.x;
            self.dragging[3] = menu.get_value("Misc", "General", "Keys y") - mouse.y;
        end
    end
    if not input_system.is_key_down(0x01) then self.dragging[1] = 0; end
    if self.dragging[1] == 1 and window.is_open then
        local q = math.max(0, math.min(engine.get_screen_width() - w, mouse.x + self.dragging[2]));
        local r = math.max(0, math.min(engine.get_screen_height() - 20, mouse.y + self.dragging[3]));
        menu.set_value("Misc", "General", "Keys x", q)
        menu.set_value("Misc", "General", "Keys y", r)
    end
end

-- On-Screen Indicators
visual_controller.default = {fake_value = 0, alpha = {manual = 0, default = 0, brute = 0}, offset = 0, binds_alp = {}, binds = {
    {key = keybinds.double_tap, name = "DT", color = {87, 232, 87, 255}},
    {key = keybinds.damage_override, name = "DMG", color = {87, 232, 87, 255}},
    {key = keybinds.hide_shots, name = "ON-SHOT", color = {87, 232, 87, 255}}
}}

visual_controller.default.handle = function()
    if menu.get_value("Visuals", "General", "On-Screen Indicators") ~= 2 then
        return
    end

    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    local self = visual_controller.default

    local r, g, b, a = 183, 150, 255, 255

    local sx, sy = engine.get_screen_width(), engine.get_screen_height()
    local x, y = sx / 2, sy / 2 

    local body_yaw = antiaim.get_body_yaw(ui.get_keybind_state(keybinds.flip_desync))
    local body_yaw_aa = math.max(-60, math.min(60, math.round(body_yaw, 1)))
    local body_yaw_abs = math.abs(body_yaw_aa)

    local brute_time_remains = clamp((anti_bruteforce.reset_time - globalvars.get_realtime()) / anti_bruteforce.timer, 0, 1)

    self.offset = lerp(self.offset, brute_time_remains > 0 and 7 or 0, globalvars.get_frametime() * 8)
    self.fake_value = lerp(self.fake_value, math.floor(math.round(body_yaw_abs, 0)), globalvars.get_frametime() * 2)
    self.alpha.manual = lerp(self.alpha.manual, (ui.get_keybind_state(keybinds.manual_left) or ui.get_keybind_state(keybinds.manual_right)) and 1 or 0, globalvars.get_frametime() * 8)
    self.alpha.default = lerp(self.alpha.default, (ui.get_keybind_state(keybinds.manual_left) or ui.get_keybind_state(keybinds.manual_right)) and 0 or 1, globalvars.get_frametime() * 8)
    self.alpha.brute = lerp(self.alpha.brute, brute_time_remains > 0 and 1 or 0, globalvars.get_frametime() * 8)

    --@region: render
    if ui.get_keybind_state(keybinds.manual_left) or ui.get_keybind_state(keybinds.manual_right) then
        render.text(fonts.default, x - render.get_text_width(fonts.default, "MANUAL AA") / 2, y + 42, color.new(255, 255, 255, self.alpha.manual*255), "MANUAL AA", true, false)
    else
        render.text(fonts.default, x - render.get_text_width(fonts.default, "NECRON YAW") / 2, y + 42, body_yaw > 10 and color.new(r, g, b, self.alpha.default*255) or color.new(255, 255, 255, self.alpha.default*255), "NECRON", true, false)
        render.text(fonts.default, x + render.get_text_width(fonts.default, "NECRON YAW") / 2 - render.get_text_width(fonts.default, "YAW"), y + 42, body_yaw < -10 and color.new(r, g, b, self.alpha.default*255) or color.new(255, 255, 255, self.alpha.default*255), "YAW", true, false)
    end

    render.text(fonts.default, x - render.get_text_width(fonts.default, math.floor(self.fake_value).."°") / 2, y + 23, color.new(255, 255, 255, 255), math.floor(self.fake_value).."°", true, false)
    render.gradient(x - 1, y + 40, self.fake_value, 1, color.new(r, g, b, 255), color.new(r, g, b, 0), 0)
    render.gradient(x - self.fake_value + 1, y + 40, self.fake_value, 1, color.new(r, g, b, 0), color.new(r, g, b, 255), 0)

    if brute_time_remains > 0 then
        render.rect_filled(x - 25, y + 60, 50, 3, color.new(17, 17, 17, 255))
        render.rect_filled(x - 25 + 1, y + 60 + 1, 50 * brute_time_remains - 2, 1, color.new(r, g, b, 255))
    end

    local offset = self.offset
    for c_key, c_value in ipairs(self.binds) do
        if self.binds_alp[c_value] == nil then self.binds_alp[c_value] = {alpha = 0} end
        self.binds_alp[c_value].alpha = lerp(self.binds_alp[c_value].alpha, ui.get_keybind_state(c_value.key) and 1 or 0, globalvars.get_frametime() * 12)

        local alpha = self.binds_alp[c_value].alpha
        local r, g, b, a = table.unpack(c_value.color)

        render.text(fonts.default, x - render.get_text_width(fonts.default, c_value.name) / 2, y + 57 + offset, color.new(r, g, b, alpha*255), c_value.name, true, false)

        offset = offset + 14 * alpha
    end
    --@endregion
end

-- Anti-Backstab radius
visual_controller.backstab_radius = function()
    if not menu.get_value("Rage", "Anti-Aim", "Enable Anti-Aim Elements") then
        return
    end

    if not menu.get_value("Rage", "Anti-Aim", "Enable Anti-Backstab") then
        return
    end

    if not menu.get_value("Visuals", "General", "Anti-Backstab Radius") then
        return
    end
    
    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    if not player:is_alive() then
        return
    end

    local r, g, b, a = 183, 150, 255, 255

    local pos = player:get_absorigin()
    local min_dist = menu.get_value("Rage", "Anti-Aim", "Anti-Backstab Distance")

    --@region: render
    render.circle_filled_3d(pos, min_dist, color.new(r, g, b, 100))
    render.circle_3d(pos, min_dist, color.new(r, g, b, 255))
    --@endregion
end

--@endregion
--@endregion

--@region: misc
-- Custom hitsound
events.register_event("player_hurt", function(event)
    if not menu.get_value("Misc", "General", "Enable Custom Hitsound") then
        return
    end
    
    local attacker = entitylist.get_player_by_index(engine.get_player_for_user_id(event:get_int("attacker")))

    if not attacker then
        return
    end

    local player = entity_helpers.local_player.pointer()
    
    if not player then
        return
    end

    if attacker ~= player then
        return
    end

    local name = menu.get_value("Misc", "General", "Hitsound Name")
    local volume = menu.get_value("Misc", "General", "Hitsound Volume")

    console.execute_client_cmd(string.format("playvol %s.wav %s", name, volume / 100))
end)

-- Custom clantag
clan_tag.default = function()
    if cmd.get_choked_commands() ~= 0 then
        return
    end

    if menu.get_value("Misc", "General", "Clantag") ~= 2 then
        return
    end

    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    engine.set_clantag("necron")
end

local old_text
clan_tag.custom = function()
    if cmd.get_choked_commands() ~= 0 then
        return
    end

    if menu.get_value("Misc", "General", "Clantag") ~= 3 then
        return
    end

    local player = entity_helpers.local_player.pointer()

    if player == nil then
        return
    end

    local clantag = {
        text = menu.get_value("Misc", "General", "Clantag Text"),
        animation = menu.get_elements("Misc", "General", "Clantag Animation")[menu.get_value("Misc", "General", "Clantag Animation")],
        speed = menu.get_value("Misc", "General", "Clantag Speed")
    }
    
    local animation = defines.clantag_animations[clantag.animation]
    local tag_length = clantag.text:len()
    tag_index = math.floor((globalvars.get_curtime() * clantag.speed / 10) % tag_length + 1)
    tag_reverse = math.floor((globalvars.get_curtime() * clantag.speed / 10) % (tag_length * 2) + 1);
    local text = animation(clantag)

    if (old_text ~= text) then
        engine.set_clantag(text)
        old_text = text
    end
end
--@endregion

--@region: visible
visible_controller.default_update = function()
    menu.set_visible("Brute", "General", "phases (not vis)", false)
end; visible_controller.default_update()

visible_controller.global_update = function()
    local rage =  menu.get_value("Rage", "General", "Enable Ragebot Elements")
    local anti_aim_state = menu.get_value("Rage", "Anti-Aim", "Enable Anti-Aim Elements")

    menu.set_visible("Rage", "General", "Custom Air Hitchance", rage)
    menu.set_visible("Rage", "General", "Air Hitchance", rage and menu.get_value("Rage", "General", "Custom Air Hitchance"))
    menu.set_visible("Rage", "General", "Freestand on key", rage)

    menu.set_visible("Rage", "Anti-Aim", "Enable Anti-Backstab", anti_aim_state)
    menu.set_visible("Rage", "Anti-Aim", "Anti-Backstab Distance", anti_aim_state and menu.get_value("Rage", "Anti-Aim", "Enable Anti-Backstab"))

    menu.set_visible("Rage", "Anti-Aim", "Enable Leg Spammer", anti_aim_state)
    menu.set_visible("Rage", "Anti-Aim", "Leg Spammer Type", anti_aim_state and menu.get_value("Rage", "Anti-Aim", "Enable Leg Spammer"))

    menu.set_visible("Rage", "Anti-Aim", "Anti-Aim preset", anti_aim_state)

    menu.set_visible("Misc", "General", "Clantag Reset", menu.get_value("Misc", "General", "Clantag") ~= 1)
    menu.set_visible("Misc", "General", "Clantag Text", menu.get_value("Misc", "General", "Clantag") == 3)
    menu.set_visible("Misc", "General", "Clantag Animation", menu.get_value("Misc", "General", "Clantag") == 3)
    menu.set_visible("Misc", "General", "Clantag Speed", menu.get_value("Misc", "General", "Clantag") == 3)

    menu.set_visible("Misc", "General", "Hitsound Name", menu.get_value("Misc", "General", "Enable Custom Hitsound"))
    menu.set_visible("Misc", "General", "Hitsound Volume", menu.get_value("Misc", "General", "Enable Custom Hitsound"))

    menu.set_visible("Rage", "Anti-Aim", "Trigger", anti_aim_state and menu.get_value("Rage", "Anti-Aim", "Anti-Aim preset") == 4)

    active_i = menu.get_value("Rage", "Anti-Aim", "Trigger")
    for i = 1, #player_states do
        local self = anti_aim[i]
        local def = anti_aim_state and menu.get_value("Rage", "Anti-Aim", "Anti-Aim preset") == 4
        local enb = menu.get_value(self.enable[1], self.enable[2], self.enable[3])

        menu.set_visible(self.enable[1], self.enable[2], self.enable[3], active_i == i and i > 0 and def)
        menu.set_visible(self.pitch[1], self.pitch[2], self.pitch[3], enb and active_i == i and def)
        menu.set_visible(self.target_yaw[1], self.target_yaw[2], self.target_yaw[3], enb and active_i == i and def)
        menu.set_visible(self.yaw_offset[1], self.yaw_offset[2], self.yaw_offset[3], enb and active_i == i and def)

        menu.set_visible(self.yaw_modifier[1], self.yaw_modifier[2], self.yaw_modifier[3], enb and active_i == i and def)
        menu.set_visible(self.jitter_range[1], self.jitter_range[2], self.jitter_range[3], enb and active_i == i and def and menu.get_value(self.yaw_modifier[1], self.yaw_modifier[2], self.yaw_modifier[3]) == 2)
        menu.set_visible(self.spin_range[1], self.spin_range[2], self.spin_range[3], enb and active_i == i and def and menu.get_value(self.yaw_modifier[1], self.yaw_modifier[2], self.yaw_modifier[3]) == 3)
        menu.set_visible(self.spin_speed[1], self.spin_speed[2], self.spin_speed[3], enb and active_i == i and def and menu.get_value(self.yaw_modifier[1], self.yaw_modifier[2], self.yaw_modifier[3]) == 3)
    
        menu.set_visible(self.desync_type[1], self.desync_type[2], self.desync_type[3], enb and active_i == i and def)
        menu.set_visible(self.desync_range[1], self.desync_range[2], self.desync_range[3], enb and active_i == i and def and menu.get_value(self.desync_type[1], self.desync_type[2], self.desync_type[3]) ~= 1)
        menu.set_visible(self.inv_desync_range[1], self.inv_desync_range[2], self.inv_desync_range[3], enb and active_i == i and def and menu.get_value(self.desync_type[1], self.desync_type[2], self.desync_type[3]) ~= 1)
        menu.set_visible(self.body_lean[1], self.body_lean[2], self.body_lean[3], enb and active_i == i and def and menu.get_value(self.desync_type[1], self.desync_type[2], self.desync_type[3]) ~= 1)
        menu.set_visible(self.inv_body_lean[1], self.inv_body_lean[2], self.inv_body_lean[3], enb and active_i == i and def and menu.get_value(self.desync_type[1], self.desync_type[2], self.desync_type[3]) ~= 1)
    end
end
--@endregion

--@region: anti-bruteforce
anti_bruteforce.menu_elements = {}

anti_bruteforce.create_new_phase = function()
    if #anti_bruteforce.menu_elements > 11 then return end

    local element = menu.create_new_element("Brute", "Phases", {name = "Fake Limit Phase " .. (#anti_bruteforce.menu_elements + 1), type = "slider", min = -60, max = 60, value = 0})
    
    table.insert(anti_bruteforce.menu_elements, element)
    menu.set_value("Brute", "General", "phases (not vis)", #anti_bruteforce.menu_elements)
end

anti_bruteforce.remove_phase = function()
    if #anti_bruteforce.menu_elements <= 2 then return end

    menu.remove_new_element(anti_bruteforce.menu_elements[#anti_bruteforce.menu_elements][1], anti_bruteforce.menu_elements[#anti_bruteforce.menu_elements][2], #anti_bruteforce.menu_elements)
    table.remove(anti_bruteforce.menu_elements, #anti_bruteforce.menu_elements)

    menu.set_value("Brute", "General", "phases (not vis)", #anti_bruteforce.menu_elements)
end

menu.create_new_element("Brute", "General", {name = "Create New Phase", type = "button", callback = anti_bruteforce.create_new_phase})
menu.create_new_element("Brute", "General", {name = "Remove Phase", type = "button", callback = anti_bruteforce.remove_phase})

for i = 1, menu.get_value("Brute", "General", "phases (not vis)") do
    anti_bruteforce.create_new_phase()
end

anti_bruteforce.reset_time = 0
anti_bruteforce.last_tick_triggered = 0
anti_bruteforce.timer = 5
anti_bruteforce.current_phase = 0
anti_bruteforce.angle = 0
anti_bruteforce.misses = 0

anti_bruteforce.side = false

anti_bruteforce.bullet_impact = function()
    local inverter_state = ui.get_keybind_state(keybinds.flip_desync)

    if anti_bruteforce.reset_time < globalvars.get_realtime() then
        for i = 1, #anti_bruteforce.menu_elements do
            local data = anti_bruteforce.menu_elements[i]

            if inverter_state and menu.get_value(data[1], data[2], data[3]) >= 0 then
                anti_bruteforce.current_phase = i
                break
            elseif not inverter_state and menu.get_value(data[1], data[2], data[3]) < 0 then
                anti_bruteforce.current_phase = i
                break
            end
        end
    else
        anti_bruteforce.current_phase = 1 + (anti_bruteforce.current_phase % #anti_bruteforce.menu_elements)
    end
    
    anti_bruteforce.reset_time = globalvars.get_realtime() + anti_bruteforce.timer

    local data = anti_bruteforce.menu_elements[anti_bruteforce.current_phase]
    anti_bruteforce.angle = menu.get_value(data[1], data[2], data[3])

    while anti_bruteforce.angle == nil do
        anti_bruteforce.current_phase = 1 + (anti_bruteforce.current_phase % #anti_bruteforce.menu_elements)
        anti_bruteforce.angle = menu.get_value(data[1], data[2], data[3])
    end

    anti_bruteforce.last_tick_triggered = globalvars.get_tickcount()
end

events.register_event("bullet_impact", function(event)
    if not menu.get_value("Brute", "General", "Anti Bruteforce") then 
        return 
    end

    if anti_bruteforce.last_tick_triggered == globalvars.get_tickcount() then
        return
    end

    local player = entity_helpers.local_player.pointer()

    if not player or not player:is_alive() then
        return
    end

    local userid = event:get_int("userid")

    if userid == nil then
        return
    end

    local player_object = entitylist.get_player_by_index(engine.get_player_for_user_id(userid))

    if not player_object or player_object:get_dormant() or not entity_helpers.is_enemy(player, player_object) then
        return
    end

    local entity_position = player_object:get_absorigin()
    entity_position.z = entity_position.z + player_object:get_angles().z

    if not entity_position then
        return
    end

    local player_head = player:get_player_hitbox_pos(0)

    if not player_head then
        return
    end

    local closest = get_closest_point({entity_position.x, entity_position.y, entity_position.z}, {event:get_int("x"), event:get_int("y"), event:get_int("z")}, {player_head.x, player_head.y, player_head.z})

    local delta = {player_head.x - closest[1], player_head.y - closest[2]}
    local delta_2d = math.sqrt(delta[1]^2 + delta[2]^2)

    if math.abs(delta_2d) < 32 then
        anti_bruteforce.bullet_impact()
        anti_bruteforce.side = not anti_bruteforce.side

        ui.set_keybind_state(keybinds.flip_desync, anti_bruteforce.side)
        
        local angle = math.abs(anti_bruteforce.angle)
        debug(string.format("Anti-Bruteforce angle status changed. [%s]", angle))

        if anti_bruteforce.current_phase % 2 == 0 then
            ui.set_int("0Antiaim.inverted_desync_range", angle)
        else
            ui.set_int("0Antiaim.desync_range", angle)
        end
    end
end)
--@endregion

--@region: configs
configs.parse = function()
    local menu_items = {}
    for i, d in pairs(menu.items) do
        local temp_table_tab = {}

        for k, v in pairs(d) do
            local temp_table_subtab = {}

            for c = 1, #v.g_Elements do
                local data = v.g_Elements[c][1]

                local temp_table_element = {}
                if data.name ~= "Author" and data.name ~= "Modified at" then
                    temp_table_element.value = menu.get_value(i, k, data.name, true)
                end

                if data.name == "Author" then
                    temp_table_element.value = globalvars.get_winuser()
                end
                if data.name == "Modified at" then
                    temp_table_element.value = globalvars.get_time()
                end

                if temp_table_element.value == nil then goto skip end
                temp_table_subtab[data.name] = temp_table_element

                ::skip::
            end

            temp_table_tab[k] = temp_table_subtab
        end

        menu_items[i] = temp_table_tab
    end

    local json_config = menu_items
    local config_name = menu.get_value("Configs", "Name", "Config name")
    if #config_name <= 1 then cheat.popup("Necron", "Config name is empty") return end

    config:write(string.format("%s", config_name), json_config)
end

configs.load = function()
    local config_name = menu.get_value("Configs", "Name", "Config name")

    if #config_name <= 0 then 
        cheat.popup("Necron", "Config name is empty") 
        return 
    end

    local json_config = config:read(string.format("%s", config_name))

    local antibrute_phases = -1

    for k, v in pairs(json_config) do
        for i, d in pairs(v) do
            for c, h in pairs(d) do
                if string.find(c, "^Fake Limit Phase ") ~= nil then
                    local ab_value = tonumber(c:sub(#"Fake Limit Phase ", #c))
                    antibrute_phases = math.max(ab_value, antibrute_phases)
                end

                if h.value ~= nil then
                    menu.set_value(k, i, c, h.value, true)
                end
            end
        end
    end

    if #anti_bruteforce.menu_elements > antibrute_phases then
        while #anti_bruteforce.menu_elements > antibrute_phases do
            anti_bruteforce.remove_phase()
        end
    else
        while #anti_bruteforce.menu_elements < antibrute_phases do
            anti_bruteforce.create_new_phase()
        end
    end

    for i = 1, antibrute_phases do
        menu.set_value("Brute", "Phases", "Fake Limit Phase ".. i, json_config["Brute"]["Phases"]["Fake Limit Phase ".. i].value)
    end

    cheat.popup("Necron", "Config loaded!")
end

menu.create_new_element("Configs", "Actions", {name = "Save", type = "button", callback = configs.parse})
menu.create_new_element("Configs", "Actions", {name = "Load", type = "button", callback = configs.load})
menu.create_new_element("Configs", "Actions", {name = "none", type = "divider"})
menu.create_new_element("Configs", "Actions", {name = "Discrod link", type = "button", callback = function()
    console.execute_client_cmd("clear")
    console.execute_client_cmd("showconsole")
    print("https://discord.gg/tPfYp4WeXq")
end})

--@endregion

--@region: callbacks
-- Creating a variable for callbacks
handlers.callbacks = {}

--[[
--
--  Creating a function with which we will call functions later
--  @param: callback type {string}
--  @param: callback function {function}
--
]]--
handlers.subscribe = function(callback, name, funct)
    -- Adding a check, if the value of "funct" in the function is nil, then we call an error and return false
    if funct == nil then
        debug("Failed to create callback", callback, name)
        return false
    end

    -- Adding a check, if the value of "name" in the function is nil, then "name" is unknown
    name = name and name or "unknown"

    -- Then I was too lazy to take notes, I think you don't need it
    local isExists = false
    for i = 1, #handlers.callbacks do
        if handlers.callbacks[i].callback == callback then
            isExists = true
            break
        end
    end

    if not isExists then
        table.insert(handlers.callbacks, {type = callback, func = funct})
        isExists = true
    end
    return true
end

--@region: handle callbacks
handlers.subscribe("on_paint", "on-screen indicators default:handle", visual_controller.default.handle)
handlers.subscribe("on_paint", "keybinds:handle", visual_controller.keybinds.handle)
handlers.subscribe("on_paint", "fake:handle", visual_controller.fake.handle)
handlers.subscribe("on_paint", "watermark:handle", visual_controller.watermark.handle)
handlers.subscribe("on_paint", "anti_backstab:radius", visual_controller.backstab_radius)
handlers.subscribe("on_paint", "freestand_on_key:handle", freestand_on_key.handle)
handlers.subscribe("on_paint", "visible:update", visible_controller.global_update)
handlers.subscribe("on_paint", "window:render", window.render)
handlers.subscribe("on_paint", "input:update", input_system.update)
handlers.subscribe("on_paint", "window:open", function() window.is_open = globalvars.is_open_menu() and true or false end)
handlers.subscribe("on_paint", "window:update", function() window.alpha = lerp(window.alpha, window.is_open and 1 or 0, globalvars.get_frametime() * 12) end)

--handlers.subscribe("on_createmove", "clantag:none", clan_tag.none)
handlers.subscribe("on_createmove", "clantag:default", clan_tag.default)
handlers.subscribe("on_createmove", "clantag:custom", clan_tag.custom)
handlers.subscribe("on_createmove", "hitchance:air", conditional_hitchance.air)
handlers.subscribe("on_createmove", "anti-aim:tank", anti_aim_controller.tank)
handlers.subscribe("on_createmove", "anti-aim:type 1", anti_aim_controller.type_1)
handlers.subscribe("on_createmove", "anti-aim:alternative", anti_aim_controller.alternative)
handlers.subscribe("on_createmove", "conditional_anti_aim:handle", conditional_anti_aim.handle)
handlers.subscribe("on_createmove", "leg_spammer:handle", leg_spammer.handle)
handlers.subscribe("on_createmove", "anti_backstab:handle", anti_backstab.handle)
--@endregion

-- Creating a variable for handle callbacks
handlers.update = {on_paint = function()for i = 1, #handlers.callbacks do local data = handlers.callbacks[i];if data.type == "on_paint" then data.func();end;end;end, on_shot = function()for i = 1, #handlers.callbacks do local data = handlers.callbacks[i];if data.type == "on_shot" then data.func();end;end;end, on_createmove = function() for i = 1, #handlers.callbacks do local data = handlers.callbacks[i];if data.type == "on_createmove" then data.func();end;end;end}
cheat.RegisterCallback("on_paint", handlers.update.on_paint); cheat.RegisterCallback("on_shot", handlers.update.on_shot); cheat.RegisterCallback("on_createmove", handlers.update.on_createmove)
--@endregion
