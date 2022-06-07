-- [@] name: essentials.lua
-- [@] version: 1.1.
-- [@] by: rmpe994#2710 OPEN SOURCE*.
-- [@] all credits:	Klient & ctzz for some sources.
-- [@] dm me if you find bugs, soon the script will be completed.   








--gui
ui.add_label("                                                        [antiaim]")
ui.next_line()

ui.add_combobox("[antiaim] fakelag", {"-", "minimal", "maximal", "boost dt"})
ui.add_combobox("[antiaim] fakelag disablers", {"-", "exploit", "r8", "air"})
ui.add_checkbox("[-] dt +")
ui.add_combobox("[antiaim] jitter", {"-", "preset", "extended"})
ui.add_checkbox("[antiaim] fakeflick")

ui.add_sliderint("[-] fakeflick speed", 0, 30)
ui.add_checkbox("[antiaim] at targets air")
ui.add_checkbox("[antiaim] peek")
ui.add_label("                                                        [visual]")
ui.next_line()

ui.add_checkbox("[visual] hitlog")
ui.add_checkbox("[visual] slowed indicator")
ui.add_combobox("[visual] indicators", {"-", "style 1"})
ui.next_line()
ui.add_colorpicker("[misc] lua color")
ui.add_label("                                                        [misc]")

ui.add_sliderint("[misc] pingspike", 0, 80)
ui.add_checkbox("[misc] viewmodel in scope")
ui.add_checkbox("[misc] neverlose viewmodel")
ui.next_line()
ui.add_combobox("[misc] better anim", {"-", "legs", "anim", "legs & anim", "breaker"})

--fonts
local font = render.setup_font("Museo Sans Cyrl 500", 15, 350, true, false, true)
local fonte = render.setup_font("Calibri", 12, 650, true, true, true)
--local icons = render.setup_font("ELEGANTICONS", 16, 850)
local fontmedium = render.setup_font("Verdana", 14)

-- locals
local local_player = entitylist.get_local_player()
local screen_w = engine.get_screen_width()
local screen_h = engine.get_screen_height()
local get_screen_size = function() return engine.get_screen_width(), engine.get_screen_height() end
local height_offset = 23
local screen = {}
local notify, notify_list = {}, {}
--table/functions
screen.table = {x = 0, y = 0, a = 0, up = 0}
local lerp = function(a, b, percentage)return a + (b - a) * percentage;end
notify.run = function(text, ms, color) return table.insert(notify_list, 1, {text = text, ms = ms, alpha = 0, asx = -10, frametime = globalvars.get_frametime(), color = color}) end

local lerpklient = function(a, b, percentage) return a + (b - a) * percentage;end
--locals menu
local animation = 0
local animations = 0
local alpha = 0
local alpha2 = 0
local switch = true
--keybind names
local keybinds_tbl = {height = 0, width = 0, alpha = 0, active = {}, dragging = {0, 0, 0},
    list = {
        {name = "dt", key = keybinds.double_tap},
        {name = "hide", key = keybinds.hide_shots},
        {name = "peek", key = keybinds.automatic_peek},
        {name = "hitbox", key = keybinds.safe_points},
        {name = "dmg", key = keybinds.damage_override},
        {name = "body", key = keybinds.body_aim},
        {name = "duck", key = keybinds.fakeduck},


    }
}
--menu gui
local function menu()

    local menu = globalvars.get_menu()
	local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()
	local options = { h = 40 }
    local self = screen.table
	local name = engine.get_gamename()
	local background = 160
    local colorr = ui.get_color("[misc] lua color")
	self.x = engine.get_screen_width()
	self.y = engine.get_screen_height()
	if globalvars.is_open_menu() then  
	animations = lerp(animations, 5, 0.05, false) if not globalvars.is_open_menu() then animations = lerp(animations, 0, 0.05, false) end
	alpha = lerp(alpha, 255, 0.05, false) if not globalvars.is_open_menu() then alpha = lerp(alpha, 0, 0.05, false) end
	alpha2 = lerp(alpha2, background , 0.05, false) if not globalvars.is_open_menu() then alpha2 = lerp(alpha2, 0, 0.05, false) end
	

	end
		if not globalvars.is_open_menu() then animations = lerp(animations, -100, 0.05, false) else animations = lerp(animations, 0, 0.05, false) end
        if not globalvars.is_open_menu() then alpha = lerp(alpha, 0, 0.05, false) else alpha = lerp(alpha, 255, 0.05, false) end
        if not globalvars.is_open_menu() then alpha2 = lerp(alpha2, 0, 0.05, false) else alpha2 = lerp(alpha2, 170, 0.05, false) end
 
        animation = animate.lerp(animation, globalvars.get_menu())
		render.rect_filled_rounded(menu.x, menu.y - options.h - animations - 5, menu.z, options.h, 60, 3, color.new(0, 0, 0, alpha2))
		render.rect_filled(menu.x, menu.y - options.h  - animations - 5, menu.z, 2, color.new(ra, ga, ba, alpha))
		render.text(fontmedium, menu.x + 15, menu.y - options.h - animations + 9, color.new(255,255,255, alpha), "Essentials.lua [beta]", true, false)




		render.text(fontmedium, menu.x + menu.z - render.get_text_width(fontmedium, engine.get_gamename() ) - 15, menu.y - options.h  - animations + 9, color.new(255,255,255,alpha), name, true, false )
