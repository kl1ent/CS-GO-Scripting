-- [@] name: essentials.lua
-- [@] version: 1.3
-- [@] by: rmpe994#2710 OPEN SOURCE*.
-- [@] all credits:	Klient & ctzz for some sources.
-- [@] dm me if you find bugs, soon the script will be completed.   








--gui
ui.add_label("                                                        [antiaim]")
ui.next_line()

ui.add_combobox("[antiaim] fakelag", {"-", "minimal", "maximal"})
ui.add_combobox("[antiaim] fakelag disablers", {"-", "exploit", "r8", "air", "shot"})
ui.add_combobox("[antiaim] jitter", {"-", "preset", "extended"})
ui.add_checkbox("[antiaim] fakeflick")

ui.add_sliderint("[-] fakeflick speed", 0, 30)
ui.add_checkbox("[antiaim] at targets air")
ui.add_checkbox("[antiaim] peek")
ui.add_label("                                                        [visual]")
ui.next_line()

ui.add_checkbox("[visual] hitlog")
ui.add_checkbox("[visual] slowed indicator")
ui.add_checkbox("[visual] watermark")
ui.add_combobox("[visual] indicators", {"-", "style 1", "style 2"})
ui.next_line()
ui.add_combobox("[visual] hitmarker", {"-", "style 1"})
ui.next_line()
--ui.add_combobox("hitsound", {"-","style 1"})

ui.add_colorpicker("[misc] lua color")
ui.add_label("                                                        [misc]")

ui.add_sliderint("[misc] pingspike", 0, 80)
ui.add_checkbox("[misc] viewmodel in scope")
ui.add_checkbox("[misc] neverlose viewmodel")
ui.next_line()
ui.add_combobox("[misc] better anim", {"-", "static legs", "static legs & anim", "breaker"})
ui.next_line()
ui.add_sliderint("[-] pitch 0 on land time", 4, 8)

--fonts
local font = render.setup_font("Museo Sans Cyrl 500", 13, fontflags.bold)
local fonte = render.setup_font("Calibri", 12, fontflags.bold, true, true, true)
local fontwater = render.setup_font("Verdana", 12)
local fonthit = render.setup_font("Verdana", 14, fontflags.bold)
local smallestitle = render.setup_font("Small Fonts", 10, fontflags.bold)
local smallestin = render.setup_font("Small Fonts", 9)


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
local shot_data = {}
local switchh = 1
--table/functions
screen.table = {x = 0, y = 0, a = 0, up = 0}
local lerp = function(a, b, percentage)return a + (b - a) * percentage;end
notify.run = function(text, ms, color) return table.insert(notify_list, 1, {text = text, ms = ms, alpha = 0, asx = -10, frametime = globalvars.get_frametime(), color = color}) end
local get_player_state = function(flags, player)local m_flags = flags;if m_flags == 256 then return "AIR";elseif m_flags == 263 then return "CROUCHING";elseif m_flags == 262 then return "CROUCHING AIR";end;if player:get_velocity():length_2d() > 70 then return "MOVEING";end;if player:get_velocity():length_2d() < 70 and player:get_velocity():length_2d() > 2 then return "SLOW";end; return "STANDING";end

local lerpklient = function(a, b, percentage) return a + (b - a) * percentage;end
--locals menu
local animation = 0
local animations = 0
local alpha = 0
local alpha2 = 0
local switch = true
local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()
local visible = 0
local second = 0
local image = steam.get_user_avatar()
local player_states = {"Global", "Standing", "Moving", "Slow motion", "Air"}


--keybind names (@Klient)
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
local keybinds_table = {height = 0, width = 0, alpha = 0, active = {}, dragging = {0, 0, 0},
    list = {
        {name = "DT", key = keybinds.double_tap},
        {name = "OSAA", key = keybinds.hide_shots},
        {name = "PEEK", key = keybinds.automatic_peek},
        {name = "SAFE", key = keybinds.safe_points},
        {name = "DMG", key = keybinds.damage_override},
        {name = "BODY", key = keybinds.body_aim},
        {name = "DUCK", key = keybinds.fakeduck},


    }
}

