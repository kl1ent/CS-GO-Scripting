
--[[ @region: script information
    * @ Grenade Helper.
    * @ Ported by Klient#1690.
    * @ Version: 3.0.0.
    * @ note: ported from gamesense lua.
-- @endregion ]]

local map_aliases = {["workshop/141243798/aim_ag_texture2"] = "aim_ag_texture2", ["workshop/1855851320/de_cache_new"] = "de_cache", ["workshop/533515529/bot_aimtrain_textured_v1"] = "bot_aimtrain_textured_v1"}
local map_patterns = {["_scrimmagemap$"] = ""}
local data_all
--@region: auxiliary functions
-- table functions
table.indexOf = function(t, object) if "table" == type(t) then for i = 1, #t do if object == t[i] then return i;end;end;return -1;else return nil;end;end
table.vector = function(t) if #t == 2 then return vector2d.new(t[1], t[2]);elseif #t == 3 then return vector.new(t[1], t[2], t[3]);elseif #t == 4 then return vector4d.new(t[1], t[2], t[3], t[4]);end;end
table.clear = function(t) for key, data in pairs(t) do t[key] = nil;end;end
table.map = function(tbl, callback) local new = {};for key, value in pairs(tbl) do new[key] = callback(value);end;return new;end
table.map_assoc = function(tbl, callback)local new = {};for key, value in pairs(tbl) do local new_key, new_value = callback(key, value);new[new_key] = new_value;end;return new;end

-- string functions
string.sanitize = function(str)str = tostring(str);str = str:gsub('[%c]', '');return str;end

-- color functions
local function hsv_to_rgb(h, s, v)if s == 0 then return v, v, v;end;h = h / 60;local hue_sector = math.floor(h);local hue_sector_offset = h - hue_sector;local p = v * (1 - s);local q = v * (1 - s * hue_sector_offset);local t = v * (1 - s * (1 - hue_sector_offset));if hue_sector == 0 then return v, t, p;elseif hue_sector == 1 then return q, v, p;elseif hue_sector == 2 then return p, v, t;elseif hue_sector == 3 then return p, q, v;elseif hue_sector == 4 then return t, p, v;elseif hue_sector == 5 then return v, p, q;end;end
local function rgb_to_hsv(r, g, b)local v = math.max(r, g, b);local d = v - math.min(r, g, b);if 1 > d then return 0, 0, v;end;if v == 0 then return -1, 0, v;end;local s = d / v;local h;if r == v then h = (g - b) / d;elseif g == v then h = 2 + (b - r) / d;else h = 4 + (r - g) / d;end;h = h * 60;if h < 0 then h = h + 360;end;return h, s, v;end

-- animation functions
local lerp = function(a, b, percentage) return a + (b - a) * percentage;end
local lerp_color = function(r1, g1, b1, a1, r2, g2, b2, a2, percentage)if percentage == 0 then return r1, g1, b1, a1;elseif percentage == 1 then return r2, g2, b2, a2;end;local h1, s1, v1 = rgb_to_hsv(r1, g1, b1);local h2, s2, v2 = rgb_to_hsv(r2, g2, b2);local r, g, b = hsv_to_rgb(lerp(h1, h2, percentage), lerp(s1, s2, percentage), lerp(v1, v2, percentage));local a = lerp(a1, a2, percentage);return r, g, b, a;end

-- print function
local print = function(...) for key, value in ipairs({...}) do if key < 2 then console.print_color(("[%s]\x20"):format("helper"), color.new(255, 120, 75, 255)); end; end; console.print(("%s\n"):format(table.concat({...}, ","))); end

-- table generation
local table_insert, table_concat, string_rep, string_len, string_sub = table.insert, table.concat, string.rep, string.len, string.sub;local math_max, math_floor, math_ceil = math.max, math.floor, math.ceil;local function len(str) local _, count = string.gsub(tostring(str), "[^\128-\193]", "");return count;end;local styles = {["ASCII"] = {"-", "|", "+"},["Compact"] = {"-", " ", " ", " ", " ", " ", " ", " "},["ASCII (Girder)"] = {"=", "||", "//", "[]", "\\\\", "|]", "[]", "[|", "\\\\", "[]", "//"},["Unicode"] = {"═", "║", "╔", "╦", "╗", "╠", "╬", "╣", "╚", "╩", "╝"},["Unicode (Single Line)"] = {"─", "│", "┌", "┬", "┐", "├", "┼", "┤", "└", "┴", "┘"},["Markdown (Github)"] = {"-", "|", "|"}};for _, style in pairs(styles) do if #style == 3 then for j=4, 11 do style[j] = style[3];end;end;end;local function justify_center(text, width) text = string_sub(text, 1, width);local length = len(text);return string_rep(" ", math_floor(width/2-length/2)) .. text .. string_rep(" ", math_ceil(width/2-length/2));end;local function justify_left(text, width) text = string_sub(text, 1, width);return text .. string_rep(" ", width-len(text));end;function table_gen(rows, headings, options) if type(options) == "string" or options == nil then options = {style=options or "ASCII",};end;if options.top_line == nil then options.top_line = options.style ~= "Markdown (Github)";end;if options.bottom_line == nil then options.bottom_line = options.style ~= "Markdown (Github)";end;if options.header_seperator_line == nil then options.header_seperator_line = true;end;local seperators = styles[options.style] or styles["ASCII"];local rows_out, columns_width, columns_count = {}, {}, 0;local has_headings = headings ~= nil and #headings > 0;if has_headings then for i=1, #headings do columns_width[i] = len(headings[i])+2;end;columns_count = #headings;else for i=1, #rows do columns_count = math_max(columns_count, #rows[i]);end;end;for i=1, #rows do local row = rows[i];for c=1, columns_count do columns_width[c] = math_max(columns_width[c] or 2, len(row[c])+2);end;end;local column_seperator_rows = {};for i=1, columns_count do table_insert(column_seperator_rows, string_rep(seperators[1], columns_width[i]));end;if options.top_line then table_insert(rows_out, seperators[3] .. table_concat(column_seperator_rows, seperators[4]) .. seperators[5]);end;if has_headings then local headings_justified = {};for i=1, columns_count do headings_justified[i] = justify_center(headings[i], columns_width[i]);end;table_insert(rows_out, seperators[2] .. table_concat(headings_justified, seperators[2]) .. seperators[2]);if options.header_seperator_line then table_insert(rows_out, seperators[6] .. table_concat(column_seperator_rows, seperators[7]) .. seperators[8]);end;end;for i=1, #rows do local row, row_out = rows[i], {};if #row == 0 then table_insert(rows_out, seperators[6] .. table_concat(column_seperator_rows, seperators[7]) .. seperators[8]);else for j=1, columns_count do local justified = options.value_justify == "center" and justify_center(row[j] or "", columns_width[j]-2) or justify_left(row[j] or "", columns_width[j]-2);row_out[j] = " " .. justified .. " ";end;table_insert(rows_out, seperators[2] .. table_concat(row_out, seperators[2]) .. seperators[2]);end;end;if options.bottom_line and seperators[9] then table_insert(rows_out, seperators[9] .. table_concat(column_seperator_rows, seperators[10]) .. seperators[11]);end;return table_concat(rows_out, "\n");end;

-- sort functions
local sort_by_distsqr = function(a, b) return a.distsqr > b.distsqr end

-- math functions
local deg_to_rad = function(val) return val * (math.pi / 180.0) end
local clamp = function(val, min, max)if(val > max) then val = max;elseif(val < min) then val = min;end;return val;end
math.pow = function(val, val1) return val ^ val1 end
math.random_float = function(lower, greater) return lower + math.random() * (greater - lower) end

-- other functions
engine.get_map_name = function()local mapname = engine.get_level_name_short();if map_aliases[mapname] ~= nil then mapname = map_aliases[mapname];end;if data_all ~= nil and data_all[mapname] == nil then for pattern, replacement in pairs(map_patterns) do local mapname_temp = mapname:gsub(pattern, replacement);if data_all[mapname_temp] ~= nil then mapname = mapname_temp;break;end;end;end;return mapname;end
local is_grenade_being_thrown = function(weapon)local pin_pulled = weapon:get_prop_bool("CBaseCSGrenade", "m_bPinPulled");if pin_pulled ~= nil then  if pin_pulled == false or bit.band(cmd.get_buttons(), 1) == 1 or bit.band(cmd.get_buttons(), 2048) == 2048 then local throw_time = weapon:get_prop_float("CBaseCSGrenade", "m_fThrowTime");if throw_time ~= nil and throw_time > 0 and throw_time < globalvars.get_curtime()+1 then return true;end;end;end;return false;end
local normalize_angles = function(pitch, yaw)if yaw ~= yaw or yaw == INF then yaw = 0;yaw = yaw;elseif not (yaw > -180 and yaw <= 180) then yaw = math.fmod(math.fmod(yaw + 360, 360), 360);yaw = yaw > 180 and yaw-360 or yaw;end;return math.max(-89, math.min(89, pitch)), yaw;end
local calculate_move = function(btn1, btn2)return btn1 and 450 or (btn2 and -450 or 0)end
local deep_flatten = function(tbl, ignore_arr, out, prefix)if out == nil then out = {};prefix = "";end;for key, value in pairs(tbl) do if type(value) == "table" and (not ignore_arr or #value == 0) then deep_flatten(value, ignore_arr, out, prefix .. key .. ".");else out[prefix .. key] = value;end;end;return out;end

-- JSON
local pretty_json = {};local json = {};local unpack, tostring = table.unpack, tostring;local concat, insert, remove = table.concat, table.insert, table.remove;local sub, rep, len = string.sub, string.rep, string.len;local COLOR_SYM_DEFAULT, COLOR_STRING_DEFAULT, COLOR_LITERAL_DEFAULT, COLOR_QUOTE_DEFAULT = {221, 221, 221}, {180, 230, 30}, {96, 160, 220}, {218, 230, 30};local function kind_of(obj)     if type(obj) ~= 'table' then return type(obj) end;      local i = 1;    for _ in pairs(obj) do      if obj[i] ~= nil then i = i + 1 else return 'table' end;    end;    if i == 1 then return 'table' else return 'array' end;end;local function escape_str(s)      local in_char  = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'};    local out_char = {'\\', '"', '/',  'b',  'f',  'n',  'r',  't'};    for i, c in ipairs(in_char) do      s = s:gsub(c, '\\' .. out_char[i]);     end;    return s;end;local function skip_delim(str, pos, delim, err_if_missing)     pos = pos + #str:match('^%s*', pos);    if str:sub(pos, pos) ~= delim then      if err_if_missing then              error('Expected ' .. delim .. ' near position ' .. pos);        end;        return pos, false;      end;    return pos + 1, true;end;local function parse_str_val(str, pos, val)    val = val or '';    local early_end_error = 'End of input found while parsing string.';     if pos > #str then error(early_end_error) end;      local c = str:sub(pos, pos);    if c == '"'  then return val, pos + 1 end;      if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end;     local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'};     local nextc = str:sub(pos + 1, pos + 1);    if not nextc then error(early_end_error) end;   return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc));end;local function parse_num_val(str, pos)     local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos);    local val = tonumber(num_str);      if not val then error('Error parsing number at position ' .. pos .. '.') end;   return val, pos + #num_str;end;function json.stringify(obj, as_key)  local s = {};  local kind = kind_of(obj);  if kind == 'array' then     if as_key then error('Can\'t encode array as key.') end;    s[#s + 1] = '[';    for i, val in ipairs(obj) do       if i > 1 then s[#s + 1] = ', ' end;      s[#s + 1] = json.stringify(val);    end;    s[#s + 1] = ']';  elseif kind == 'table' then     if as_key then error('Can\'t encode table as key.') end;    s[#s + 1] = '{';    for k, v in pairs(obj) do       if #s > 1 then s[#s + 1] = ', ' end;      s[#s + 1] = json.stringify(k, true);      s[#s + 1] = ':';      s[#s + 1] = json.stringify(v);    end;    s[#s + 1] = '}';  elseif kind == 'string' then     return '"' .. escape_str(obj) .. '"';  elseif kind == 'number' then     if as_key then return '"' .. tostring(obj) .. '"' end;    return tostring(obj);  elseif kind == 'boolean' then     return tostring(obj);  elseif kind == 'nil' then     return 'null';  else     error('Unjsonifiable type: ' .. kind .. '.');  end;  return table.concat(s);end;json.null = {};function json.parse(str, pos, end_delim)  pos = pos or 1;  if pos > #str then error('Reached unexpected end of input.') end;  local pos = pos + #str:match('^%s*', pos);  local first = str:sub(pos, pos);  if first == '{' then     local obj, key, delim_found = {}, true, true;    pos = pos + 1;    while true do       key, pos = json.parse(str, pos, '}');      if key == nil then return obj, pos end;      if not delim_found then error('Comma missing between object items.') end;      pos = skip_delim(str, pos, ':', true);      obj[key], pos = json.parse(str, pos);      pos, delim_found = skip_delim(str, pos, ',');    end;  elseif first == '[' then     local arr, val, delim_found = {}, true, true;    pos = pos + 1;    while true do       val, pos = json.parse(str, pos, ']');      if val == nil then return arr, pos end;      if not delim_found then error('Comma missing between array items.') end;      arr[#arr + 1] = val;      pos, delim_found = skip_delim(str, pos, ',');    end;  elseif first == '"' then     return parse_str_val(str, pos + 1);  elseif first == '-' or first:match('%d') then     return parse_num_val(str, pos);  elseif first == end_delim then     return nil, pos + 1;  else     local literals = {['true'] = true, ['false'] = false, ['null'] = json.null};    for lit_str, lit_val in pairs(literals) do       local lit_end = pos + #lit_str - 1;      if str:sub(pos, lit_end) == lit_str then return lit_val, lit_end + 1 end;    end;    local pos_info_str = 'position ' .. pos .. ': ' .. str:sub(pos, pos + 10);    error('Invalid json syntax starting at ' .. pos_info_str);  end;end;function pretty_json.format(json_text, line_feed, indent, ac)  json_text = tostring(json_text);    line_feed, indent, ac = tostring(line_feed or "\n"), tostring(indent or "\t"), tostring(ac or " "); local i, j, k, n, r, p, q  = 1, 0, 0, len(json_text), {}, nil, nil; local al = sub(ac, -1) == "\n"; for x = 1, n do         local c = sub(json_text, x, x);     if not q and (c == "{" or c == "[") then            r[i] = p == ":" and (c .. line_feed) or (rep(indent, j) .. c .. line_feed);         j = j + 1;      elseif not q and (c == "}" or c == "]") then            j = j - 1;          if p == "{" or p == "[" then                i = i - 1;              r[i] = rep(indent, j) .. p .. c;            else                r[i] = line_feed .. rep(indent, j) .. c;            end;        elseif not q and c == "," then          r[i] = c .. line_feed;          k = -1;     elseif not q and c == ":" then          r[i] = c .. ac;         if al then              i = i + 1;              r[i] = rep(indent, j);          end;        else            if c == '"' and p ~= "\\" then              q = not q and true or nil;          end;            if j ~= k then              r[i] = rep(indent, j);              i, k = i + 1, j;            end;            r[i] = c;       end;        p, i = c, i + 1;    end;    return concat(r);end;local pretty_json1 = pretty_json.format;function pretty_json.highlight(json_text, color_sym, color_quote, color_string, color_literal) color_sym, color_string, color_literal, color_quote = color_sym or COLOR_SYM_DEFAULT, color_string or COLOR_STRING_DEFAULT, color_literal or COLOR_LITERAL_DEFAULT, color_quote or COLOR_QUOTE_DEFAULT; json_text = tostring(json_text);    local i, n, result, prev, quote = 1, len(json_text), {}, nil, nil;  local cur_clr, cur_text = color_sym, {};    for x = 1, n do         local c = sub(json_text, x, x);     local new_clr;      if not quote and (c == "{" or c == "[") then            new_clr = color_sym;            insert(cur_text, c);        elseif not quote and (c == "}" or c == "]") then            new_clr = color_sym;            if prev == "{" or prev == "[" then              insert(cur_text, concat(prev, c));          else                insert(cur_text, c);            end;        elseif not quote and (c == "," or c == ":") then            new_clr = color_sym;            insert(cur_text, c);        else            if c == '"' and prev ~= "\\" then               quote = not quote and true or nil;              new_clr = color_quote;          elseif cur_clr == color_quote then              new_clr = quote and color_string or color_literal;          elseif cur_clr == color_sym and (c ~= " " and c ~= "\n" and c ~= "\t") then                 new_clr = quote and color_string or color_literal;          end;            insert(cur_text, c);        end;        if new_clr ~= nil and new_clr ~= cur_clr then           local new_text = {remove(cur_text, #cur_text)};         insert(result, {cur_clr[1], cur_clr[2], cur_clr[3], concat(cur_text)});         cur_clr, cur_text = new_clr, new_text;      end;        prev = c;   end;    if #cur_text > 0 then       insert(result, {cur_clr[1], cur_clr[2], cur_clr[3], concat(cur_text)}); end;    return result;end;local highlight_json = pretty_json.highlight;function pretty_json.print_highlighted(json_text, color_sym, color_quote, color_string, color_literal)   local highlighted = highlight_json(json_text, color_sym, color_string, color_literal, color_quote); local count = #highlighted; for i=1, count do       local r, g, b, str = unpack(highlighted[i]);        console.print(str, i == count and "" or "\0"); end;    return highlighted;end;function pretty_json.stringify(tbl, line_feed, indent, ac)   local json_text = json.stringify(tbl);  return pretty_json1(json_text, line_feed, indent, ac);end;
--@endregion