end

--indicator
indicator = function()
    if not entitylist.get_local_player() then return end
    if entitylist.get_local_player():get_health() == 0 then return end
    local self = keybinds_tbl
    self.alpha = lerpklient(self.alpha, ui.get_int("[visual] indicators") == 1 and 1 or 0, globalvars.get_frametime() * 12)
    local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()

    if self.alpha < 0 then return end

    local maximum_offset = 66
    local indexes = 0

    for c_id, c_data in pairs(self.list) do
        local item_active = ui.get_keybind_state(c_data.key)

        if item_active then
            indexes = indexes + 1
            if self.active[c_id] == nil then
                self.active[c_id] = {
                     alpha = 0, offset = 0, active = true, name = ""
                }
            end

            local text_width = render.get_text_width(fontmedium, c_data.name)
            
            self.active[c_id].name = c_data.name
            self.active[c_id].active = true
            self.active[c_id].offset = text_width
            self.active[c_id].alpha = lerpklient(self.active[c_id].alpha, 1, globalvars.get_frametime() * 12)

            if self.active[c_id].alpha > 1 then
                self.active[c_id].alpha = 1
            end
        elseif self.active[c_id] ~= nil then
            self.active[c_id].active = false
            self.active[c_id].alpha = lerpklient(self.active[c_id].alpha, 0, globalvars.get_frametime() * 12)

            if self.active[c_id].alpha < 0.1 then
                self.active[c_id] = nil
            end
        end

        if self.active[c_id] ~= nil and self.active[c_id].offset > maximum_offset then
            maximum_offset = self.active[c_id].offset
        end
    end

    local sx, sy = engine.get_screen_width(), engine.get_screen_height()
    local x, y = sx / 2, sy / 2 

    self.height = lerpklient(self.height, indexes > 0 and 5 + indexes * 15 or 0, globalvars.get_frametime() * 12)
    local height_offset = 23; self.width = lerpklient(self.width, 75 + maximum_offset, globalvars.get_frametime() * 12)



    for c_name, c_ref in pairs(self.active) do
        render.text(fontmedium, x - render.get_text_width(fontmedium, c_ref.name)/2 , y + height_offset, color.new(ra, ga, ba, self.alpha*c_ref.alpha*255), c_ref.name, true)
        height_offset = height_offset + 15 * c_ref.alpha
    end
end

--antiaim/misc
local function createmove()
if not entitylist.get_local_player() then return end
if entitylist.get_local_player():get_health() == 0 then return end
local tickcount = globalvars.get_tickcount() % 60
local fspeed = ui.get_int("[-] fakeflick speed")
local inverter = ui.get_keybind_state(keybinds.flip_desync)
local mathh = math.random(1,16)

