--[[
--
--  Title: Sunset mode
--  Author: Klient#1690
--  Version: 1.0.0
--
]]--

--region locals
-- Creating tables in which all data will be stored
local sunset = {}

-- Creating all the necessary variables for the "sunset" table
sunset.rot_override = "cl_csm_rot_override"
sunset.rot_x = "cl_csm_rot_x"
sunset.rot_y = "cl_csm_rot_y"
sunset.rot_z = "cl_csm_rot_z"
--endregion

--region menu items
ui.add_checkbox("Enable sunset mode")

ui.add_sliderint("Sunset x", -100, 100)
ui.add_sliderint("Sunset y", -100, 100)
ui.add_sliderint("Sunset z", -100, 100)
--endregion

--region function
sunset.handle = function()
    -- We get the player
    local player = entitylist.get_local_player()

    -- We make a check, if the player is equal to nil, then nothing happens
    if player == nil then return end

    -- We check whether the player is alive
    if not player:is_alive() then return end

    console.set_int(sunset.rot_override, ui.get_bool("Enable sunset mode") and 1 or 0)
    console.set_int(sunset.rot_x, ui.get_int("Sunset x"))
    console.set_int(sunset.rot_y, ui.get_int("Sunset y"))
    console.set_int(sunset.rot_z, ui.get_int("Sunset z"))
end
--endregion

--region callback
cheat.RegisterCallback("on_paint", sunset.handle)
--endregion