local desc_font = render.setup_font("Verdana", 10, fontflags.noantialiasing)
local default_font = render.setup_font("Verdana", 13)
local weapon_font = render.setup_weapon_font(19)

--@region: locals
local Helper = {}

local QAngle = {}
local bit = {}

local callbacks = {}
local data_call = {}

local easing = {}
local database = {}
--@endregion

--@region: input section
local input_keys = {"-", "mouse1", "mouse2", "break", "mouse3", "mouse4", "mouse5", "-", "backspace", "tab", "-", "-", "-", "enter", "-", "-", "shift", "control", "alt", "pause", "capslock", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "space", "page up", "page down", "end", "home", "left", "up", "right", "down", "-", "Print", "-", "print screen", "insert", "delete", "-", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "-", "-", "-", "-", "-", "-", "Error", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "left windows", "right windows", "-", "-", "-", "insert", "end", "down", "page down", "left", "numpad 5", "right", "home", "up", "page up", "*", "+", "_", "-", ".", "/", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "f19", "f20", "f21", "f22", "f23", "f24", "-", "-", "-", "-", "-", "-", "-", "-", "number lock", "scroll lock", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "shift", "right shift", "control", "right control", "menu", "right menu", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "next", "previous", "stop", "toggle", "-", "-", "-", "-", "-", "-", ";", "+", ",", "-", ".", "/?", "~", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "[{", "\\|", "}]", "'\"", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-"}
--@endregion

--@region: bit functions
bit.band = function(a, b) return a & b end
bit.bor = function(a, b) return a | b end
bit.bxor = function(a, b) return a ~ b end
bit.bnot = function(a) return ~a end
bit.rshift = function(a, b) return a >> b end
bit.lshift = function(a, b) return a << b end
--@endregion

--@region: callbacks functions
callbacks.setup = function(callback)
    assert(type(callback) == "string", "[debugger] Invalid type of callback")

    callbacks[callback] = {}
    callbacks[callback].list = {}

    callbacks[callback].func = function(...)
        for i, j in pairs(callbacks[callback].list) do
            j(...)
        end
    end

    cheat.RegisterCallback(callback, callbacks[callback].func)
end

callbacks.push = function(callback, func)
    assert(func, "[debugger] Undefined callbacked variable")
    assert(type(func) == "function", "[debugger] Invalid type of callbacked variable")

    if not callbacks[callback] then
        callbacks.setup(callback)
    end

    table.insert(callbacks[callback].list, func)
end

callbacks.push_event = function(callback, func)
    assert(func, "[debugger] Undefined callbacked variable")
    assert(type(func) == "function", "[debugger] Invalid type of callbacked variable")

    events.register_event(callback, function(e) func(e) end)
end

callbacks.pop = function(callback, func)
    assert(callbacks[callback], "[debugger] Undefined callback")
    assert(type(func) == "function", "[debugger] Invalid type of variable to pop")

    for k, v in pairs(callbacks[callback].list) do
        if v == func then
            table.remove(callbacks[callback].list, k)

            return
        end
    end
end

callbacks.push_delay = function(time, fn)
    table.insert(data_call, {
        fn = fn,
        time = time,
        realtime = globalvars.get_realtime()
    })

    callbacks.push("on_paint", function()
        for key, data in ipairs(data_call) do
            if data.realtime + data.time < globalvars.get_realtime() then
                data.fn()
                data.realtime = globalvars.get_realtime()
            end
        end
    end)
end
--@endregion

--@region: easing functions
easing.quad_in_out = function(t, b, c, d)
    t = t / d * 2
    if t < 1 then
        return c / 2 * math.pow(t, 2) + b
    else
        return -c / 2 * ((t - 1) * (t - 3) - 1) + b
    end
end

easing.cubic_in = function(t, b, c, d)
    t = t / d
    return c * math.pow(t, 3) + b
end

easing.sine_out = function(t, b, c, d)
    return c * math.sin(t / d * (math.pi / 2)) + b
end

easing.expo_in = function(t, b, c, d)
    if t == 0 then
        return b
    else
        return c * math.pow(2, 10 * (t / d - 1)) + b - c * 0.001
    end
end

easing.quart_out = function(t, b, c, d)
    t = t / d - 1
    return -c * (math.pow(t, 4) - 1) + b
end


easing.sine_in_out = function(t, b, c, d)
    return -c / 2 * (math.cos(math.pi * t / d) - 1) + b
end
--@endregion

--@region: vector functions
function vector:init_from_angles()
    local temp, pitch, yaw = 0, 0, 0

    if self.y == 0 and self.x == 0 then
        yaw = 0

        if self.z > 0 then 
            pitch = 270
        else 
            pitch = 90
        end
    else 
        yaw = math.atan(self.y, self.x) * 180 / math.pi

        if yaw < 0 then 
            yaw = yaw + 360
        end

        temp = math.sqrt(self.x * self.x + self.y * self.y)
        pitch = math.atan(-self.z, temp) * 180 / math.pi

        if pitch < 0 then 
            pitch = pitch + 360
        end
    end

    return vector.new(pitch, yaw, 0)
end

function vector:dist_to_2d(Vector_2)
    local Vector_X = self.x - Vector_2.x
    local Vector_Y = self.y - Vector_2.y

    return math.sqrt(Vector_X * Vector_X + Vector_Y * Vector_Y)
end

function vector:normalized()
    local length = self:length()

    if length ~= 0 then
        return vector.new(self.x / length, self.y / length, self.z / length)
    else
        return vector.new(0, 0, 1)
    end
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

function vector:unpack()
    return self.x, self.y, self.z
end

function vector:lerp(destination, percentage)
    return self + (destination - self) * percentage
end

function vector:forward()
    local cp, sp = math.cos(deg_to_rad(self.x)), math.sin(deg_to_rad(self.x))
    local cy, sy = math.cos(deg_to_rad(self.y)), math.sin(deg_to_rad(self.y))
    local cr, sr = math.cos(deg_to_rad(self.z)), math.sin(deg_to_rad(self.z))

    local forward = vector.new(0, 0, 0)
    forward.x = cp * cy
    forward.y = cp * sy
    forward.z = -sp

    return forward
end

function vector:rotate()
    local sin = math.sin(self.x)
    local cos = math.cos(self.x)

    local x_n = self.y * cos - self.z * sin
    local y_n = self.y * sin + self.z * cos

    return x_n, y_n
end
--@endregion

--@region: render functions
function render.triangle_rotated(x, y, width, height, angle, r, g, b, a)
    local a_x, a_y = vector.new(angle, width / 2, 0):rotate()
    local b_x, b_y = vector.new(angle, 0, height):rotate()
    local c_x, c_y = vector.new(angle, width, height):rotate()

    local o_x, o_y = vector.new(angle, -width / 2, -height / 2):rotate()
    x, y = x + o_x, y + o_y

    render.triangle(x + a_x, y + a_y, x + b_x, y + b_y, x + c_x,y + c_y, color.new(r, g, b, a))
end
--@endregion

--@region: constants
local sources_locations = {}
local last_vischeck, weapon_prev, active_locations_in_range = 0
local location_set_closest, location_selected, location_playback

local DEFAULTS = {
    visibility_offset = vector.new(0, 0, 24),
    fov = 0.7,
    fov_movement = 0.1,
    select_fov_legit = 8,
    select_fov_rage = 25,
    max_dist = 6,
    destroy_text = "Break the object",
    source_ttl = 5
}

local MAX_DIST_ICON = 1500
local MAX_DIST_ICON_SQR = MAX_DIST_ICON*MAX_DIST_ICON
local MAX_DIST_COMBINE_SQR = 20*20
local MAX_DIST_TEXT = 650
local MAX_DIST_CLOSE = 28
local MAX_DIST_CLOSE_DRAW = 15
local MAX_DIST_CORRECT = 0.1
local POSITION_WORLD_OFFSET = vector.new(0, 0, 8)
local POSITION_WORLD_TOP_SIZE = 6
local INF = 1/0
local NULL_VECTOR = vector.new(0, 0, 0)
local FL_ONGROUND = 1
local GRENADE_PLAYBACK_PREPARE, GRENADE_PLAYBACK_RUN, GRENADE_PLAYBACK_THROW, GRENADE_PLAYBACK_THROWN, GRENADE_PLAYBACK_FINISHED = 1, 2, 3, 4, 5

local CLR_TEXT_EDIT = {255, 16, 16}

local LOCATION_TYPE_NAMES = {
    grenade = "Grenade",
    wallbang = "Wallbang",
    movement = "Movement"
}

local MOVEMENT_BUTTONS_CHARS = {
    [bit.lshift(1, 0)] = "A",
    [bit.lshift(1, 1)] = "J",
    [bit.lshift(1, 2)] = "D",
    [bit.lshift(1, 3)] = "F",
    [bit.lshift(1, 9)] = "L",
    [bit.lshift(1, 10)] = "R",
    [bit.lshift(1, 4)] = "B",
    [bit.lshift(1, 5)] = "U",
    [bit.lshift(1, 11)] = "Z",
    [bit.lshift(1, 17)] = "S"
}

local vector_index_i, vector_index_lookup = 1, {}
local VECTOR_INDEX = setmetatable({}, {
    __index = function(self, key)
        local id = string.format("%.2f %.2f %.2f", key:unpack())
        local index = vector_index_lookup[id]

        -- first time we met this location
        if index == nil then
            index = vector_index_i
            vector_index_lookup[id] = index
            vector_index_i = index + 1
        end

        self[key] = index
        return index
    end,
    __mode = "k"
})

local GRENADE_WEAPON_CONSOLE_NAMES = {
    ["HE GRENADE"] = "weapon_hegrenade",
    ["MOLOTOV"] = "weapon_molotov",
    ["INCENDIARY"] = "weapon_molotov",
    ["SMOKE"] = "weapon_smokegrenade",
    ["FLASHBANG"] = "weapon_flashbang",
    ["KNIFE"] = "weapon_knife"
}

local GRENADE_WEAPON_NAMES = setmetatable({
    ["SMOKE"] = "Smoke",
    ["FLASHBANG"] = "Flashbang",
    ["HE GRENADE"] = "HE",
    ["MOLOTOV"] = "Molotov",
    ["KNIFE"] = "Knife"
}, {
    __index = function(tbl, key)
        if type(key) == "table" and key ~= nil then
            tbl[key] = key
            return tbl[key]
        end
    end
})

local GRENADE_WEAPON_NAMES_UI = setmetatable({
    ["weapon_smokegrenade"] = "Smoke",
    ["weapon_flashbang"] = "Flashbang",
    ["weapon_hegrenade"] = "High Explosive",
    ["weapon_molotov"] = "Molotov",
    ["weapon_knife"] = "Knife"
}, {
    __index = GRENADE_WEAPON_NAMES
})

local WEAPON_ICONS = {
    ["weapon_molotov"] = "l",
    ["weapon_hegrenade"] = "j",
    ["weapon_smokegrenade"] = "k",
    ["weapon_flashbang"] = ""
}

local WEPAON_ICONS_OFFSETS = setmetatable({
    ["weapon_smokegrenade"] = {0.23, 0, 0.35, 0},
    ["weapon_hegrenade"] = {0.05, -0.03, 0.2, 0},
    ["weapon_molotov"] = {0, -0.03, 0, 0},
    ["weapon_knife"] = {-0.05, 0.03, 0, 0},
}, {
    __index = function(tbl, key)
        tbl[key] = {0, 0, 0, 0}
        return tbl[key]
    end
})

local tickrates_mt = {
    __index = function(tbl, key)
        if tbl.tickrate ~= nil then
            return key / tbl.tickrate
        end
    end
}

local map_locations, active_locations = {}

local function flush_active_locations(reason)
    active_locations = nil
    table.clear(map_locations)
end

local MOVEMENT_BUTTONS_CHARS_INV = table.map_assoc(MOVEMENT_BUTTONS_CHARS, function(k, v) return v, k end)

local function parse_buttons_str(str)
    local buttons_down, buttons_up = {}, {}

    for c in str:gmatch(".") do
        if c:lower() == c then
            table.insert(buttons_up, MOVEMENT_BUTTONS_CHARS_INV[c:upper()] or false)
        else
            table.insert(buttons_down, MOVEMENT_BUTTONS_CHARS_INV[c] or false)
        end
    end

    return buttons_down, buttons_up
end
--@endregion

--@region: database
database.path = engine.get_winpath("appdata").."\\rawetripp\\Scripts\\helper_data.json"
--@endregion

--@region: movement compression algorithm
local function compress_usercmds(usercmds)
    local frames = {}

    local current = {
        viewangles = {pitch=usercmds[1].pitch, yaw=usercmds[1].yaw},
        buttons = {}
    }

    -- initialize all buttons as false
    for key, char in pairs(MOVEMENT_BUTTONS_CHARS) do
        current.buttons[key] = false
    end

    local empty_count = 0
    for i, cmd in ipairs(usercmds) do
        local buttons = ""

        for btn, value_prev in pairs(current.buttons) do
            if cmd[btn] and not value_prev then
                buttons = buttons .. MOVEMENT_BUTTONS_CHARS[btn]
            elseif not cmd[btn] and value_prev then
                buttons = buttons .. MOVEMENT_BUTTONS_CHARS[btn]:lower()
            end
            current.buttons[btn] = cmd[btn]
        end

        local frame = {cmd.pitch-current.viewangles.pitch, cmd.yaw-current.viewangles.yaw, buttons, cmd.forwardmove, cmd.sidemove}
        current.viewangles = {pitch=cmd.pitch, yaw=cmd.yaw}

        if frame[#frame] == calculate_move(cmd[bit.lshift(1, 10)], cmd[bit.lshift(1, 9)]) then
            frame[#frame] = nil

            if frame[#frame] == calculate_move(cmd[bit.lshift(1, 3)], cmd[bit.lshift(1, 4)]) then
                frame[#frame] = nil

                if frame[#frame] == "" then
                    frame[#frame] = nil

                    if frame[#frame] == 0 then
                        frame[#frame] = nil

                        if frame[#frame] == 0 then
                            frame[#frame] = nil
                        end
                    end
                end
            end
        end

        if #frame > 0 then
            -- first frame after a bunch of empty frames
            if empty_count > 0 then
                table.insert(frames, empty_count)
                empty_count = 0
            end

            -- insert frame normally
            table.insert(frames, frame)
        else
            empty_count = empty_count + 1
        end
    end

    if empty_count > 0 then
        table.insert(frames, empty_count)
        empty_count = 0
    end

    return frames
end
--@endregion

--@region: locations
local location_mt = {
    __index = {
        get_type_string = function(self)
            if self.type == "grenade" then
                local names = table.map(self.weapons, function(weapon) return GRENADE_WEAPON_NAMES[weapon] end)
                return table.concat(names, "/")
            else
                return LOCATION_TYPE_NAMES[self.type] or self.type
            end
        end,

        get_export_tbl = function(self)
            local tbl = {
                name = (self.name == self.full_name) and self.name or {self.full_name:match("^(.*) to (.*)$")},
                description = self.description,
                weapon = #self.weapons == 1 and self.weapons[1] or table.map(self.weapons, function(weapon) return weapon end),
                position = {self.position.x, self.position.y, self.position.z},
                viewangles = {self.viewangles.pitch, self.viewangles.yaw},
            }

            if getmetatable(self.tickrates) == tickrates_mt then
                if self.tickrates.tickrate_set then
                    tbl.tickrate = self.tickrates.tickrate
                end
            elseif self.tickrates.orig ~= nil then
                tbl.tickrate = self.tickrates.orig
            end

            if self.approach_accurate ~= nil then
                tbl.approach_accurate = self.approach_accurate
            end

            if self.duckamount ~= 0 then
                tbl.duck = self.duckamount == 1 and true or self.duckamount
            end

            if self.position_visibility_different then
                tbl.position_visibility = {
                    self.position_visibility.x-self.position.x,
                    self.position_visibility.y-self.position.y,
                    self.position_visibility.z-self.position.z
                }
            end

            if self.type == "grenade" then
                tbl.grenade = {
                    fov = self.fov ~= DEFAULTS.fov and self.fov or nil,
                    jump = self.jump and true or nil,
                    strength = self.throw_strength ~= 1 and self.throw_strength or nil,
                    run = self.run_duration ~= nil and self.run_duration or nil,
                    run_yaw = self.run_yaw ~= self.viewangles.yaw and self.run_yaw-self.viewangles.yaw or nil,
                    run_speed = self.run_speed ~= nil and self.run_speed or nil,
                    recovery_yaw = self.recovery_yaw ~= nil and self.recovery_yaw-self.run_yaw or nil,
                    recovery_jump = self.recovery_jump and true or nil,
                    delay = self.delay > 0 and self.delay or nil
                }

                if next(tbl.grenade) == nil then
                    tbl.grenade = nil
                end
            elseif self.type == "movement" then
                local frames = {}
                tbl.movement = {
                    frames = compress_usercmds(self.movement_commands)
                }
            end

            if self.destroy_text ~= nil then
                tbl.destroy = {
                    ["start"] = self.destroy_start and {table.unpack(self.destroy_start)} or nil,
                    ["end"] = {table.unpack(self.destroy_end)},
                    ["text"] = self.destroy_text ~= DEFAULTS.destroy_text and self.destroy_text or nil,
                }
            end

            return tbl
        end,

        get_export = function(self, fancy)
            local tbl = self:get_export_tbl()
            local indent = "  "

            local json_str
            if fancy then
                local default_keys, default_fancy, seen = {"name", "description", "weapon", "position", "viewangles", "position_visibility", "grenade"}, {["grenade"] = 1}, {}
                local result = {}

                for i=1, #default_keys do
                    local key = default_keys[i]
                    local value = tbl[key]
                    if value ~= nil then
                        local str = default_fancy[key] == 1 and pretty_json.stringify(value, "\n", indent) or json.stringify(value)

                        if type(value[1]) == "number" and type(value[2]) == "number" and (value[3] == nil or type(value[3]) == "number") then
                            str = str:gsub(",", ", ")
                        else
                            str = str:gsub("\",\"", "\", \"")
                        end

                        table.insert(result, string.format("\"%s\": %s", key, str))
                        tbl[key] = nil
                    end
                end

                for key, value in pairs(tbl) do
                    table.insert(result, string.format("\"%s\": %s", key, pretty_json.stringify(tbl[key], "\n", indent)))
                end

                json_str = "{\n" .. indent .. table.concat(result, ",\n"):gsub("\n", "\n" .. indent) .. "\n}"
            else
                json_str = json.stringify(tbl)
            end

            -- print("json_str: ", json_str:sub(0, 500))

            return json_str
        end
    }
}

--@note: creatting location
local function create_location(location_parsed)
    if type(location_parsed) ~= "table" then
        return "wrong type, expected table"
    end

    if getmetatable(location_parsed) == location_mt then
        return "trying to create an already created location"
    end

    local location = {}

    if type(location_parsed.name) == "string" and location_parsed.name:len() > 0 then
        location.name = string.sanitize(location_parsed.name)
        location.full_name = location.name
    elseif type(location_parsed.name) == "table" and #location_parsed.name == 2 then
        location.name = string.sanitize(location_parsed.name[2])
        location.full_name = string.sanitize(string.format("%s to %s", location_parsed.name[1], location_parsed.name[2]))
    else
        return "invalid name, expected string or table of length 2"
    end

    if type(location_parsed.description) == "string" and location_parsed.description:len() > 0 then
        location.description = location_parsed.description
    elseif location_parsed.description ~= nil then
        return "invalid description, expected nil or non-empty string"
    end

    if type(location_parsed.weapon) == "string" and location_parsed.weapon ~= nil then
        location.weapons = {location_parsed.weapon}
        location.weapons_assoc = {[location_parsed.weapon] = true}
    elseif type(location_parsed.weapon) == "table" and #location_parsed.weapon > 0 then
        location.weapons = {}
        location.weapons_assoc = {}

        for i=1, #location_parsed.weapon do
            local weapon = location_parsed.weapon[i]
            if weapon ~= nil then
                if location.weapons_assoc[weapon] then
                    return "duplicate weapon: " .. location_parsed.weapon[i]
                else
                    location.weapons[i] = weapon
                    location.weapons_assoc[weapon] = true
                end
            else
                return "invalid weapon: " .. location_parsed.weapon[i]
            end
        end
    else
        return string.format("invalid weapon (%s)", tostring(location_parsed.weapon))
    end

    if type(location_parsed.position) == "table" and #location_parsed.position == 3 then
        local x, y, z = table.unpack(location_parsed.position)

        if type(x) == "number" and type(y) == "number" and type(z) == "number" then
            location.position = vector.new(x, y, z)
            location.position_visibility = location.position + DEFAULTS.visibility_offset
            location.position_id = VECTOR_INDEX[location.position]
        else
            return "invalid type in position"
        end
    else
        return "invalid position"
    end

    if type(location_parsed.position_visibility) == "table" and #location_parsed.position_visibility == 3 then
        local x, y, z = unpack(location_parsed.position_visibility)

        if type(x) == "number" and type(y) == "number" and type(z) == "number" then
            local origin = location.position
            location.position_visibility = vector.new(origin.x+x, origin.y+y, origin.z+z)
            location.position_visibility_different = true
        else
            return "invalid type in position_visibility"
        end
    elseif location_parsed.position_visibility ~= nil then
        return "invalid position_visibility"
    end

    if type(location_parsed.viewangles) == "table" and #location_parsed.viewangles == 2 then
        local pitch, yaw = table.unpack(location_parsed.viewangles)

        if type(pitch) == "number" and type(yaw) == "number" then
            location.viewangles = {
                pitch = pitch,
                yaw = yaw
            }
            location.viewangles_forward = vector.new(pitch, yaw, 0):init_from_angles()
            location.viewangles_target = nil
        else
            return "invalid type in viewangles"
        end
    else
        return "invalid viewangles"
    end

    if type(location_parsed.approach_accurate) == "boolean" then
        location.approach_accurate = location_parsed.approach_accurate
    elseif location_parsed.approach_accurate ~= nil then
        return "invalid approach_accurate"
    end

    if location_parsed.duck == nil or type(location_parsed.duck) == "boolean" then
        location.duckamount = location_parsed.duck and 1 or 0
    else
        return string.format("invalid duck value (%s)", tostring(location_parsed.duck))
    end
    location.eye_pos = location.position + vector.new(0, 0, 64-location.duckamount*18)

    if (type(location_parsed.tickrate) == "number" and location_parsed.tickrate > 0) or location_parsed.tickrate == nil then
        location.tickrates = setmetatable({
            tickrate = location_parsed.tickrate or 64,
            tickrate_set = location_parsed.tickrate ~= nil
        }, tickrates_mt)
    elseif type(location_parsed.tickrate) == "table" and #location_parsed.tickrate > 0 then
        location.tickrates = {
            orig = location_parsed.tickrate
        }

        local orig_tickrate

        for i=1, #location_parsed.tickrate do
            local tickrate = location_parsed.tickrate[i]
            if type(tickrate) == "number" and tickrate > 0 then
                if orig_tickrate == nil then
                    orig_tickrate = tickrate
                    location.tickrates[tickrate] = 1
                else
                    location.tickrates[tickrate] = orig_tickrate/tickrate
                end
            else
                return "invalid tickrate: " .. tostring(location_parsed.tickrate[i])
            end
        end
    else
        return string.format("invalid tickrate (%s)", tostring(location_parsed.tickrate))
    end

    if type(location_parsed.target) == "table" then
        local x, y, z = table.unpack(location_parsed.target)

        if type(x) == "number" and type(y) == "number" and type(z) == "number" then
            location.target = vector.new(x, y, z)
        else
            return "invalid type in target"
        end
    elseif location_parsed.target ~= nil then
        return "invalid target"
    end

    local has_grenade, has_non_grenade
    for i=1, #location.weapons do
        if location.weapons[i] == "weapon_molotov" or location.weapons[i] == "weapon_smokegrenade" 
        or location.weapons[i] == "weapon_hegrenade" or location.weapons[i] == "weapon_flashbang" then
            has_grenade = true
        else
            has_non_grenade = true
        end
    end

    if has_grenade and has_non_grenade then
        return "can't have grenade and non-grenade in one location"
    end

    if location_parsed.movement ~= nil then
        location.type = "movement"
        location.fov = DEFAULTS.fov_movement
    elseif has_grenade then
        location.type = "grenade"
        location.throw_strength = 1
        location.fov = DEFAULTS.fov
        location.delay = 0
        location.jump = false
        location.run_yaw = location.viewangles.yaw
    elseif has_non_grenade then
        location.type = "wallbang"
    else
        return "invalid type"
    end

    if location.type == "grenade" and type(location_parsed.grenade) == "table" then
        local grenade = location_parsed.grenade
        -- location.throw_strength = 1
        -- location.fov = 0.3
        -- location.jump = false
        -- location.run = false
        -- location.run_yaw = 0

        if type(grenade.strength) == "number" and grenade.strength >= 0 and grenade.strength <= 1 then
            location.throw_strength = grenade.strength
        elseif grenade.strength ~= nil then
            return string.format("invalid grenade.strength (%s)", tostring(grenade.strength))
        end

        if type(grenade.delay) == "number" and grenade.delay > 0 then
            location.delay = grenade.delay
        elseif grenade.delay ~= nil then
            return string.format("invalid grenade.delay (%s)", tostring(grenade.delay))
        end

        if type(grenade.fov) == "number" and grenade.fov >= 0 and grenade.fov <= 180 then
            location.fov = grenade.fov
        elseif grenade.fov ~= nil then
            return string.format("invalid grenade.fov (%s)", tostring(grenade.fov))
        end

        if type(grenade.jump) == "boolean" then
            location.jump = grenade.jump
        elseif grenade.jump ~= nil then
            return string.format("invalid grenade.jump (%s)", tostring(grenade.jump))
        end

        if type(grenade.run) == "number" and grenade.run > 0 and grenade.run < 512 then
            location.run_duration = grenade.run
        elseif grenade.run ~= nil then
            return string.format("invalid grenade.run (%s)", tostring(grenade.run))
        end

        if type(grenade.run_yaw) == "number" and grenade.run_yaw >= -180 and grenade.run_yaw <= 180 then
            location.run_yaw = location.viewangles.yaw + grenade.run_yaw
        elseif grenade.run_yaw ~= nil then
            return string.format("invalid grenade.run_yaw (%s)", tostring(grenade.run_yaw))
        end

        if type(grenade.run_speed) == "boolean" then
            location.run_speed = grenade.run_speed
        elseif grenade.run_speed ~= nil then
            return "invalid grenade.run_speed"
        end

        if type(grenade.recovery_yaw) == "number" then
            location.recovery_yaw = location.run_yaw + grenade.recovery_yaw
        elseif grenade.recovery_yaw ~= nil then
            return "invalid grenade.recovery_yaw"
        end

        if type(grenade.recovery_jump) == "boolean" then
            location.recovery_jump = grenade.recovery_jump
        elseif grenade.recovery_jump ~= nil then
            return "invalid grenade.recovery_jump"
        end
    elseif location_parsed.grenade ~= nil then
        -- print(DEBUG.inspect(location_parsed))
        return "invalid grenade"
    end

    if location.type == "movement" and type(location_parsed.movement) == "table" then
        local movement = location_parsed.movement

        if type(movement.fov) == "number" and movement.fov > 0 and movement.fov < 360 then
            location.fov = movement.fov
        end

        if type(movement.frames) == "table" then
            -- decompress frames
            local frames = {}

            -- step one, insert the empty frames for numbers
            for i, frame in ipairs(movement.frames) do
                if type(frame) == "number" then
                    if movement.frames[i] > 0 then
                        for j=1, frame do
                            table.insert(frames, {})
                        end
                    else
                        return "invalid frame " .. tostring(i)
                    end
                elseif type(frame) == "table" then
                    table.insert(frames, frame)
                end
            end

            -- step two, delta decompress frames into ready-made usercmds
            local current = {
                viewangles = {pitch=location.viewangles.pitch, yaw=location.viewangles.yaw},
                buttons = {}
            }

            -- initialize all buttons as false
            for key, char in pairs(MOVEMENT_BUTTONS_CHARS) do
                current.buttons[key] = false
            end

            for i, value in ipairs(frames) do
                local pitch, yaw, buttons, forwardmove, sidemove = table.unpack(value)

                if pitch ~= nil and type(pitch) ~= "number" then
                    return string.format("invalid pitch in frame #%d", i)
                elseif yaw ~= nil and type(yaw) ~= "number" then
                    return string.format("invalid yaw in frame #%d", i)
                end

                -- update current viewangles with new delta data
                current.viewangles.pitch = current.viewangles.pitch + (pitch or 0)
                current.viewangles.yaw = current.viewangles.yaw + (yaw or 0)

                -- update buttons
                if type(buttons) == "string" then
                    local buttons_down, buttons_up = parse_buttons_str(buttons)

                    local buttons_seen = {}
                    for _, btn in ipairs(buttons_down) do
                        if btn == false then
                            return string.format("invalid button in frame #%d", i)
                        elseif buttons_seen[btn] then
                            return string.format("invalid frame #%d: duplicate button %s", i, btn)
                        end
                        buttons_seen[btn] = true

                        -- button is down
                        current.buttons[btn] = true
                    end

                    for _, btn in ipairs(buttons_up) do
                        if btn == false then
                            return string.format("invalid button in frame #%d", i)
                        elseif buttons_seen[btn] then
                            return string.format("invalid frame #%d: duplicate button %s", i, btn)
                        end
                        buttons_seen[btn] = true

                        -- button is up
                        current.buttons[btn] = false
                    end
                elseif buttons ~= nil then
                    return string.format("invalid buttons in frame #%d", i)
                end

                -- either copy or reconstruct forwardmove and sidemove
                if type(forwardmove) == "number" and forwardmove >= -450 and forwardmove <= 450 then
                    current.forwardmove = forwardmove
                elseif forwardmove ~= nil then
                    return string.format("invalid forwardmove in frame #%d: %s", i, tostring(forwardmove))
                else
                    current.forwardmove = calculate_move(current.buttons[bit.lshift(1, 3)], current.buttons[bit.lshift(1, 4)])
                end

                if type(sidemove) == "number" and sidemove >= -450 and sidemove <= 450 then
                    current.sidemove = sidemove
                elseif sidemove ~= nil then
                    return string.format("invalid sidemove in frame #%d: %s", i, tostring(sidemove))
                else
                    current.sidemove = calculate_move(current.buttons[bit.lshift(1, 10)], current.buttons[bit.lshift(1, 9)])
                end

                -- copy data from current into the frame
                frames[i] = {
                    pitch = current.viewangles.pitch,
                    yaw = current.viewangles.yaw,
                    move_yaw = current.viewangles.yaw,
                    forwardmove = current.forwardmove,
                    sidemove = current.sidemove
                }

                -- copy over buttons
                for btn, value in pairs(current.buttons) do
                    frames[i][btn] = value
                end
            end

            location.movement_commands = frames
        else
            return "invalid movement.frames"
        end
    elseif location_parsed.movement ~= nil then
        return "invalid movement"
    end

    if type(location_parsed.destroy) == "table" then
        local destroy = location_parsed.destroy
        location.destroy_text = "Break the object"

        if type(destroy.start) == "table" then
            local x, y, z = table.unpack(destroy.start)

            if type(x) == "number" and type(y) == "number" and type(z) == "number" then
                location.destroy_start = vector.new(x, y, z)
            else
                return "invalid type in destroy.start"
            end
        elseif destroy.start ~= nil then
            return "invalid destroy.start"
        end

        if type(destroy["end"]) == "table" then
            local x, y, z = table.unpack(destroy["end"])

            if type(x) == "number" and type(y) == "number" and type(z) == "number" then
                location.destroy_end = vector.new(x, y, z)
            else
                return "invalid type in destroy.end"
            end
        else
            return "invalid destroy.end"
        end

        if type(destroy.text) == "string" and destroy.text:len() > 0 then
            location.destroy_text = destroy.text
        elseif destroy.text ~= nil then
            return "invalid destroy.text"
        end
    elseif location_parsed.destroy ~= nil then
        return "invalid destroy"
    end

    return setmetatable(location, location_mt)
end

local parse_and_create_locations = function(table_or_json, mapname)
    local locations_parsed
    if type(table_or_json) == "string" then
        local locations_parsed = json.parse(table_or_json)

        if not locations_parsed then
            return
        end
    elseif type(table_or_json) == "table" then
        locations_parsed = table_or_json
    else
        assert(false)
    end

    if type(locations_parsed) ~= "table" then
        error(string.format("invalid type %s, expected table", type(locations_parsed)))
        return
    end

    local locations = {}
    for i, data in pairs(locations_parsed[mapname]) do
        local location = create_location(data)

        if type(location) == "table" then
            table.insert(locations, location)
        else
            error(location or "failed to parse")
            return
        end
    end

    return locations
end

local export_locations = function(tbl, fancy)
    local indent = "  "
    local result = {}

    for i=1, #tbl do
        local str = tbl[i]:get_export(fancy)
        if fancy then
            str = indent .. str:gsub("\n", "\n" .. indent)
        end
        table.insert(result, str)
    end

    return (fancy and "[\n" or "[") .. table.concat(result, fancy and ",\n" or ",") .. (fancy and "\n]" or "]")
end
--@endregion

--@region: normal menu items
local aimbot_types = {"Off", "Legit", "Rage"}
local helper_types = {"Smoke", "Flashbang", "High Explosive", "Molotov", "Movement"}

ui.add_checkbox("Helper")
ui.add_colorpicker("Helper Color")
ui.add_combobox("Helper Key", input_keys)
ui.add_label("     ")
ui.add_label("Helper types")
for i = 1, #helper_types do
    ui.add_checkbox(helper_types[i])
end
ui.add_label(" ")
ui.add_combobox("Aim at locations", aimbot_types)
ui.add_label("  ")
ui.add_sliderint("Helper Aimbot FOV", 0, 200)
ui.add_sliderint("Helper Aimbot Speed", 0, 100)
ui.add_label("   ")
ui.add_checkbox("Show locations behind walls")
ui.add_label("    ")
ui.add_button("Helper Statistics")
--@endregion

--@region: source
local source = {
    get_locations = function(self, mapname)
        if sources_locations[mapname] == nil then
            local locations = parse_and_create_locations(json.parse(file.read(database.path)), mapname)

            if mapname ~= nil then
                local contents_raw = file.read(database.path)
                local contents = json.parse(contents_raw)

                local current_map_name = engine.get_map_name()

                sources_locations[mapname] = locations

                flush_active_locations()

                if mapname ~= current_map_name then
                    sources_locations[mapname] = nil
                end
            end
        end

        return sources_locations[mapname]
    end
}

local function populate_map_locations(local_player, weapon)
    map_locations[weapon] = {}
    active_locations = map_locations[weapon]

    local tickrate = 1/globalvars.get_intervalpertick()
    local mapname = engine.get_map_name()

    local source_locations = source:get_locations(mapname)
    local types_enabled = {
        ["weapon_smokegrenade"] = true, 
        ["weapon_molotov"] = true, 
        ["weapon_flashbang"] = true, 
        ["weapon_hegrenade"] = true,
        ["Movement"] = true
    }

    for i=1, #source_locations do
        local location = source_locations[i]

        local include = false
        if location.type == "grenade" then
            if location.tickrates[tickrate] ~= nil then
                for i=1, #location.weapons do
                    local weapon_name = location.weapons[i]
                    if types_enabled[weapon_name] then
                        include = true
                    end
                end
            end
        elseif location.type == "movement" then
            if types_enabled["Movement"] then
                include = true
            end
        else
            error("not yet implemented: " .. location.type)
        end

        if include and location.weapons_assoc[weapon] then
            local location_set = active_locations[location.position_id]
            if location_set == nil then
                location_set = {
                    position=location.position,
                    position_approach=location.position,
                    position_visibility=location.position_visibility,
                    visible_alpha = 0,
                    distance_alpha = 0,
                    distance_width_mp = 0,
                    in_range_draw_mp = 0,
                    position_world_bottom = location.position+POSITION_WORLD_OFFSET,
                }
                active_locations[location.position_id] = location_set
            end

            location.in_fov_select_mp = 0
            location.in_fov_mp = 0
            location.on_screen_mp = 0
            table.insert(location_set, location)

            location.set = location_set

            -- if this location has a custom position_visibility, it overrides the location set's one
            if location.position_visibility_different then
                location_set.position_visibility = location.position_visibility
            end

            if location.duckamount ~= 1 then
                location_set.has_only_duck = false
            elseif location.duckamount == 1 and location_set.has_only_duck == nil then
                location_set.has_only_duck = true
            end

            -- if this location has approach_accurate set, set it for the whole location set
            if location.approach_accurate ~= nil then
                if location_set.approach_accurate == nil or location_set.approach_accurate == location.approach_accurate then
                    location_set.approach_accurate = location.approach_accurate
                else
                    -- todo: better warning here
                    print("approach_accurate conflict found")
                end
            end
        end
    end

    -- combines nearby positions
    local count = 0

    for key, value in pairs(active_locations) do
        if key > count then
            count = key
        end
    end

    for position_id_1=1, count do
        local locations_1 = active_locations[position_id_1]

        -- can be nil if location was already merged
        if locations_1 ~= nil then
            local pos_1 = locations_1.position

            -- loop from current index to end, to avoid checking locations we already checked (just different order)
            for position_id_2=position_id_1+1, count do
                local locations_2 = active_locations[position_id_2]

                -- can be nil if location was already merged
                if locations_2 ~= nil then
                    local pos_2 = locations_2.position

                    if pos_1:dist_to_sqr(pos_2) < MAX_DIST_COMBINE_SQR then
                        -- the position with more locations is seen as the main one
                        -- the other one is deleted and all locations are inserted into the main one
                        local main = #locations_2 > #locations_1 and position_id_2 or position_id_1
                        local other = main == position_id_1 and position_id_2 or position_id_1

                        -- copy over locations
                        local main_locations = active_locations[main]
                        local other_locations = active_locations[other]

                        if main_locations ~= nil and other_locations ~= nil then
                            local main_count = #main_locations
                            for i=1, #other_locations do
                                local location = other_locations[i]
                                main_locations[main_count+i] = location

                                location.set = main_locations

                                if location.duckamount ~= 1 then
                                    main_locations.has_only_duck = false
                                elseif location.duckamount == 1 and main_locations.has_only_duck == nil then
                                    main_locations.has_only_duck = true
                                end
                            end

                            -- recompute location.position from location.positions
                            local sum_x, sum_y, sum_z = 0, 0, 0
                            local new_len = #main_locations
                            for i=1, new_len do
                                local position = main_locations[i].position
                                sum_x = sum_x + position.x
                                sum_y = sum_y + position.y
                                sum_z = sum_z + position.z
                            end
                            main_locations.position = vector.new(sum_x/new_len, sum_y/new_len, sum_z/new_len)
                            main_locations.position_world_bottom = main_locations.position+POSITION_WORLD_OFFSET

                            -- delete other
                            active_locations[other] = nil
                        end
                    end
                end
            end
        end
    end
end

-- playback variables
local playback_state, playback_begin, playback_sensitivity_set, playback_weapon
local playback_data = {}
--@endregion

--@region: editing

--@endregion

--@region: paint
local ui_restore = {}

local function restore_disabled()
    for key, value in pairs(ui_restore) do
        if type(value) == "boolean" then
            ui.set_bool(key, value)
        elseif type(value) == "number" then
            ui.set_int(key, value)
        end
    end

    table.clear(ui_restore)
end

local function on_paint_help()
    if ui.get_button("Helper Statistics") then
        local all_locations = json.parse(file.read(database.path))
        local maps = {}
        for map, map_spots in pairs(all_locations) do
            table.insert(maps, map)
        end
        table.sort(maps)

        local rows = {}
        local headings = {"MAP", "Smoke", "Flash", "Molotov", "HE Grenade", "Movement", " TOTAL "}
        local total_row = {"TOTAL", 0, 0, 0, 0, 0, 0}

        for i=1, #maps do
            local row = {maps[i], 0, 0, 0, 0, 0, 0}
            local map_locations = all_locations[maps[i]]

            for i=1, #map_locations do
                local location = map_locations[i]
                local index = 5

                local type = location.movement ~= nil and "movement" or "grenade"
                if type == "grenade" then
                    local weapon = location.weapon
                    if weapon == "weapon_smokegrenade" then
                        index = 2
                    elseif weapon == "weapon_flashbang" then
                        index = 3
                    elseif weapon == "weapon_molotov" then
                        index = 4
                    elseif weapon == "weapon_hegrenade" then
                        index = 5
                    end
                elseif type == "movement" then
                    index = 6
                end

                row[index] = row[index] + 1
                total_row[index] = total_row[index] + 1
                row[7] = row[7] + 1
                total_row[7] = total_row[7] + 1
            end

            table.insert(rows, row)
        end

        table.insert(rows, {})
        table.insert(rows, total_row)

        -- remove empty columns
        for i=#total_row, 2, -1 do
            if total_row[i] == 0 then
                table.remove(headings, i)
                for j=1, #rows do
                    table.remove(rows[j], i)
                end
            end
        end

        console.execute_client_cmd("clear")
        local tbl_result = table_gen(rows, headings, {style="ASCII (Girder)"})
        print("Statistics: \n" .. tbl_result .. "\n")
        console.execute_client_cmd("toggleconsole")
    end
end

local movetype_prev, waterlevel_prev
local function on_paint()
    if not ui.get_bool("Helper") then
        return
    end

    -- these variables are set every paint, so if we ever early return here or something, make sure to reset them
    location_set_closest = nil
    location_selected = nil

    local local_player = entitylist.get_local_player()
    if local_player == nil then
        active_locations = nil

        if location_playback ~= nil then
            location_playback = nil
            restore_disabled()
        end

        return
    end

    local weapon_entindex = entitylist.get_weapon_by_player(local_player)
    if weapon_entindex == nil then
        active_locations = nil

        if location_playback ~= nil then
            location_playback = nil
            restore_disabled()
        end

        return
    end

    local weapon = GRENADE_WEAPON_CONSOLE_NAMES[weapon_entindex:get_name()]
    if weapon == nil then
        active_locations = nil

        if location_playback ~= nil then
            location_playback = nil
            restore_disabled()
        end

        return
    end

    local weapon_changed = weapon_prev ~= weapon
    if weapon_changed then
        active_locations = nil
        weapon_prev = weapon
    end

    local types_enabled = {
        ["weapon_smokegrenade"] = ui.get_bool("Smoke"), 
        ["weapon_molotov"] = ui.get_bool("Molotov"), 
        ["weapon_flashbang"] = ui.get_bool("Flashbang"), 
        ["weapon_hegrenade"] = ui.get_bool("High Explosive"),
        ["weapon_knife"] = ui.get_bool("Movement")
    }

    if not types_enabled[weapon] then
        active_locations = nil

        if location_playback ~= nil then
            location_playback = nil
            restore_disabled()
        end

        return
    end

    local dpi_scale = 1

    local aimbot_fov_reference = ui.get_int("Helper Aimbot FOV")
    local aimbot_speed_reference = ui.get_int("Helper Aimbot Speed")

    local hotkey = engine.get_active_key(ui.get_int("Helper Key"))
    local aimbot = aimbot_types[ui.get_int("Aim at locations")+1]
    local aimbot_is_silent = aimbot == "Legit (Silent)" or aimbot == "Rage" or (aimbot == "Legit" and aimbot_speed_reference == 0)

    local screen_width, screen_height = engine.get_screen_width(), engine.get_screen_height()
    local min_height, max_height = math.floor(screen_height*0.012)*dpi_scale, screen_height*0.018*dpi_scale
    local realtime = globalvars.get_realtime()
    local frametime = globalvars.get_frametime()

    local cam_pitch, cam_yaw = engine.get_view_angles().x, engine.get_view_angles().y
    local cam_pos = local_player:get_shoot_pos()
    local cam_up = vector.new(cam_pitch-90, cam_yaw, 0):init_from_angles()

    local local_origin = local_player:get_absorigin()

    local position_world_top_offset = POSITION_WORLD_TOP_SIZE

    local color_reference = ui.get_color("Helper Color")
    local r_m, g_m, b_m, a_m = color_reference:r(), color_reference:g(), color_reference:b(), color_reference:a()

    if location_playback ~= nil and (not hotkey or not local_player:is_alive() or local_player:get_prop_int("CBasePlayer", "m_MoveType") == 8) then
        location_playback = nil
        restore_disabled()
    end

    if active_locations == nil then
        active_locations = {}
        active_locations_in_range = {}
        last_vischeck = 0

        -- create map_locations entry for this weapon
        if map_locations[weapon] == nil then
            populate_map_locations(local_player, weapon)
        else
            active_locations = map_locations[weapon]

            if weapon_changed then
                for _, location_set in pairs(active_locations) do
                    location_set.visible_alpha = 0
                    location_set.distance_alpha = 0
                    location_set.distance_width_mp = 0
                    location_set.in_range_draw_mp = 0

                    for i=1, #location_set do
                        location_set[i].set = location_set
                    end
                end
            end
        end
    end

    if active_locations ~= nil then
        if realtime > last_vischeck+0.07 then
            table.clear(active_locations_in_range)
            last_vischeck = realtime

            for _, location_set in pairs(active_locations) do
                location_set.distsqr = local_origin:dist_to_sqr(location_set.position)
                location_set.in_range = location_set.distsqr <= MAX_DIST_ICON_SQR
                if location_set.in_range then
                    location_set.distance = math.sqrt(location_set.distsqr)

                    local trace = trace.ray(cam_pos, location_set.position_visibility, local_player, 0x200400B)

                    location_set.visible = trace.fraction > 0.99
                    location_set.in_range_text = location_set.distance <= MAX_DIST_TEXT

                    table.insert(active_locations_in_range, location_set)
                else
                    location_set.distance_alpha = 0
                    location_set.in_range_text = false
                    location_set.distance_width_mp = 0
                end
            end

            table.sort(active_locations_in_range, sort_by_distsqr)
        end

        if #active_locations_in_range == 0 then
            return
        end

        -- find any location sets that we're on and store closest one
        for i=1, #active_locations_in_range do
            local location_set = active_locations_in_range[i]

            if location_set_closest == nil or location_set.distance < location_set_closest.distance then
                location_set_closest = location_set
            end
        end

        -- override drawing if we're playing back a location
        local location_playback_set = location_playback ~= nil and location_playback.set or nil

        local closest_mp = 1
        if location_playback_set ~= nil then
            location_set_closest = location_playback_set
            closest_mp = 1
        elseif location_set_closest.distance < MAX_DIST_CLOSE then
            closest_mp = 0.4+easing.quad_in_out(location_set_closest.distance, 0, 0.6, MAX_DIST_CLOSE)
        else
            location_set_closest = nil
        end

        local behind_walls = ui.get_bool("Show locations behind walls")

        local boxes_drawn_aabb = {}
        for i=1, #active_locations_in_range do
            local location_set = active_locations_in_range[i]
            local is_closest = location_set == location_set_closest

            location_set.distance = local_origin:dist_to(location_set.position)
            location_set.distance_alpha = location_playback_set == location_set and 1 or easing.quart_out(1 - location_set.distance / MAX_DIST_ICON, 0, 1, 1)

            local display_full_width = location_set.in_range_text and (closest_mp > 0.5 or is_closest)
            if display_full_width and location_set.distance_width_mp < 1 then
                location_set.distance_width_mp = math.min(1, location_set.distance_width_mp + frametime*7.5)
            elseif not display_full_width and location_set.distance_width_mp > 0 then
                location_set.distance_width_mp = math.max(0, location_set.distance_width_mp - frametime*7.5)
            end
            local distance_width_mp = easing.quad_in_out(location_set.distance_width_mp, 0, 1, 1)

            local invisible_alpha = (behind_walls and location_set.distance_width_mp > 0) and 0.45 or 0
            local invisible_fade_mp = (behind_walls and location_set.distance_width_mp > 0 and not location_set.visible) and 0.33 or 1

            if (location_set.visible and location_set.visible_alpha < 1) or (location_set.visible_alpha < invisible_alpha) then
                location_set.visible_alpha = math.min(1, location_set.visible_alpha + frametime*5.5*invisible_fade_mp)
            elseif not location_set.visible and location_set.visible_alpha > invisible_alpha then
                location_set.visible_alpha = math.max(invisible_alpha, location_set.visible_alpha - frametime*7.5*invisible_fade_mp)
            end
            local visible_alpha = easing.sine_in_out(location_set.visible_alpha, 0, 1, 1) * (is_closest and 1 or closest_mp) * location_set.distance_alpha

            if not is_closest then
                location_set.in_range_draw_mp = 0
            end

            if visible_alpha > 0 then
                local position_bottom = location_set.position_world_bottom
                local ws_bot = render.world_to_screen(position_bottom)
                local wx_bot, wy_bot = ws_bot.x, ws_bot.y

                if wx_bot ~= nil then
                    local ws_top = render.world_to_screen(position_bottom + position_world_top_offset)
                    local wx_top, wy_top = ws_top.x, ws_top.y

                    if wx_top ~= nil then
                        local width_text, height_text = 0, 0
                        local lines = {}

                        -- get text and its size
                        for i=1, #location_set do
                            local location = location_set[i]
                            local name = location.name
                            local r, g, b, a = r_m, g_m, b_m, a_m*visible_alpha

                            if location.editing then
                                r, g, b = table.unpack(CLR_TEXT_EDIT)
                            end

                            table.insert(lines, {r, g, b, a, "d", name})
                        end

                        for i=1, #lines do
                            local r, g, b, a, flags, text = table.unpack(lines[i])
                            local lw, lh = render.get_text_width(default_font, text), render.get_text_height(default_font, text)
                            lh = lh - 1
                            if lw > width_text then
                                width_text = lw
                            end
                            lines[i].y_o = height_text-1
                            height_text = height_text + lh
                            lines[i].width = lw
                            lines[i].height = lh
                        end

                        if location_set.distance_width_mp < 1 then
                            width_text = width_text * location_set.distance_width_mp
                            height_text = math.max(lines[1] and lines[1].height or 0, height_text * math.min(1, location_set.distance_width_mp * 1))

                            -- modify text and make it smaller
                            for i=1, #lines do
                                local r, g, b, a, flags, text = table.unpack(lines[i])

                                for j=text:len(), 0, -1 do
                                    local text_modified = text:sub(1, j)
                                    local lw = render.get_text_width(default_font, text_modified)

                                    if width_text >= lw then
                                        -- got new text, update shit
                                        lines[i][6] = text_modified
                                        lines[i].width = lw
                                        break
                                    end
                                end
                            end
                        end

                        if location_set.distance_width_mp > 0 then
                            width_text = width_text + 2
                        else
                            width_text = 0
                        end

                        -- get icon
                        local wx_icon, wy_icon, width_icon, height_icon, width_icon_orig, height_icon_orig
                        local icon

                        local location = location_set[1]
                        local is_grenade = location.weapons[1] == "weapon_molotov" or location.weapons[1] == "weapon_hegrenade" 
                                           or location.weapons[1] == "weapon_smokegrenade" or location.weapons[1] == "weapon_flashbang"
                        if location.type == "movement" and not is_grenade then
                            icon = "q"
                        else
                            icon = WEAPON_ICONS[location.weapons[1]]
                        end

                        local ox, oy, ow, oh
                        if icon ~= nil then
                            ox, oy, ow, oh = unpack(WEPAON_ICONS_OFFSETS[location.weapons[1]])
                            local _height = math.min(max_height, math.max(min_height, height_text+2, math.abs(wy_bot-wy_top)))
                            width_icon_orig, height_icon_orig = 19, 19
                            -- wx_icon, wy_icon = wx_bot-width_icon/2, wy_top+(wy_bot-wy_top)/2-_height/2

                            ox = ox * width_icon_orig
                            oy = oy * height_icon_orig
                            width_icon = width_icon_orig + ow * width_icon_orig
                            height_icon = height_icon_orig + oh * height_icon_orig
                        end

                        -- got all the width's, calculate our topleft position
                        local full_width, full_height = width_text, height_text
                        if width_icon ~= nil then
                            full_width = full_width+(location_set.distance_width_mp*8*dpi_scale)+width_icon
                            full_height = math.max(height_icon, height_text)
                        else
                            full_height = math.max(math.floor(15*dpi_scale), height_text)
                        end

                        local wx_topleft, wy_topleft = math.floor(wx_top-full_width/2), math.floor(wy_bot-full_height) + 30

                        if width_icon ~= nil then
                            wx_icon = wx_top-full_width/2+ox
                            wy_icon = wy_bot-full_height+oy

                            if height_text > height_icon then
                                wy_icon = wy_icon + (height_text-height_icon)/2
                            end
                        end

                        render.rect_filled(wx_topleft-2, wy_topleft-2, full_width+4, full_height+4, color.new(16, 16, 16, 180*visible_alpha))
                        render.rect(wx_topleft-3, wy_topleft-3, full_width+6, full_height+6, color.new(16, 16, 16, 170*visible_alpha))
                        render.rect(wx_topleft-4, wy_topleft-4, full_width+8, full_height+8, color.new(16, 16, 16, 195*visible_alpha))
                        render.rect(wx_topleft-5, wy_topleft-5, full_width+10, full_height+10, color.new(16, 16, 16, 40*visible_alpha))

                        local r_m, g_m, b_m = r_m, g_m, b_m
                        if location_set[1].editing and #location_set == 1 then
                            r_m, g_m, b_m = table.unpack(CLR_TEXT_EDIT)
                        end

                        if location_set.distance_width_mp > 0 then
                            if width_icon ~= nil then
                                -- draw divider
                                render.rect_filled(wx_topleft+width_icon+3, wy_topleft+2, 1, full_height-3, color.new(r_m, g_m, b_m, a_m*visible_alpha))
                            end

                            -- draw text lines vertically centered
                            local wx_text, wy_text = wx_topleft+(width_icon == nil and 0 or width_icon+8*dpi_scale), wy_topleft
                            if full_height > height_text then
                                wy_text = wy_text + math.floor((full_height-height_text) / 2)
                            end

                            for i=1, #lines do
                                local r, g, b, a, flags, text = table.unpack(lines[i])
                                local _x, _y = wx_text, wy_text+lines[i].y_o

                                if lines[i].y_o+lines[i].height-4 > height_text then
                                    break
                                end

                                render.text(default_font, _x, _y, color.new(r, g, b, a), text)
                            end
                        end

                        -- draw icon
                        if icon ~= nil then
                            local outline_size = math.min(2, full_height*0.03)

                            local outline_a_mp = 1
                            if outline_size > 0.6 and outline_size < 1 then
                                outline_a_mp = (outline_size-0.6)/0.4
                                outline_size = 1
                            else
                                outline_size = math.floor(outline_size)
                            end

                            local outline_r, outline_g, outline_b, outline_a = 0, 0, 0, 80*outline_a_mp*visible_alpha
                            if outline_size > 0 then
                                --icon:draw(wx_icon, wy_icon, width_icon_orig, height_icon_orig, r_m, g_m, b_m, a_m*visible_alpha, true)
                                render.text(weapon_font, wx_icon-outline_size+3, wy_icon+30, color.new(outline_r, outline_g, outline_b, outline_a*visible_alpha), icon)
                                render.text(weapon_font, wx_icon+outline_size+3, wy_icon+30, color.new(outline_r, outline_g, outline_b, outline_a*visible_alpha), icon)
                                render.text(weapon_font, wx_icon+3, wy_icon-outline_size+30, color.new(outline_r, outline_g, outline_b, outline_a*visible_alpha), icon)
                                render.text(weapon_font, wx_icon+3, wy_icon+outline_size+30, color.new(outline_r, outline_g, outline_b, outline_a*visible_alpha), icon)
                            end

                            render.text(weapon_font, wx_icon+3, wy_icon+30, color.new(r_m, g_m, b_m, a_m*visible_alpha), icon)
                        end

                        table.insert(boxes_drawn_aabb, {wx_topleft-10, wy_topleft-10, full_width+10, full_height+10})
                    end
                end
            end
        end

        if location_set_closest ~= nil then
            if location_set_closest.distance == nil then
                location_set_closest.distance = local_origin:dist_to(location_set_closest.position)
            end
            local in_range_draw = location_set_closest.distance < MAX_DIST_CLOSE_DRAW

            if location_set_closest == location_playback_set then
                location_set_closest.in_range_draw_mp = 1
            elseif in_range_draw and location_set_closest.in_range_draw_mp < 1 then
                location_set_closest.in_range_draw_mp = math.min(1, location_set_closest.in_range_draw_mp + frametime*8)
            elseif not in_range_draw and location_set_closest.in_range_draw_mp > 0 then
                location_set_closest.in_range_draw_mp = math.max(0, location_set_closest.in_range_draw_mp - frametime*8)
            end

            if location_set_closest.in_range_draw_mp > 0 then
                local location_closest
                for i=1, #location_set_closest do
                    local location = location_set_closest[i]

                    if not location.viewangles_target then
                        local vec_start = vector.new(location.position.x, location.position.y, location.position.z + 64)
                        local forward = vector.new(location.viewangles.pitch, location.viewangles.yaw, 0):forward()
                        local vec_end = vector.new(vec_start.x + 800 * forward.x, vec_start.y + 800 * forward.y, vec_start.z + 800 * forward.z)

                        local trace = trace.ray(vec_start, vec_end, local_player, 0x46004003)
                        location.viewangles_target = vector.new(trace.endpos.x, trace.endpos.y, trace.endpos.z)
                    end

                    if location.viewangles_target ~= nil then
                        local pitch, yaw = location.viewangles.pitch, location.viewangles.yaw
                        local dp, dy = normalize_angles(cam_pitch - pitch, cam_yaw - yaw)
                        location.viewangles_dist = math.sqrt(dp*dp + dy*dy)

                        if location_closest == nil or location_closest.viewangles_dist > location.viewangles_dist then
                            location_closest = location
                        end

                        if aimbot == "Legit" or (aimbot == "Legit (Silent)" and location.type == "movement") then
                            location.is_in_fov_select = location.viewangles_dist <= aimbot_fov_reference*0.1
                        else
                            location.is_in_fov_select = location.viewangles_dist <= (location.fov_select or aimbot == "Rage" and DEFAULTS.select_fov_rage or DEFAULTS.select_fov_legit)
                        end

                        local dist = local_origin:dist_to(location.position)
                        local dist2d = local_origin:dist_to_2d(location.position)
                        if dist2d < 1.5 then
                            dist = dist2d
                        end

                        location.is_position_correct = dist < MAX_DIST_CORRECT+0.4 and local_player:get_prop_float("CBasePlayer", "m_flDuckAmount") == location.duckamount
                        if location.fov ~= nil then
                            location.is_in_fov = location.is_in_fov_select and ((not (location.type == "movement" and aimbot == "Legit (Silent)") and aimbot_is_silent) or location.viewangles_dist <= location.fov)
                        end
                    end
                end

                local in_range_draw_mp = easing.cubic_in(location_set_closest.in_range_draw_mp, 0, 1, 1)

                for i=1, #location_set_closest do
                    local location = location_set_closest[i]

                    if location.viewangles_target ~= nil then
                        local is_closest = location == location_closest
                        local is_selected = is_closest and location.is_in_fov_select
                        local is_in_fov = is_selected and location.is_in_fov

                        -- determine distance based multiplier
                        local in_fov_select_mp = 1
                        if location.is_in_fov_select ~= nil then
                            if is_selected and location.in_fov_select_mp < 1 then
                                location.in_fov_select_mp = math.min(1, location.in_fov_select_mp + frametime*2.5*(is_in_fov and 2 or 1))
                            elseif not is_selected and location.in_fov_select_mp > 0 then
                                location.in_fov_select_mp = math.max(0, location.in_fov_select_mp - frametime*4.5)
                            end

                            in_fov_select_mp = location.in_fov_select_mp
                        end

                        -- determine if we pass the fov check (for legit)
                        local in_fov_mp = 1
                        if location.is_in_fov ~= nil then
                            if is_in_fov and location.in_fov_mp < 1 then
                                location.in_fov_mp = math.min(1, location.in_fov_mp + frametime*6.5)
                            elseif not is_in_fov and location.in_fov_mp > 0 then
                                location.in_fov_mp = math.max(0, location.in_fov_mp - frametime*5.5)
                            end

                            in_fov_mp = (location.is_position_correct or location == location_playback) and location.in_fov_mp or location.in_fov_mp * 0.5
                        end

                        if is_selected then
                            location_selected = location
                        end

                        local ws = render.world_to_screen(location.viewangles_target)
                        local wx, wy, on_screen = ws.x, ws.y, ws.x > -100 and ws.x < screen_width + 100 and ws.y > -100 and ws.y < screen_height + 100 and true or false

                        if wx ~= nil then
                            wx, wy = math.floor(wx+0.5), math.floor(wy+0.5)

                            if on_screen and location.on_screen_mp < 1 then
                                location.on_screen_mp = math.min(1, location.on_screen_mp + frametime*3.5)
                            elseif not on_screen and location.on_screen_mp > 0 then
                                location.on_screen_mp = math.max(0, location.on_screen_mp - frametime*4.5)
                            end

                            local visible_alpha = (0.5 + location.on_screen_mp * 0.5) * in_range_draw_mp

                            local name = "»" .. location.name
                            local description

                            local title_width, title_height = render.get_text_width(default_font, name), render.get_text_height(default_font, name)
                            local description_width, description_height = 0, 0

                            if location.description ~= nil then
                                description = location.description:upper():gsub(" ", "  ")
                                description_width, description_height = render.get_text_width(desc_font, description .. " "), render.get_text_height(desc_font, description .. " ")
                                description_width = description_width
                            end
                            local extra_target_width = math.floor(description_height/2)
                            extra_target_width = extra_target_width - extra_target_width % 2

                            local full_width, full_height = math.max(title_width, description_width), title_height+description_height

                            local r_m, g_m, b_m = r_m, g_m, b_m

                            if location.editing then
                                r_m, g_m, b_m = table.unpack(CLR_TEXT_EDIT)
                            end

                            local circle_size = math.floor(title_height / 2 - 1) * 2
                            local target_size = 0
                            if location.on_screen_mp > 0 then
                                target_size = math.floor((circle_size + 8*dpi_scale) * location.on_screen_mp) + extra_target_width

                                full_width = full_width + target_size
                            end

                            wx, wy = wx-circle_size/2-extra_target_width/2, wy-full_height/2

                            -- adjust if offscreen to the right
                            local wx_topleft = math.min(wx, screen_width-40-full_width)
                            local wy_topleft = wy

                            -- draw background

                            local background_mp = easing.sine_out(visible_alpha, 0, 1, 1)

                            render.rect_filled(wx_topleft-3, wy_topleft-3, full_width+5, full_height+5, color.new(16, 16, 16, 150*background_mp))
                            render.rect(wx_topleft-3, wy_topleft-3, full_width+6, full_height+6, color.new(16, 16, 16, 170*background_mp))
                            render.rect(wx_topleft-4, wy_topleft-4, full_width+8, full_height+8, color.new(16, 16, 16, 195*background_mp))
                            render.rect(wx_topleft-5, wy_topleft-5, full_width+10, full_height+10, color.new(16, 16, 16, 40*background_mp))

                            if not on_screen then
                                local triangle_alpha = 1 - location.on_screen_mp

                                if triangle_alpha > 0 then
                                    local cx, cy = screen_width/2, screen_height/2

                                    local angle = math.atan(wy_topleft+full_height/2-cy, wx_topleft+full_width/2-cx)
                                    local triangle_angle = angle+math.rad(90)
                                    local offset_x, offset_y =  vector.new(triangle_angle, 0, -screen_height/2+100):rotate()

                                    local tx, ty = screen_width/2+offset_x, screen_height/2+offset_y

                                    local dist_triangle_text = vector.new(tx, ty, 0):dist_to(vector.new(wx_topleft+full_width/2, wy_topleft+full_height/2, 0))
                                    local dist_center_triangle = vector.new(tx, ty, 0):dist_to(vector.new(cx, cy, 0))
                                    local dist_center_text = vector.new(cx, cy, 0):dist_to(vector.new(wx_topleft+full_width/2, wy_topleft+full_height/2, 0))

                                    local a_mp_dist = 1
                                    if 40 > dist_triangle_text then
                                        a_mp_dist = (dist_triangle_text-30)/10
                                    end

                                    if dist_center_text > dist_center_triangle and a_mp_dist > 0 then
                                        local height = math.floor(title_height*1.5)

                                        local realtime_alpha_mp = 1

                                        render.triangle_rotated(tx, ty, height*1.66, height, triangle_angle, r_m, g_m, b_m, a_m*math.min(1, visible_alpha*1.5)*triangle_alpha*a_mp_dist*realtime_alpha_mp)
                                    end
                                end
                            end

                            if location.on_screen_mp > 0.5 and in_range_draw_mp > 0 then
                                -- in_fov_select_mp
                                -- CIRCLE_GREEN_R

                                local c_a = 255*1*in_range_draw_mp*easing.expo_in(location.on_screen_mp, 0, 1, 1)
                                local red_r, red_g, red_b = 255, 10, 10
                                local green_r, green_g, green_b = 20, 236, 0
                                local white_r, white_g, white_b = 140, 140, 140

                                -- fade from red to green based on selection
                                local sel_r, sel_g, sel_b = lerp_color(red_r, red_g, red_b, 0, green_r, green_g, green_b, 0, in_fov_mp)

                                -- fade from white to red/green
                                local c_r, c_g, c_b = lerp_color(white_r, white_g, white_b, 0, sel_r, sel_g, sel_b, 0, in_fov_select_mp)

                                local c_x, c_y = wx+circle_size/2 + extra_target_width/2, wy+full_height/2
                                local c_radius = circle_size/2

                                render.circle(c_x, c_y, 60, c_radius+1, color.new(16, 16, 16, c_a*0.6))

                                render.circle_filled(c_x, c_y, 60, c_radius, color.new(c_r, c_g, c_b, c_a))

                                render.circle(c_x, c_y, 60, c_radius+1, color.new(16, 16, 16, c_a*0.3))
                                render.circle(c_x, c_y, 60, c_radius, color.new(16, 16, 16, c_a*0.2))
                                render.circle(c_x, c_y, 60, c_radius-1, color.new(16, 16, 16, c_a*0.1))
                            end

                            -- divider
                            if target_size > 1 then
                                render.rect_filled(wx_topleft+target_size-4*dpi_scale, wy_topleft+1, 1, full_height-1, color.new(r_m, g_m, b_m, a_m*visible_alpha*location.on_screen_mp))
                            end

                            -- text
                            render.text(default_font, wx_topleft+target_size, wy, color.new(r_m, g_m, b_m, a_m*visible_alpha), name)

                            if description ~= nil then
                                render.text(desc_font, wx_topleft+target_size, wy+title_height, color.new(math.min(255, r_m*1.2), math.min(255, g_m*1.2), math.min(255, b_m*1.2), a_m*visible_alpha*0.92), description, false, true)
                            end
                        end
                    end
                end
            end
        end

        -- run smooth aimbot in paint
        if hotkey and location_selected ~= nil and ((location_selected.type == "movement" and aimbot ~= "Rage") or (location_selected.type ~= "movement" and aimbot == "Legit")) then
            if (not location_selected.is_in_fov or location_selected.viewangles_dist > 0.1) then
                local speed = aimbot_speed_reference/100

                if speed == 0 then
                    if location_selected.type == "grenade" and weapon_entindex:get_prop_bool("CBaseCSGrenade", "m_bPinPulled") == true then
                        -- local aim_pitch, aim_yaw = location_selected.viewangles.pitch, location_selected.viewangles.yaw
                        engine.set_view_angles(vector.new(location_selected.viewangles.pitch, location_selected.viewangles.yaw, 0))
                    end
                else
                    local aim_pitch, aim_yaw = location_selected.viewangles.pitch, location_selected.viewangles.yaw
                    local dp, dy = normalize_angles(cam_pitch - aim_pitch, cam_yaw - aim_yaw)

                    local dist = location_selected.viewangles_dist
                    dp = dp / dist
                    dy = dy / dist

                    local mp = math.min(1, dist/3)*0.5
                    local delta_mp = (mp + math.abs(dist*(1-mp)))*globalvars.get_frametime()*15*speed

                    local pitch = cam_pitch - dp*delta_mp*math.random_float(0.7, 1.2)
                    local yaw = cam_yaw - dy*delta_mp*math.random_float(0.7, 1.2)

                    engine.set_view_angles(vector.new(pitch, yaw, 0))
                end
            end
        end
    end
end
--@endregion

--@region: movement
local function cmd_remove_user_input()
    cmd.set_button_state(8, false)
    cmd.set_button_state(16, false)
    cmd.set_button_state(512, false)
    cmd.set_button_state(1024, false)

    cmd.set_button_state(2, false)
    cmd.set_button_state(bit.lshift(1, 17), false)
end

local viewangles_silent = {}
local fast_stop_cache = ui.get_bool("Misc.fast_stop")
local air_strafe_cache = ui.get_int("Misc.airstrafe")
local function cmd_location_playback_grenade(local_player, weapon)
    local tickrate = 1/globalvars.get_intervalpertick()
    local tickrate_mp = location_playback.tickrates[tickrate]

    if playback_state == nil then
        playback_state = GRENADE_PLAYBACK_PREPARE
        table.clear(playback_data)

        local aimbot = aimbot_types[ui.get_int("Aim at locations")+1]
        if aimbot == "Legit" or aimbot == "Off" then
            playback_sensitivity_set = true
        end

        local begin = playback_begin

        callbacks.push_delay((location_playback.run_duration or 0)*tickrate_mp*2+2, function()
            if location_playback ~= nil and playback_begin == begin then
                print("playback timed out")

                location_playback = nil
                restore_disabled()
            end
        end)
    end

    if weapon ~= playback_weapon and playback_state ~= GRENADE_PLAYBACK_FINISHED then
        location_playback = nil
        restore_disabled()

        return
    end

    if playback_state ~= GRENADE_PLAYBACK_FINISHED then
        cmd_remove_user_input(location_playback)

        cmd.set_button_state(4, location_playback.duckamount == 1 and true or false)

        local movedirection = location_playback.run_yaw
        local angle = vector.new(0, engine.get_view_angles().y - movedirection, 0):forward()
        cmd.forwardmove(angle.x * 450)
        cmd.sidemove(angle.y * 450)
    end

    -- prepare for the playback, here we make sure we have the right throwstrength etc
    if playback_state == GRENADE_PLAYBACK_PREPARE or playback_state == GRENADE_PLAYBACK_RUN or playback_state == GRENADE_PLAYBACK_THROWN then
        if location_playback.throw_strength == 1 then
            cmd.set_button_state(1, true)
            cmd.set_button_state(2048, false)
        elseif location_playback.throw_strength == 0.5 then
            cmd.set_button_state(1, true)
            cmd.set_button_state(2048, true)
        elseif location_playback.throw_strength == 0 then
            cmd.set_button_state(1, false)
            cmd.set_button_state(2048, true)
        end
    end

    -- check if we have the right throwstrength and go to next state
    if playback_state == GRENADE_PLAYBACK_PREPARE and weapon:get_prop_float("CBaseCSGrenade", "m_flThrowStrength") == location_playback.throw_strength then
        playback_state = GRENADE_PLAYBACK_RUN
        playback_data.start_at = cmd.get_command_number()
    end

    if playback_state == GRENADE_PLAYBACK_RUN or playback_state == GRENADE_PLAYBACK_THROW or playback_state == GRENADE_PLAYBACK_THROWN then
        local step = cmd.get_command_number()-playback_data.start_at

        if location_playback.run_duration ~= nil and location_playback.run_duration*tickrate_mp > step then
        elseif playback_state == GRENADE_PLAYBACK_RUN then
            playback_state = GRENADE_PLAYBACK_THROW
        end

        if location_playback.run_duration ~= nil then
            --cmd.forwardmove(450)
            --cmd.set_button_state(bit.lshift(1, 3), true)
            cmd.set_button_state(bit.lshift(1, 17), location_playback.run_speed)
        end
    end

    if playback_state == GRENADE_PLAYBACK_THROW then
        if location_playback.jump then
            cmd.set_button_state(2, true)
        end

        playback_state = GRENADE_PLAYBACK_THROWN
        playback_data.throw_at = cmd.get_command_number()
    end

    if playback_state == GRENADE_PLAYBACK_THROWN then
        if cmd.get_command_number() - playback_data.throw_at >= location_playback.delay then
            cmd.set_button_state(1, false)
            cmd.set_button_state(2048, false)
        end
    end

    if playback_state == GRENADE_PLAYBACK_FINISHED then
        if location_playback.jump then
            local onground = bit.band(local_player:get_prop_int("CBasePlayer", "m_fFlags"), 1) == 1
            if onground then
                playback_state = nil
                location_playback = nil

                restore_disabled()
            else
                local aimbot = aimbot_types[ui.get_int("Aim at locations")+1]

                local v1, v2, v3, v4 = cmd.get_button_state(8), cmd.get_button_state(16), cmd.get_button_state(512), cmd.get_button_state(1024)
                local in_move = (v1 or v2 or v3 or v4)

                -- recovery strafe after throw
                if aimbot == "Rage" and not in_move and bit.band(cmd.get_buttons(), 2) == 0 then
                    cmd_remove_user_input()

                    local movedirection = location_playback.recovery_yaw or location_playback.run_yaw-180
                    local angle = vector.new(0, engine.get_view_angles().y - movedirection, 0):forward()
                    cmd.forwardmove(angle.x * 450)
                    cmd.sidemove(angle.y * 450)

                    --cmd.set_button_state(bit.lshift(1, 3), true)
                    cmd.set_button_state(2, location_playback.recovery_jump)
                end
            end
        elseif location_playback.recovery_yaw ~= nil then
            local aimbot = aimbot_types[ui.get_int("Aim at locations")+1]

            local v1, v2, v3, v4 = cmd.get_button_state(8), cmd.get_button_state(16), cmd.get_button_state(512), cmd.get_button_state(1024)
            local in_move = (v1 or v2 or v3 or v4)


            if aimbot == "Rage" and not in_move and bit.band(cmd.get_buttons(), 2) == 0 then
                if playback_data.recovery_start_at == nil then
                    playback_data.recovery_start_at = cmd.get_command_number()
                end

                local recovery_duration = math.min(32, location_playback.run_duration or 16) + 13 + (location_playback.recovery_jump and 10 or 0)

                if playback_data.recovery_start_at+recovery_duration >= cmd.get_command_number() then
                    local movedirection = location_playback.recovery_yaw
                    local angle = vector.new(0, engine.get_view_angles().y - movedirection, 0):forward()
                    cmd.forwardmove(angle.x * 450)
                    cmd.sidemove(angle.y * 450)

                    --cmd.set_button_state(bit.lshift(1, 3), true)
                    cmd.set_button_state(2, location_playback.recovery_jump)
                end
            else
                location_playback = nil

                restore_disabled()
            end
        end
    end

    if playback_state == GRENADE_PLAYBACK_THROWN then
        if location_playback.jump and ui.get_int("Misc.airstrafe") >= 0 then
            ui_restore["Misc.airstrafe"] = air_strafe_cache
            ui.set_int("Misc.airstrafe", 0)
        end

        if ui.get_bool("Misc.fast_stop") then
            ui_restore["Misc.fast_stop"] = fast_stop_cache
            ui.set_int("Misc.fast_stop", false)
        end

        local aimbot = aimbot_types[ui.get_int("Aim at locations")+1]
        local throw_time = weapon:get_prop_float("CBaseCSGrenade", "m_fThrowTime")

        -- true if this is the last tick of the throw, here we can start resetting stuff
        if is_grenade_being_thrown(weapon, cmd) then
            playback_data.thrown_at = cmd.get_command_number()

            -- actually aim
            if aimbot == "Legit (Silent)" or aimbot == "Rage" then
                cmd.set_viewangles("x", location_playback.viewangles.pitch)
                cmd.set_viewangles("y", location_playback.viewangles.yaw)
                cmd.set_send_packet(false)
            end
        elseif throw_time == 0 and playback_data.thrown_at ~= nil and playback_data.thrown_at > playback_data.throw_at then
            playback_state = GRENADE_PLAYBACK_FINISHED

            local begin = playback_begin
            callbacks.push_delay(0.6, function()
                if playback_state == GRENADE_PLAYBACK_FINISHED and playback_begin == begin then
                    location_playback = nil
                end
            end)
        end
    end
end

local function cmd_location_playback_movement(local_player, weapon)
    if playback_state == nil then
        playback_state = 1

        table.clear(playback_data)
        playback_data.start_at = cmd.get_command_number()
        playback_data.last_offset_swap = 0
    end

    local is_grenade = location_playback.weapons[1] == "weapon_molotov" or location_playback.weapons[1] == "weapon_hegrenade" 
                       or location_playback.weapons[1] == "weapon_smokegrenade" or location_playback.weapons[1] == "weapon_flashbang"
    local current_weapon = weapon:get_name()
    local current_weapon_is_grenade = current_weapon == "MOLOTOV" or current_weapon == "INCENDIARY" 
                                      or current_weapon == "SMOKE" or current_weapon == "FLASHBANG" or current_weapon == "HE GRENADE"

    if weapon ~= playback_weapon and not (is_grenade and current_weapon == "KNIFE") then
        location_playback = nil
        restore_disabled()
        return
    end

    local index = cmd.get_command_number()-playback_data.start_at+1
    local command = location_playback.movement_commands[index]

    if command == nil then
        location_playback = nil
        restore_disabled()
        return
    end

    if ui.get_int("Misc.airstrafe") >= 0 then
        ui_restore["Misc.airstrafe"] = air_strafe_cache
        ui.set_int("Misc.airstrafe", 0)
    end

    if ui.get_bool("Misc.fast_stop") then
        ui_restore["Misc.fast_stop"] = fast_stop_cache
        ui.set_int("Misc.fast_stop", false)
    end

    local aimbot = aimbot_types[ui.get_int("Aim at locations")+1]
    local ignore_pitch_yaw = false--aimbot == "Rage"
    local aa_enabled = ui.get_bool("Antiaim.enable") and ui.get_int("0Antiaim.pitch") ~= 0

    local onground = bit.band(local_player:get_prop_int("CBasePlayer", "m_fFlags"), 1) == 1

    local origin = local_player:get_absorigin()
    local velocity = local_player:get_velocity():length_2d()

    for key, value in pairs(command) do
        local set_key = true

        if key == "pitch" or key == "yaw" then
            set_key = false
        elseif key == bit.lshift(1, 5) and value == false then
            set_key = false
        elseif key == bit.lshift(1, 0) or key == bit.lshift(1, 11) then
            if is_grenade and current_weapon_is_grenade then
                set_key = true
            elseif value == false then
                set_key = false
            end
        end

        if set_key then
            if key == "sidemove" then
                cmd.sidemove(value)
            elseif key == "forwardmove" then
                cmd.forwardmove(value)
            else
                cmd.set_button_state(key, value)
            end
        end
    end

   --[[if aimbot == "Rage" and aa_enabled and (is_grenade or (bit.band(cmd.get_buttons(), 1) == 1 and bit.band(cmd.get_buttons(), 2048) == 2048)) and (not is_grenade or (is_grenade and playback_data.thrown_at == nil)) then
        if cmd.get_command_number() - playback_data.last_offset_swap > 16 then
            local angles = cmd.get_viewangles()

            local _, target_yaw = normalize_angles(0, bit.band(cmd.get_buttons(), 32) == 32 and angles.y or angles.y - 180)
            playback_data.set_pitch = bit.band(cmd.get_buttons(), 32) ~= 32

            local min_diff, new_offset = 90
            -- find closest 90 deg offset of command.yaw to target_yaw
            for o=-180, 180, 90 do
                local _, command_yaw = normalize_angles(0, command.yaw+o)
                local diff = math.abs(command_yaw-target_yaw)

                if min_diff > diff then
                    min_diff = diff
                    new_offset = o
                end
            end

            if new_offset ~= playback_data.last_offset then
                playback_data.last_offset = new_offset
                playback_data.last_offset_swap = cmd.get_command_number()
            end
        end

        if playback_data.last_offset ~= nil then
            cmd.set_viewangles("y", command.yaw+playback_data.last_offset)

            if playback_data.set_pitch then
                cmd.set_viewangles("x", 89)
            end
        end
    end]]

    if not ignore_pitch_yaw then
        engine.set_view_angles(vector.new(command.pitch, command.yaw, 0))

        --[[if not aa_enabled then
            cmd.set_viewangles("x", command.pitch)
            cmd.set_viewangles("y", command.yaw)
        end]]
    elseif (is_grenade and current_weapon_is_grenade) and aimbot == "Rage" and is_grenade_being_thrown(weapon, cmd) then 
        engine.set_view_angles(vector.new(command.pitch, command.yaw, 0))

        --[[cmd.set_viewangles("x", command.pitch)
        cmd.set_viewangles("y", command.yaw)]]
        cmd.set_send_packet(false)

        playback_data.thrown_at = cmd.get_command_number()
    end
end

local function cmd_location_playback(local_player, weapon)
    if location_playback.type == "grenade" then
        cmd_location_playback_grenade(local_player, weapon)
    elseif location_playback.type == "movement" then
        cmd_location_playback_movement(local_player, weapon)
    end
end

local function on_setup_command()
    if not ui.get_bool("Helper") then
        return
    end

    local local_player = entitylist.get_local_player()

    if local_player == nil then
        return
    end

    local weapon = entitylist.get_weapon_by_player(local_player)
    if weapon == nil then
        return
    end

    local hotkey = engine.get_active_key(ui.get_int("Helper Key"))
    local local_origin = local_player:get_absorigin()

    if location_playback ~= nil then
        cmd_location_playback(local_player, weapon)

        ui.set_int("Misc.fast_stop", hotkey and false or fast_stop_cache)
    elseif location_selected ~= nil and hotkey and location_selected.is_in_fov and location_selected.is_position_correct then
        -- if we're already aiming at the location properly, start executing it
        local speed = local_player:get_velocity():length_2d()
        local pin_pulled = weapon:get_prop_bool("CBaseCSGrenade", "m_bPinPulled")

        if location_selected.duckamount == 1 or location_set_closest.has_only_duck then
            cmd.set_button_state(4, true)
        end

        ui.set_int("Misc.fast_stop", hotkey and false or fast_stop_cache)

        local is_grenade = location_selected.weapons[1] == "weapon_molotov" or location_selected.weapons[1] == "weapon_hegrenade" 
                           or location_selected.weapons[1] == "weapon_smokegrenade" or location_selected.weapons[1] == "weapon_flashbang"
        local is_in_attack = bit.band(cmd.get_buttons(), 1) == 1 or bit.band(cmd.get_buttons(), 2048) == 2048

        if (location_selected.type == "movement" and speed < 2 and (not is_grenade or is_in_attack))
        or (location_selected.type == "grenade" and pin_pulled and is_in_attack and speed < 2)
        and location_selected.duckamount == local_player:get_prop_float("CBasePlayer", "m_flDuckAmount") then
            location_playback = location_selected
            playback_state = nil
            playback_weapon = weapon
            playback_begin = cmd.get_command_number()

            cmd_location_playback(local_player, weapon)
        elseif not pin_pulled and (is_in_attack) then
            -- just started holding attack for the first cmd, here we still have the chance to instantly go to the right throwstrength
            if location_selected.throw_strength == 1 then
                cmd.set_button_state(1, true)
                cmd.set_button_state(2048, false)
            elseif location_selected.throw_strength == 0.5 then
                cmd.set_button_state(1, true)
                cmd.set_button_state(2048, true)
            elseif location_selected.throw_strength == 0 then
                cmd.set_button_state(1, false)
                cmd.set_button_state(2048, true)
            end
        end
    elseif location_set_closest ~= nil and hotkey then
        -- move towards closest location set
        local target_position = (location_selected ~= nil and location_selected.is_in_fov) and location_selected.position or location_set_closest.position_approach
        local distance = local_origin:dist_to(target_position)
        local distance_2d = local_origin:dist_to_2d(target_position)

        ui.set_int("Misc.fast_stop", hotkey and false or fast_stop_cache)

        if (distance_2d < 0.5 and distance > 0.08 and distance < 5) or (location_set_closest.inaccurate_position and distance < 40) then
            distance = distance_2d
        end

        if ((location_selected ~= nil and location_selected.duckamount == 1) or location_set_closest.has_only_duck) and distance < 10 then
            cmd.set_button_state(4, true)
        end

        local v1, v2, v3, v4 = cmd.get_button_state(8), cmd.get_button_state(16), cmd.get_button_state(512), cmd.get_button_state(1024)
        if cmd.get_forwardmove() == 0 and cmd.get_sidemove() == 0 and not v1 and not v2 and not v3 and not v4 then
            if distance < 32 and distance >= MAX_DIST_CORRECT*0.5 then
                local fwd1 = target_position - local_origin
                local fwd1_normalized = fwd1:normalized()

                local pos1 = target_position + fwd1_normalized*10

                local fwd = pos1 - local_origin
                local angles = fwd:init_from_angles()

                if angles.y == nil then
                    return
                end

                local move_speed = 0
                if distance > 14 then
                    move_speed = 450
                else
                    local wishspeed = math.min(450, math.max(1.1+local_player:get_prop_float("CBasePlayer", "m_flDuckAmount")*10, distance * 9))
                    local vel = local_player:get_velocity():length_2d()

                    if vel >= math.min(250, wishspeed)+15 then
                        move_speed = 0
                    else
                        move_speed = math.max(6, vel >= math.min(250, wishspeed) and wishspeed*0.9 or wishspeed)
                    end
                end

                local move_yaw = vector.new(0, engine.get_view_angles().y - angles.y, 0):forward()
                cmd.forwardmove(move_yaw.x * move_speed)
                cmd.sidemove(move_yaw.y * move_speed)
            end
        end
    end
end
--@endregion

--@region: callbacks
callbacks.push("on_createmove", on_setup_command)
callbacks.push("on_paint", on_paint)
callbacks.push("on_paint", on_paint_help)
callbacks.push_event("switch_team", function(event)
    flush_active_locations()
end)
callbacks.push_event("player_say", function(event)
    on_chat_input(event)
end)
--@endregion