if ui.get_int("[antiaim] fakelag") == 1 and cmd.get_send_packet() == true then
if not engine.is_in_game() then return end


	if  tickcount == 1 or tickcount == 2 or tickcount == 3 or tickount == 4 or tickount == 5 or tickount == 6 or tickcount == 7 or tickcount == 8 or tickcount == 9 or tickcount == 10 or tickcount == 11 or tickcount == 12 or tickcount == 13 or tickcount == 14 or tickcount == 15 or tickcount == 16 or tickcount == 17 or tickcount == 18 or tickcount == 19 or tickcount == 20 then 
		ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 3)
        ui.set_int("Antiaim.fake_lag_limit", 5)
		ui.set_int("Antiaim.fake_lag_limit", 8)
        ui.set_int("Antiaim.fake_lag_limit", 2)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 6)
		ui.set_int("Antiaim.fake_lag_limit", 2)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 8)
        ui.set_int("Antiaim.fake_lag_limit", 4)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 1) 
		ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 3)
        ui.set_int("Antiaim.fake_lag_limit", 5)
		ui.set_int("Antiaim.fake_lag_limit", 1)
        ui.set_int("Antiaim.fake_lag_limit", 2)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 4)
		ui.set_int("Antiaim.fake_lag_limit", 2)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 1)
        ui.set_int("Antiaim.fake_lag_limit", 4)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 3)
        ui.set_int("Antiaim.fake_lag_limit", 5)
		ui.set_int("Antiaim.fake_lag_limit", 1)
        ui.set_int("Antiaim.fake_lag_limit", 2)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 2)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 1)
        ui.set_int("Antiaim.fake_lag_limit", 4)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 5) 
		ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 3)
        ui.set_int("Antiaim.fake_lag_limit", 5)
		ui.set_int("Antiaim.fake_lag_limit", 1)
        ui.set_int("Antiaim.fake_lag_limit", 2)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 4)
		ui.set_int("Antiaim.fake_lag_limit", 2)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 1)
        ui.set_int("Antiaim.fake_lag_limit", 1)
        ui.set_int("Antiaim.fake_lag_limit", 1)
		ui.set_int("Antiaim.fake_lag_limit", 1)  
	else
		ui.set_int("Antiaim.fake_lag_limit", 10)
    end
end

if ui.get_int("[antiaim] fakelag") == 2 and cmd.get_send_packet() == true then
    if not engine.is_in_game() then return end

    if  tickcount == 1 or tickcount == 2 or tickcount == 3 or tickount == 4 or tickount == 5 or tickount == 6 or tickcount == 7 or tickcount == 8 or tickcount == 9 or tickcount == 10 or tickcount == 11 or tickcount == 12 or tickcount == 13 or tickcount == 14 or tickcount == 15 or tickcount == 16 or tickcount == 17 or tickcount == 18 or tickcount == 19 or tickcount == 20 or tickcount == 21
    or tickcount == 22 or tickcount == 23 or tickcount == 24 or tickcount == 24  or tickcount == 25  or tickcount == 26 or tickcount == 27 or tickcount == 28 or tickcount == 29 or tickcount == 30 then 
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14) 
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)  
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14) 
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
        ui.set_int("Antiaim.fake_lag_limit", 14)
		ui.set_int("Antiaim.fake_lag_limit", 14) 
	else
		ui.set_int("Antiaim.fake_lag_limit", 1)
    end
end

if ui.get_int("[antiaim] fakelag") == 3 and cmd.get_send_packet() == true then
    if not engine.is_in_game() then return end

    if  tickcount == 1 or tickcount == 2 or tickcount == 3 or tickount == 4 or tickount == 5 or tickount == 6 or tickcount == 7 or tickcount == 8 or tickcount == 9 or tickcount == 10 or tickcount == 11 or tickcount == 12 or tickcount == 13 or tickcount == 14 or tickcount == 15 or tickcount == 16 or tickcount == 17 or tickcount == 18 or tickcount == 19 or tickcount == 20 then 
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        ui.set_int("Antiaim.fake_lag_limit", 8)
		ui.set_int("Antiaim.fake_lag_limit", 10)
        
	else
		ui.set_int("Antiaim.fake_lag_limit", 1)
    end
end

if ui.get_int("[antiaim] fakelag disablers") == 1 then

    if not entitylist.get_local_player() then return end
    if not engine.is_in_game() then return end
	if not ui.get_int("[antiaim] fakelag disablers") == 1 then return end

    if ui.get_keybind_state(keybinds.double_tap) or ui.get_keybind_state(keybinds.hide_shots) then ui.set_int("Antiaim.fake_lag_limit", 1) end

end

if ui.get_int("[antiaim] fakelag disablers") == 2 then

    if not entitylist.get_local_player() then return end
    if not engine.is_in_game() then return end
	if not ui.get_int("[antiaim] fakelag disablers") == 2 then return end

    local weapname = weapon.get_name(entitylist.get_weapon_by_player(entitylist.get_local_player()))

    if weapname == "REVOLVER" then ui.set_int("Antiaim.fake_lag_limit", 1) end

end

if ui.get_int("[antiaim] fakelag disablers") == 3 then
    if not entitylist.get_local_player() then return end
    if not engine.is_in_game() then return end
	if not ui.get_int("[antiaim] fakelag disablers") == 3 then return end

    flag = entitylist.get_local_player():get_prop_int("CBasePlayer","m_fFlags") 

    if flag == 256 then ui.set_int("Antiaim.fake_lag_limit", 1) end

end

