--[[ @region: script information
    * @ Necron.
    * @ Created by Klient#1690.
    * @ Version: 4.0.0
-- @endregion ]]

--- @region: libraries
local json = {_version = "0.1.2"}; local encode; local escape_char_map = {[ "\\" ] = "\\",[ "\"" ] = "\"",[ "\b" ] = "b",[ "\f" ] = "f",[ "\n" ] = "n",[ "\r" ] = "r",[ "\t" ] = "t",}; local escape_char_map_inv = { [ "/" ] = "/" }; for k, v in pairs(escape_char_map) do escape_char_map_inv[v] = k; end; local function escape_char(c) return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte())); end; local function encode_nil(val) return "null"; end; local function encode_table(val, stack) local res = {}; stack = stack or {}; if stack[val] then error("circular reference") end; stack[val] = true; if rawget(val, 1) ~= nil or next(val) == nil then local n = 0; for k in pairs(val) do if type(k) ~= "number" then error("invalid table: mixed or invalid key types"); end; n = n + 1; end; if n ~= #val then error("invalid table: sparse array"); end; for i, v in ipairs(val) do table.insert(res, encode(v, stack)); end; stack[val] = nil; return "[" .. table.concat(res, ",") .. "]"; else for k, v in pairs(val) do if type(k) ~= "string" then error("invalid table: mixed or invalid key types"); end; table.insert(res, encode(k, stack) .. ":" .. encode(v, stack)); end; stack[val] = nil; return "{" .. table.concat(res, ",") .. "}"; end; end; local function encode_string(val) return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'; end local function encode_number(val) if val ~= val or val <= -math.huge or val >= math.huge then error("unexpected number value '" .. tostring(val) .. "'"); end; return string.format("%.14g", val); end; local type_func_map = {[ "nil" ] = encode_nil,[ "table" ] = encode_table,[ "string" ] = encode_string,[ "number" ] = encode_number,[ "boolean" ] = tostring,}; encode = function(val, stack) local t = type(val); local f = type_func_map[t]; if f then return f(val, stack); end; error("unexpected type '" .. t .. "'"); end; function json.encode(val) return ( encode(val) ); end; local parse; local function create_set(...) local res = {}; for i = 1, select("#", ...) do res[ select(i, ...) ] = true; end; return res; end; local space_chars = create_set(" ", "\t", "\r", "\n"); local delim_chars = create_set(" ", "\t", "\r", "\n", "]", "}", ","); local escape_chars = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u"); local literals = create_set("true", "false", "null"); local literal_map = {[ "true" ] = true,[ "false" ] = false,[ "null" ] = nil,}; local function next_char(str, idx, set, negate) for i = idx, #str do if set[str:sub(i, i)] ~= negate then return i; end; end; return #str + 1; end; local function decode_error(str, idx, msg) local line_count = 1; local col_count = 1; for i = 1, idx - 1 do col_count = col_count + 1; if str:sub(i, i) == "\n" then line_count = line_count + 1; col_count = 1; end; end; error( string.format("%s at line %d col %d", msg, line_count, col_count) ); end; local function codepoint_to_utf8(n) local f = math.floor; if n <= 0x7f then return string.char(n); elseif n <= 0x7ff then return string.char(f(n / 64) + 192, n % 64 + 128); elseif n <= 0xffff then return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128); elseif n <= 0x10ffff then return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128, f(n % 4096 / 64) + 128, n % 64 + 128); end; error( string.format("invalid unicode codepoint '%x'", n) ); end; local function parse_unicode_escape(s) local n1 = tonumber( s:sub(1, 4), 16 ); local n2 = tonumber( s:sub(7, 10), 16 ); if n2 then return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000); else return codepoint_to_utf8(n1); end; end; local function parse_string(str, i) local res = ""; local j = i + 1; local k = j; while j <= #str do local x = str:byte(j); if x < 32 then decode_error(str, j, "control character in string"); elseif x == 92 then res = res .. str:sub(k, j - 1); j = j + 1; local c = str:sub(j, j); if c == "u" then local hex = str:match("^[dD][89aAbB]%x%x\\u%x%x%x%x", j + 1) or str:match("^%x%x%x%x", j + 1) or decode_error(str, j - 1, "invalid unicode escape in string"); res = res .. parse_unicode_escape(hex); j = j + #hex; else if not escape_chars[c] then decode_error(str, j - 1, "invalid escape char '" .. c .. "' in string"); end; res = res .. escape_char_map_inv[c]; end; k = j + 1; elseif x == 34 then res = res .. str:sub(k, j - 1); return res, j + 1; end; j = j + 1; end; decode_error(str, i, "expected closing quote for string"); end; local function parse_number(str, i) local x = next_char(str, i, delim_chars); local s = str:sub(i, x - 1); local n = tonumber(s); if not n then decode_error(str, i, "invalid number '" .. s .. "'"); end; return n, x; end; local function parse_literal(str, i) local x = next_char(str, i, delim_chars); local word = str:sub(i, x - 1); if not literals[word] then decode_error(str, i, "invalid literal '" .. word .. "'"); end; return literal_map[word], x; end; local function parse_array(str, i) local res = {}; local n = 1; i = i + 1; while 1 do local x; i = next_char(str, i, space_chars, true); if str:sub(i, i) == "]" then i = i + 1; break; end; x, i = parse(str, i); res[n] = x; n = n + 1; i = next_char(str, i, space_chars, true); local chr = str:sub(i, i); i = i + 1; if chr == "]" then break end; if chr ~= "," then decode_error(str, i, "expected ']' or ','") end; end; return res, i; end; local function parse_object(str, i) local res = {}; i = i + 1; while 1 do local key, val; i = next_char(str, i, space_chars, true); if str:sub(i, i) == "}" then i = i + 1; break; end; if str:sub(i, i) ~= '"' then decode_error(str, i, "expected string for key"); end; key, i = parse(str, i); i = next_char(str, i, space_chars, true); if str:sub(i, i) ~= ":" then decode_error(str, i, "expected ':' after key"); end; i = next_char(str, i + 1, space_chars, true); val, i = parse(str, i); res[key] = val; i = next_char(str, i, space_chars, true); local chr = str:sub(i, i); i = i + 1; if chr == "}" then break end; if chr ~= "," then decode_error(str, i, "expected '}' or ','") end; end; return res, i; end; local char_func_map = {[ '"' ] = parse_string,[ "0" ] = parse_number,[ "1" ] = parse_number,[ "2" ] = parse_number,[ "3" ] = parse_number,[ "4" ] = parse_number,[ "5" ] = parse_number,[ "6" ] = parse_number,[ "7" ] = parse_number,[ "8" ] = parse_number,[ "9" ] = parse_number,[ "-" ] = parse_number,[ "t" ] = parse_literal,[ "f" ] = parse_literal,[ "n" ] = parse_literal,[ "[" ] = parse_array,[ "{" ] = parse_object,}; parse = function(str, idx) local chr = str:sub(idx, idx); local f = char_func_map[chr]; if f then return f(str, idx); end; decode_error(str, idx, "unexpected character '" .. chr .. "'"); end; function json.decode(str) if type(str) ~= "string" then error("expected argument of type string, got " .. type(str)); end; local res, idx = parse(str, next_char(str, 1, space_chars, true)); idx = next_char(str, idx, space_chars, true); if idx <= #str then decode_error(str, idx, "trailing garbage"); end; return res; end;
local print = function(...)local data = {...};local current_table_with_strings = {};if #data == 0 then current_table_with_strings[#current_table_with_strings + 1] = "No values selected to debug.";else for index = 1, #data do local current_element = data[index];if type(current_element) == "function" then current_table_with_strings[index] = ("function %s: %s"):format((tostring(current_element)):gsub("function: ", ""), current_element() or "nil");elseif type(current_element) == "table" then for additional_elements = 1, #current_element do if type(current_element[additional_elements]) == "function" then current_element[additional_elements] = ("function %s: %s"):format((tostring(current_element[additional_elements])):gsub("function: ", ""), current_element[additional_elements]() or "nil");elseif type(current_element[additional_elements]) == "string" then current_element[additional_elements] = ("\"%s\""):format(current_element[additional_elements]);else current_element[additional_elements] = tostring(current_element[additional_elements]);end;end;current_table_with_strings[index] = ("{%s}"):format(table.concat(current_element, ", "));else current_table_with_strings[index] = tostring(current_element);end;end;end;console.print_color("[Necron] ", color.new(255, 192, 118));console.print(table.concat(current_table_with_strings, " ") .. "\n");end
--- @endregion

--- @region: defines
local path = engine.get_winpath("appdata").."\\rawetripp\\"
local npath = "C:\\necron"

if not file.exists(npath) then
    file.create_dir(npath)
end

if not file.exists(path .. "assets") then
    file.create_dir(path .. "assets")
end

if not file.exists(npath .. "\\assets") then
    file.create_dir(npath .. "\\assets")
end

local assets_path = path .. "assets\\"
local necron_path = "C:/necron/"

local loading_time = 0

local best_enemy = nil
--- @endregion

--- @region: script helpers
local script = {}

function script:create(name, color, vector, version, type)
    local data = {name = name, color = color, vector = vector, version = version, type = type}

    self.__index = self
    return setmetatable(data, self)
end

function script:get_name()
    return self.name
end

function script:get_color()
    return self.color
end

function script:get_menu()
    return self.vector
end

function script:get_version()
    return self.version
end

function script:get_type()
    return self.type
end

function script:set_color(color)
    self.color = color
end

script.data = script:create("Necron", color.new(255, 192, 118), vector2d.new(720, 460), "4.0.0", "stable")
--- @endregion

--- @region: all math & other operations
local bit = {
    band = function(a, b) return a & b end,
    lshift = function(a, b) return a << b end,
    rshift = function(a, b) return a >> b end,
    bor = function(a, b) return a | b end,
    bnot = function(a) return ~a end
}

math.round = function(x)
    return x >= 0 and math.floor(x + 0.5) or math.ceil(x - 0.5)
end

math.round_mul = function(num, numDecimalPlaces)
    local mult = 10 ^ (numDecimalPlaces or 0)

    return math.floor(num * mult + 0.5) / mult
end

math.clamp = function(value, min, max) 
    return math.min(math.max(value, min), max) 
end

math.normalize_yaw = function(Yaw)
    while (Yaw > 180.0) do
        Yaw = Yaw - 360.0 end

    while (Yaw < -180.0) do
        Yaw = Yaw + 360.0 end

    return Yaw
end

math.calc_angle = function(local_x, local_y, enemy_x, enemy_y)
    local ydelta = local_y - enemy_y
    local xdelta = local_x - enemy_x
    local relativeyaw = math.atan(ydelta / xdelta)
    relativeyaw = math.normalize_yaw(relativeyaw * 180 / math.pi)
    if xdelta >= 0 then
        relativeyaw = math.normalize_yaw(relativeyaw + 180)
    end
    return relativeyaw
end

math.get_closest_point = function(A, B, P)
    local a_to_p = {P[1] - A[1], P[2] - A[2]}
    local a_to_b = {B[1] - A[1], B[2] - A[2]}

    local atb2 = a_to_b[1] ^ 2 + a_to_b[2] ^ 2
    local atp_dot_atb = a_to_p[1] * a_to_b[1] + a_to_p[2] * a_to_b[2]

    local t = atp_dot_atb / atb2

    return {A[1] + a_to_b[1] * t, A[2] + a_to_b[2] * t}
end

math.random_float = function(min, max)
    return math.random() * (max - min) + min
end
--- @endregion

--- @region: player helpers
function player:is_enemy()
    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    if self:get_team() ~= Player:get_team() then
        return true
    end

    return false
end

function player:is_zeusable()
    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local max_zeus_range = 167

    local self_position = self:get_absorigin()
    local player_position = Player:get_absorigin()

    local dist = player_position:dist_to(self_position)

    return dist < max_zeus_range
end

function player:get_body_yaw()
    local body_yaw = (math.floor(math.min(60, (self:m_flposeparameter()[12] * 120 - 60))))

    return body_yaw
end

function player:get_state()
    if self ~= nil then
        local self_velocity = self:get_velocity():length_2d()
        local current_state = "UNKNOWN"

        local duck_amount = self:get_prop_float("CBasePlayer", "m_flDuckAmount")
        local is_local = self == entitylist.get_local_player()

        local flags = self:get_prop_int("CBasePlayer", "m_fFlags")
        local isFD = ui.get_keybind_state(keybinds.fakeduck)
        local isSW = ui.get_keybind_state(keybinds.slowwalk)

        if is_local then
            if isFD then
                current_state = "FAKEDUCK"
            elseif bit.band(flags, 1) == 0 then
                current_state = duck_amount ~= 1 and "IN AIR" or duck_amount == 1 and "IN CROUCH AIR"
            elseif bit.band(flags, 1) ~= 0 and duck_amount == 1 then
                current_state = self:get_team() == 2 and "CROUCH T" or self:get_team() == 3 and "CROUCH CT"
            elseif isSW then
                current_state = "SLOWWALK"
            elseif self_velocity > 1.1 then
                current_state = "MOVING"
            elseif self_velocity <= 1.1 then
                current_state = "STANDING"
            end
        else
            if bit.band(flags, 1) == 0 then
                current_state = duck_amount ~= 1 and "IN AIR" or duck_amount == 1 and "IN CROUCH AIR"
            elseif bit.band(flags, 1) ~= 0 and duck_amount == 1 then
                current_state = self:get_team() == 2 and "CROUCH T" or self:get_team() == 3 and "CROUCH CT"
            elseif self_velocity > 5 and self_velocity <= 80 then
                current_state = "SLOWWALK"
            elseif self_velocity > 1.1 then
                current_state = "MOVING"
            elseif self_velocity <= 1.1 then
                current_state = "STANDING"
            end
        end
        return current_state
    end
end

function player:get_eye_pos()
    local entity = self

    if not entity then
        return 0, 0, 0
    end

    local origin = entity:get_absorigin()
    local duck_amount = entity:get_prop_float("CBasePlayer", "m_flDuckAmount")

    return origin.x, origin.y, origin.z + 64 - (duck_amount * 18)
end
--- @endregion

--- @region: render helpers
render.measure_multitext = function(_table)
    local a = 0

    for b, c in pairs(_table) do
        if not c.font then
            return
        end

        a = a + render.get_text_width(c.font, c.text)
    end

    return a
end

render.multitext = function(x, y, _table)
    for a, b in pairs(_table) do
        if not b.font then
            return
        end

        b.shadow = b.shadow or false
        b.outline = b.outline or false
        b.color = b.color or color.new(255, 255, 255, 255)

        render.text(b.font, x, y, b.color, b.text, b.shadow, b.outline)

        x = x + render.get_text_width(b.font, b.text)
    end
end

render.glow_line = function(x, y, x2, y2, w, color, th)
    render.line(x, y, x2, y2, color, th or 0)

    for i = 1, w do
        local alpha = 0.3
        local new_color = color.new(color:r(), color:g(), color:b(), (color:a() - color:a() * i / w) * alpha)

        render.line(x + i, y - i, x2 + i, y2 - i, new_color, th or 0)
        render.line(x - i, y + i, x2 - i, y2 + i, new_color, th or 0)
    end
end
--- @endregion

--- @region: table helpers
table.count = function(tbl)
    if tbl == nil then 
        return 0 
    end

    if #tbl == 0 then 
        local count = 0

        for data in pairs(tbl) do 
            count = count + 1 
        end

        return count 
    end
    return #tbl
end
--- @endregion

--- @region: images helpers
local images = {}

local steam_avatars = {}
images.get_steam_avatar = function(entity)
    if entity == nil then
        return
    end

    local cache_key = string.format("%s", tostring(entity))

    if steam_avatars[cache_key] == nil then
        steam_avatars[cache_key] = steam.get_friend_avatar(entity:get_index())
    end

    if steam_avatars[cache_key] then
        return steam_avatars[cache_key]
    end
end
--- @endregion

--- @region: vector helpers
function vector:forward()
    local forward, right = vector.new(0, 0, 0), vector.new(0, 0, 0)
    local pitch, yaw, roll = math.rad(self.x), math.rad(self.y), math.rad(self.z)

    local cp, sp = math.cos(pitch), math.sin(pitch)
    local cy, sy = math.cos(yaw), math.sin(yaw)
    local cr, sr = math.cos(roll), math.sin(roll)
 
    forward.x = cp * cy
    forward.y = cp * sy
    forward.z = -sp
 
    right.x = (-1 * sr * sp * cy) + (-1 * cr * -sy)
    right.y = (-1 * sr * sp * sy) + (-1 * cr * cy)
    right.z = -1 * sr * cp
 
    return forward, right
end

function vector.__sub(vector1, vector2)
    if type(vector1) == "number" then
        return vector.new(
            vector1 - vector2.x, 
            vector1 - vector2.y, 
            vector1 - vector2.z
        )
    end

    if type(vector2) == "number" then
        return vector.new(
            vector1.x - vector2,
            vector1.y - vector2, 
            vector1.z - vector2
        )
    end

    return vector.new(
        vector1.x - vector2.x,
        vector1.y - vector2.y, 
        vector1.z - vector2.z
    )
end