--menu gui (@Ctzz)
local function menu()
local menu = globalvars.get_menu()
	local options = { h = 40 }
    local self = screen.table
	local name = engine.get_gamename()
	local background = 160
    local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()

	self.x = engine.get_screen_width()
	self.y = engine.get_screen_height()
	if globalvars.is_open_menu() then  
	animations = lerp(animations, 5, 0.05, false) if not globalvars.is_open_menu() then animations = lerp(animations, 0, 0.05, false) end
	alpha = lerp(alpha, 255, 0.05, false) if not globalvars.is_open_menu() then alpha = lerp(alpha, 0, 0.05, false) end
	alpha2 = lerp(alpha2, background , 0.05, false) if not globalvars.is_open_menu() then alpha2 = lerp(alpha2, 0, 0.05, false) end
	visible = lerp(visible, 25, 0.05, false) if not globalvars.is_open_menu() then visible = lerp(visible, 0, 0.05, false) end

	end
		if not globalvars.is_open_menu() then animations = lerp(animations, -100, 0.05, false) else animations = lerp(animations, 0, 0.05, false) end
        if not globalvars.is_open_menu() then alpha = lerp(alpha, 0, 0.05, false) else alpha = lerp(alpha, 255, 0.05, false) end
        if not globalvars.is_open_menu() then alpha2 = lerp(alpha2, 0, 0.05, false) else alpha2 = lerp(alpha2, 170, 0.05, false) end
        if not globalvars.is_open_menu() then visible = lerp(visible, 0, 0.05, false) else visible = lerp(visible, 24, 0.05, false) end

        animation = animate.lerp(animation, globalvars.get_menu())
		render.rect_filled_rounded(menu.x, menu.y - options.h - animations - 5, menu.z, options.h, 60, 3, color.new(0, 0, 0, alpha2))
		render.rect_filled(menu.x, menu.y - options.h  - animations - 5, menu.z, 2, color.new(ra, ga, ba, alpha))
		render.text(fontmedium, menu.x + 15, menu.y - options.h - animations + 9, color.new(255,255,255, alpha), "Essentials.lua [stable]", true, false)




		render.text(fontmedium, menu.x + menu.z - render.get_text_width(fontmedium, engine.get_gamename() ) - 15, menu.y - options.h  - animations + 9, color.new(255,255,255,alpha), name, true, false )
        render.image(image, menu.x + menu.z - render.get_text_width(fontmedium, engine.get_gamename() ) - 45, menu.y - options.h  - animations + 3, visible, visible, 200) 
       


end
--watermark (@Ctzz)
local function watermark()
    if ui.get_bool("[visual] watermark") then
    if not ui.get_bool("[visual] watermark") then return end 
    if globalvars.is_open_menu() then watermark_animation = animate.lerp(watermark_animation, 100, 0.05, false) else watermark_animation = animate.lerp(watermark_animation, 0, 0.05, false) end

    local info = { x = engine.get_screen_width(), y = engine.get_screen_height(), text = "essentials.lua / " .. string.lower(engine.get_gamename()) .. " / " .. globalvars.get_ping() .. "ms / " .. globalvars.get_time() .. " " }

    local textwidth = render.get_text_width(fontwater, info.text)
    local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()

    render.rect_filled(info.x - textwidth - 15 , 10 - watermark_animation , textwidth + 10, 23, color.new(ra - 20,ga - 20,ba -20,150))
    render.text(fontwater, info.x - textwidth - 9 , 16 - watermark_animation, color.new(255,255,255,255), info.text)
    --render.image(image, info.x - textwidth - 12, 10 - watermark_animation, 21, 21, 200)
    end
end

--indicators (@Klient)
indicator = function()
    if not entitylist.get_local_player() then return end
    if entitylist.get_local_player():get_health() == 0 then return end
    local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()
    local self = keybinds_tbl
    self.alpha = lerpklient(self.alpha, ui.get_int("[visual] indicators") == 1 and 1 or 0, globalvars.get_frametime() * 12)

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

