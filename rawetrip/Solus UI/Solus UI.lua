--@region: script information
    -- @name: solus ui
    -- @created by: Klient#1690
    -- @version: 1.0.0
--@endregion

local __debug = true
--@region: auxiliary functions
math.round = function(num, numDecimalPlaces)local mult = 10 ^ (numDecimalPlaces or 0);return math.floor(num * mult + 0.5) / mult;end
local clamp = function(value, min, max) return math.min(math.max(value, min), max) end
local lerp = function(start, end_pos, time)if time == nil then time = 0.095;end;time = clamp(time, 0, 1)local delta = end_pos - start;delta = delta * time; delta = delta + start; if end_pos == 0 and delta < 0.01 and delta > -0.01 then delta = 0;elseif end_pos == 1 and delta < 1.01 and delta > 0.99 then delta = 1;end;return delta;end
local print = function(...) for i, data in pairs({...}) do if i < 2 then console.print_color(string.format("%s", "\n[solus] "), color.new(183, 150, 255, 255));end;console.print(string.format("%s%s", tostring(data), i > 0 and "," or ""):gsub(i == #{...} and "," or "", ""));end;end
local debug = function(...) if not __debug then return end return print(...) end
local formatting = function(avg)
    if avg < 1 then 
        return math.round(avg, 2)
    end;

    if avg < 10 then 
        return math.round(avg, 1)
    end;

    return math.floor(avg)
end
--@endregion

--@region: locals
local solus, meta = {}, {}
--@endregion

--@region: fonts
local fonts = {
    default = {
        verdana = render.setup_font("Verdana", 13)
    }
}
--@endregion

--@region: solus functions
solus.create_fade = function(x, y, w, h, color, length, round)
    local r, g, b, a = color:r(), color:g(), color:b(), color:a()

    for i = 1, 10 do
        render.rect_rounded(x - i, y - i, w + i * 2, h + i * 2, color.new(r, g, b, (60 - (60 / length) * i) * (a / 255)), round)
    end
end

solus.create_window = function(x, y, w, h, color, shadow_color, outline_color, left, outline)
    local r, g, b, a = color:r(), color:g(), color:b(), color:a()
    local r1, g1, b1, a1 = shadow_color:r(), shadow_color:g(), shadow_color:b(), shadow_color:a()
    local r2, g2, b2, a2 = outline_color:r(), outline_color:g(), outline_color:b(), outline_color:a()

    render.blur(x, y, w, h, (255 / 255) * a)
    render.rect_filled_rounded(x, y, w, h, 10, 5, color.new(0, 0, 0, (50 / 255) * a))
    render.rect_rounded(x, y, w, h, color.new(r2, g2, b2, (80 / 255) * a2), 5)

    solus.create_fade(x, y, w, h, color.new(r1, g1, b1, (120 / 255) * a1), 10, 10)

    if outline then
        render.begin_cliprect(x, y, 4, 4)
            render.arc(x + 4, y + 4, 3, 4, -180, 90, color.new(r, g, b, (255 / 255) * a))
        render.end_cliprect()

        render.rect_filled(x + 4, y, w - 8, 1, color.new(r, g, b, (255 / 255) * a))

        render.begin_cliprect(x + w - 4, y, 4, 4)
            render.arc(x + w - 5, y + 4, 3, 4, -90, 90, color.new(r, g, b, (255 / 255) * a))
        render.end_cliprect()

        render.gradient(x, y + 4, 1, h - 6, color.new(r, g, b, (255 / 255) * a), color.new(r, g, b, 0), 1)
        render.gradient(x + w - 1, y + 4, 1, h - 6, color.new(r, g, b, (255 / 255) * a), color.new(r, g, b, 0), 1)
    end

    if left then
        render.rect_filled(x, y + 4, 1, h - 8, color.new(r, g, b, (255 / 255) * a))

        render.begin_cliprect(x, y, 4, 4)
            render.arc(x + 4, y + 4, 3, 4, -180, 90, color.new(r, g, b, (255 / 255) * a))
        render.end_cliprect()

        render.begin_cliprect(x, y + h - 4, 4, 4)
            render.arc(x + 4, y + h - 5, 3, 4, 90, 90, color.new(r, g, b, (255 / 255) * a))
        render.end_cliprect()

        render.gradient(x + 4, y, 15, 1, color.new(r, g, b, (255 / 255) * a), color.new(r, g, b, 0), 0)
        render.gradient(x + 4, y + h - 1, 15, 1, color.new(r, g, b, (255 / 255) * a), color.new(r, g, b, 0), 0)
    end
end
--@endregion

--@region: ui
ui.add_colorpicker("solus color")
ui.add_sliderint("keybinds x", 0, engine.get_screen_width())
ui.add_sliderint("keybinds y", 0, engine.get_screen_height())
--@endregion

--@region: paint
--@region: watermark
solus.watermark = {}
solus.watermark.paint = function()
    local self = solus.watermark

    if not self then
        cheat.popup("solus", "solus.watermark undefined")
        return
    end

    local nickname = engine.get_gamename() or ""

    local actual_time = globalvars.get_time() or nil

    if not actual_time then
        return
    end

    local r, g, b, a = ui.get_color("solus color"):r(), ui.get_color("solus color"):g(), ui.get_color("solus color"):b(), ui.get_color("solus color"):a()

    local cheat_name = "rawetrip"
    local suffix = ("%s"):format(cheat_name)

    local text = ("%s | %s | %s"):format(suffix, nickname, actual_time)

    if engine.is_in_game() then
        local latency = globalvars.get_ping() or 0
        local latency_text = latency > 5 and (" | delay: %dms"):format(latency) or ""

        text = ("%s | %s%s | %s"):format(suffix, nickname, latency_text, actual_time)
    end

    local h, w = 20, render.get_text_width(fonts.default.verdana, text) + 11
    local x, y = engine.get_screen_width(), 10
    x = x - w - 10

    solus.create_window(x, y, w, h, color.new(r, g, b, 255), color.new(r, g, b, a), color.new(r, g, b, 255), false, true)

    render.text(fonts.default.verdana, x + 5, y + 3, color.new(255, 255, 255, 255), (cheat_name):sub(1, #cheat_name / 2))
    render.text(fonts.default.verdana, x + 5 + render.get_text_width(fonts.default.verdana, (cheat_name):sub(1, #cheat_name / 2)), y + 3, color.new(r, g, b, 255), (cheat_name):sub(#cheat_name / 2 + 1, #cheat_name), false)
    render.text(fonts.default.verdana, x + 5 + render.get_text_width(fonts.default.verdana, cheat_name), y + 3, color.new(255, 255, 255, 255), (text):gsub(cheat_name, ""), false)
end
--@endregion

--@region: antiaim indication
solus.antiaim = {value = 0, last_sent = 0, current_choke = 0}
solus.antiaim.move = function()
    local self = solus.antiaim

    if not self then
        cheat.popup("solus", "solus.antiaim undefined")
        return
    end

    if cmd.get_choked_commands() == 0 then
        self.last_sent = self.current_choke
    end

    self.current_choke = cmd.get_choked_commands()
end

solus.antiaim.paint = function()
    local self = solus.antiaim

    if not self then
        cheat.popup("solus", "solus.antiaim undefined")
        return
    end

    local player = entitylist.get_local_player()

    if not player then
        return
    end

    if not player:is_alive() then
        return
    end

    local r, g, b, a = ui.get_color("solus color"):r(), ui.get_color("solus color"):g(), ui.get_color("solus color"):b(), ui.get_color("solus color"):a()

    --@region: fl
    local addr = ""

    if ui.get_keybind_state(keybinds.double_tap) then
        addr = " | EXPLOITING"
    end

    local text = ("FL: %s%s"):format(
        (function()
            if tonumber(self.last_sent) < 10 then
                return '\x20\x20' .. self.last_sent
            end

            return self.last_sent
        end)(),
    addr)

    local h, w = 20, render.get_text_width(fonts.default.verdana, text) + 9
    local x, y = engine.get_screen_width(), 35
    x = x - w - 10

    solus.create_window(x, y, w, h, color.new(r, g, b, 255), color.new(r, g, b, a), color.new(r, g, b, 255), false, false)

    render.gradient(x + 10, y + h - 1, (w / 2 - 10), 1, color.new(r, g, b, 0), color.new(r, g, b, 255), 0)
    render.gradient(x + (w / 2), y + h - 1, (w / 2 - 10), 1, color.new(r, g, b, 255), color.new(r, g, b, 0), 0)

    render.text(fonts.default.verdana, x + 5, y + 3, color.new(255, 255, 255, 255), text)
    --@endregion

    --@region: fake
    local body_yaw = antiaim.get_body_yaw(ui.get_keybind_state(keybinds.flip_desync))
    local body_yaw_aa = math.max(-60, math.min(60, math.round(body_yaw, 1)))
    local body_yaw_abs = math.abs(body_yaw_aa)

    self.value = lerp(self.value, math.floor(math.round(body_yaw_abs, 0)), globalvars.get_frametime() * 2)

    local r_d, g_d, b_d = 192 - (body_yaw_abs / 58 * 71), 32 + (body_yaw_abs / 58 * 146), 28

    local text = ("FAKE (%.1f°)"):format(self.value)

    local h, w = 20, render.get_text_width(fonts.default.verdana, text) + 9

    solus.create_window(x - w - 6, y, w, h, color.new(r_d, g_d, b_d, 255), color.new(r, g, b, a), color.new(r, g, b, 255), true, false)
    render.text(fonts.default.verdana, x + 5 - w - 6, y + 3, color.new(255, 255, 255, 255), text)
    --@endregion
end
--@endregion

--@region: ilstate
solus.ilstate = {request_time = globalvars.get_frametime(), frametime = globalvars.get_curtime(), frametimes = {}}
solus.ilstate.paint = function()
    local self = solus.ilstate

    if not self then
        cheat.popup("solus", "solus.ilstate undefined")
        return
    end

    local r, g, b, a = ui.get_color("solus color"):r(), ui.get_color("solus color"):g(), ui.get_color("solus color"):b(), ui.get_color("solus color"):a()

    --@region: update frame
    if (self.request_time + 1) < globalvars.get_curtime() then
        self.frametime = globalvars.get_frametime()
        self.request_time = globalvars.get_curtime()

        table.insert(self.frametimes, 1, self.frametime)

        if #self.frametimes > 4 then
            table.remove(self.frametimes, #self.frametimes)
        end
    end
    --@endregion

    --@region: ms/hz
    local avg = math.abs((self.frametime * 1000) - 5)
    local display_frequency = 144
    avg = avg > display_frequency and display_frequency or avg

    local text = ("%sms / %shz"):format(formatting(avg), display_frequency)

    local h, w = 20, render.get_text_width(fonts.default.verdana, text) + 9
    local x, y = engine.get_screen_width(), (engine.is_in_game() and 60 or 35)

    x = x - w - 10

    solus.create_window(x, y, w, h, color.new(r, g, b, 255), color.new(r, g, b, a), color.new(r, g, b, 255), false, false)

    render.gradient(x + 10, y + h - 1, (w / 2 - 10), 1, color.new(r, g, b, 0), color.new(r, g, b, 255), 0)
    render.gradient(x + (w / 2), y + h - 1, (w / 2 - 10), 1, color.new(r, g, b, 255), color.new(r, g, b, 0), 0)

    render.text(fonts.default.verdana, x + 5, y + 3, color.new(255, 255, 255, 255), text)
    --@endregion

    --@region: io
    local text = "IO | "
    local sub = text .. '\x20\x20\x20\x20\x20\x20\x20'
    local h, w = 20, render.get_text_width(fonts.default.verdana, sub) + 7
    local ie_w = render.get_text_width(fonts.default.verdana, text) + 5

    solus.create_window(x - w - 4, y, w, h, color.new(r, g, b, 255), color.new(r, g, b, a), color.new(r, g, b, 255), true, false)

    render.text(fonts.default.verdana, x - w, y + 3, color.new(255, 255, 255, 255), sub)

    for i = 1, #self.frametimes do
        local height = math.floor(math.min(12, self.frametimes[i] / 1 * 1000))

        render.gradient(x - w + ie_w - (5 * i) + 15, y + 15 - (height - 1), 5, height - 1, color.new(r, g, b, 0), color.new(r, g, b, 255), 1)
    end
    --@endregion
end
--@endregion

--@region: keybinds
solus.keybinds = {active = {}, hotkey_modes = {"always", "holding", "toggled", "disabled"},
    list = {
        {name = "Minimum damage", key = keybinds.damage_override},
        {name = "Double tap", key = keybinds.double_tap},
        {name = "On shot anti-aim", key = keybinds.hide_shots},
        {name = "Slow motion", key = keybinds.slowwalk},
        {name = "Anti-aim inverter", key = keybinds.flip_desync},
        {name = "Duck peek assist", key = keybinds.fakeduck},
        {name = "Quick peek assist", key = keybinds.automatic_peek},
        {name = "Body aim", key = keybinds.body_aim},
        {name = "Auti Fire", key = keybinds.legit_automatic_fire}
    }
}
solus.keybinds.paint = function()
    local self = solus.keybinds

    if not self then
        cheat.popup("solus", "solus.keybinds undefined")
        return
    end

    local r, g, b, a = ui.get_color("solus color"):r(), ui.get_color("solus color"):g(), ui.get_color("solus color"):b(), ui.get_color("solus color"):a()

    local is_menu_open = globalvars.is_open_menu()
    local frames = 8 * globalvars.get_frametime()

    local latest_item = false
    local maximum_offset = 66

    for c_value, c_data in pairs(self.list) do
        local item_active = ui.get_keybind_state(c_data.key)
        local c_name = c_data.name

        local state = ui.get_keybind_mode(c_data.key) + 2

        if item_active then
            latest_item = true

            if self.active[c_name] == nil then
                self.active[c_name] = {
                    name = "", mode = "", alpha = 0, offset = 0, active = true
                }
            end

            local text_width = render.get_text_width(fonts.default.verdana, c_name)

            self.active[c_name].name = c_name
            self.active[c_name].active = true
            self.active[c_name].offset = text_width
            self.active[c_name].mode = self.hotkey_modes[state]
            self.active[c_name].alpha = self.active[c_name].alpha + frames

            if self.active[c_name].alpha > 1 then
                self.active[c_name].alpha = 1
            end
        elseif self.active[c_name] ~= nil then
            self.active[c_name].active = false
            self.active[c_name].alpha = self.active[c_name].alpha - frames

            if self.active[c_name].alpha <= 0 then
                self.active[c_name] = nil
            end
        end

        if self.active[c_name] ~= nil and self.active[c_name].offset > maximum_offset then
            maximum_offset = self.active[c_name].offset
        end
    end

    local text = "keybinds"
    local x, y = ui.get_int("keybinds x"), ui.get_int("keybinds y")

    local height_offset = 23
    local w, h = 75 + maximum_offset, 20

    solus.create_window(x, y, w, h, color.new(r, g, b, 255), color.new(r, g, b, a), color.new(r, g, b, 255), false, true)
    render.text(fonts.default.verdana, x - render.get_text_width(fonts.default.verdana, text) / 2 + w / 2, y + 3, color.new(255, 255, 255, 255), text)

    for c_name, c_ref in pairs(self.active) do
        local key_type = "[" .. (c_ref.mode or "?") .. "]"

        render.text(fonts.default.verdana, x + 5, y + height_offset, color.new(255, 255, 255, c_ref.alpha*255), c_ref.name, true)
        render.text(fonts.default.verdana, x + w - render.get_text_width(fonts.default.verdana, key_type) - 5, y + height_offset, color.new(255, 255, 255, c_ref.alpha*255), key_type, true)

        height_offset = height_offset + 15
    end
end
--@endregion
--@endregion

cheat.RegisterCallback("on_paint", function()
    solus.watermark.paint()
    solus.antiaim.paint()
    solus.ilstate.paint()
    solus.keybinds.paint()
end)

cheat.RegisterCallback("on_createmove", function()
    solus.antiaim.move()
end)