function vector.__mul(vector1, vector2)
    if (type(vector1) == "number") then
        return vector.new(
            vector1 * vector2.x, 
            vector1 * vector2.y, 
            vector1 * vector2.z
        )
    end

    if (type(vector2) == "number") then
        return vector.new(
            vector1.x * vector2,
            vector1.y * vector2, 
            vector1.z * vector2
        )
    end

    return vector.new(
        vector1.x * vector2.x,
        vector1.y * vector2.y, 
        vector1.z * vector2.z
    )
end

function vector.__div(vector1, vector2)
    if type(vector1) == "number" then
        return vector.new(
            vector1 / vector2.x, 
            vector1 / vector2.y, 
            vector1 / vector2.z
        )
    end

    if type(vector2) == "number" then
        return vector.new(
            vector1.x / vector2,
            vector1.y / vector2, 
            vector1.z / vector2
        )
    end

    return vector.new(
        vector1.x / vector2.x,
        vector1.y / vector2.y, 
        vector1.z / vector2.z
    )
end

function vector.__add(vector1, vector2)
    if type(vector1) == "number" then
        return vector.new(
            vector1 + vector2.x, 
            vector1 + vector2.y, 
            vector1 + vector2.z
        )
    end

    if type(vector2) == "number" then
        return vector.new(
            vector1.x + vector2,
            vector1.y + vector2, 
            vector1.z + vector2
        )
    end

    return vector.new(
        vector1.x + vector2.x,
        vector1.y + vector2.y, 
        vector1.z + vector2.z
    )
end
--- @endregion

--- @region: entity helpers
local entity = {}

entity.get_best_enemy = function()
    best_enemy = nil

    local player = entitylist.get_local_player()

    local best_fov = 180

    local lx, ly, lz = player:get_eye_pos()

    local viewangles = engine.get_view_angles()
    local view_x, view_y, roll = viewangles.x, viewangles.y, viewangles.z
    
    for key = 1, globalvars.get_maxclients() do
        local enemy = entitylist.get_player_by_index(engine.get_player_for_user_id(key))

        if not enemy then
            goto skip
        end

        if enemy:is_enemy() and enemy:is_alive() and not enemy:get_dormant() then
            local cur_pos = enemy:get_absorigin()
            local cur_x, cur_y, cur_z = cur_pos.x, cur_pos.y, cur_pos.z
            
            local cur_fov = math.abs(math.normalize_yaw(math.deg(math.atan(ly - cur_y, lx - cur_x)) - view_y + 180))
            if cur_fov < best_fov then
                best_fov = cur_fov
                best_enemy = enemy
            end
        end

        ::skip::
    end
end
--- @endregion