local function newindicators()

    if ui.get_int("[visual] indicators") == 2 then
        if entitylist.get_local_player() == nil then return end 
		if not engine.is_in_game() then return end
		if entitylist.get_local_player():get_health() == 0 then return end

        local lua_namee = "ESSENTIALS.LUA"
        local state = get_player_state(local_player:get_prop_int("CBasePlayer", "m_fFlags"), local_player)
        local offsett = 6
        local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()


        render.text(smallestitle, screen_w/2 - render.get_text_width(smallestitle, lua_namee)/2, screen_h/2 + 15, color.new(ra,ga,ba,255), lua_namee, true, true)
        render.text(smallestin, screen_w/2 - render.get_text_width(smallestin, state)/2 , screen_h/2 + 24, color.new(255,255,255,255), state, false, true)

        if ui.get_keybind_state(keybinds.double_tap) then 

        render.text(smallestin, screen_w/2 - render.get_text_width(smallestin, "DT")/2 , screen_h/2 + 29 + offsett, color.new(255,255,255,255), "DT", false, true) offsett = offsett + 10
        end

        if (ui.get_keybind_state(keybinds.hide_shots)) then 

        render.text(smallestin, screen_w/2 - render.get_text_width(smallestin, "OSAA")/2 , screen_h/2 + 29 + offsett, color.new(255,255,255,255), "OSAA", false, true) offsett = offsett + 10 
        end

        if (ui.get_keybind_state(keybinds.damage_override)) then 

            render.text(smallestin, screen_w/2 - render.get_text_width(smallestin, "DMG")/2 , screen_h/2 + 29 + offsett, color.new(255,255,255,255), "DMG", false, true) offsett = offsett + 10 
        end

        if (ui.get_keybind_state(keybinds.body_aim)) then 

            render.text(smallestin, screen_w/2 - render.get_text_width(smallestin, "BODY")/2 , screen_h/2 + 29 + offsett, color.new(255,255,255,255), "BODY", false, true) offsett = offsett + 10 
        end

        if (ui.get_keybind_state(keybinds.safe_points)) then 

            render.text(smallestin, screen_w/2 - render.get_text_width(smallestin, "SAFE")/2 , screen_h/2 + 29 + offsett, color.new(255,255,255,255), "SAFE", false, true) offsett = offsett + 10 
        end

    end
end



--antiaim/misc 
local function createmove()
if not entitylist.get_local_player() then return end
if entitylist.get_local_player():get_health() == 0 then return end
local tickcount = globalvars.get_tickcount() % 60
local fspeed = ui.get_int("[-] fakeflick speed")
local inverter = ui.get_keybind_state(keybinds.flip_desync)


if ui.get_int("[antiaim] fakelag") == 1 then
    local first = 0
    if first < globalvars.get_tickcount() then
     second = second + 1
    end
    if second == 110 then second = 0 end
 if second == 1 then ui.set_int("Antiaim.fake_lag_limit", 8) end

 if second == 80 then ui.set_int("Antiaim.fake_lag_limit", 1) end

    
    

end
if ui.get_int("[antiaim] fakelag") == 2 then
    if not engine.is_in_game() then return end

    local first = 0
    if first < globalvars.get_tickcount() then
     second = second + 1
    end
    if second == 110 then second = 0 end
 if second == 1 then ui.set_int("Antiaim.fake_lag_limit", 14) end

 if second == 80 then ui.set_int("Antiaim.fake_lag_limit", 1) end

end


--fakelag disablers
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


--fakeflick
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

end
local function weapon_fire(e)
    if ui.get_int("[antiaim] fakelag disablers") == 3 then
    local player_fire = e:get_int("userint")
    local local_player = entitylist.get_local_player()
    --local nextAttack = local_player:get_prop_float("CCSPlayer", "m_flNextAttack")


    if player_fire then
        ui.set_int("Antiaim.fake_lag_limit", 1) 
    end

    --if ui.get_int("Antiaim.fake_lag_limit", 1) then ui.set_int("Antiaim.fake_lag_limit", 15)  end

    --if nextAttack then ui.set_keybind_state(keybinds.hide_shots, true) end
end
end
--anims
anim = function()
    if ui.get_int("[misc] better anim") == 1 then
		if entitylist.get_local_player() == nil then return end 
		if not engine.is_in_game() then return end
		if entitylist.get_local_player():get_health() == 0 then return end
        entitylist.get_local_player():m_flposeparameter()[7] = 1 -- static legs


	end
    
	if ui.get_int("[misc] better anim") == 2 then
		if entitylist.get_local_player() == nil then return end 
		if not engine.is_in_game() then return end
		if entitylist.get_local_player():get_health() == 0 then return end
        ui.set_bool("Misc.balance_adjustment", true)

        entitylist.get_local_player():m_flposeparameter()[7] = 1 -- static legs
        local timee = ui.get_int("[-] pitch 0 on land time")
        flag = entitylist.get_local_player():get_prop_int("CBasePlayer","m_fFlags") 

        if flag == 256 or flag == 262 then 
            int = 0 end 
        if flag == 257 or flag == 261 or flag == 263 then 
            int = int + timee end 
        if int > 45 and int < 250 then 
        ui.set_int("0Antiaim.pitch", 0) 
        else 
        ui.set_int("0Antiaim.pitch", 1) end  

	end
    if ui.get_int("[misc] better anim") == 3 then
		if entitylist.get_local_player() == nil then return end 
		if not engine.is_in_game() then return end
		if entitylist.get_local_player():get_health() == 0 then return end
            ui.set_int("Misc.leg_movement", math.random(1, 2))
        
	end
end