if ui.get_int("[antiaim] jitter") == 1 and cmd.get_send_packet() == true then
    if not engine.is_in_game() then return end
	if not ui.get_int("[antiaim] jitter") == 1 then return end

	ui.set_int("0Antiaim.desync", 2)
	ui.set_int("0Antiaim.desync_range", 48)
	ui.set_int("0Antiaim.inverted_desync_range", 42)
	ui.set_int("0Antiaim.body_lean", 100)
	ui.set_int("0Antiaim.inverted_body_lean", 100)
	ui.set_int("0Antiaim.yaw", 0)	

end


if ui.get_int("[antiaim] jitter") == 2 and cmd.get_send_packet() == true then

	if not ui.get_int("[antiaim] jitter") == 2 then return end
    if not engine.is_in_game() then return end

	ui.set_int("0Antiaim.desync", 2)
	ui.set_int("0Antiaim.desync_range", 60)
	ui.set_int("0Antiaim.inverted_desync_range", 60)
	ui.set_int("0Antiaim.body_lean", 100)
	ui.set_int("0Antiaim.inverted_body_lean", 100)
	ui.set_int("0Antiaim.yaw", 1)
	ui.set_int("0Antiaim.range", 124)


end

if ui.get_bool("[antiaim] peek") then

    if not engine.is_in_game() then return end
	if not ui.get_bool("[antiaim] peek") then return end

	if ui.get_keybind_state(keybinds.automatic_peek) then 


	ui.set_bool("Antiaim.freestand", true)
    
	else

	ui.set_bool("Antiaim.freestand", false)

	end
end



    if ui.get_bool("[antiaim] fakeflick") then
        if not engine.is_in_game() then return end
		if not ui.get_bool("[antiaim] fakeflick") then return end


        if tickcount == 1 or tickcount == fspeed then
        if inverter == true then
                ui.set_int("Antiaim.yaw_offset", -90)
            else
                ui.set_int("Antiaim.yaw_offset", 90)
            end
        else
            ui.set_int("Antiaim.yaw_offset", 0)
        end
    end
    if ui.get_bool("[-] dt +") then
        ui.set_int("Ragebot.dtspeed", 0)
    end
end

anim = function()
    if ui.get_int("[misc] better anim") == 1 then
		if entitylist.get_local_player() == nil then return end 
		if not engine.is_in_game() then return end
		if entitylist.get_local_player():get_health() == 0 then return end
        ui.set_int("Misc.leg_movement", 1)

	end
    if ui.get_int("[misc] better anim") == 2 then
		if entitylist.get_local_player() == nil then return end 
		if not engine.is_in_game() then return end
		if entitylist.get_local_player():get_health() == 0 then return end
        ui.set_bool("Misc.balance_adjustment", true)
        flag = entitylist.get_local_player():get_prop_int("CBasePlayer","m_fFlags") 
        if flag == 256 or flag == 262 then int = 0 end if flag == 257 or flag == 261 or flag == 263 then int = int + 4 end if int > 45 and int < 250 then 
        ui.set_int("0Antiaim.pitch", 0) 
        else 
        ui.set_int("0Antiaim.pitch", 1) end  

	end
    
	if ui.get_int("[misc] better anim") == 3 then
		if entitylist.get_local_player() == nil then return end 
		if not engine.is_in_game() then return end
		if entitylist.get_local_player():get_health() == 0 then return end
        ui.set_bool("Misc.balance_adjustment", true)
        ui.set_int("Misc.leg_movement", 1)
        flag = entitylist.get_local_player():get_prop_int("CBasePlayer","m_fFlags") 
        if flag == 256 or flag == 262 then int = 0 end if flag == 257 or flag == 261 or flag == 263 then int = int + 4 end if int > 45 and int < 250 then 
        ui.set_int("0Antiaim.pitch", 0) 
        else 
        ui.set_int("0Antiaim.pitch", 1) end  
        
	end
    if ui.get_int("[misc] better anim") == 4 then
		if entitylist.get_local_player() == nil then return end 
		if not engine.is_in_game() then return end
		if entitylist.get_local_player():get_health() == 0 then return end
            ui.set_int("Misc.leg_movement", math.random(1, 2))
        
	end
end

fakeping = function()
    value = ui.get_int("[misc] pingspike")
    if ui.get_int("[misc] pingspike") then
        console.set_int("net_fakelag", value)   
end
end