--- @region: string helpers
string.split = function(str, pattern)
    local words = {}

    for word in str:gmatch(pattern) do
        words[#words + 1] = word
    end

    return words
end

string.wrap = function(self, width)
    local text = self

    local lines = string.split(text, "[^\r\n]+")

    local widthleft
    local result = {}
    local line = {}

    for k = 1, #lines do
        sourceLine = lines[k]
        widthleft = width

        local words = string.split(sourceLine, "%S+")

        for l = 1, #words do
            word = words[l]

            if #word > width then
                while (#word > width) do
                    table.insert(line, word:sub(0, widthleft))
                    table.insert(result, table.concat(line, " "))

                    word = word:sub(widthleft + 1)
                    widthleft = width
                    line = {}
                end

                line = {word}
                widthleft = width - (#word + 1)
            elseif (#word + 1) > widthleft then
                table.insert(result, table.concat(line, " "))

                line = {word}
                widthleft = width - (#word + 1)
            else
                table.insert(line, word)
                widthleft = widthleft - (#word + 1)
            end
        end

        table.insert(result, table.concat(line, " "))
        line = {}
    end

    return {text = table.concat(result, "\n"), tbl = result}
end
--- @endregion


--- @region: input section
local input_system = {}
local pressed_keys = {}
local last_pressed_keys = {}

input_system.update = function() 
    for i = 1, 255 do 
        last_pressed_keys[i] = pressed_keys[i]
        pressed_keys[i] = engine.get_active_key(i)
    end
end

input_system.is_key_down = function(key) 
    return pressed_keys[key]
end

input_system.is_key_pressed = function(key) 
    return pressed_keys[key] and not last_pressed_keys[key]
end

input_system.is_key_released = function(key) 
    return not pressed_keys[key] and last_pressed_keys[key]
end

input_system.cursor_in_bounds = function(x, y, w, h) 
    local mouse_pos = engine.get_cursor_position()

    return ((mouse_pos.x >= x and mouse_pos.x < x + w and mouse_pos.y >= y and mouse_pos.y < y + h) and globalvars.is_open_menu()) 
end

input_system.keys = {["MOUSE1"] = 0x01,["MOUSE2"] = 0x02,["CANCEL"] = 0x03,["MOUSE3"] = 0x04,["MOUSE4"] = 0x05,["MOUSE5"] = 0x06,["BACK"] = 0x08,["TAB"] = 0x09,["CLEAR"] = 0x0C,["RETURN"] = 0x0D,["SHIFT"] = 0x10,["CTRL"] = 0x11,["MENU"] = 0x12,["PAUSE"] = 0x13,["CAPS"] = 0x14,["KANA"] = 0x15,["HANGUEL"] = 0x15,["HANGUL"] = 0x15,["IME_ON"] = 0x16,["JUNJA"] = 0x17,["FINAL"] = 0x18,["HANJA"] = 0x19,["KANJI"] = 0x19,["IME_OFF"] = 0x1A,["Disabled"] = 0x1B,["CONVERT"] = 0x1C,["NONCONVERT"] = 0x1D,["ACCEPT"] = 0x1E,["MODECHANGE"] = 0x1F,["SPACE"] = 0x20,["PRIOR"] = 0x21,["NEXT"] = 0x22,["END"] = 0x23,["HOME"] = 0x24,["LEFT"] = 0x25,["UP"] = 0x26,["RIGHT"] = 0x27,["DOWN"] = 0x28,["SELECT"] = 0x29,["PRINT"] = 0x2A,["EXECUTE"] = 0x2B, ["SNAPSHOT"] = 0x2C,["INSERT"] = 0x2D,["DELETE"] = 0x2E,["HELP"] = 0x2F,["0"] = 0x30,["1"] = 0x31,["2"] = 0x32,["3"] = 0x33,["4"] = 0x34,["5"] = 0x35,["6"] = 0x36,["7"] = 0x37,["8"] = 0x38,["9"] = 0x39,["A"] = 0x41,["B"] = 0x42,["C"] = 0x43,["D"] = 0x44,["E"] = 0x45,["F"] = 0x46,["G"] = 0x47,["H"] = 0x48,["I"] = 0x49,["J"] = 0x4A,["K"] = 0x4B,["L"] = 0x4C,["M"] = 0x4D,["N"] = 0x4E,["O"] = 0x4F,["P"] = 0x50,["Q"] = 0x51,["R"] = 0x52,["S"] = 0x53,["T"] = 0x54,["U"] = 0x55,["V"] = 0x56,["W"] = 0x57,["X"] = 0x58,["Y"] = 0x59,["Z"] = 0x5A,["LWIN"] = 0x5B,["RWIN"] = 0x5C,["APPS"] = 0x5D,["SLEEP"] = 0x5F,["NUM0"] = 0x60,["NUMP1"] = 0x61,["NUM2"] = 0x62,["NUM3"] = 0x63,["NUM4"] = 0x64,["NUM5"] = 0x65,["NUM6"] = 0x66,["NUM7"] = 0x67,["NUM8"] = 0x68,["NUM9"] = 0x69,["MULTIPLY"] = 0x6A,["ADD"] = 0x6B,["SEPARATOR"] = 0x6C,["SUBTR"] = 0x6D,["DECIMAL"] = 0x6E,["DIVIDE"] = 0x6F,["F1"] = 0x70,["F2"] = 0x71,["F3"] = 0x72,["F4"] = 0x73,["F5"] = 0x74,["F6"] = 0x75,["F7"] = 0x76,["F8"] = 0x77,["F9"] = 0x78,["F10"] = 0x79,["F11"] = 0x7A,["F12"] = 0x7B,["F13"] = 0x7C,["F14"] = 0x7D,["F15"] = 0x7E,["F16"] = 0x7F,["F17"] = 0x80,["F18"] = 0x81,["F19"] = 0x82,["F20"] = 0x83,["F21"] = 0x84,["F22"] = 0x85,["F23"] = 0x86,["F24"] = 0x87,["NUMLCK"] = 0x90,["SCROLL"] = 0x91,["LSHIFT"] = 0xA0,["RSHIFT"] = 0xA1,["LCONTROL"] = 0xA2,["RCONTROL"] = 0xA3,["LMENU"] = 0xA4,["RMENU"] = 0xA5,["BROWSER_BACK"] = 0xA6,["BROWSER_FORWARD"] = 0xA7,["BROWSER_REFRESH"] = 0xA8,["BROWSER_STOP"] = 0xA9,["BROWSER_SEARCH"] = 0xAA,["BROWSER_FAVORITES"] = 0xAB,["BROWSER_HOME"] = 0xAC,["VOLUME_MUTE"] = 0xAD,["VOLUME_DOWN"] = 0xAE,["VOLUME_UP"] = 0xAF,["MEDIA_NEXT_TRACK"] = 0xB0,["MEDIA_PREV_TRACK"] = 0xB1,["MEDIA_STOP"] = 0xB2,["MEDIA_PLAY_PAUSE"] = 0xB3,["LAUNCH_MAIL"] = 0xB4,["LAUNCH_MEDIA_SELECT"] = 0xB5,["LAUNCH_APP1"] = 0xB6,["LAUNCH_APP2"] = 0xB7,["OEM_1"] = 0xBA,["OEM_PLUS"] = 0xBB,["OEM_COMMA"] = 0xBC,["OEM_MINUS"] = 0xBD,["OEM_PERIOD"] = 0xBE,["OEM_2"] = 0xBF,["OEM_3"] = 0xC0,["OEM_4"] = 0xDB,["OEM_5"] = 0xDC,["OEM_6"] = 0xDD,["OEM_7"] = 0xDE,["OEM_8"] = 0xDF,["OEM_102"] = 0xE2,["PROCESSKEY"] = 0xE5,["PACKET"] = 0xE7,["ATTN"] = 0xF6,["CRSEL"] = 0xF7,["EXSEL"] = 0xF8,["EREOF"] = 0xF9,["PLAY"] = 0xFA,["ZOOM"] = 0xFB,["NONAME"] = 0xFC,["PA1"] = 0xFD,["OEM_CLEAR"] = 0xFE}
input_system.state = {["Disabled"] = 0, ["Always"] = 1, ["Toggle"] = 2, ["Hold"] = 3}
--- @endregion

--- @region: color helpers
color.unpack = function(element)
    return element:r(), element:g(), element:b(), element:a()
end
--- @endregion

--- @region: vector helpers
function vector:unpack()
    return self.x, self.y, self.z
end

function vector2d:unpack()
    return self.x, self.y
end
--- @endregion

--- @region: custom animations
--- @note: author - prince
local animation = {}
animation.data = {}

animation.lerp = function(start, end_pos, time)
    if type(start) == "userdata" then
        local color_data = {0, 0, 0, 0}

        color_data[1] = animation.lerp(start:r(), end_pos:r(), time)
        color_data[2] = animation.lerp(start:g(), end_pos:g(), time)
        color_data[3] = animation.lerp(start:b(), end_pos:b(), time)
        color_data[4] = animation.lerp(start:a(), end_pos:a(), time)

        return color.new(table.unpack(color_data))
    end

    return (end_pos - start) * (globalvars.get_frametime() * time) + start
end

animation.new = function(name, value, time)
    if not animation.data[name] then
        animation.data[name] = value
    end

    animation.data[name] = animation.lerp(animation.data[name], value, time)

    return animation.data[name]
end

animation.get = function(name)
    return animation.data[name]
end
--- @endregion

--- @region: http helpers
local Http = {}

Http.assets = {
    {
        name = "logo.png",
        path = "C:\\necron\\assets\\",
        link = "https://raw.githubusercontent.com/kl1ent/CS-GO-Scripting/main/rawetrip/Necron/Vector.png"
    },

    {
        name = "smallest.ttf",
        path = "C:\\necron\\assets\\",
        link = "https://raw.githubusercontent.com/kl1ent/CS-GO-Scripting/main/rawetrip/Necron/smallest.ttf"
    },

    {
        name = "zeus_icon.png",
        path = "C:\\necron\\assets\\",
        link = "https://raw.githubusercontent.com/kl1ent/CS-GO-Scripting/main/rawetrip/Necron/zeus_icon.png"
    },

    --[[{
        name = "keyboard.png",
        path = "C:\\necron\\assets\\",
        link = "https://raw.githubusercontent.com/kl1ent/CS-GO-Scripting/main/rawetrip/Necron/keyboard.png"
    },

    {
        name = "spectator.png",
        path = "C:\\necron\\assets\\",
        link = "https://raw.githubusercontent.com/kl1ent/CS-GO-Scripting/main/rawetrip/Necron/spectator.png"
    }]]
}
--- @endregion

--- @region: assets section
local assets = {}

assets.load = function()
    if #Http.assets < 0 then
        return
    end

    for key, value in ipairs(Http.assets) do
        if not value.name and not value.link then
            return
        end

        local current_path = value.path ~= nil and value.path .. value.name or assets_path .. value.name

        if not file.exists(current_path) then
            file.write(current_path, http.get(value.link))
        end
    end
end; assets.load()

assets.logo = render.setup_texture(npath .. "\\assets\\logo.png")
assets.zeus_logo = render.setup_texture(npath .. "\\assets\\zeus_icon.png")
--assets.keyboard = render.setup_texture(npath .. "\\assets\\keyboard.png") 
--assets.spectator = render.setup_texture(npath .. "\\assets\\spectator.png") 
assets.user_avatar = steam.get_user_avatar()
--- @endregion

--- @region: fonts section
local fonts = {}

fonts.velocity = render.setup_font("Verdanab", 27)

fonts.default = render.setup_font("Verdana", 13)
fonts.default_bold = render.setup_font("Verdanab", 13)
fonts.default_naa = render.setup_font("Verdana", 13, fontflags.noantialiasing)

fonts.logo = render.setup_font("Verdana", 17)
if file.exists(npath .. "\\assets\\smallest.ttf") then
    fonts.small = render.setup_font(necron_path .. "assets/smallest.ttf", 10)
end

fonts.small_bold = render.setup_font("Verdanab", 12)
--- @endregion

--- @region: gui section
local gui = {}
gui.items_data = {}

gui.combo_open = false
gui.element_in_bounds = false

gui.selected_tab = "Ragebot"
gui.tabs = {"Ragebot", "Anti-Aim", "Visuals", "Misc", --[["Player list",]] "Configs"}

-- child setup
gui.update_child = function(array)
    array = array == nil and {x = 0, y = 0, offset = 0, right = false} or array

    local x = array.x or 0; local y = array.y or 0; local offset = array.offset or 0; local add_value = array.add_value or 0
    local height = array.height or 270

    local right = array.right or false

    local alpha = array.alpha or 0; local check = array.check or false

    local width = array.width or 230

    local scrolling = array.scrolling or nil; local scroll_alpha = array.scroll_alpha or 0; local scroll_cache = array.scroll_cache or 0; local scroll_value = array.scroll_value or 0; local scorll_cursor = array.scroll_cursor or false

    return {
        x = x, y = y, offset = offset, height = height, add_value = add_value, 
        right = right,
        alpha = alpha, check = check,
        width = width,
        scrolling = scrolling, scroll_alpha = scroll_alpha, scroll_cache = scroll_cache, scroll_value = scroll_value, scroll_cursor = scroll_cursor
    }
end

-- items setup
gui.update_items = function(array)
    if not array then
        return
    end

    local type = array.type or nil; local value = array.value or 1
    local state = array.state or false
    local name = array.name or ""
    local text = array.text or ""

    local items = array.items or {}; local value = array.value or 1

    local callback = array.callback or nil; local visible = array.visible or true

    local setup = array.setup or {}; local elements = array.elements or {}; local loaded = array.loaded or nil
    local selected = array.selected or {}

    local min = array.min or 0; local max = array.max or 0; local float = array.float or false

    local key = array.key or "Disabled"; local key_state = array.key_state or input_system.state["Disabled"]; local active = array.active or false

    return {
        type = type, value = value, 
        state = state, 
        name = name, 
        text = text,
        items = items, value = value,
        callback = callback, visible = visible, 
        setup = setup, elements = elements, loaded = loaded,
        selected = selected,
        min = min, max = max, float = float,
        key = key, key_state = key_state, active = active
    }
end

-- menu items
gui.items = {
    ["Ragebot"] = {
        ["General"] = {
            settings = gui.update_child(),

            items = {
                gui.update_items({name = "Enable revolver helper", type = "checkbox"}),
                gui.update_items({name = "Enable freestand on key", type = "checkbox"}),
                gui.update_items({name = "Freestand key", type = "hotkey"})
            }
        },

        ["Anti-Bruteforce"] = {
            settings = gui.update_child({right = true}),

            items = {
                gui.update_items({name = "Enable anti-bruteforce", type = "checkbox"}),
                gui.update_items({name = "Bruteforce phases", type = "slider", min = 2, max = 20, value = 2}),
                gui.update_items({name = "Add new phase", type = "button"}),
                gui.update_items({name = "Remove phase", type = "button"}),
            }
        }
    },

    ["Anti-Aim"] = {
        ["Roll angles"] = {
            settings = gui.update_child(),

            items = {
                gui.update_items({name = "Enable roll angles", type = "checkbox"}),
                gui.update_items({name = "Roll angles hotkey", type = "hotkey"}),
                gui.update_items({name = "Left roll angle value", type = "slider", min = -45, max = 45, value = 45}),
                gui.update_items({name = "Right roll angle value", type = "slider", min = -45, max = 45, value = -45})
            }
        },

        ["Presets"] = {
            settings = gui.update_child({right = true}),

            items = {
                gui.update_items({name = "Anti-Aim Presets", type = "combo", items = {"None", "Default"}})
            }
        }
    },

    ["Visuals"] = {
        ["Other stuff"] = {
            settings = gui.update_child(),

            items = {
                gui.update_items({name = "Enable weapons in scope", type = "checkbox"}),
                gui.update_items({name = "Enable dark console", type = "checkbox"}),
                gui.update_items({name = "Enable snaplines", type = "checkbox"}),
                gui.update_items({name = "Enable zeusable indicator", type = "checkbox"}),
            }
        },

        ["Grenades stuff"] = {
            settings = gui.update_child(),

            items = {
                gui.update_items({name = "Enable molotov wireframe", type = "checkbox"}),
                gui.update_items({name = "Enable molotov ignore-z", type = "checkbox"})
            }
        },

        ["Indicators list"] = {
            settings = gui.update_child({right = true}),

            items = {
                gui.update_items({name = "Enable velocity warning", type = "checkbox"}),
                gui.update_items({name = "Enable hitmarker", type = "checkbox"}),
                gui.update_items({name = "Enable circles arrows", type = "checkbox"}),
                gui.update_items({name = "Enable indicators", type = "checkbox"}),
                gui.update_items({name = "Enable scope animation", type = "checkbox"}),
                gui.update_items({name = "Indicators type", type = "combo", items = {"Default", "Alternative"}}),
                gui.update_items({name = "Enable information panel", type = "checkbox"}),
                gui.update_items({name = "Information panel type", type = "combo", items = {"Default", "Medusa"}}),
            }
        },

        ["Widgets"] = {
            settings = gui.update_child({right = true, height = 109}),

            items = {
                gui.update_items({name = "Enable watermark", type = "checkbox"}),
                gui.update_items({name = "Enable spectators list", type = "checkbox"}),
                gui.update_items({name = "Enable keybinds", type = "checkbox"})
            }
        }
    },

    ["Misc"] = {
        ["Hitlogging information"] = {
            settings = gui.update_child(),

            items = {
                gui.update_items({name = "Enable hitlogs", type = "checkbox"}),
                gui.update_items({name = "Max hitlogs value", type = "slider", min = 1, max = 15, value = 8}),
            }
        },

        ["Animation breaker"] = {
            settings = gui.update_child(),

            items = {
                gui.update_items({name = "Enable animation breaker", type = "checkbox"}),
                gui.update_items({name = "Enable static legs in air", type = "checkbox"}),
                gui.update_items({name = "Enable pitch 0 on land", type = "checkbox"}),
                gui.update_items({name = "Enable jitter legs", type = "checkbox"}),
                gui.update_items({name = "Jitter value", type = "slider", min = 1, max = 10, value = 4}),
            }
        },

        ["Other stuff"] = {
            settings = gui.update_child({right = true}),

            items = {
                gui.update_items({name = "Enable clantag spammer", type = "checkbox"}),
            }
        }
    },

    --[[["Player list"] = {
        ["Players"] = {
            settings = gui.update_child(),

            items = {
                gui.update_items({name = "Select player", type = "combo", items = {}}),
            }
        },

        ["Settings"] = {
            settings = gui.update_child({right = true}),

            items = {
                
            }  
        }
    },]]

    ["Configs"] = {
        ["Configs"] = {
            settings = gui.update_child(),

            items = {
                gui.update_items({name = "Config slot", type = "combo", items = {"slot1", "slot2", "slot3", "slot4", "slot5"}}),
                gui.update_items({name = "Save", type = "button"}),
                gui.update_items({name = "Load", type = "button"}),
                gui.update_items({name = "Configs path: C:\\necron", type = "button"})
            }
        },

        ["Other stuff"] = {
            settings = gui.update_child({right = true}),

            items = {
                gui.update_items({name = "Menu style", type = "combo", items = {"Default", "Blue", "Red", "White"}}),
                gui.update_items({name = "Enable debug mode", type = "checkbox"}),
                --gui.update_items({name = "Was ist das für ein Mist", type = "checkbox"}),
                gui.update_items({name = "Discord link", type = "button", callback = function() 
                    console.execute_client_cmd("clear")
                    console.execute_client_cmd("showconsole")

                    print("https://discord.gg/tPfYp4WeXq")
                end}),
            }
        }
    }
}

--- @region: paint items
-- child
gui.create_child = function(array, title, update_offset, check, menu_x, menu_y)
    local x, y = array.x, array.y
    local add_value = 0

    local width, height = 245, array.height - 5

    local scroll_offset = 35
    local scroll_smooth = animation.new("child::scroll::" .. title, array.scroll_cache, 18)

    local c_height = update_offset
    local vRatio = height / c_height
    local s_height = height * vRatio
    local scrollY = (vRatio * scroll_smooth)

    array.alpha = animation.lerp(array.alpha, check and 1 or 0, 12)
    array.scroll_alpha = animation.lerp(array.scroll_alpha, input_system.cursor_in_bounds(x + width + 3, y + scrollY, 5, s_height) and 100 or 50, 12)
    if array.alpha > 0.2 then
        render.text(fonts.default, x, y-20, color.new(255, 255, 255, 255*array.alpha), title)

        if update_offset > height then
            render.rect_filled_rounded(x + width + 3, y + scrollY, 5, s_height, 10, 10, color.new(255, 255, 255, array.scroll_alpha*array.alpha))
        end
    end

    if update_offset > height then
        if input_system.cursor_in_bounds(x + width + 3, y + scrollY, 5, s_height) then
            array.scroll_cursor = true

            if input_system.is_key_down(0x01) then
                array.scrolling = not array.scrolling and engine.get_cursor_position().y - scrollY + 5 or array.scrolling
            end
        elseif not input_system.is_key_down(0x01) then
            array.scrolling = nil
        else
            array.scroll_cursor = false
        end

        if array.scrolling then
            array.scroll_cache = math.min(math.max((engine.get_cursor_position().y - array.scrolling) / vRatio, 0), c_height - height)
        end
    else
        array.scroll_cache = 0
    end

    if input_system.cursor_in_bounds(x, y, width, height) and (c_height > height) then
        if im.call("GetScrollY") >= 1.0 then
            array.scroll_cache = math.max(array.scroll_cache - scroll_offset, 0)
        elseif im.call("GetScrollY") <= -1.0 then
            array.scroll_cache = math.min(array.scroll_cache + scroll_offset, c_height - height)
        end
    end

    add_value = array.right and (width + 20) or add_value

    array.x, array.y = menu_x + add_value + 190, menu_y + array.add_value + 50
    array.offset = 0
    array.check = check
    array.width = width

    array.scroll_value = scroll_smooth
end

-- button
gui.create_button = function(tab_name, child_name, child_element, array)
    local element_data = ("%s.%s.%s.button"):format(tab_name, child_name, array.name)
    if not gui.items_data[element_data] then
        gui.items_data[element_data] = {
            alpha = {
                visible = 0,
            },

            offset = 0,

            color = {
                bounds = color.new(255, 255, 255, 30)
            }
        }
    end

    local r, g, b = color.unpack(script.data:get_color())

    local self = gui.items_data[element_data]
    local cache = array

    local text = array.name:wrap(30).text
    local text_height = render.get_text_height(fonts.default, text)

    local width, height = child_element.width, math.max(text_height + 20, 35)
    local x, y = child_element.x, child_element.y + 5 + self.offset - child_element.scroll_value

    local button_in_bounds = false
    if gui.combo_open == true then
        button_in_bounds = false
    else
        button_in_bounds = input_system.cursor_in_bounds(child_element.x, child_element.y, child_element.width, child_element.height) and input_system.cursor_in_bounds(x, y, width, height)
    end

    gui.element_in_bounds = button_in_bounds

    self.offset = animation.lerp(self.offset, child_element.offset, 12)

    self.alpha.visible = animation.lerp(self.alpha.visible, child_element.check and array.visible and 1 or 0, 20)

    self.color.bounds = animation.lerp(self.color.bounds, button_in_bounds and color.new(255, 255, 255, 70) or color.new(255, 255, 255, 30), 12)

    local b_r, b_g, b_b, b_a = color.unpack(self.color.bounds)

    render.rect_filled_rounded(x, y, width, height, 10, 4, color.new(b_r, b_g, b_b, b_a*self.alpha.visible))

    local name = text
    local name_width, name_height = render.get_text_width(fonts.default, name), text_height

    render.text(fonts.default, x + (width / 2) - (name_width / 2), y + (height / 2) - (name_height / 2), color.new(255, 255, 255, 255*self.alpha.visible), name)

    if button_in_bounds and input_system.is_key_pressed(0x01) and array.visible and child_element.check then
        if cache.callback ~= nil then
            array.callback() 
        end
    end

    child_element.offset = child_element.offset + (height + 10)
    child_element.offset = not array.visible and child_element.offset - (height + 10) or child_element.offset

    return cache
end

-- slider
gui.create_slider = function(tab_name, child_name, child_element, array)
    local element_data = ("%s.%s.%s.slider"):format(tab_name, child_name, array.name)
    if not gui.items_data[element_data] then
        gui.items_data[element_data] = {
            alpha = {
                visible = 0,
            },

            offset = 0,
            divider = 0,
            value = 0,

            color = {
                bounds = color.new(255, 255, 255, 30)
            }
        }
    end

    local r, g, b = color.unpack(script.data:get_color())

    local self = gui.items_data[element_data]
    local cache = array

    local text = array.name
    local text_height = render.get_text_height(fonts.default, text)

    local width, height = child_element.width, math.max(text_height + 20, 55)
    local x, y = child_element.x, child_element.y + 5 + self.offset - child_element.scroll_value

    local slider_in_bounds = false
    if gui.combo_open == true then
        slider_in_bounds = false
    else
        slider_in_bounds = input_system.cursor_in_bounds(child_element.x, child_element.y, child_element.width, child_element.height) and input_system.cursor_in_bounds(x, y, width, height)
    end

    gui.element_in_bounds = slider_in_bounds

    local fraction = (array.value - array.min) / (array.max - array.min)
    self.value = fraction * (width - 20)

    self.offset = animation.lerp(self.offset, child_element.offset, 12)

    self.alpha.visible = animation.lerp(self.alpha.visible, child_element.check and array.visible and 1 or 0, 20)

    self.color.bounds = animation.lerp(self.color.bounds, slider_in_bounds and color.new(255, 255, 255, 70) or color.new(255, 255, 255, 30), 12)

    self.divider = animation.lerp(self.divider, self.value, 12)

    if slider_in_bounds and input_system.is_key_down(0x01) and array.visible and child_element.check then
        self.value = math.clamp(engine.get_cursor_position().x - (x + 5), 0, width)
        cache.value = array.float and (self.value * ((array.max - array.min) / (width - 10)) + array.min) or math.floor(math.round(self.value * ((array.max - array.min) / (width - 10)) + array.min))
    end

    cache.value = math.clamp(array.value, array.min, array.max)

    local b_r, b_g, b_b, b_a = color.unpack(self.color.bounds)

    render.rect_filled_rounded(x, y, width, height, 10, 4, color.new(b_r, b_g, b_b, b_a*self.alpha.visible))

    render.text(fonts.default, x + 10, y + 7, color.new(255, 255, 255, 120*self.alpha.visible), text)

    local value = array.value
    local value_width = render.get_text_width(fonts.default, value)

    render.text(fonts.default, x + width - value_width - 10, y + 7, color.new(255, 255, 255, 255*self.alpha.visible), value)

    render.rect_filled_rounded(x + 10, y + 35, width - 20, 6, 10, 5, color.new(30, 30, 30, 255*self.alpha.visible))
    render.rect_filled_rounded(x + 10, y + 35, self.divider, 6, 10, 5, color.new(r, g, b, 255*self.alpha.visible))
    render.gradient(x + 10, y + 35, self.divider, 6, color.new(0, 0, 0, 80*self.alpha.visible), color.new(0, 0, 0, 0*self.alpha.visible), 0)

    render.circle_filled(x + 10 + self.divider, y + 38, 180, 9, color.new(120, 120, 120, 90*self.alpha.visible))
    render.circle_filled(x + 10 + self.divider, y + 38, 180, 6, color.new(255, 255, 255, 255*self.alpha.visible))

    child_element.offset = child_element.offset + (height + 10)
    child_element.offset = not array.visible and child_element.offset - (height + 10) or child_element.offset

    return cache
end

-- checkbox
gui.create_checkbox = function(tab_name, child_name, child_element, array)
    local element_data = ("%s.%s.%s.checkbox"):format(tab_name, child_name, array.name)
    if not gui.items_data[element_data] then
        gui.items_data[element_data] = {
            alpha = {
                visible = 0,
            },

            offset = 0,
            divider = 0,

            color = {
                active = color.new(255, 255, 255, 255),
                bounds = color.new(255, 255, 255, 30)
            }
        }
    end

    local r, g, b = color.unpack(script.data:get_color())

    local self = gui.items_data[element_data]
    local cache = array

    local text = array.name:wrap(27).text
    local text_height = render.get_text_height(fonts.default, text)

    local width, height = child_element.width, math.max(text_height + 20, 35)
    local x, y = child_element.x, child_element.y + 5 + self.offset - child_element.scroll_value

    local checkbox_in_bounds = false
    if gui.combo_open == true then
        checkbox_in_bounds = false
    else
        checkbox_in_bounds = input_system.cursor_in_bounds(child_element.x, child_element.y, child_element.width, child_element.height) and input_system.cursor_in_bounds(x, y, width, height)
    end

    gui.element_in_bounds = checkbox_in_bounds

    self.offset = animation.lerp(self.offset, child_element.offset, 12)

    self.alpha.visible = animation.lerp(self.alpha.visible, child_element.check and array.visible and 1 or 0, 20)

    self.color.active = animation.lerp(self.color.active, array.state and color.new(r, g, b, 255) or color.new(255, 255, 255, 255), 12)
    self.color.bounds = animation.lerp(self.color.bounds, checkbox_in_bounds and color.new(255, 255, 255, 70) or color.new(255, 255, 255, 30), 12)

    self.divider = animation.lerp(self.divider, array.state and 17 or 0, 12)

    local a_r, a_g, a_b, a_a = color.unpack(self.color.active)
    local b_r, b_g, b_b, b_a = color.unpack(self.color.bounds)

    render.rect_filled_rounded(x, y, width, height, 10, 4, color.new(b_r, b_g, b_b, b_a*self.alpha.visible))
    render.rect_filled_rounded(x + width - 45, y + (height / 2) - (17 / 2), 35, 17, 10, 8, color.new(30, 30, 30, 255*self.alpha.visible))

    render.circle_filled(x + width - 36 + self.divider, y + (height / 2) - (17 / 2) + 8, 180, 5, color.new(a_r, a_g, a_b, a_a*self.alpha.visible))

    render.text(fonts.default, x + 10, y + (height / 2) - (text_height / 2), color.new(255, 255, 255, 120*self.alpha.visible), text)

    if checkbox_in_bounds and input_system.is_key_pressed(0x01) and array.visible and child_element.check then
        cache.state = not cache.state
    end

    child_element.offset = child_element.offset + (height + 10)
    child_element.offset = not array.visible and child_element.offset - (height + 10) or child_element.offset

    return cache
end

-- hotkey
gui.create_hotkey = function(tab_name, child_name, child_element, array)
    local element_data = ("%s.%s.%s.hotkey"):format(tab_name, child_name, array.name)
    if not gui.items_data[element_data] then
        gui.items_data[element_data] = {
            alpha = {
                visible = 0,
                open = 0
            },

            offset = 0,

            listening = false, 
            changingstate = false,

            color = {
                bounds = color.new(255, 255, 255, 30)
            }
        }
    end

    local r, g, b = color.unpack(script.data:get_color())

    local self = gui.items_data[element_data]
    local cache = array

    local text = array.name:wrap(27).text
    local text_height = render.get_text_height(fonts.default, text)

    local list_offset = 0
    for key, value in pairs(input_system.state) do
        list_offset = list_offset + 20 * self.alpha.open
    end

    local width, height = child_element.width, math.max(text_height + 20, math.max(self.changingstate and list_offset + 60 or 0, 50))
    local x, y = child_element.x, child_element.y + 5 + self.offset - child_element.scroll_value

    local hotkey_in_bounds = false
    if gui.combo_open == true then
        hotkey_in_bounds = false
    else
        hotkey_in_bounds = input_system.cursor_in_bounds(child_element.x, child_element.y, child_element.width, child_element.height) and input_system.cursor_in_bounds(x, y, width, height)
    end

    gui.element_in_bounds = hotkey_in_bounds

    self.offset = animation.lerp(self.offset, child_element.offset, 12)

    self.alpha.visible = animation.lerp(self.alpha.visible, child_element.check and array.visible and 1 or 0, 20)
    self.alpha.open = animation.lerp(self.alpha.open, self.changingstate and 1 or 0, 12)

    self.color.bounds = animation.lerp(self.color.bounds, (not self.changingstate and hotkey_in_bounds) and color.new(255, 255, 255, 70) or color.new(255, 255, 255, 30), 12)

    local b_r, b_g, b_b, b_a = color.unpack(self.color.bounds)

    if child_element.check and array.visible then
        if hotkey_in_bounds then
            if input_system.is_key_pressed(2) and not self.listening and not self.changingstate then
                self.changingstate = not self.changingstate
            end
            if input_system.is_key_pressed(1) and not self.listening and not self.changingstate then
                self.listening = true
            end
        else
            if input_system.is_key_pressed(2) then
                self.changingstate = false
            end
        end
    end

    if self.listening then
        for key, value in pairs(input_system.keys) do
            if input_system.is_key_pressed(value) and not input_system.is_key_pressed(1) then
                cache.key = tostring(key)
                self.listening = false
            end
        end
    end

    render.rect_filled_rounded(x, y, width, height, 10, 4, color.new(b_r, b_g, b_b, b_a*self.alpha.visible))
    render.text(fonts.default, x + 10, y + (height / 2) - (text_height / 2), color.new(255, 255, 255, 120*self.alpha.visible), text)
    render.rect_filled_rounded(x, y, width, height, 10, 4, color.new(0, 0, 0, 100*self.alpha.visible*self.alpha.open))

    local value = self.listening and "..." or (array.key_state == input_system.state["Always"]) and "on" or (array.key_state == input_system.state["Disabled"]) and "none" or array.key
    local value_width, value_height = render.get_text_width(fonts.default, value), render.get_text_height(fonts.default, value)
    local value_size = math.max(value_width + 15, 65)

    render.rect_filled_rounded(x + width - (value_size + 10), y + ((self.changingstate and 40 or height) / 2) - (28 / 2), value_size, 28, 10, 4, color.new(30, 30, 30, 255*self.alpha.visible))

    local new_x, new_y = x + width - (value_size + 10), y + ((self.changingstate and 40 or height) / 2) - (28 / 2)
    render.text(fonts.default, new_x + (value_size / 2) - (value_width / 2), new_y + (28 / 2) - (value_height / 2), color.new(255, 255, 255, 255*self.alpha.visible), value)

    local new_text_width = 120
    local new_x1, new_y1 = x + width - ((new_text_width + 10)*self.alpha.open), y + ((self.changingstate and 50 or height) / 2) - ((25*self.alpha.open) / 2)
    local new_width, new_height = (new_text_width*self.alpha.open), (25*self.alpha.open)

    render.rect_filled_rounded(new_x1, new_y1 + 25, new_width, list_offset, 10, 3, color.new(23, 24, 25, 255*self.alpha.visible*self.alpha.open))
    render.rect_rounded(new_x1, new_y1 + 24, new_width, list_offset, color.new(255, 255, 255, 20*self.alpha.visible*self.alpha.open), 3)

    local text_offset = 25
    for key, value in pairs(input_system.state) do
        render.text(fonts.default, new_x1 + 5, new_y1 + text_offset + 3, color.new(255, 255, 255, (array.key_state == value and 255 or 100)*self.alpha.visible*self.alpha.open), key)

        local text_in_bounds = input_system.cursor_in_bounds(new_x1 + 5, new_y1 + text_offset + 1, 100, 20)
        if text_in_bounds and input_system.is_key_pressed(0x01) then
            cache.key_state = value
            self.changingstate = false
        end

        text_offset = text_offset + 18 * self.alpha.open
    end

    if self.changingstate and not input_system.cursor_in_bounds(new_x1, new_y1 + 25, new_width, list_offset) and input_system.is_key_pressed(0x01) then
        self.changingstate = false
    end 

    child_element.offset = child_element.offset + (height + 10)
    child_element.offset = not array.visible and child_element.offset - (height + 10) or child_element.offset

    return cache
end

-- combobox
gui.create_combo = function(tab_name, child_name, child_element, array)
    local element_data = ("%s.%s.%s.combobox"):format(tab_name, child_name, array.name)
    if not gui.items_data[element_data] then
        gui.items_data[element_data] = {
            alpha = {
                visible = 0,
                open = 0
            },

            offset = 0,

            open = false,

            divider = 0,

            color = {
                bounds = color.new(255, 255, 255, 30)
            }
        }
    end

    local r, g, b = color.unpack(script.data:get_color())

    local self = gui.items_data[element_data]
    local cache = array

    local text = array.name:wrap(15).text
    local text_height = render.get_text_height(fonts.default, text)

    local list_offset = 0
    for key, value in ipairs(array.items) do
        list_offset = list_offset + 20 * self.alpha.open
    end

    local width, height = child_element.width, math.max(text_height + 20, math.max(self.open and list_offset + 60 or 0, 50))
    local x, y = child_element.x, child_element.y + 5 + self.offset - child_element.scroll_value

    local value = array.items[array.value]
    local value_width, value_height = render.get_text_width(fonts.default, value), render.get_text_height(fonts.default, value)

    local combo_in_bounds = input_system.cursor_in_bounds(child_element.x, child_element.y, child_element.width, child_element.height) and input_system.cursor_in_bounds(x, y, width, height)

    gui.element_in_bounds = combo_in_bounds

    self.offset = animation.lerp(self.offset, child_element.offset, 12)

    self.alpha.visible = animation.lerp(self.alpha.visible, child_element.check and array.visible and 1 or 0, 20)
    self.alpha.open = animation.lerp(self.alpha.open, self.open and 1 or 0, 12)

    self.color.bounds = animation.lerp(self.color.bounds, (not self.open and combo_in_bounds) and color.new(255, 255, 255, 70) or color.new(255, 255, 255, 30), 12)

    self.divider = animation.lerp(self.divider, self.open and (value_width + 15) or value_width + 15, 12)

    local b_r, b_g, b_b, b_a = color.unpack(self.color.bounds)

    render.rect_filled_rounded(x, y, width, height, 10, 4, color.new(b_r, b_g, b_b, b_a*self.alpha.visible))

    render.text(fonts.default, x + 10, y + (height / 2) - (text_height / 2), color.new(255, 255, 255, 120*self.alpha.visible), text)

    render.rect_filled_rounded(x, y, width, height, 10, 4, color.new(0, 0, 0, 100*self.alpha.visible*self.alpha.open))

    local new_text_width = 120
    local new_x, new_y = x + width - ((new_text_width + 10)*self.alpha.open), y + ((self.open and 40 or height) / 2) - ((25*self.alpha.open) / 2)
    local new_width, new_height = (new_text_width*self.alpha.open), (25*self.alpha.open)

    render.rect_filled_rounded(new_x, new_y + 25, new_width, list_offset, 10, 3, color.new(23, 24, 25, 255*self.alpha.visible*self.alpha.open))
    render.rect_rounded(new_x, new_y + 24, new_width, list_offset, color.new(255, 255, 255, 20*self.alpha.visible*self.alpha.open), 3)

    local text_offset = 25
    for key, value in ipairs(array.items) do
        render.text(fonts.default, new_x + 5, new_y + text_offset + 3, color.new(255, 255, 255, (array.value == key and 255 or 100)*self.alpha.visible*self.alpha.open), value)

        local text_in_bounds = input_system.cursor_in_bounds(new_x + 5, new_y + text_offset + 1, 100, 20)
        if text_in_bounds and input_system.is_key_pressed(0x01) then
            cache.value = key
        end

        text_offset = text_offset + 18 * self.alpha.open
    end

    render.text(fonts.default, x + width - self.divider, y + ((self.open and 40 or height) / 2) - (value_height / 2), color.new(255, 255, 255, 255*self.alpha.visible), value)

    if combo_in_bounds and input_system.is_key_pressed(0x01) and array.visible and child_element.check then
        self.open = true
        gui.combo_open = true
    elseif not input_system.cursor_in_bounds(new_x, new_y + 25, (120*self.alpha.open), list_offset) and input_system.is_key_pressed(0x01) and array.visible and child_element.check and not child_element.scroll_cursor then
        self.open = false
        gui.combo_open = false
    end

    child_element.offset = child_element.offset + (height + 10)
    child_element.offset = not array.visible and child_element.offset - (height + 10) or child_element.offset

    return cache
end
--- @endregion

--- @region: menu functions
gui.__index = gui

-- Update Hotkey States
gui.update_hotkey = function(array)
    local cache = array

    if array.key == nil then
        return false
    else
        if array.key_state == input_system.state["Disabled"] then
            cache.active = false
        elseif array.key_state == input_system.state["Always"] then
            cache.active = true
        elseif array.key_state == input_system.state["Toggle"] then
            if input_system.is_key_pressed(input_system.keys[array.key]) then
                cache.active = not cache.active
            end
        elseif array.key_state == input_system.state["Hold"] then
            cache.active = input_system.is_key_down(input_system.keys[array.key])
        end
    end

    return cache.active
end

-- Find Var
function gui.find(tab, child, name)
    return setmetatable({tab = tab or "", child = child or "", name = name or ""}, gui)
end

-- Get value
function gui:get(is_hotkey)
    local update = gui.items[self.tab][self.child].items

    for key, data in ipairs(update) do
        if self.name == data.name then
            if data.type == "checkbox" then
                return data.state
            elseif data.type == "slider" then
                return data.value
            elseif data.type == "combo" then
                return data.value
            elseif data.type == "hotkey" then
                if not is_hotkey then
                    return data.active
                else
                    return {data.key, data.key_state, data.active}
                end
            end
        end
    end
end

-- Set Value
function gui:set(val, is_hotkey)
    local update = gui.items[self.tab][self.child].items

    for key, data in ipairs(update) do
        if self.name == data.name then
            if data.type == "checkbox" then
                data.state = val
            elseif data.type == "button" then
                data.callback = val
            elseif data.type == "combo" then
                data.value = val
            elseif data.type == "slider" then
                data.value = val
            elseif data.type == "hotkey" then
                if not is_hotkey then
                    data.active = val
                else
                    data.key = val[1]
                    data.key_state = val[2]
                    data.active = val[3]
                end
            end
        end
    end
end

-- Set Visible
function gui:set_visible(val)
    local update = gui.items[self.tab][self.child].items

    for key, data in ipairs(update) do
        if self.name == data.name and type(val) == "boolean" then
            data.visible = val
        end
    end
end

-- Get Child Offset
function gui.get_child_offset(tab, child, height)
    return height and gui.items[tab][child].settings.height or gui.items[tab][child].settings.offset
end

-- Set Child Value
function gui.set_child_value(tab, child, value)
    gui.items[tab][child].settings.add_value = value
end

-- Create New Element
function gui.create_new_element(tab, child, array)
    table.insert(gui.items[tab][child].items, gui.update_items(array))

    return {tab, child, array.name}
end

-- Destroy Element
function gui.destroy_element(tab, child, index)
    table.remove(gui.items[tab][child].items, index)
end

-- Get Child Items
function gui.get_child_items(tab, child)
    return gui.items[tab][child].items
end

-- Update Combo Items
function gui:update_combo_items(value)
    local update = gui.items[self.tab][self.child].items

    for key, data in ipairs(update) do
        if self.name == data.name then
            if data.type == "combo" then
                data.items = value
            end
        end
    end
end

setmetatable(gui, {__call = function(Table, ...) return gui.find(...) end})
--- @endregion
--- @endregion

--- @region: dragging
local dragging_fn = function(name, base_x, base_y) return (function()local a={}local b,c,d,e,f,g,h,i,j,k,l,m,n,o;local p={ __index={drag=function(self,...)local q,r=self:get()local s,t=a.drag(q,r,...)if q~=s or r~=t then self:set(s,t)end;return s,t end,set=function(self,q,r)local j,k=engine.get_screen_width(), engine.get_screen_height()self.x_reference:set(q/j*self.res)self.y_reference:set(r/k*self.res)end,get=function(self)local j,k=engine.get_screen_width(), engine.get_screen_height()return self.x_reference:get()/self.res*j,self.y_reference:get()/self.res*k end}}function a.new(u,v,w,x)x=x or 10000;local j,k=engine.get_screen_width(), engine.get_screen_height();gui.create_new_element("Configs", "Other stuff", {name = u.." window position", type = "slider", min = 0, max = x, value = v/j*x});gui.create_new_element("Configs", "Other stuff", {name = u.." window position y", type = "slider", min = 0, max = x, value = w/k*x});local y=gui.find("Configs", "Other stuff", u.." window position");local z=gui.find("Configs", "Other stuff", u.." window position y");y:set_visible(false);z:set_visible(false);return setmetatable({name=u,x_reference=y,y_reference=z,res=x},p);end;function a.drag(q,r,A,B,C,D,E)if globalvars.get_framecount()~=b then c=globalvars.is_open_menu()f,g=d,e;d,e=engine.get_cursor_position().x, engine.get_cursor_position().y;i=h;h=engine.get_active_key(0x01)==true;m=l;l={};o=n;n=false;j,k=engine.get_screen_width(), engine.get_screen_height()end;if c and i~=nil then if(not i or o)and h and f>q and g>r and f<q+A and g<r+B then n=true;q,r=q+d-f,r+e-g;if not D then q=math.max(0,math.min(j-A,q))r=math.max(0,math.min(k-B,r))end end end;table.insert(l,{q,r,A,B})return q,r,A,B end;return a end)().new(name, base_x, base_y) end
--- @endregion

--- @region: paint
local paint = {}
paint.animate = {}

paint.animate.tabs = {}

-- @region: tabs
paint.tabs = function(x, y, alpha, width, tabs_width)
    local tabs_offset = 0
    local r, g, b = color.unpack(script.data:get_color())

    for key, value in ipairs(gui.tabs) do
        if not paint.animate.tabs[key] then
            paint.animate.tabs[key] = {
                alpha = 0,
                color = color.new(15, 15, 15, 0), text_color = color.new(255, 255, 255, 100)
            }
        end

        local data = paint.animate.tabs[key]

        local new_x, new_y = x + (tabs_width / 2) - (width / 2), y + tabs_offset
        local new_height = 30

        local tabs_in_bounds = input_system.cursor_in_bounds(new_x, new_y, width, new_height)

        data.color = animation.lerp(data.color, gui.selected_tab == value and color.new(20, 20, 20, 255) or color.new(20, 20, 20, 0), 15)
        data.text_color = animation.lerp(data.text_color, (gui.selected_tab == value or tabs_in_bounds) and color.new(255, 255, 255, 255) or color.new(255, 255, 255, 100), 15)

        local c_r, c_g, c_b, c_a = color.unpack(data.color)
        local t_r, t_g, t_b, t_a = color.unpack(data.text_color)

        render.rect_filled_rounded(new_x, new_y, width, new_height, 10, 4, color.new(c_r, c_g, c_b, c_a*alpha))
        render.rect_filled_rounded(new_x + width - 2, new_y, 2, new_height, 10, 5, color.new(r, g, b, c_a*alpha))

        local text_height = render.get_text_height(fonts.default)
        render.text(fonts.default, new_x + 10, new_y + (new_height / 2) - (text_height / 2), color.new(t_r, t_g, t_b, t_a*alpha), value)

        if tabs_in_bounds and input_system.is_key_pressed(0x01) then
            gui.selected_tab = value
        end

        tabs_offset = tabs_offset + 40
    end
end
--- @endregion
paint.dragging = {0, 0, 0}
paint.position = {0, 30}
paint.window = function()
    local x, y = paint.position[1], paint.position[2]
    local width, height = script.data:get_menu():unpack()
    local head_height = 40
    local tabs_width = 170

    local username = "Klient"
    local version = script.data:get_version()
    local script_name = script.data:get_name()

    local r, g, b = color.unpack(script.data:get_color())
    local alpha = animation.new("window::alpha", globalvars.is_open_menu() and 1 or 0, 12)

    if alpha > 0.1 then
        -- header
        render.begin_cliprect(x, y - head_height + 5, width, head_height)
        render.blur(x, y - head_height + 10, width, head_height, 255*alpha)
        render.rect_filled_rounded(x, y - head_height + 10, width, head_height, 10, 5, color.new(135, 135, 135, 50*alpha))
        render.rect_rounded(x, y - head_height + 10, width, head_height, color.new(255, 255, 255, 30*alpha), 5)

        local script_name_width, script_name_height = render.get_text_width(fonts.logo, script_name:lower()), render.get_text_height(fonts.logo, script_name:lower())

        if alpha > 0.4 then
            render.image(assets.logo, x + (width / 2) - (45 / 2) - script_name_width, y - head_height + 9 + (head_height / 2) - (23 / 2), 45, 23)
        end

        render.text(fonts.logo, x + (width / 2) - (45 / 2) + 5, y - head_height + 9 + (head_height / 2) - (script_name_height / 2), color.new(255, 255, 255, 150*alpha), script_name:lower())
        render.end_cliprect()

        -- main
        render.begin_cliprect(x, y + 5, width, height)
        render.blur(x, y + 5, width, height - 5, 255*alpha)
        render.blur(x, y + 5, width, height - 5, 255*alpha)
        render.rect_filled_rounded(x, y, width, height, 10, 5, color.new(10, 10, 10, 240*alpha))
        render.rect_rounded(x, y, width, height, color.new(255, 255, 255, 30*alpha), 5)
        render.end_cliprect()

        render.rect_filled(x, y + 5, width, 1, color.new(255, 255, 255, 30*alpha))

        -- tabs
        render.rect_filled(x + tabs_width, y + 5, 1, height - 5, color.new(255, 255, 255, 30*alpha))

        paint.tabs(x, y + 30, alpha, tabs_width - 25, tabs_width)
    end

    -- loading
    local realtime = globalvars.get_realtime()*1.5

    loading_time = loading_time - globalvars.get_frametime()
    local loading_alpha = animation.new("window::loading::alpha", loading_time <= 0 and 0 or 1, 12)

    if loading_alpha > 0.2 and alpha > 0.1 then
        render.arc(x + (width / 2) - (20 / 2) + (tabs_width / 2), y + (height / 2) - (20 / 2), 17, 20, 0, 360, color.new(20, 21, 23, 255*loading_alpha*alpha))

        if realtime%2 <= 1 then
            render.arc(x + (width / 2) - (20 / 2) + (tabs_width / 2), y + (height / 2) - (20 / 2), 17, 20, 0, (realtime%1)*360, color.new(255, 255, 255, 20*loading_alpha*alpha))
        else
            render.arc(x + (width / 2) - (20 / 2) + (tabs_width / 2), y + (height / 2) - (20 / 2), 17, 20, realtime%1*370, (1-realtime%1)*360, color.new(255, 255, 255, 20*loading_alpha*alpha))
        end
    end

    -- items
    local childs_offset = height - 8
    if loading_alpha < 0.5 then
        for index, data in pairs(gui.items) do
            for key, value in pairs(data) do
                render.begin_cliprect(x + tabs_width, y + 7, width - tabs_width, height - 8)

                if gui.selected_tab == index and globalvars.is_open_menu() and alpha > 0.1 then
                    gui.create_child(value.settings, key, value.settings.offset, gui.selected_tab == index and true or false, x, y)

                    for keys, items in ipairs(value.items) do
                        render.begin_cliprect(value.settings.x, value.settings.y, value.settings.width, value.settings.height)
                        if items.type == "button" then
                            items.setup = gui.create_button(index, key, value.settings, items)
                        end

                        if items.type == "checkbox" then
                            items.setup = gui.create_checkbox(index, key, value.settings, items)
                        end

                        if items.type == "combo" then
                            items.setup = gui.create_combo(index, key, value.settings, items)
                        end

                        if items.type == "slider" then
                            items.setup = gui.create_slider(index, key, value.settings, items)
                        end

                        if items.type == "hotkey" then
                            items.setup = gui.create_hotkey(index, key, value.settings, items)
                        end
                        render.end_cliprect()
                    end
                end
                render.end_cliprect()
            end
        end
    end

    if alpha > 0.1 then
        local header_in_bounds = input_system.cursor_in_bounds(x, y - head_height + 5, width, head_height)
        local mouse = engine.get_cursor_position()
        if header_in_bounds then
            if (input_system.is_key_down(0x01)) and (paint.dragging[1] == 0) then
                paint.dragging[1] = 1
                paint.dragging[2] = paint.position[1] - mouse.x
                paint.dragging[3] = paint.position[2] - mouse.y
            end
        end
        if not input_system.is_key_down(0x01) then paint.dragging[1] = 0; end
        if paint.dragging[1] == 1 and globalvars.is_open_menu() then
            local q = math.max(0, math.min(engine.get_screen_width() - width, mouse.x + paint.dragging[2]));
            local r = math.max(head_height - 9, math.min(engine.get_screen_height() - head_height, mouse.y + paint.dragging[3]));

            paint.position[1], paint.position[2] = q, r
        end
    end
end
--- @endregion

--- @region: update ui
local update_ui = {}

update_ui.change_child_offset = function(who, to, tab, child, anim_name)
    local child_height = gui.get_child_offset(who, to, true)
    local child_offset = gui.get_child_offset(who, to)

    local total_height = child_offset > child_height and child_height or child_offset
    local child_offset_anim = animation.new(anim_name, total_height + 30, 12)

    gui.set_child_value(tab, child, child_offset_anim)
end

update_ui.handle = function()
    local roll_var = gui.find("Anti-Aim", "Roll angles", "Enable roll angles")
    local roll_hotkey_var = gui.find("Anti-Aim", "Roll angles", "Roll angles hotkey")
    local left_roll_value_var = gui.find("Anti-Aim", "Roll angles", "Left roll angle value")
    local right_roll_value_var = gui.find("Anti-Aim", "Roll angles", "Right roll angle value")

    roll_hotkey_var:set_visible(roll_var:get())
    left_roll_value_var:set_visible(roll_var:get())
    right_roll_value_var:set_visible(roll_var:get())

    local animation_breaker_var = gui.find("Misc", "Animation breaker", "Enable animation breaker")
    local animation_breaker_static_legs = gui.find("Misc", "Animation breaker", "Enable static legs in air")
    local animation_breaker_pitch_on_land = gui.find("Misc", "Animation breaker", "Enable pitch 0 on land")
    local animation_breaker_jitter_legs = gui.find("Misc", "Animation breaker", "Enable jitter legs")
    local animation_breaker_jitter_value = gui.find("Misc", "Animation breaker", "Jitter value")

    animation_breaker_static_legs:set_visible(animation_breaker_var:get())
    animation_breaker_pitch_on_land:set_visible(animation_breaker_var:get())
    animation_breaker_jitter_legs:set_visible(animation_breaker_var:get())
    animation_breaker_jitter_value:set_visible(animation_breaker_var:get() and animation_breaker_jitter_legs:get())

    local indicators_var = gui.find("Visuals", "Indicators list", "Enable indicators")
    local indicators_type_var = gui.find("Visuals", "Indicators list", "Indicators type")
    local scope_animation = gui.find("Visuals", "Indicators list", "Enable scope animation")

    indicators_type_var:set_visible(indicators_var:get())
    scope_animation:set_visible(indicators_var:get())

    local info_panel_var = gui.find("Visuals", "Indicators list", "Enable information panel")
    local info_panel_type_var = gui.find("Visuals", "Indicators list", "Information panel type")

    info_panel_type_var:set_visible(info_panel_var:get())

    local hitlogs_var = gui.find("Misc", "Hitlogging information", "Enable hitlogs")
    local hitlogs_max_var = gui.find("Misc", "Hitlogging information", "Max hitlogs value")

    hitlogs_max_var:set_visible(hitlogs_var:get())

    local phases_var = gui.find("Ragebot", "Anti-Bruteforce", "Bruteforce phases")

    phases_var:set_visible(false)

    local phases_1_var = gui.find("Ragebot", "Anti-Bruteforce", "Fake limit phase [1]")
    local phases_2_var = gui.find("Ragebot", "Anti-Bruteforce", "Fake limit phase [2]")

    local anti_brute_var = gui.find("Ragebot", "Anti-Bruteforce", "Enable anti-bruteforce")

    phases_1_var:set_visible(anti_brute_var:get())
    phases_2_var:set_visible(anti_brute_var:get())

    local freestand_on_key_var = gui.find("Ragebot", "General", "Enable freestand on key")
    local freestand_key_var = gui.find("Ragebot", "General", "Freestand key")

    freestand_key_var:set_visible(freestand_on_key_var:get())

    --- @region: update offsets
    update_ui.change_child_offset("Misc", "Hitlogging information", "Misc", "Animation breaker", "hitlogging_stuff_child_offset_anim")
    update_ui.change_child_offset("Visuals", "Indicators list", "Visuals", "Widgets", "indicators_stuff_child_offset_anim")
    update_ui.change_child_offset("Visuals", "Other stuff", "Visuals", "Grenades stuff", "other_stuff_child_offset_anim")
    --- @endregion

    --- @region: update menu style
    local style_var = gui.find("Configs", "Other stuff", "Menu style")
    local style_table = {color.new(255, 192, 118), color.new(126, 132, 255), color.new(255, 87, 87),color.new(255, 255, 255)}

    script.data:set_color(style_table[style_var:get()])
    --- @endregion
end
--- @endregion

--- @region: all ragebot functions
local ragebot = {}

-- revolver helper
ragebot.check_revolver_distance = function(Player, Victim)
    if not Player then
        return
    end

    if not Victim then
        return
    end

    local PlayerWeapon = entitylist.get_weapon_by_player(Player)

    if not PlayerWeapon then
        return
    end

    local m_iItemDefinitionIndex = PlayerWeapon:get_prop_int("CBaseCombatWeapon", "m_iItemDefinitionIndex")

    if not m_iItemDefinitionIndex then
        return
    end

    local vnum = bit.band(m_iItemDefinitionIndex, 0xFFFF)

    local player_origin = Player:get_absorigin()
    local victim_origin = Victim:get_absorigin()

    local units = player_origin:dist_to(victim_origin)
    local no_kevlar = Victim:get_prop_int("CCSPlayer", "m_ArmorValue") == 0

    if not (vnum == 64 and no_kevlar) then
        return 0
    end

    if units < 585 and units > 511 then
        return 1
    elseif units < 511 then
        return 2
    else
        return 0
    end
end

ragebot.revolver_helper_handle = function()
    local revolver_helper_var = gui.find("Ragebot", "General", "Enable revolver helper")

    if not revolver_helper_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local debug_mode_var = gui.find("Configs", "Other stuff", "Enable debug mode")

    for key = 1, globalvars.get_maxclients() do
        local ent = entitylist.get_player_by_index(engine.get_player_for_user_id(key))

        if ent:is_alive() and not ent:get_dormant() and ent:is_enemy() then
            local bbox = ent:get_bbox()

            local line_start = ent:get_player_hitbox_pos(13)
            local line_stop = Player:get_player_hitbox_pos(3)

            local line_start_ws = render.world_to_screen(line_start)
            local line_stop_ws = render.world_to_screen(line_stop)

            local revolver = ragebot.check_revolver_distance(Player, ent)
            local enemy_revolver = ragebot.check_revolver_distance(ent, Player)

            if revolver ~= 0 and revolver ~= nil then
                local x, y = bbox.x + (bbox.w / 2), bbox.y + bbox.h + 5 + (debug_mode_var:get() and 20 or 0)

                local revolver_text = revolver == 1 and "DMG" or "DMG+"

                render.text(fonts.small, x - (render.get_text_width(fonts.small, revolver_text) / 2), y, revolver == 1 and color.new(255, 0, 0) or color.new(50, 205, 50), revolver_text, false, true)
            end

            if enemy_revolver ~= 0 and enemy_revolver ~= nil then
                if line_start_ws ~= nil and line_stop_ws ~= nil then
                    render.line(line_start_ws.x, line_start_ws.y, line_stop_ws.x, line_stop_ws.y, color.new(255, 0, 0))
                end
            end
        end
    end
end

-- freestand on key
ragebot.freestand_cache = ui.get_bool("Antiaim.freestand")

ragebot.freestand_on_key = function()
    local freestand_on_key_var = gui.find("Ragebot", "General", "Enable freestand on key")

    if not freestand_on_key_var:get() then
        return
    end

    local freestand_key_var = gui.find("Ragebot", "General", "Freestand key")

    ui.set_bool("Antiaim.freestand", (freestand_on_key_var:get() and freestand_key_var:get()) and freestand_key_var:get() or ragebot.freestand_cache)
end

-- anti bruteforce
ragebot.anti_brute = {}
ragebot.anti_brute.list = {}

ragebot.anti_brute.add_new_phase_var = gui.find("Ragebot", "Anti-Bruteforce", "Add new phase")
ragebot.anti_brute.remove_phase_var = gui.find("Ragebot", "Anti-Bruteforce", "Remove phase")
ragebot.anti_brute.phases_var = gui.find("Ragebot", "Anti-Bruteforce", "Bruteforce phases")

ragebot.anti_brute.add_new_phase = function()
    if #ragebot.anti_brute.list > 11 then 
        return 
    end

    local new_phase = gui.create_new_element("Ragebot", "Anti-Bruteforce", {name = "Fake limit phase [" .. (#ragebot.anti_brute.list + 1) .. "]", type = "slider", min = -60, max = 60, value = 0})

    table.insert(ragebot.anti_brute.list, new_phase)
    ragebot.anti_brute.phases_var:set(#ragebot.anti_brute.list)
end

ragebot.anti_brute.add_new_phase_var:set(ragebot.anti_brute.add_new_phase)

ragebot.anti_brute.remove_phase = function()
    if #ragebot.anti_brute.list <= 2 then 
        return 
    end

    local data = ragebot.anti_brute.list[#ragebot.anti_brute.list]

    gui.destroy_element(data[1], data[2], #ragebot.anti_brute.list + 4)

    table.remove(ragebot.anti_brute.list, #ragebot.anti_brute.list)
    ragebot.anti_brute.phases_var:set(#ragebot.anti_brute.list)
end

ragebot.anti_brute.remove_phase_var:set(ragebot.anti_brute.remove_phase)

for i = 1, ragebot.anti_brute.phases_var:get() do
    ragebot.anti_brute.add_new_phase()
end

ragebot.anti_brute.reset_time = 0
ragebot.anti_brute.last_tick_triggered = 0
ragebot.anti_brute.timer = 5
ragebot.anti_brute.current_phase = 0
ragebot.anti_brute.angle = 0
ragebot.anti_brute.misses = 0

ragebot.anti_brute.side = false

ragebot.anti_brute.bullet_impact = function()
    local inverter_state = ui.get_keybind_state(keybinds.flip_desync)

    if ragebot.anti_brute.reset_time < globalvars.get_realtime() then
        for i = 1, #ragebot.anti_brute.list do
            local data = ragebot.anti_brute.list[i]

            if inverter_state and gui.find(data[1], data[2], data[3]):get() >= 0 then
                ragebot.anti_brute.current_phase = i
                break
            elseif not inverter_state and gui.find(data[1], data[2], data[3]):get() < 0 then
                ragebot.anti_brute.current_phase = i
                break
            end
        end
    else
        ragebot.anti_brute.current_phase = 1 + (ragebot.anti_brute.current_phase % #ragebot.anti_brute.list)
    end
    
    ragebot.anti_brute.reset_time = globalvars.get_realtime() + ragebot.anti_brute.timer

    local data = ragebot.anti_brute.list[ragebot.anti_brute.current_phase]
    ragebot.anti_brute.angle = gui.find(data[1], data[2], data[3]):get()

    while ragebot.anti_brute.angle == nil do
        ragebot.anti_brute.current_phase = 1 + (ragebot.anti_brute.current_phase % #ragebot.anti_brute.list)
        ragebot.anti_brute.angle = gui.find(data[1], data[2], data[3]):get()
    end

    ragebot.anti_brute.last_tick_triggered = globalvars.get_tickcount()
end

ragebot.anti_brute.handle_bullet_impact = function(event)
    local anti_brute_var = gui.find("Ragebot", "Anti-Bruteforce", "Enable anti-bruteforce")

    if not anti_brute_var:get() then
        return
    end

    if ragebot.anti_brute.last_tick_triggered == globalvars.get_tickcount() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player or not Player:is_alive() then
        return
    end

    local userid = event:get_int("userid")

    if not userid then
        return
    end

    local player_object = entitylist.get_player_by_index(engine.get_player_for_user_id(userid))

    if not player_object or player_object:get_dormant() or not player_object:is_enemy() then
        return
    end

    local entity_position = player_object:get_absorigin()
    entity_position.z = entity_position.z + player_object:get_angles().z

    if not entity_position then
        return
    end

    local player_head = Player:get_player_hitbox_pos(0)

    if not player_head then
        return
    end

    local closest = math.get_closest_point({entity_position.x, entity_position.y, entity_position.z}, {event:get_int("x"), event:get_int("y"), event:get_int("z")}, {player_head.x, player_head.y, player_head.z})

    local delta = {player_head.x - closest[1], player_head.y - closest[2]}
    local delta_2d = math.sqrt(delta[1]^2 + delta[2]^2)

    if math.abs(delta_2d) < 32 then
        ragebot.anti_brute.bullet_impact()
        ragebot.anti_brute.side = not ragebot.anti_brute.side

        ui.set_keybind_state(keybinds.flip_desync, ragebot.anti_brute.side)
        
        local angle = math.abs(ragebot.anti_brute.angle)

        if ragebot.anti_brute.current_phase % 2 == 0 then
            ui.set_int("0Antiaim.inverted_desync_range", angle)
        else
            ui.set_int("0Antiaim.desync_range", angle)
        end
    end
end
--- @endregion

--- @region: all anti-aim functions
local anti_aim_functions = {}

-- anti-aim presets
anti_aim_functions.presets = {
    [2] = {
        ["STANDING"] = {1, 54, function(value) return value == 1 and -12 or 17 end, 1, 60, 60, 1, 0, 0},
        ["MOVING"] = {1, 52, function(value) return value == 1 and -23 or 20 end, 1, 60, 60, 0, 0, 0},
        ["SLOWWALK"] = {1, 40, function(value) return value == 1 and -13 or 9 end, 1, 60, 60, 0, 0, 0},
        ["IN AIR"] = {1, 27, function(value) return value == 1 and 5 or 12 end, 1, 60, 60, 0, 0, 0},
        ["IN CROUCH AIR"] = {1, 42, function(value) return value == 1 and -12 or 17 end, 1, 60, 60, 0, 0, 0},
        ["CROUCH T"] = {1, 37, function(value) return value == 1 and -10 or 15 end, 1, 60, 60, 0, 0, 0},
        ["CROUCH CT"] = {1, 37, function(value) return value == 1 and -10 or 15 end, 1, 60, 60, 0, 0, 0}
    }
}

anti_aim_functions.presets_handle = function()
    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local state = Player:get_state()

    local anti_aim_preset_var = gui.find("Anti-Aim", "Presets", "Anti-Aim Presets")

    local side = Player:get_body_yaw() > 0 and 1 or -1

    local yaw_mod = anti_aim_functions.presets[anti_aim_preset_var:get()][state][1]
    local yaw_mod_value = anti_aim_functions.presets[anti_aim_preset_var:get()][state][2]
    local yaw_value = anti_aim_functions.presets[anti_aim_preset_var:get()][state][3](side)

    local dsy_type = anti_aim_functions.presets[anti_aim_preset_var:get()][state][4]
    local dsy_range = anti_aim_functions.presets[anti_aim_preset_var:get()][state][5]
    local inv_dsy_range = anti_aim_functions.presets[anti_aim_preset_var:get()][state][6]

    local yaw_target = anti_aim_functions.presets[anti_aim_preset_var:get()][state][7]

    local body_lean = anti_aim_functions.presets[anti_aim_preset_var:get()][state][8]
    local inv_body_lean = anti_aim_functions.presets[anti_aim_preset_var:get()][state][9]

    local brute_time_remains = math.clamp((ragebot.anti_brute.reset_time - globalvars.get_realtime()) / ragebot.anti_brute.timer, 0, 1)

    ui.set_int("0Antiaim.yaw", yaw_mod)
    ui.set_int("0Antiaim.range", yaw_mod_value)
    ui.set_int("Antiaim.yaw_offset", yaw_value)

    ui.set_int("0Antiaim.desync", dsy_type)

    if brute_time_remains <= 0 then
        ui.set_int("0Antiaim.desync_range", dsy_range)
        ui.set_int("0Antiaim.inverted_desync_range", inv_dsy_range)
    end

    ui.set_int("0Antiaim.base_angle", yaw_target)

    ui.set_int("0Antiaim.body_lean", body_lean)
    ui.set_int("0Antiaim.inverted_body_lean", inv_body_lean)
end

-- extended desync
anti_aim_functions.roll = false
anti_aim_functions.extended_desync = function()
    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local on_ground = bit.band(Player:get_prop_int("CBasePlayer", "m_fFlags"), 1)

    if on_ground ~= 1 then
        return
    end

    anti_aim_functions.roll = false

    local roll_var = gui.find("Anti-Aim", "Roll angles", "Enable roll angles")
    local left_roll_value_var = gui.find("Anti-Aim", "Roll angles", "Left roll angle value")
    local right_roll_value_var = gui.find("Anti-Aim", "Roll angles", "Right roll angle value")
    local roll_hotkey_var = gui.find("Anti-Aim", "Roll angles", "Roll angles hotkey")

    if not roll_hotkey_var:get() or not roll_var:get() then
        return
    end

    local degree = right_roll_value_var:get()
    if ui.get_keybind_state(keybinds.flip_desync) then
        degree = left_roll_value_var:get()
    end

    cmd.set_viewangles("z", degree)
    anti_aim_functions.roll = true
end

anti_aim_functions.extended_desync_move_fix = function()
    if not anti_aim_functions.roll then
        return
    end

    local frL, riL = vector.new(0, cmd.get_viewangles().y, 0):forward()
    local frC, riC = cmd.get_viewangles():forward()

    frL.z = 0
    riL.z = 0
    frC.z = 0
    riC.z = 0

    frL = frL / frL:length()
    riL = riL / riL:length()
    frC = frC / frC:length()
    riC = riC / riC:length()

    local Move = vector2d.new(cmd.get_forwardmove(), cmd.get_sidemove())
    local Coord = (frL * Move.x) + (riL * Move.y)

    cmd.sidemove((frC.x * Coord.y - frC.y * Coord.x) / (riC.y * frC.x - riC.x * frC.y))
    cmd.forwardmove((riC.y * Coord.x - riC.x * Coord.y) / (riC.y * frC.x - riC.x * frC.y))
end
--- @endregion

--- @region: all visual functions
local visual_functions = {}

-- velocity warining
visual_functions.velocity_warning = function()
    local velocity_warning_var = gui.find("Visuals", "Indicators list", "Enable velocity warning")

    if not velocity_warning_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local modifier = Player:get_prop_float("CCSPlayer", "m_flVelocityModifier")

    local alpha = animation.new("velocity_warning::alpha", modifier == 1 and 0 or 1, 12)
    local cur_alpha = math.atan(globalvars.get_curtime()*4 % 2 - 1)

    local Screen = vector2d.new(engine.get_screen_width(), engine.get_screen_height())

    local text_width = 95

    local x, y = Screen.x / 2 - text_width, Screen.y * 0.35
    local rx, ry, rw, rh = x + 35 + 8, y + 3 + 17, text_width, 12

    local r, g, b = 124*2 - 124 * modifier, 195 * modifier, 13

    if alpha < 0.01 then
        return
    end

    render.polygon(color.new(16, 16, 16, 255 * alpha), {vector2d.new(x + 15, y - 4), vector2d.new(x - 8, y + 37), vector2d.new(x + 38, y + 37)})
    render.polygon(color.new(r, g, b, (255 * cur_alpha) * alpha), {vector2d.new(x + 15, y + 0), vector2d.new(x - 5, y + 35), vector2d.new(x + 35, y + 35)})

    render.text(fonts.velocity, x + 11, y + 7, color.new(16, 16, 16, 255*alpha), "!")

    render.text(fonts.default_bold, rx, y + 3, color.new(255, 255, 255, 255*alpha), ("%s %s"):format("Speed", math.floor(modifier*100)) .. "%%")

    render.rect(rx, ry, rw, rh, color.new(0, 0, 0, 255*alpha))
    render.rect_filled(rx + 1, ry + 1, rw - 2, rh - 2, color.new(16, 16, 16, 180*alpha))
    render.rect_filled(rx + 1, ry + 1, math.floor((rw - 2) * modifier), rh - 2, color.new(r, g, b, 180*alpha))
end

-- circles arrows
visual_functions.circles_arrows = function()
    local circles_arrows_var = gui.find("Visuals", "Indicators list", "Enable circles arrows")

    if not circles_arrows_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local r, g, b = color.unpack(script.data:get_color())

    local Screen = vector2d.new(engine.get_screen_width(), engine.get_screen_height())

    local viewangles = engine.get_view_angles()

    local angles = Player:get_angles()

    local head_position = Player:get_player_hitbox_pos(0)
    local pelvis_position = Player:get_player_hitbox_pos(2)

    local yaw = math.calc_angle(pelvis_position.x, pelvis_position.y, head_position.x, head_position.y)

    local radius = 30
    local real = math.normalize_yaw(yaw - viewangles.y - 180)

    local left_rad = math.rad(real - 1)
    local right_rad = math.rad(real + 1)

    local center = vector2d.new(Screen.x / 2, Screen.y / 2)
    local size = 12
    local sharpness = 4

    local gap = math.rad(size * 2)

    local BodyYaw = Player:get_body_yaw()

    local FirstColor = animation.new("first_color_arrow", BodyYaw > 10 and color.new(r, g, b, 255) or color.new(255, 255, 255, 255), 8)
    local SecondColor = animation.new("second_color_arrow", BodyYaw < -10 and color.new(r, g, b, 255) or color.new(255, 255, 255, 255), 8)

    local polygons = {
        left = {
            vector2d.new(center.x + (radius * math.sin(left_rad)), center.y + (radius * math.cos(left_rad))),
            vector2d.new(center.x + (radius + size) * math.sin(left_rad), center.y + (radius + size) * math.cos(left_rad)),
            vector2d.new(center.x + (radius - sharpness) * math.sin(left_rad - gap), center.y + (radius - sharpness) * math.cos(left_rad - gap)),
        },

        right = {
            vector2d.new(center.x + (radius * math.sin(right_rad)), center.y + (radius * math.cos(right_rad))),
            vector2d.new(center.x + (radius + size) * math.sin(right_rad), center.y + (radius + size) * math.cos(right_rad)),
            vector2d.new(center.x + (radius - sharpness) * math.sin(right_rad + gap), center.y + (radius - sharpness) * math.cos(right_rad + gap)),
        }
    }

    render.polygon(FirstColor, polygons.left)
    render.polygon(SecondColor, polygons.right)
end

-- information panel
local dragging_info = dragging_fn("Information panel", 0, 0)
visual_functions.info_panel = function()
    local info_panel_var = gui.find("Visuals", "Indicators list", "Enable information panel")

    if not info_panel_var:get() then
        return
    end

    local info_panel_type_var = gui.find("Visuals", "Indicators list", "Information panel type")

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local roll_var = gui.find("Anti-Aim", "Roll angles", "Enable roll angles")

    local r, g, b = color.unpack(script.data:get_color())

    local script_name = script.data:get_name():lower()
    local script_name_width = render.get_text_width(fonts.default, script_name)
    local script_type = script.data:get_type():lower()

    local x, y = dragging_info:get()

    local Screen = vector2d.new(engine.get_screen_width(), engine.get_screen_height())

    if info_panel_type_var:get() == 1 then
        local text = {
            {font = fonts.default, text = ("user: %s "):format(engine.get_gamename()), shadow = true},
            {font = fonts.default, text = ("[%s]"):format(script_type), color = color.new(r, g, b, 255), shadow = true}
        }

        local x, y = 5, Screen.y / 2

        render.image(assets.user_avatar, x, y - (30 / 2), 30, 30, 2)
        render.text(fonts.default, x + 33, y - 14, color.new(255, 255, 255, 255), script_name, true)
        render.multitext(x + 33, y, text)
    elseif info_panel_type_var:get() == 2 then
        local width, height = 145, 50
        local anim = math.sin(math.abs(-math.pi + (globalvars.get_curtime() * 2) % (math.pi * 2)))

        render.blur(x, y, width, height, 255)

        render.gradient(x, y, width, height, color.new(r, g, b, 120 + (80 * anim)), color.new(r, g, b, 0), 1)
        render.rect_filled(x, y, width, 2, color.new(r, g, b, 255))
        render.gradient(x, y, 2, height, color.new(r, g, b, 255), color.new(r, g, b, 0), 1)
        render.gradient(x + width - 2, y, 2, height, color.new(r, g, b, 255), color.new(r, g, b, 0), 1)

        render.text(fonts.default, x + (width / 2) - (script_name_width / 2), y + 4, color.new(255, 255, 255, 255), script_name, true)

        local aa_type = anti_aim_functions.roll and "roll" or "default"
        local aa_type_text = {{font = fonts.default, text = "aa: ", shadow = true}, {font = fonts.default, text = aa_type, color = color.new(r, g, b, 255), shadow = true}}
        local aa_state = Player:get_body_yaw() > 0 and "left" or "right"
        local body_yaw_text = {{font = fonts.default, text = "body ", shadow = true}, {font = fonts.default, text = "yaw", color = color.new(r, g, b, 255), shadow = true}}

        render.multitext(x + 7, y + 20, aa_type_text)
        render.text(fonts.default, x + width - render.get_text_width(fonts.default, aa_state) - 7, y + 20, color.new(255, 255, 255, 255), aa_state, true)

        render.multitext(x + 7, y + 34, body_yaw_text)
        render.text(fonts.default, x + width - render.get_text_width(fonts.default, Player:get_body_yaw()) - 7, y + 34, color.new(255, 255, 255, 255), Player:get_body_yaw(), true)
        
        render.rect(x + 7, y + 50, width - 14, 3, color.new(10, 10, 10, 30))
        render.gradient(x + 7, y + 50, (math.abs(Player:get_body_yaw()) / 60 * width) - 14, 3, color.new(r, g, b, 255), color.new(r, g, b, 0), 0)

        dragging_info:drag(width, height)
    end
end

-- debug mode
visual_functions.debug_mode = function()
    local debug_mode_var = gui.find("Configs", "Other stuff", "Enable debug mode")

    if not debug_mode_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local text = {}

    local max_width = 0
    local x, y = 10, engine.get_screen_height() / 2 - 100

    local text_offset = 0
    for key, value in ipairs(text) do
        local text_width = render.get_text_width(fonts.default, value.text)

        render.text(fonts.default, x, y + text_offset, color.new(255, 255, 255, 255), value.text, true)

        text_offset = text_offset + 15
    end
end

-- hitmarker
visual_functions.hitmarker_data = {}

visual_functions.hitmarker_event = function(shot)
    local player = entitylist.get_local_player()

    local userid = entitylist.get_player_by_index(engine.get_player_for_user_id(shot:get_int("userid")))
    local attacker = entitylist.get_player_by_index(engine.get_player_for_user_id(shot:get_int("attacker")))

    local hgroup = shot:get_int("hitgroup")

    if attacker ~= player then
        return
    end

    local bullet_position = userid:get_player_hitbox_pos(hgroup)
    if not bullet_position then
        bullet_position = userid:get_absorigin()
        bullet_position.y = bullet_position.y + 30
    end

    bullet_position.x = (bullet_position.x - 10) + (math.random() * 20)
    bullet_position.y = (bullet_position.y - 10) + (math.random() * 20)
    bullet_position.z = (bullet_position.z - 15) + (math.random() * 30)

    visual_functions.hitmarker_data[globalvars.get_tickcount()] = {
        position = bullet_position,
        time = globalvars.get_curtime() + 4
    }
end

visual_functions.hitmarker = function()
    local hitmarker_var = gui.find("Visuals", "Indicators list", "Enable hitmarker")

    if not hitmarker_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    for tick, value in pairs(visual_functions.hitmarker_data) do
        if globalvars.get_curtime() <= value.time then
            local Screen = render.world_to_screen(value.position)

            render.line(Screen.x, Screen.y - 6, Screen.x, Screen.y + 6, color.new(0, 255, 255, 255))
            render.line(Screen.x - 6, Screen.y, Screen.x + 6, Screen.y, color.new(0, 255, 0, 255))
        end
    end
end

-- zeusable indicator
visual_functions.zeus_indicator_handle = function()
    local indicator_var = gui.find("Visuals", "Other stuff", "Enable zeusable indicator")

    if not indicator_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local indicator_text = "MJOLNIR"
    local indicator_text_width = render.get_text_width(fonts.default, indicator_text)

    for key = 1, globalvars.get_maxclients() do
        local ent = entitylist.get_player_by_index(engine.get_player_for_user_id(key))

        if ent:is_alive() and not ent:get_dormant() and ent:is_enemy() and ent:is_zeusable() then
            local bbox = ent:get_bbox()

            local x = bbox.x + (bbox.w / 2)
            local y = bbox.y - 30

            local curtime = globalvars.get_curtime()
            local anim = math.sin(math.abs(-math.pi + (curtime * 2.5) % (math.pi * 2)))

            local alpha = anim * 80

            render.text(fonts.default, x - (indicator_text_width / 2), y, color.new(255, 255, 255, 120 + alpha), indicator_text)
            render.image(assets.zeus_logo, x - (40 / 2), y - 50, 50, 50)
        end
    end
end

-- crosshair indicators
visual_functions.crosshair_default = function()
    local indicators_var = gui.find("Visuals", "Indicators list", "Enable indicators")
    local indicators_type_var = gui.find("Visuals", "Indicators list", "Indicators type")
    local circles_arrows_var = gui.find("Visuals", "Indicators list", "Enable circles arrows")
    local scope_animation = gui.find("Visuals", "Indicators list", "Enable scope animation")

    if not indicators_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local binds = {
        {name = "ROLL", active = anti_aim_functions.roll},
        {name = "DT", active = ui.get_keybind_state(keybinds.double_tap)},
        {name = "OS", active = ui.get_keybind_state(keybinds.hide_shots)},
        {name = "DMG", active = ui.get_keybind_state(keybinds.damage_override)}
    }

    local script_name = script.data:get_name():lower() .. "°"
    local r, g, b = color.unpack(script.data:get_color())
    local script_type = script.data:get_type():upper()

    local PlayerWeapon = entitylist.get_weapon_by_player(Player)

    local Screen = vector2d.new(engine.get_screen_width(), engine.get_screen_height())

    local IsScoped = not PlayerWeapon:is_non_aim() and Player:is_scoped()
    local AnimationScoped = animation.new("crosshair_default", (IsScoped and scope_animation:get()) and 1 or 0, 8)

    local BodyYaw = Player:get_body_yaw()

    local FirstColor = animation.new("first_color", BodyYaw > 10 and color.new(r, g, b, 255) or color.new(255, 255, 255, 255), 8)
    local SecondColor = animation.new("second_color", BodyYaw < -10 and color.new(r, g, b, 255) or color.new(255, 255, 255, 255), 8)

    local animation_additional = 40
    local additional = circles_arrows_var:get() and 60 or 45
    local x, y = Screen.x / 2 + (animation_additional * AnimationScoped), Screen.y / 2 + additional
    
    if indicators_type_var:get() == 1 then
        local width, height = 45/1.3, 23/1.3

        render.image(assets.logo, x - (width / 2), y - (height / 2), width, height)
    elseif indicators_type_var:get() == 2 then
        y = y - (circles_arrows_var:get() and 6 or 13)

        local text = {{font = fonts.small_bold, text = script_name:sub(1, #script_name / 2 - 1), color = FirstColor, shadow = true},{font = fonts.small_bold, text = script_name:sub(#script_name / 2, #script_name), color = SecondColor, shadow = true}}
        local text_width = render.measure_multitext(text)
        local type_width = render.get_text_width(fonts.small, script_type)

        render.text(fonts.small, x - (type_width / 2), y - 7, color.new(255, 255, 255, 255), script_type, false, true)
        render.multitext(x - (text_width / 2), y, text)

        local binds_offset = 0
        for key, value in ipairs(binds) do
            if not value.active then
                goto skip
            end

            local name_width = render.get_text_width(fonts.small, value.name)

            render.text(fonts.small, x - (name_width / 2), y + 12 + binds_offset, color.new(255, 255, 255, 255), value.name, false, true)

            binds_offset = binds_offset + 10

            ::skip::
        end
    end
end

-- weapons in scope
visual_functions.weapons_in_scope = function()
    local weapons_in_scope_var = gui.find("Visuals", "Other stuff", "Enable weapons in scope")

    if not weapons_in_scope_var:get() then
        console.set_int("fov_cs_debug", 0)
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local PlayerWeapon = entitylist.get_weapon_by_player(Player)

    local is_scoped = not PlayerWeapon:is_non_aim() and Player:is_scoped()
    if is_scoped then
        local is_third_person = ui.get_keybind_state(keybinds.thirdperson)

        console.set_int("fov_cs_debug", is_third_person and 0 or 90)
    else
        console.set_int("fov_cs_debug", 0)
    end
end

-- dark console
visual_functions.console_materials = {"vgui_white", "vgui/hud/800corner1", "vgui/hud/800corner2", "vgui/hud/800corner3", "vgui/hud/800corner4"}
visual_functions.console_list = {}

visual_functions.console_get_materials = function()
    if visual_functions.console_list[1] then
        return
    end

    local material = materials.get_first_material()
    local foundCount = 0

    while(foundCount < 5)
    do
        local mat = materials.get_material(material)
        local name = materials.get_material_name(mat)

        for i = 1, #visual_functions.console_materials do
            if name == visual_functions.console_materials[i] then
                visual_functions.console_list[i] = mat

                foundCount = foundCount + 1
                break
            end
        end

        material = materials.get_next_material(material)
    end
end

visual_functions.console_set_color = function(color)
    local r, g, b, a = color:r(), color:g(), color:b(), color:a()

    for i = 1, #visual_functions.console_list do
        local mat = visual_functions.console_list[i]

        materials.color_modulate(mat, color.new(r, g, b))
        materials.set_alpha(mat, a)
    end
end

visual_functions.console_handle = function()
    local dark_console_var = gui.find("Visuals", "Other stuff", "Enable dark console")
    local r, g, b, a = 81, 81, 81, 210

    local color = dark_console_var:get() and color.new(r, g, b, a) or color.new(255, 255, 255, 255)

    visual_functions.console_get_materials()
    visual_functions.console_set_color(color)
end

visual_functions.console_unload = function()
    local reset_color = color.new(255, 255, 255, 255)

    console_color.get_materials()
    console_color.set_color(reset_color)
end

-- grenade stuff
-- molotov settings
visual_functions.molotov_materials = {
    "particle/fire_burning_character/fire_env_fire_depthblend_oriented",
    "particle/fire_burning_character/fire_burning_character",
    "particle/fire_explosion_1/fire_explosion_1_oriented",
    "particle/fire_explosion_1/fire_explosion_1_bright",
    "particle/fire_burning_character/fire_burning_character_depthblend",
    "particle/fire_burning_character/fire_env_fire_depthblend",
}

visual_functions.molotov_handle = function()
    local molotov_wireframe_var = gui.find("Visuals", "Grenades stuff", "Enable molotov wireframe")
    local molotov_ignore_z_var = gui.find("Visuals", "Grenades stuff", "Enable molotov ignore-z")

    for key, value in ipairs(visual_functions.molotov_materials) do
        local material = materials.get_material_by_name(value)

        if material ~= nil then
            materials.set_material_var_flag(material, bit.lshift(1, 28), molotov_wireframe_var:get())
            materials.set_material_var_flag(material, bit.lshift(1, 15), molotov_ignore_z_var:get())
        end
    end
end

visual_functions.molotov_unload = function()
    for key, value in ipairs(visual_functions.molotov_materials) do
        local material = materials.get_material_by_name(value)

        if material ~= nil then
            materials.set_material_var_flag(material, bit.lshift(1, 28), false)
            materials.set_material_var_flag(material, bit.lshift(1, 15), false)
        end
    end
end

-- snaplines
visual_functions.snaplines_handle = function()
    local snaplines_var = gui.find("Visuals", "Other stuff", "Enable snaplines")

    if not snaplines_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local snaplines_color = color.new(255, 255, 255, 150)

    local player_hitbox = Player:get_absorigin()
    local player_hitbox_screen = render.world_to_screen(player_hitbox)

    for key = 1, globalvars.get_maxclients() do
        local ent = entitylist.get_player_by_index(engine.get_player_for_user_id(key))
        
        if ent:is_enemy() and ent:is_alive() and not ent:get_dormant() then
            local ent_hitbox = ent:get_absorigin()
            local ent_hitbox_screen = render.world_to_screen(ent_hitbox)

            render.line(player_hitbox_screen.x, player_hitbox_screen.y, ent_hitbox_screen.x, ent_hitbox_screen.y, snaplines_color)
        end
    end
end

-- widgets
visual_functions.create_solus_window = function(x, y, firts_width, width, height, color, type)
    local r, g, b, a = color:r(), color:g(), color:b(), color:a()

    if type == 1 then
        render.begin_cliprect(x, y, firts_width - 1, height)
        render.blur(x, y, firts_width, height, (255 / 255) * a)
        render.rect_filled_rounded(x, y, width + 4, height, 10, 4, color.new(135, 135, 135, (50 / 255) * a))
        render.rect_rounded(x, y, firts_width + 4, height, color.new(255, 255, 255, (30 / 255) * a), 4)
        render.end_cliprect()

        render.begin_cliprect(x + firts_width - 1, y, width + 1, height)
        render.blur(x + firts_width, y, width, height, (255 / 255) * a)
        render.rect_filled_rounded(x + firts_width - 5, y, width + 5, height, 10, 4, color.new(10, 10, 10, (200 / 255) * a))
        render.rect_rounded(x + firts_width - 5, y, width + 5, height, color.new(255, 255, 255, (30 / 255) * a), 4)
        render.end_cliprect()
    end
end

visual_functions.solus_watermark = function()
    local solus_watermark_var = gui.find("Visuals", "Widgets", "Enable watermark")

    if not solus_watermark_var:get() then
        return
    end

    local script_name = script.data:get_name():lower()
    local script_type = script.data:get_type()

    local script_name_width, script_name_height = render.get_text_width(fonts.default, script_name), render.get_text_height(fonts.default, script_name)

    local text = {
        {font = fonts.default, text = script_type},
        {font = fonts.default, text = " | ", color = color.new(255, 255, 255, 50)},
        {font = fonts.default, text = engine.get_gamename()},
    }

    if engine.is_in_game() then
        local latency = globalvars.get_ping()
        if latency > 5 then
            local latency_text = ("delay: %dms"):format(latency)

            table.insert(text, {font = fonts.default, text = " | ", color = color.new(255, 255, 255, 50)})
            table.insert(text, {font = fonts.default, text = latency_text})
        end
    end

    table.insert(text, {font = fonts.default, text = " | ", color = color.new(255, 255, 255, 50)})
    table.insert(text, {font = fonts.default, text = globalvars.get_time()})

    local firts_width, height, width = script_name_width + 10, 25, render.measure_multitext(text) + 11
    local x, y = engine.get_screen_width(), 8
    x = x - firts_width - width - 10

    visual_functions.create_solus_window(x, y, firts_width, width, height, color.new(255, 255, 255, 255), 1)
    render.text(fonts.default, x + 5, y + (height / 2) - (script_name_height / 2), color.new(255, 255, 255, 200), script_name)

    render.multitext(x + firts_width + 5, y + (height / 2) - (script_name_height / 2), text)
end

visual_functions.spectators_list_data = {active = {}, contents = {}, unsorted = {}}

local dragging_specs = dragging_fn("Spectators list", 0, 0)
visual_functions.spectators_list = function()
    local spectators_list_var = gui.find("Visuals", "Widgets", "Enable spectators list")

    if not spectators_list_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    local data = visual_functions.spectators_list_data

    local latest_item = false
    local maximum_offset = 100

    local spectators = globalvars.get_spectators()

    for i = 1, 64 do 
        data.unsorted[i] = {
            idx = i,
            active = false
        }
    end

    for key, value in ipairs(spectators) do
        local spectator = entitylist.get_player_by_index(value)
        local spectator_index = spectator:get_index()

        data.unsorted[spectator_index] = { 
            idx = spectator_index,

            active = (function()
                if spectator_index == Player:get_index() then
                    return false
                end

                return true
            end)(),

            avatar = (function()
                local avatar = images.get_steam_avatar(spectator)

                if avatar == nil then
                    return nil
                end

                if data.contents[spectator_index] == nil then
                    data.contents[spectator_index] = {
                        texture = avatar
                    }
                end

                return data.contents[spectator_index].texture
            end)()
        }
    end

    for _, c_ref in ipairs(data.unsorted) do
        local c_id = c_ref.idx
        local c_nickname = entitylist.get_player_by_index(c_ref.idx)

        if c_ref.active then
            latest_item = true

            if data.active[c_id] == nil then
                data.active[c_id] = {
                    alpha = 0, offset = 0, active = true
                }
            end

            local text_width = render.get_text_width(fonts.default, c_nickname:get_name())

            data.active[c_id].active = true
            data.active[c_id].offset = text_width
            data.active[c_id].alpha = animation.lerp(data.active[c_id].alpha, 1, 8)
            data.active[c_id].avatar = c_ref.avatar
            data.active[c_id].name = c_nickname:get_name()
        elseif data.active[c_id] ~= nil then
            data.active[c_id].active = false
            data.active[c_id].alpha = animation.lerp(data.active[c_id].alpha, 0, 8)

            if data.active[c_id].alpha < 0.2 then
                data.active[c_id] = nil
            end
        end

        if data.active[c_id] ~= nil and data.active[c_id].offset > maximum_offset then
            maximum_offset = data.active[c_id].offset
        end
    end

    local text = "spectators"
    local text_width, text_height = render.get_text_width(fonts.default, text), render.get_text_height(fonts.default, text)

    local x, y = dragging_specs:get()

    local height_offset, head_height = 40, 30
    local width, height = animation.new("spectators::width", 55 + maximum_offset, 8), animation.new("spectators::height", (table.count(data.active) * 20) + 15, 8)

    local m_alpha = animation.new("spectators::alpha", (globalvars.is_open_menu() or table.count(data.active) > 0 and latest_item) and 1 or 0, 8)

    render.begin_cliprect(x, y + 5, width, head_height)
    render.blur(x, y + 10, width, head_height, 255*m_alpha)
    render.rect_filled_rounded(x, y + 10, width, head_height, 10, 3, color.new(135, 135, 135, 50*m_alpha))
    render.rect_rounded(x, y + 10, width, head_height, color.new(255, 255, 255, 30*m_alpha), 3)

    render.text(fonts.default, x + (width / 2) - (text_width / 2), y + (head_height / 2) - (text_height / 2) + 7, color.new(255, 255, 255, m_alpha*255), text)
    render.end_cliprect()

    render.begin_cliprect(x, y + head_height + 5, width, height)
    render.blur(x, y + head_height + 5, width, height - 5, 255*m_alpha)
    render.blur(x, y + head_height + 5, width, height - 5, 255*m_alpha)
    render.rect_filled_rounded(x, y + head_height, width, height, 10, 3, color.new(10, 10, 10, 240*m_alpha))
    render.rect_rounded(x, y + head_height, width, height, color.new(255, 255, 255, 30*m_alpha), 3)
    render.end_cliprect()

    for c_name, c_ref in pairs(data.active) do
        local image_size = 15

        local name_height = render.get_text_height(fonts.default, c_ref.name)

        render.text(fonts.default, x + 10, y + height_offset + (image_size / 2) - (name_height / 2), color.new(255, 255, 255, m_alpha*c_ref.alpha*255), c_ref.name)
        
        if c_ref.avatar ~= nil and c_ref.alpha > 0.4 and m_alpha > 0.4 then
            render.image(c_ref.avatar, x + width - image_size - 10, y + height_offset, image_size, image_size, 15)
        end

        height_offset = height_offset + 20 * c_ref.alpha
    end

    dragging_specs:drag(width, head_height + height)
end

visual_functions.keybinds_list_data = {active = {}, modes = {"always", "holding", "toggled", "disabled"}}
visual_functions.keybinds_list_data.list = {
    {name = "Minimum damage", key = keybinds.damage_override},
    {name = "Double tap", key = keybinds.double_tap},
    {name = "On shot anti-aim", key = keybinds.hide_shots},
    {name = "Slow motion", key = keybinds.slowwalk},
    {name = "Anti-aim inverter", key = keybinds.flip_desync},
    {name = "Duck peek assist", key = keybinds.fakeduck},
    {name = "Quick peek assist", key = keybinds.automatic_peek},
    {name = "Body aim", key = keybinds.body_aim},
}

local dragging_keys = dragging_fn("Keybinds", 0, 0)
visual_functions.keybinds = function()
    local keybinds_list_var = gui.find("Visuals", "Widgets", "Enable keybinds")

    if not keybinds_list_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    local data = visual_functions.keybinds_list_data

    local latest_item = false
    local maximum_offset = 100
    local items_offset = 0

    for c_name, c_data in pairs(data.list) do
        local item_active = ui.get_keybind_state(c_data.key)

        if item_active then
            items_offset = items_offset + 20

            latest_item = true

            if data.active[c_name] == nil then
                data.active[c_name] = {
                    mode = "", alpha = 0, offset = 0, active = true, name = ""
                }
            end

            local text_width = render.get_text_width(fonts.default, c_data.name)

            data.active[c_name].name = c_data.name
            data.active[c_name].active = true
            data.active[c_name].offset = text_width + render.get_text_width(fonts.default, data.active[c_name].mode) - 15
            data.active[c_name].mode = data.modes[(ui.get_keybind_mode(c_data.key) + 2)]
            data.active[c_name].alpha = animation.lerp(data.active[c_name].alpha, 1, 8)
        elseif data.active[c_name] ~= nil then
            data.active[c_name].active = false
            data.active[c_name].alpha = animation.lerp(data.active[c_name].alpha, 0, 8)

            if data.active[c_name].alpha < 0.2 then
                data.active[c_name] = nil
                items_offset = items_offset - 1
            end
        end

        if data.active[c_name] ~= nil and data.active[c_name].offset > maximum_offset then
            maximum_offset = data.active[c_name].offset
        end
    end

    local text = "keybinds"
    local text_width, text_height = render.get_text_width(fonts.default, text), render.get_text_height(fonts.default, text)

    local x, y = dragging_keys:get()

    local height_offset, head_height = 40, 30
    local width, height = animation.new("keybinds::width", 55 + maximum_offset, 8), animation.new("keybinds::height", items_offset + 15, 8)

    local m_alpha = animation.new("keybinds::alpha", (globalvars.is_open_menu() or table.count(data.active) > 0 and latest_item) and 1 or 0, 8)

    render.begin_cliprect(x, y + 5, width, head_height)
    render.blur(x, y + 10, width, head_height, 255*m_alpha)
    render.rect_filled_rounded(x, y + 10, width, head_height, 10, 3, color.new(135, 135, 135, 50*m_alpha))
    render.rect_rounded(x, y + 10, width, head_height, color.new(255, 255, 255, 30*m_alpha), 3)

    render.text(fonts.default, x + (width / 2) - (text_width / 2), y + (head_height / 2) - (text_height / 2) + 7, color.new(255, 255, 255, m_alpha*255), text)
    render.end_cliprect()

    render.begin_cliprect(x, y + head_height + 5, width, height)
    render.blur(x, y + head_height + 5, width, height - 5, 255*m_alpha)
    render.blur(x, y + head_height + 5, width, height - 5, 255*m_alpha)
    render.rect_filled_rounded(x, y + head_height, width, height, 10, 3, color.new(10, 10, 10, 240*m_alpha))
    render.rect_rounded(x, y + head_height, width, height, color.new(255, 255, 255, 30*m_alpha), 3)
    render.end_cliprect()

    for c_name, c_ref in pairs(data.active) do
        local key_type = '[' .. (c_ref.mode or '?') .. ']'

        render.text(fonts.default, x + 10, y + height_offset + 3, color.new(255, 255, 255, m_alpha*c_ref.alpha*255), c_ref.name)
        render.text(fonts.default, x + width - render.get_text_width(fonts.default, key_type) - 10, y + height_offset + 3, color.new(255, 255, 255, m_alpha*c_ref.alpha*100), key_type)

        height_offset = height_offset + 20 * c_ref.alpha
    end

    dragging_keys:drag(width, head_height + height)
end

-- debug esp
visual_functions.debug_esp = function()
    local debug_mode_var = gui.find("Configs", "Other stuff", "Enable debug mode")

    if not debug_mode_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    for key = 1, globalvars.get_maxclients() do
        local ent = entitylist.get_player_by_index(engine.get_player_for_user_id(key))

        if ent:is_alive() and not ent:get_dormant() and ent:is_enemy() then
            local bbox = ent:get_bbox()

            local body_yaw = ent:get_body_yaw()
            local body_yaw_width = render.get_text_width(fonts.default, body_yaw .. "°")

            local distance = Player:get_absorigin():dist_to(ent:get_absorigin())

            local x, y = bbox.x + (bbox.w / 2), bbox.y + bbox.h + 5

            local body_yaw_text = ("BodyYaw: %s"):format(body_yaw .. "°")
            local distance_text = ("Distance: %s"):format(math.floor(distance))
            render.text(fonts.small, x - (render.get_text_width(fonts.small, body_yaw_text) / 2), y, color.new(255, 255, 255, 255), body_yaw_text, false, true)
            render.text(fonts.small, x - (render.get_text_width(fonts.small, distance_text) / 2), y + 10, color.new(255, 255, 255, 255), distance_text, false, true)
        end
    end
end
--- @endregion

--- @region: all miscellaneous functions
local miscellaneous_functions = {}

-- hitlogs
miscellaneous_functions.hitlogs_list = {}
miscellaneous_functions.hitlogs_groups = {[1] = "head", [2] = "chest", [3] = "stomach", [4] = "left arm", [5] = "right arm", [6] = "left leg", [7] = "right leg"}
miscellaneous_functions.hitlogs_var = gui.find("Misc", "Hitlogging information", "Enable hitlogs")
miscellaneous_functions.hitlogs_max_var = gui.find("Misc", "Hitlogging information", "Max hitlogs value")

miscellaneous_functions.hitlogs_event = function(shot)
    local player = entitylist.get_local_player()

    local userid = entitylist.get_player_by_index(engine.get_player_for_user_id(shot:get_int("userid")))
    local attacker = entitylist.get_player_by_index(engine.get_player_for_user_id(shot:get_int("attacker")))

    local remaining = shot:get_int("health")
    local hgroup = shot:get_int("hitgroup")
    local hurt = shot:get_int("dmg_health")

    if attacker ~= player then
        return
    end

    local text = ("%s in the %s for %s damage (%s health remaining)"):format(userid:get_name(), miscellaneous_functions.hitlogs_groups[hgroup], hurt, remaining)

    table.insert(miscellaneous_functions.hitlogs_list, {
        text = text,
        time = 6,
        type = "HIT",
        alpha = 0
    })
end

miscellaneous_functions.hitlogs = function()
    local Player = entitylist.get_local_player()

    if not miscellaneous_functions.hitlogs_var:get() then
        return
    end

    local x, y = 0, 10
    local r, g, b, a = color.unpack(script.data:get_color())

    local hitlogs_offset = 0
    for key, value in ipairs(miscellaneous_functions.hitlogs_list) do
        value.time = value.time - globalvars.get_frametime()

        value.alpha = animation.lerp(value.alpha, value.time <= 0 and 0 or 1, 8)

        local type_width, type_height = render.get_text_width(fonts.default, value.type), render.get_text_height(fonts.default, value.type)
        local text_width, text_height = type_width + render.get_text_width(fonts.default, value.text) + 24, render.get_text_height(fonts.default, value.text)

        local new_x, new_y = x + (10*value.alpha), y + hitlogs_offset
        render.blur(new_x, new_y, text_width, 30, 10, 255*value.alpha)
        render.rect_filled_rounded(new_x, new_y, text_width, 30, 10, 4, color.new(18, 22, 26, 200*value.alpha))
        render.rect_filled_rounded(new_x, new_y, 4, 30, 10, 4, color.new(r, g, b, 255*value.alpha))

        render.text(fonts.default, new_x + 10, new_y + (30 / 2) - (type_height / 2), color.new(255, 255, 255, 255*value.alpha), value.type)

        render.rect_filled(new_x + 10 + type_width + 4, new_y + 5, 1, 20, color.new(255, 255, 255, 50*value.alpha))

        render.text(fonts.default, new_x + 19 + type_width, new_y + (30 / 2) - (text_height / 2), color.new(255, 255, 255, 150*value.alpha), value.text)

        hitlogs_offset = hitlogs_offset + 35 * value.alpha

        if value.alpha <= 0.01 or #miscellaneous_functions.hitlogs_list > miscellaneous_functions.hitlogs_max_var:get() then
            table.remove(miscellaneous_functions.hitlogs_list, key)
        end
    end
end

-- clantag
miscellaneous_functions.build_tag = function(tag)
    local ret = {}

    for i = 1, #tag do
        table.insert(ret, tag:sub(1, i))
    end

    for i = 1, 4 do
        table.insert(ret, tag)
    end

    for i = 1, #tag do
        table.insert(ret, tag:sub(i, #tag))
    end

    table.insert(ret, '')

    return ret
end

miscellaneous_functions.clantag = miscellaneous_functions.build_tag("Necron " .. script.data:get_type():lower())
miscellaneous_functions.clantag_old = ""
miscellaneous_functions.clantag_handle = function()
    local clantag_var = gui.find("Misc", "Other stuff", "Enable clantag spammer")

    if not clantag_var:get() then
        return
    end

    if not engine.is_in_game() then
        return
    end

    local index = math.floor(globalvars.get_curtime() * 3 % #miscellaneous_functions.clantag) + 1
    local text = miscellaneous_functions.clantag[index]

    if text ~= miscellaneous_functions.clantag_old then
        engine.set_clantag(text)
        miscellaneous_functions.clantag_old = text
    end
end

-- animation breakers
miscellaneous_functions.ground_ticks = 1
miscellaneous_functions.end_time = 0
miscellaneous_functions.random_value = 0

miscellaneous_functions.animation_breaker_var = gui.find("Misc", "Animation breaker", "Enable animation breaker")
miscellaneous_functions.static_legs = gui.find("Misc", "Animation breaker", "Enable static legs in air")
miscellaneous_functions.pitch_on_land = gui.find("Misc", "Animation breaker", "Enable pitch 0 on land")
miscellaneous_functions.jitter_legs = gui.find("Misc", "Animation breaker", "Enable jitter legs")
miscellaneous_functions.jitter_value = gui.find("Misc", "Animation breaker", "Jitter value")
miscellaneous_functions.leg_movement_cache = ui.get_int("Misc.leg_movement")

miscellaneous_functions.animation_breakers = function()
    if not miscellaneous_functions.animation_breaker_var:get() then
        return
    end

    local Player = entitylist.get_local_player()

    if not Player then
        return
    end

    local fakelag = ui.get_int("Antiaim.fake_lag_limit")

    if miscellaneous_functions.static_legs:get() then
        Player:m_flposeparameter()[7] = 1
    end

    if miscellaneous_functions.pitch_on_land:get() then
        local on_ground = bit.band(Player:get_prop_int("CBasePlayer", "m_fFlags"), 1)

        if on_ground == 1 then
            miscellaneous_functions.ground_ticks = miscellaneous_functions.ground_ticks + 1
        else
            miscellaneous_functions.ground_ticks = 0
            miscellaneous_functions.end_time = globalvars.get_curtime() + 1
        end

        if miscellaneous_functions.ground_ticks > fakelag + 1 and miscellaneous_functions.end_time > globalvars.get_curtime() then
            Player:m_flposeparameter()[13] = 0.5
        end
    end

    if miscellaneous_functions.jitter_legs:get() then
        ui.set_int("Misc.leg_movement", 2)

        miscellaneous_functions.random_value = math.random(1, 10)

        if miscellaneous_functions.random_value > miscellaneous_functions.jitter_value:get() then
            Player:m_flposeparameter()[1] = 1
        end
    else
        ui.set_int("Misc.leg_movement", miscellaneous_functions.leg_movement_cache)

        Player:m_flposeparameter()[1] = 1
    end
end
--- @endregion

--- @region: player list
--[[local player_list = {}

player_list.data = {names = {}, indexes = {}}
player_list.players_var = gui.find("Player list", "Players", "Select player")

player_list.solve_modes = {"PREVIOUS_GFY", "ZERO", "FIRST", "SECOND", "LOW_FIRST", "LOW_SECOND"}]]

--- @endregion

--- @region: Config system
local base64 = {}
base64.extract = function(value, from, width)
    return bit.band(bit.rshift(value, from), bit.lshift(1, width) - 1)
end

base64.create_encoder = function(input_alphabet)
    local encoder = {}
    local alphabet = {}

    for i = 1, #input_alphabet do
        alphabet[i - 1] = input_alphabet:sub(i, i)
    end

    for b64code, char in pairs(alphabet) do
        encoder[b64code] = char:byte()
    end

    return encoder
end

base64.create_decoder = function(alphabet)
    local decoder = {}
    for b64code, charcode in pairs(base64.create_encoder(alphabet)) do
        decoder[charcode] = b64code
    end

    return decoder
end

base64.default_encode_alphabet = base64.create_encoder("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")
base64.default_decode_alphabet = base64.create_decoder("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=")

base64.custom_encode_alphabet = base64.create_encoder("a8tsQE4FdNKZ1WlzRP6UH9fmkiAyjxw2OXcgVvL5IG0eYDnTB3CMJqhpbSo7ru+/=")
base64.custom_decode_alphabet = base64.create_decoder("a8tsQE4FdNKZ1WlzRP6UH9fmkiAyjxw2OXcgVvL5IG0eYDnTB3CMJqhpbSo7ru+/=")

base64.encode = function(string, encoder)
    string = tostring(string)
    encoder = encoder or base64.default_encode_alphabet

    local t, k, n = {}, 1, #string
    local lastn = n % 3
    local cache = {}

    for i = 1, n - lastn, 3 do
        local a, b, c = string:byte(i, i + 2)
        local v = a * 0x10000 + b * 0x100 + c
        local s = string.char(encoder[base64.extract(v, 18, 6)], encoder[base64.extract(v, 12, 6)], encoder[base64.extract(v, 6, 6)], encoder[base64.extract(v, 0, 6)])

        t[k] = s
        k = k + 1
    end

    if lastn == 2 then
        local a, b = string:byte(n - 1, n)
        local v = a * 0x10000 + b * 0x100

        t[k] = string.char(encoder[base64.extract(v, 18, 6)], encoder[base64.extract(v, 12, 6)], encoder[base64.extract(v, 6, 6)], encoder[64])
    elseif lastn == 1 then
        local v = string:byte(n) * 0x10000
        t[k] = string.char(encoder[base64.extract(v, 18, 6)], encoder[base64.extract(v, 12, 6)], encoder[64], encoder[64])
    end

    return table.concat(t)
end

function base64.decode(b64, decoder)
    decoder = decoder or base64.default_decode_alphabet
    local pattern = "[^%w%+%/%=]"
    
    if decoder then
        local s62 = nil
        local s63 = nil

        for charcode, b64code in pairs(decoder) do
            if b64code == 62 then
                s62 = charcode
            elseif b64code == 63 then
                s63 = charcode
            end
        end

        pattern = ("[^%%w%%%s%%%s%%=]"):format(string.char(s62), string.char(s63))
    end

    b64 = b64:gsub(pattern, "")
    local n = #b64

    local t, k = {}, 1
    local padding = b64:sub(-2) == "==" and 2 or b64:sub(-1) == "=" and 1 or 0

    for i = 1, padding > 0 and n - 4 or n, 4 do
        local a, b, c, d = b64:byte(i, i + 3)
        local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40 + decoder[d]
        local s = string.char(base64.extract(v, 16, 8), base64.extract(v, 8, 8), base64.extract(v, 0, 8))

        t[k] = s
        k = k + 1
    end

    if padding == 1 then
        local a, b, c = b64:byte(n - 3, n - 1)
        local v = decoder[a] * 0x40000 + decoder[b] * 0x1000 + decoder[c] * 0x40

        t[k] = string.char(base64.extract(v, 16, 8), base64.extract(v, 8, 8))
    elseif padding == 2 then
        local a, b = b64:byte(n - 3, n - 2)
        local v = decoder[a] * 0x40000 + decoder[b] * 0x1000

        t[k] = string.char(base64.extract(v, 16, 8))
    end

    return table.concat(t)
end

local config_system = {}

config_system.save = function()
    local menu_items = {}

    for index, data in pairs(gui.items) do
        local temp_table_tab = {}

        for key, value in pairs(data) do
            local temp_table_subtab = {}

            for keys, items in ipairs(value.items) do
                local temp_table_element = {}

                temp_table_element.value = gui.find(index, key, items.name):get(true)

                if not temp_table_element.value then 
                    goto skip 
                end

                temp_table_subtab[items.name] = temp_table_element
                ::skip::
            end

            temp_table_tab[key] = temp_table_subtab
        end

        menu_items[index] = temp_table_tab
    end

    local response = json.encode(menu_items)
    local encoded_config = base64.encode(response)

    local selected_config = gui.find("Configs", "Configs", "Config slot"):get()
    local config_name = ("slot%s.cfg"):format(selected_config)

    file.write(("%s\\%s"):format(npath, config_name), encoded_config)
end

config_system.load = function()
    local selected_config = gui.find("Configs", "Configs", "Config slot"):get()
    local config_name = ("slot%s.cfg"):format(selected_config)

    if not file.exists(("%s\\%s"):format(npath, config_name)) then
        return
    end

    local config_data = file.read(("%s\\%s"):format(npath, config_name))
    local decoded_config_data = base64.decode(config_data)
    local json_to_table = json.decode(decoded_config_data)

    for key, value in pairs(json_to_table) do
        for index, data in pairs(value) do
            for keys, items in pairs(data) do
                if items.value ~= nil then
                    gui.find(key, index, keys):set(items.value, true)
                end
            end
        end
    end
end

local save_config_var = gui.find("Configs", "Configs", "Save")
local load_config_var = gui.find("Configs", "Configs", "Load")

save_config_var:set(config_system.save)
load_config_var:set(config_system.load)
--- @endregion

--- @region: callback section
cheat.RegisterCallback("on_paint", function()
    ragebot.revolver_helper_handle()

    visual_functions.velocity_warning()
    visual_functions.debug_esp()
    visual_functions.circles_arrows()
    visual_functions.info_panel()
    visual_functions.debug_mode()
    visual_functions.hitmarker()
    visual_functions.zeus_indicator_handle()
    visual_functions.crosshair_default()
    visual_functions.snaplines_handle()
    visual_functions.molotov_handle()
    visual_functions.solus_watermark()
    visual_functions.spectators_list()
    visual_functions.keybinds()

    miscellaneous_functions.hitlogs()
    miscellaneous_functions.clantag_handle()

    --player_list.update()

    if globalvars.is_open_menu() then
        paint.window()
    end

    input_system.update()

    if globalvars.is_open_menu() then
        update_ui.handle()
    end

    for index, data in pairs(gui.items) do
        for key, value in pairs(data) do
            for keys, items in ipairs(value.items) do
                if items.type == "hotkey" then
                    gui.update_hotkey(items)
                end
            end
        end
    end
end)

cheat.RegisterCallback("on_framestage", function()
    ragebot.freestand_on_key()

    miscellaneous_functions.animation_breakers()

    visual_functions.weapons_in_scope()
    visual_functions.console_handle()
end)

cheat.RegisterCallback("on_createmove", function()
    --entity.get_best_enemy()
    anti_aim_functions.presets_handle()
end)

cheat.RegisterCallback("after_prediction", function()
    anti_aim_functions.extended_desync()
    anti_aim_functions.extended_desync_move_fix()
end)

cheat.RegisterCallback("on_unload", function()
    visual_functions.console_unload()
    visual_functions.molotov_unload()

    engine.set_clantag("")
end)

events.register_event("player_hurt", function(event)
    miscellaneous_functions.hitlogs_event(event)
    visual_functions.hitmarker_event(event)
end)

events.register_event("switch_team", function(event)
    --player_list.get_players()
end)

events.register_event("bullet_impact", function(event)
    ragebot.anti_brute.handle_bullet_impact(event)
end)
--- @endregion