--fakeping
fakeping = function()
    value = ui.get_int("[misc] pingspike")
    if ui.get_int("[misc] pingspike") then
        console.set_int("net_fakelag", value)   
end
end


--slowed down indicator
slowed = function()
    if ui.get_bool("[visual] slowed indicator") then 
        local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()
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


--hitmarker


function hitmarker()
 if ui.get_int("[visual] hitmarker") == 1 then
    ui.set_bool("Esp.damage_marker", false) 
    if not ui.get_int("[visual] hitmarker") == 1 then return end
    local ra, ga, ba = ui.get_color("[misc] lua color"):r(), ui.get_color("[misc] lua color"):g(), ui.get_color("[misc] lua color"):b()

    for i = 1, #shot_data do
    
        local shot = shot_data[i]
        
        if shot.draw then

            if shot.alpha <= 0 then
                shot.alpha = 0
                shot.draw = false
            else
                if shot.z >= shot.target then shot.alpha = shot.alpha - 1 end
                
                local s = render.world_to_screen(vector.new(shot.x,shot.y,shot.z))
                
                if shot.dmg then
    
                   		render.text(fonthit,s.x, s.y, color.new(ra,ga,ba,shot.alpha), "-".. shot.dmg,true,false)


                end
                shot.z = shot.z + 0.5
                
            end
        end
    end
end
end


--hitmarker function
local function player_hurt(e)
    if ui.get_int("[visual] hitmarker") == 1 then
    if not ui.get_int("[visual] hitmarker") == 1 then return end

    local attacker = e:get_int("attacker")
    local attacker_idx = engine.get_player_for_user_id(attacker)
    
    local victim = e:get_int("userid")
    local victim_idx = engine.get_player_for_user_id(victim)
    
    if attacker_idx ~= engine.get_local_player_index() then
        return
    end

    
    local pos = entitylist.get_player_by_index(victim_idx):get_absorigin()
    local duck = entitylist.get_player_by_index(victim_idx):get_prop_float("CBasePlayer", "m_flDuckAmount")
    
    pos.z = pos.z + (46 + (1 - duck) * 18)
    
    switchh = switchh*-1
    
    shot_data[#shot_data+1] = { x = pos.x, y = pos.y+switchh*35, z = pos.z, target = pos.z + 25, dmg = e:get_int("dmg_health"), alpha = 255, draw = true,}
    console.execute_client_cmd("playvol name.wav 1") --if you want to replace the sound change the sound put "name.wav" to the name


    
end
end


--hitmarker reset
function round_start()
    shot_data = {}
end
--notify function (@Klient)
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

--paint notify (@Klient)
local function shot_info(e)
    if ui.get_bool("[visual] hitlog") then
    if e.result == "Hit" then
		if e.server_hitbox == "Head" then clor = {255 , 112 ,106} else clor = {255 , 255 , 255} end
        notify.run(string.lower(e.target_name).."'s " .. string.lower(e.server_hitbox) .. " -"..e.server_damage, 5, clor )
    elseif e.result == "Spread" then
        notify.run(" missed at "..string.lower(e.target_name) .. " due to spread " , 5, {244,181,76,255})
    elseif e.result == "Resolver" then
        notify.run(" missed at "..string.lower(e.target_name) .. " due to resolver " , 5, {255, 0, 0})
    elseif e.result == "Occlusion" then
        notify.run(" missed at "..string.lower(e.target_name) .. " due to ? " , 5, {255, 255, 255})
    end
end
end
--print function (@Klient)
local print = function(...)
    console.execute_client_cmd("con_filter_enable 0")
    for i, data in pairs({...}) do
        console.execute_client_cmd(string.format("echo %s %s", "[essentials]", tostring(data)))
    end
end
cheat.popup("essentials loaded", "check the console")
print("useful information about lua and functions", "version : 1.3","discord: https://discord.gg/wBMSpVDXqu")
 
--register_event
events.register_event("player_hurt", player_hurt)
events.register_event("weapon_fire", weapon_fire)

events.register_event("round_prestart", round_start)
--callbacks
cheat.RegisterCallback("on_framestage", anim)
cheat.RegisterCallback("on_shot", shot_info)
cheat.RegisterCallback("on_paint", function()
	notify.on_paint()
	indicator()
    newindicators()
	menu()
    watermark()
    slowed()
    hitmarker()
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
        local fflag = entitylist.get_local_player():get_prop_int("CBasePlayer", "m_fFlags")
        if fflag == 256 or fflag == 262 then
            ui.set_int("0Antiaim.base_angle", 1 )
            else
            ui.set_int("0Antiaim.base_angle", 0 )
        end
    end

    createmove()
    fakeping()
	
end)