slowed = function()
    if ui.get_bool("[visual] slowed indicator") then 
        ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()
        local sc = { 
            xx = engine.get_screen_width() / 2,
            yy = engine.get_screen_height() / 2,
          }        
          
        velocity_modifier = entitylist.get_local_player():get_prop_float("CCSPlayer", "m_flVelocityModifier")
        x, y = sc.xx - 90 / 2 , sc.yy - 150

        if velocity_modifier ~= 1 then
            render.text(fonte, x- 1 + 10 + 4, y - 15, color.new(ra,ga,ba), "Slowed Down " .. math.floor( 100 * velocity_modifier) .. "%%", true, true, true)
            render.rect_filled_rounded(x + 13, y - 2, 90, 12, 50, 5, color.new(0, 0, 0, 150 ), color.new(0, 0, 0, 150)) 
            render.rect_filled_rounded(x+ 14, y - 1, math.floor(100 * velocity_modifier) - 15, 8, 50, 5, color.new(ra,ga,ba), color.new(ra,ga,ba))
            --render.text(icons, x - 5 , y - 17, color.new(ra,ga,ba), "s",true,true)
        end
    end
end

notify.on_paint = function()
    local height_offset = 23

    local sx, sy = get_screen_size()
    sy = sy - 300

    for c_name, c_data in pairs(notify_list) do
        c_data.ms = c_data.ms - globalvars.get_frametime()
        c_data.alpha = lerp(c_data.alpha, c_data.ms <= 0 and 0 or 1, globalvars.get_frametime() * 8)
        c_data.asx = lerp(c_data.asx, c_data.ms <= 0 and 10 or 0, globalvars.get_frametime() * 8)
        c_data.color = c_data.color == nil and {255, 255, 255} or c_data.color

        render.text(font, ((sx / 2) - (render.get_text_width(font, c_data.text) / 2)) + 12 * c_data.asx, sy + height_offset, color.new(c_data.color[1], c_data.color[2], c_data.color[3], c_data.alpha*255), c_data.text,true,false)

        height_offset = height_offset + 13 * c_data.alpha
    end
end


local function shot_info(e)
    if ui.get_bool("[visual] hitlog") then
    if e.result == "Hit" then
		if e.server_hitbox == "Head" then clor = {255 , 0 ,0} else clor = {255 , 255 , 255} end
        notify.run(e.target_name.."'s " ..e.server_hitbox.. " -"..e.server_damage , 5, clor )
    elseif e.result == "Spread" then
        notify.run(" Missed at "..e.target_name.. " due to spread " , 5, {244,181,76,255})
    elseif e.result == "Resolver" then
        notify.run(" Missed at "..e.target_name.. " due to resolver " , 5, {255, 0, 0})
    elseif e.result == "Occlusion" then
        notify.run(" Missed at "..e.target_name.. " due to ? " , 5, {255, 255, 255})
    end
end
end

local print = function(...)
    console.execute_client_cmd("con_filter_enable 0")
    for i, data in pairs({...}) do
        console.execute_client_cmd(string.format("echo %s %s", "[essentials]", tostring(data)))
    end
end
cheat.popup("essentials loaded", "check the console")
print("useful information about lua and functions", "use dt boost and dt + with fast exploit recharge")
 
cheat.RegisterCallback("on_shot", shot_info)
cheat.RegisterCallback("on_paint", function()
	notify.on_paint()
	indicator()                          
	menu()
    slowed()
end)

cheat.RegisterCallback("on_createmove", function()

	if ui.get_bool("[misc] viewmodel in scope") then 
		if not ui.get_bool("[misc] viewmodel in scope") then return end 

 
			if ui.get_keybind_state(keybinds.third_person) then
				console.set_int( "fov_cs_debug", 0 )
			else
				console.set_int( "fov_cs_debug", 90 )
		 end
		else
		console.set_int( "fov_cs_debug", 0 )
	end
    if ui.get_bool("[misc] neverlose viewmodel") then 
        ui.set_int("Esp.viewmodel_fov", 0)
        ui.set_int("Esp.viewmodel_x", 1)
        ui.set_int("Esp.viewmodel_y", 14)
        ui.set_int("Esp.viewmodel_z", -6)
        ui.set_int("Esp.viewmodel_roll", 0)
        console.execute_client_cmd("viewmodel_fov 40")
    end
    if ui.get_bool("[antiaim] at targets air") then
        if not ui.get_bool("[antiaim] at targets air") then return end

        if engine.get_active_key(0x20) then
            ui.set_int("0Antiaim.base_angle", 1 )
            else
            ui.set_int("0Antiaim.base_angle", 0 )
        end
    end

    createmove()
    anim()
    fakeping()
	
end)





