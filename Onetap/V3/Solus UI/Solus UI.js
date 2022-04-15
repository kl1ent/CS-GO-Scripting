if (!String.format) {
    String.format = function(format) {
        var args = Array.prototype.slice.call(arguments, 1)
        return format.replace(/{(\d+)}/g, function(match, number) { 
            return typeof args[number] != "undefined" ? args[number] : match
        })
    }
}

var easing = {
    lerp: function(a, b, percentage) {
        return a + (b - a) * percentage
    }
}

var hsv_to_rgb = function(h, s, v) {
    var r, g, b, i, f, p, q, t;

    if (arguments.length === 1) {
        s = h.s, v = h.v, h = h.h;
    }

    i = Math.floor(h * 6);
    f = h * 6 - i;
    p = v * (1 - s);
    q = v * (1 - f * s);
    t = v * (1 - (1 - f) * s);

    switch (i % 6) {
        case 0: r = v, g = t, b = p; break;
        case 1: r = q, g = v, b = p; break;
        case 2: r = p, g = v, b = t; break;
        case 3: r = p, g = q, b = v; break;
        case 4: r = t, g = p, b = v; break;
        case 5: r = v, g = p, b = q; break;
    }

    return {
        r: Math.round(r * 255),
        g: Math.round(g * 255),
        b: Math.round(b * 255)
    }
}

var get_bar_color = function() {
    var color = menu.GetColor("Global color")

    var palette = menu.GetValue("Palette")

    if (palette != 0) {
        var rgb_split_ratio = menu.GetValue("Fade split ratio") / 100

        var h = palette == 2 ?
            Globals.Realtime() * (menu.GetValue("Fade frequency") / 100) :
            menu.GetValue("Fade offset") / 1000

        color = hsv_to_rgb(h, 1, 1)
        color = [
            color.r * rgb_split_ratio, 
            color.g * rgb_split_ratio, 
            color.b * rgb_split_ratio
        ]
    }

    return color
}

var anti_aimbot = {
    get_desync: function() {
        var RealYaw = Local.GetRealYaw();
        var FakeYaw = Local.GetFakeYaw();
        var delta = Math.min(Math.abs(RealYaw - FakeYaw) / 2, 58).toFixed(1);

        return delta
    }
}

var mouse_on_object = function(x, y, length, height) {
    var cursor = Input.GetCursorPosition()
    if (cursor[0] > x && cursor[0] < x + length && cursor[1] > y && cursor[1] < y + height)
        return true
    return false
}

Render.ShadowStringCustom = function(x, y, id, text, color, font) {
    Render.StringCustom(x + 1, y + 1, id, text, [0, 0, 0, (color[3] / 255) * 255], font)
    Render.StringCustom(x, y, id, text, color, font)
}

var menu = {
    Switch: function(name, state) {
        UI.AddCheckbox(name)
        UI.SetValue("Script items", name, state)
    },

    Hotkey: function(name) {
        return UI.AddHotkey(name)
    },

    SliderInt: function(name, default_value, min, max) {
        UI.AddSliderInt(name, min, max)
        UI.SetValue("Script items", name, default_value)
    },

    SliderFloat: function(name, default_value, min, max) {
        UI.AddSliderFloat(name, min, max)
        UI.SetValue("Script items", name, default_value)
    },

    ColorEdit: function(name, color) {
        UI.AddColorPicker(name)
        UI.SetColor("Script items", name, color)
    },

    Combo: function(name, elements) {
        return UI.AddDropdown(name, elements)
    },

    MultiCombo: function(name, elements) {
        return UI.AddMultiDropdown(name, elements)
    },

    Text: function(name) {
        return UI.AddLabel(name)
    },

    Block: function(name) {
        return UI.AddSliderFloat(name, 0, 0)
    },

    TextBox: function(name) {
        return UI.AddTextbox(name)
    },

    SetVisible: function(name, state) {
        return UI.SetEnabled("Script items", name, state)
    },

    GetValue: function(name) {
        return UI.GetValue("Script items", name)
    },

    GetColor: function(name) {
        return UI.GetColor("Script items", name)
    },

    SetValue: function(name, value) {
        return UI.SetValue("Script items", name, value)
    },

    DropdownValue: function(value, index) {
        var mask = 1 << index;
        return value & mask ? true : false;
    }
}

var menu_palette = ["Solid", "Fade", "Dynamic fade"]
var menu_elements = ["Watermark", "Frequency update info", "Anti-aimbot indication", "Hotkey list", "Spectators"]

menu.Block("")

menu.MultiCombo("Elements", menu_elements)
menu.Combo("Palette", menu_palette)
menu.ColorEdit("Global color", [142, 165, 229, 85])

menu.Block("  ")
menu.SliderInt("Fade offset", 825, 1, 1000)
menu.SliderInt("Fade frequency", 10, 1, 100)
menu.SliderInt("Fade split ratio", 100, 0, 100)

menu.Block(" ")
menu.Switch("Enable text shadow", false)
menu.TextBox("Watermark name")
menu.TextBox("Watermark prefix")
menu.TextBox("Watermark suffix")
menu.SliderInt("HZ", 60, 1, 360)
menu.Switch("Enable 'Avatars'", false)
menu.SliderInt("hotkey_x", 0, 0, Global.GetScreenSize()[0])
menu.SliderInt("hotkey_y", 0, 0, Global.GetScreenSize()[1])
menu.SetVisible("hotkey_x", false)
menu.SetVisible("hotkey_y", false)
menu.SliderInt("specs_x", 0, 0, Global.GetScreenSize()[0])
menu.SliderInt("specs_y", 0, 0, Global.GetScreenSize()[1])
menu.SetVisible("specs_x", false)
menu.SetVisible("specs_y", false)

menu.Block("")

var fonts = function(size, h) {
    return {
        verdana: Render.AddFont("Verdana", size == undefined ? 7 : size, h == undefined ? 400 : h)  
    }
}

var ms_classes = {
    position: {
        offset: 0,

        g_paint_handler: function() {
            ms_classes.position.offset = 0
        }
    },

    watermark: {
        width: 0,
        x: Global.GetScreenSize()[0],

        alpha: 0,

        offset: 0,

        g_paint_handler: function() {
            ms_classes.watermark.offset = easing.lerp(ms_classes.watermark.offset, ms_classes.position.offset, Globals.Frametime() * 8)
            var off = ms_classes.watermark.offset
            if (menu.DropdownValue(menu.GetValue("Elements"), 0)) {
                ms_classes.watermark.alpha = easing.lerp(ms_classes.watermark.alpha, 1, Globals.Frametime() * 12)
                ms_classes.position.offset++
            } else {
                ms_classes.watermark.alpha = easing.lerp(ms_classes.watermark.alpha, 0, Globals.Frametime() * 12)
            }     

            if (ms_classes.watermark.alpha == 0)
                return   

            var font = fonts().verdana
            var today = new Date()
            today = today.toTimeString().substring(0, 8)  
            var color = get_bar_color()

            var actual_time = String.format("{0}", today)
            var prefix = "onetap"
            var suffix = ""
            var nickname = Cheat.GetUsername()

            if (UI.GetString("Script items", "Watermark name") != 0) {
                nickname = UI.GetString("Script items", "Watermark name")
            }

            if (UI.GetString("Script items", "Watermark prefix") != 0) {
                prefix = UI.GetString("Script items", "Watermark prefix")
            }

            if (UI.GetString("Script items", "Watermark suffix") != 0) {
               prefix +=  " [" + UI.GetString("Script items", "Watermark suffix") + "]"
            }

            if (typeof prefix == "Symbol") {
                prefix = prefix.toString();
                prefix = prefix.replace("Symbol(")
                prefix = prefix.replace(")")
            }

            if (typeof nickname == "Symbol") {
                nickname = nickname.toString();
                nickname = nickname.replace("Symbol(")
                nickname = nickname.replace(")")
            }

            var text = ""

            if (!World.GetServerString()) {
                text = String.format("{0} | {1} | {2}", prefix, nickname, actual_time)
            } else {
                text = String.format("{0} | {1} | delay: {2}ms | {3}tick | {4}", prefix, nickname, Math.floor(Entity.GetProp(Entity.GetLocalPlayer(), "CPlayerResource", "m_iPing")), Globals.Tickrate(), today)
            }

            ms_classes.watermark.width = easing.lerp(ms_classes.watermark.width, Render.TextSizeCustom(text, font)[0], Globals.Frametime() * 12)
            ms_classes.watermark.x = easing.lerp(ms_classes.watermark.x, Global.GetScreenSize()[0] - ms_classes.watermark.width - 14, Globals.Frametime() * 8)

            if (menu.GetValue("Palette") == 0) {
                Render.FilledRect(ms_classes.watermark.x - 4, 8 + 22 * off, ms_classes.watermark.width + 8, 2, [color[0], color[1], color[2], 255 * ms_classes.watermark.alpha])
            } else {
                Render.GradientRect(ms_classes.watermark.x - 4, 8 + 22 * off, Math.floor((ms_classes.watermark.width + 8) / 2), 2, 1, [color[1], color[2], color[0], 255 * ms_classes.watermark.alpha], [color[0], color[1], color[2], 255 * ms_classes.watermark.alpha])
                Render.GradientRect(ms_classes.watermark.x - 4 + Math.floor((ms_classes.watermark.width + 8) / 2), 8 + 22 * off, Math.floor((ms_classes.watermark.width + 8) / 2) + 1, 2, 1, [color[0], color[1], color[2], 255 * ms_classes.watermark.alpha], [color[2], color[0], color[1], 255 * ms_classes.watermark.alpha])
            }

            Render.FilledRect(ms_classes.watermark.x - 4, 10 + 22 * off, Math.floor(ms_classes.watermark.width + 8), 17, [17, 17, 17, (255 * ms_classes.watermark.alpha) * (menu.GetColor("Global color")[3] / 255)])

            Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](ms_classes.watermark.x, 11 + 22 * off, 0, text, [255, 255, 255, 255 * ms_classes.watermark.alpha], font)
        }
    },

    keybinds: {
        binds_list: [
            ["Resolver override", ["Rage", "General", "Resolver override"], "Toggle", 0],
            ["Slow motion", ["Anti-Aim", "Extra", "Slow walk"], "Toggle", 0],
            ["Force body aim", ["Rage", "General", "Force body aim"], "Toggle", 0],
            ["Force safe point", ["Rage", "General", "Force safe point"], "Toggle", 0],
            ["Anti-aim inverter", ["Anti-Aim", "Fake angles", "Inverter"], "Toggle", 0],
            ["Auto peek", ["Misc", "Movement", "Auto peek"], "Toggle", 0],
            ["Jump at edge", ["Misc", "Movement", "Edge jump"], "Toggle", 0],
            ["Duck peek assist", ["Anti-Aim", "Extra", "Fake duck"], "Toggle", 0],
            ["On-shot anti-aim", ["Rage", "Exploits", "Hide shots"], "Toggle", 0],
            ["Double tap", ["Rage", "Exploits", "Doubletap"], "Toggle", 0],
        ],

        kbalpha: 0,
        latest_item_width: 0,
        item_width: 0,
        kb: new Array,
        kbh: new Array,
        width: 0,
        x_off: 0,
        y_off: 0,
        stored: false,
        drag: new Array(0, 0, 0),

        state: function(i) {
            switch (i) {
                case "Hold":
                    return "[holding]";
                    break;
                case "Toggle":
                    return "[toggled]";
                    break;
                case "Always":
                    return "[enabled]";
                    break;
                case "[~]":
                    return "[~]";
                    break;
            }
        },

        namekb: function(i) {
            switch (i) {
                case "Hide shots":
                    return "On shot anti-aim";
                    break;
                case "Auto peek":
                    return "Quick peek assist";
                    break;
                case "Fake duck":
                    return "Duck peek assist";
                    break;
                case "Slow walk":
                    return "Slow motion";
                    break;
                case "Edge jump":
                    return "Jump at edge";
                    break;
                case "Force safe point":
                    return "Safe point";
                    break;
                case "Minimum damage override":
                    return "Damage override";
                default:
                    return i;
                    break;
            }           
        },

        g_paint_handler: function() {
            if (!menu.DropdownValue(menu.GetValue("Elements"), 3)) 
                return

            var font = fonts().verdana

            var x = menu.GetValue("hotkey_x")
            var y = menu.GetValue("hotkey_y")

            for (i = 0; i < ms_classes.keybinds.binds_list.length; i++) {
                if (UI.IsHotkeyActive.apply(null, ms_classes.keybinds.binds_list[i][1])) {
                    if (ms_classes.keybinds.kb.indexOf(ms_classes.keybinds.namekb(ms_classes.keybinds.binds_list[i][0])) == -1) {
                        ms_classes.keybinds.kb.push(ms_classes.keybinds.namekb(ms_classes.keybinds.binds_list[i][0]))
                        ms_classes.keybinds.kbh.push([ms_classes.keybinds.binds_list[i][2], ms_classes.keybinds.binds_list[i][3], ms_classes.keybinds.binds_list[i][1]])
                    }
                }
            }

            var fr = 8 * 255 * Globals.Frametime();
            var color = get_bar_color()
            if (UI.IsMenuOpen() || ms_classes.keybinds.kb.length > 0) {
                if (ms_classes.keybinds.kbalpha <= 1) {
                    ms_classes.keybinds.kbalpha = easing.lerp(ms_classes.keybinds.kbalpha, 1, Globals.Frametime() * 8);
                } else {
                    ms_classes.keybinds.kbalpha = 1;
                }
            } else {
                if (ms_classes.keybinds.kbalpha >= 0) {
                    ms_classes.keybinds.kbalpha = easing.lerp(ms_classes.keybinds.kbalpha, 0, Globals.Frametime() * 8);
                } else {
                    ms_classes.keybinds.kbalpha = 0;
                }
            }

            if (ms_classes.keybinds.kb.length < 1) {
                ms_classes.keybinds.item_width = 0
            }

            for (i = 0; i < ms_classes.keybinds.kb.length; i++) {
                if (Render.TextSizeCustom(ms_classes.keybinds.kb[i], font)[0] > ms_classes.keybinds.latest_item_width) {
                    ms_classes.keybinds.latest_item_width = Render.TextSizeCustom(ms_classes.keybinds.kb[i], font)[0]
                    ms_classes.keybinds.item_width = ms_classes.keybinds.latest_item_width
                }
            }
            ms_classes.keybinds.width = easing.lerp(ms_classes.keybinds.width, ms_classes.keybinds.item_width + 80, Globals.Frametime() * 8);

            if (menu.GetValue("Palette") == 0) {
                Render.FilledRect(x, y, ms_classes.keybinds.width, 2, [color[0], color[1], color[2], 255 * ms_classes.keybinds.kbalpha])
            } else {
                Render.GradientRect(x, y, Math.floor((ms_classes.keybinds.width) / 2), 2, 1, [color[1], color[2], color[0], 255 * ms_classes.keybinds.kbalpha], [color[0], color[1], color[2], 255 * ms_classes.keybinds.kbalpha])
                Render.GradientRect(x + Math.floor((ms_classes.keybinds.width) / 2), y, Math.floor((ms_classes.keybinds.width) / 2), 2, 1, [color[0], color[1], color[2], 255 * ms_classes.keybinds.kbalpha], [color[2], color[0], color[1], 255 * ms_classes.keybinds.kbalpha])
            }

            Render.FilledRect(x, y + 2, ms_classes.keybinds.width, 18, [17, 17, 17, (255 * ms_classes.keybinds.kbalpha) * (menu.GetColor("Global color")[3] / 255)]);
            Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](x + ms_classes.keybinds.width / 2, y + 5, 1, "keybinds", [255, 255, 255, 255 * ms_classes.keybinds.kbalpha], font);

            var sy = y + 23

            for (i = 0; i < ms_classes.keybinds.binds_list.length; i++) {
                if (UI.IsHotkeyActive.apply(null, ms_classes.keybinds.binds_list[i][1])) {
                    ms_classes.keybinds.binds_list[i][3] = easing.lerp(ms_classes.keybinds.binds_list[i][3], 1, Globals.Frametime() * 12)
                } else {
                    ms_classes.keybinds.binds_list[i][3] = easing.lerp(ms_classes.keybinds.binds_list[i][3], 0, Globals.Frametime() * 12)

                    ms_classes.keybinds.kb.splice(i)
                    ms_classes.keybinds.kbh.splice(i)
                    ms_classes.keybinds.latest_item_width = 0
                }

                Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](x + 2 + 5, sy, 0, ms_classes.keybinds.namekb(ms_classes.keybinds.binds_list[i][0]), [255, 255, 255, (255 * ms_classes.keybinds.kbalpha) * ms_classes.keybinds.binds_list[i][3]], font);
                Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](x + ms_classes.keybinds.width - 3 - Render.TextSizeCustom(ms_classes.keybinds.state(ms_classes.keybinds.binds_list[i][2]), font)[0] - 5, sy, 0, ms_classes.keybinds.state(ms_classes.keybinds.binds_list[i][2]), [255, 255, 255, (255 * ms_classes.keybinds.kbalpha) * ms_classes.keybinds.binds_list[i][3]], font);
                sy += 15 * ms_classes.keybinds.binds_list[i][3]
            }

            var cursor = Input.GetCursorPosition();
            if(mouse_on_object(x, y, ms_classes.keybinds.width, 20)){
                if ((Input.IsKeyPressed(0x01)) && (ms_classes.keybinds.drag[0] == 0)) {
                    ms_classes.keybinds.drag[0] = 1;
                    ms_classes.keybinds.drag[1] = x - cursor[0];
                    ms_classes.keybinds.drag[2] = y - cursor[1];
                }
            }
            if (!Input.IsKeyPressed(0x01)) ms_classes.keybinds.drag[0] = 0;
            if (ms_classes.keybinds.drag[0] == 1 && UI.IsMenuOpen()) {
                menu.SetValue("hotkey_x", cursor[0] + ms_classes.keybinds.drag[1]);
                menu.SetValue("hotkey_y", cursor[1] + ms_classes.keybinds.drag[2]);
            }
        }
    },

    spectators: {
        unsorted: new Array,
        m_active: new Array,
        m_alpha: new Array,
        sp: new Array,

        av_x: 0,
        latest_item_width: 0,
        item_width: 0,

        spalpha: 0,
        width: 0,

        stored: false,
        drag: new Array(0, 0, 0),

        get_spectating_players: function() {
            var me = Entity.GetLocalPlayer()
            var players = Entity.GetPlayers()

            var players1 = new Array
            var players_name = new Array
            var observing = me

            for (var i = 0; i < players.length; i++) {
                var cur = players[i]

                var m_iObserverMode = Entity.GetProp(cur, "CBasePlayer", "m_iObserverMode")
                var m_hObserverTarget = Entity.GetProp(cur, "CBasePlayer", "m_hObserverTarget")

                if (m_hObserverTarget != null && m_hObserverTarget <= 64 && !Entity.IsAlive(cur)) {
                    if (players1[m_hObserverTarget] == null) {
                        players1[m_hObserverTarget] = new Array
                    }

                    if (cur == me) {
                        observing = m_hObserverTarget
                    }

                    players1[m_hObserverTarget].push(i)
                }
            }

            return [players1, observing]
        },

        on_load: function() {
            for (var i = 0; i < 64; i++) {
                ms_classes.spectators.m_alpha[i] = 0
            }
        },

        g_paint_handler: function() {
            if (!menu.DropdownValue(menu.GetValue("Elements"), 4)) 
                return

            var self = ms_classes.spectators

            var me = Entity.GetLocalPlayer()

            var specs = self.get_spectating_players()[0] 
            var player = self.get_spectating_players()[1]

            var font = fonts().verdana
            var font1 = fonts(6).verdana
            var unsorted = self.unsorted

            var color = get_bar_color()

            var x = menu.GetValue("specs_x")
            var y = menu.GetValue("specs_y")

            var cursor = Input.GetCursorPosition();
            if(mouse_on_object(x, y, self.width, 20)){
                if ((Input.IsKeyPressed(0x01)) && (self.drag[0] == 0)) {
                    self.drag[0] = 1;
                    self.drag[1] = x - cursor[0];
                    self.drag[2] = y - cursor[1];
                }
            }
            if (!Input.IsKeyPressed(0x01)) self.drag[0] = 0;
            if (self.drag[0] == 1 && UI.IsMenuOpen()) {
                menu.SetValue("specs_x", cursor[0] + self.drag[1]);
                menu.SetValue("specs_y", cursor[1] + self.drag[2]);
            }

            for (var i = 0; i < 64; i++) {
                unsorted[i] = [i, false]
            }

            if (specs[player] != null) {
                for (var i in specs[player]) {
                    var ind = specs[player][i]

                    var pss = true
                    if (ind == me) {
                        pss == false
                    }

                    unsorted[ind] = [i, pss]
                }
            }

            if (UI.IsMenuOpen() || specs[player] != null) {
                if (self.spalpha <= 1) {
                    self.spalpha = easing.lerp(self.spalpha, 1, Globals.Frametime() * 8)
                } else {
                    self.spalpha = 1
                }
            } else {
                if (self.spalpha >= 0) {
                    self.spalpha = easing.lerp(self.spalpha, 0, Globals.Frametime() * 8)
                } else {
                    self.spalpha = 0
                }
            }

            if (specs[player] == null) {
                self.item_width = 0
            }

            for (var i = 0; i < unsorted.length; i++) {
                if (unsorted[i][1]) {
                    var name = Entity.GetName(i + 1)

                    if (Render.TextSizeCustom(name, font)[0] > self.latest_item_width) {
                        self.latest_item_width = Render.TextSizeCustom(name, font)[0] 
                        self.item_width = self.latest_item_width
                    }
                }
            }
            self.width = easing.lerp(self.width, self.item_width + 80, Globals.Frametime() * 8)

            if (menu.GetValue("Palette") == 0) {
                Render.FilledRect(x, y, self.width, 2, [color[0], color[1], color[2], 255 * self.spalpha])
            } else {
                Render.GradientRect(x, y, Math.floor((self.width) / 2), 2, 1, [color[1], color[2], color[0], 255 * self.spalpha], [color[0], color[1], color[2], 255 * self.spalpha])
                Render.GradientRect(x + Math.floor((self.width) / 2), y, Math.floor((self.width) / 2), 2, 1, [color[0], color[1], color[2], 255 * self.spalpha], [color[2], color[0], color[1], 255 * self.spalpha])
            }

            Render.FilledRect(x, y + 2, self.width, 18, [17, 17, 17, (255 * self.spalpha) * (menu.GetColor("Global color")[3] / 255)]);
            Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](x + self.width / 2, y + 5, 1, "spectators", [255, 255, 255, 255 * self.spalpha], font)

            var sy = y + 23
            for (var i = 0; i < unsorted.length; i++) {
                var active = unsorted[i][1]
                var name = Entity.GetName(i + 1)
                var text_h = Render.TextSizeCustom(name, font)[1]

                var add_x = menu.GetValue("Enable 'Avatars'") ? text_h + 5 : 0
                self.av_x = easing.lerp(self.av_x, add_x, Globals.Frametime() * 4)

                if (active) {
                    self.m_alpha[i] = easing.lerp(self.m_alpha[i], 1, Globals.Frametime() * 8)
                } else {
                    self.m_alpha[i] = easing.lerp(self.m_alpha[i], 0, Globals.Frametime() * 8)
                    self.sp.splice(i)
                    self.latest_item_width = 0   
                }

                if (menu.GetValue("Enable 'Avatars'")) {
                    Render.FilledRect(x + 7, sy, text_h, text_h, [40, 45, 50, 255 * self.m_alpha[i] * self.spalpha])
                    Render.StringCustom(x + 11, sy + 1, 0, "?", [255, 255, 255, 255 * self.m_alpha[i] * self.spalpha], font1)
                }
                Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](x + 7 + self.av_x, sy, 0, name, [255, 255, 255, 255 * self.m_alpha[i] * self.spalpha], font)
                sy += 15 * self.m_alpha[i]
            }
        }
    },

    antiaim: {
        delta: 0,

        last_set: 0,
        old_time: 0,
        choked_time: 0,
        sim_time: 0,
        ticks: 0,
        choked_ticks_arr: [],

        width_1: 0,
        width_2: 0,

        alpha: 0,

        x_1: Global.GetScreenSize()[0],
        x_2: Global.GetScreenSize()[0],

        offset: 0,

        Arc: function(x, y, radius, start_angle, percent, thickness, color) {
            var precision = (2 * Math.PI) / 30;
            var step = Math.PI / 180;
            var inner = radius - thickness;
            var end_angle = (start_angle + percent) * step;
            var start_angle = (start_angle * Math.PI) / 180;

            for (; radius > inner; --radius) {
                for (var angle = start_angle; angle < end_angle; angle += precision) {
                    var cx = Math.round(x + radius * Math.cos(angle));
                    var cy = Math.round(y + radius * Math.sin(angle));

                    var cx2 = Math.round(x + radius * Math.cos(angle + precision));
                    var cy2 = Math.round(y + radius * Math.sin(angle + precision));

                    Render.Line(cx, cy, cx2, cy2, color);
                }
            }
        },

        g_paint_handler: function() {
            if (!World.GetServerString()) return;
            if (!Entity.IsAlive(Entity.GetLocalPlayer())) return;
            ms_classes.antiaim.offset = easing.lerp(ms_classes.antiaim.offset, ms_classes.position.offset, Globals.Frametime() * 8)
            var off = ms_classes.antiaim.offset
            if (menu.DropdownValue(menu.GetValue("Elements"), 2)) {
                ms_classes.antiaim.alpha = easing.lerp(ms_classes.antiaim.alpha, 1, Globals.Frametime() * 12)
                ms_classes.position.offset++
            } else {
                ms_classes.antiaim.alpha = easing.lerp(ms_classes.antiaim.alpha, 0, Globals.Frametime() * 12)
            } 

            if (ms_classes.antiaim.alpha == 0)
                return

            var body_yaw = anti_aimbot.get_desync()
            ms_classes.antiaim.delta = easing.lerp(ms_classes.antiaim.delta, body_yaw, Globals.Frametime() * 8)

            var sim_time = Entity.GetProp(Entity.GetLocalPlayer(), "CBaseEntity", "m_flSimulationTime");
            var length = 1

            ms_classes.antiaim.choked_time = sim_time - ms_classes.antiaim.old_time;

            if (sim_time != ms_classes.antiaim.old_time) {
                ms_classes.antiaim.ticks = 0;
                ms_classes.antiaim.old_time = sim_time;
                ms_classes.antiaim.ticks = ms_classes.antiaim.choked_time;
                ms_classes.antiaim.choked_ticks_arr.push(Math.round(ms_classes.antiaim.ticks/(1/Globals.Tickrate())));
                ms_classes.antiaim.choked_time = 0;
            }

            if(ms_classes.antiaim.choked_ticks_arr.length > length) {
                ms_classes.antiaim.choked_ticks_arr.shift();
            }

            str = "";

            for (t = 0; t < ms_classes.antiaim.choked_ticks_arr.length; t++) {
                if(ms_classes.antiaim.choked_ticks_arr[t] > 16)
                    continue;
                str += ms_classes.antiaim.choked_ticks_arr[t];

                if(t != ms_classes.antiaim.choked_ticks_arr.length - 1) {
                    str += " - ";
                }
            }

            if (str < 0) 
                str = 0
            
            var font = fonts().verdana

            var addr = Exploit.GetCharge() == 1 ? " | SHIFTING " : ""
            var text = String.format("FL: {0}{1} ", str - 1, addr)

            var y = 13
            ms_classes.antiaim.width_1 = easing.lerp(ms_classes.antiaim.width_1, Render.TextSizeCustom(text, font)[0], Globals.Frametime() * 12)
            ms_classes.antiaim.x_1 = easing.lerp(ms_classes.antiaim.x_1, Global.GetScreenSize()[0] - 10 - ms_classes.antiaim.width_1, Globals.Frametime() * 8)

            var c = [180, 190, 190]
            if (Exploit.GetCharge() == 1)
                c = [255, 150, 0]

            Render.GradientRect(ms_classes.antiaim.x_1 - 5, y + 16 + 22 * off, Math.floor((ms_classes.antiaim.width_1) / 2), 1, 1, [c[0], c[1], c[2], 0 * ms_classes.antiaim.alpha], [c[0], c[1], c[2], 255 * ms_classes.antiaim.alpha])
            Render.GradientRect(ms_classes.antiaim.x_1 - 5 + Math.floor((ms_classes.antiaim.width_1) / 2), y + 16 + 22 * off, Math.floor((ms_classes.antiaim.width_1 + 8) / 2), 1, 1, [c[0], c[1], c[2], 255 * ms_classes.antiaim.alpha], [c[0], c[1], c[2], 0 * ms_classes.antiaim.alpha])

            Render.FilledRect(ms_classes.antiaim.x_1 - 4, y + 22 * off, Math.floor(ms_classes.antiaim.width_1 + 4), 17, [17, 17, 17, 100 * ms_classes.antiaim.alpha])
            Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](ms_classes.antiaim.x_1, y + 1 + 22 * off, 0, text, [255, 255, 255, 255 * ms_classes.antiaim.alpha], font)

            var add_text = (body_yaw <= 0) ? "" : "\x20\x20\x20\x20\x20"
            var f_text = String.format("{0}FAKE ({1} )", add_text, body_yaw)
            var color_fake = [170 + (154 - 186) * body_yaw / 58, 0 + (255 - 0) * body_yaw / 58, 16 + (0 - 16) * body_yaw / 58, 255 * ms_classes.antiaim.alpha]

            ms_classes.antiaim.width_2 = easing.lerp(ms_classes.antiaim.width_2, Render.TextSizeCustom(f_text, font)[0], Globals.Frametime() * 12)
            ms_classes.antiaim.x_2 = easing.lerp(ms_classes.antiaim.x_2, Global.GetScreenSize()[0] - 10 - ms_classes.antiaim.width_2, Globals.Frametime() * 8)

            Render.GradientRect((ms_classes.antiaim.x_2 - ms_classes.antiaim.width_1) - 25 - 2 + 11 + 1, y - 1 + 22 * off, ms_classes.antiaim.width_2 / 2 + 4, 17, 1, [17, 17, 17, 25 * ms_classes.antiaim.alpha], [17, 17, 17, 100 * ms_classes.antiaim.alpha])
            Render.GradientRect((ms_classes.antiaim.x_2 - ms_classes.antiaim.width_1) - 25 - 2 + ms_classes.antiaim.width_2 / 2 + 4 + 11 + 1, y - 1 + 22 * off, ms_classes.antiaim.width_2 / 2, 17, 1, [17, 17, 17, 100 * ms_classes.antiaim.alpha], [17, 17, 17, 25 * ms_classes.antiaim.alpha])

            Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"]((ms_classes.antiaim.x_2 - ms_classes.antiaim.width_1) - 25 + 12 + 1, y + 1 + 22 * off, 0, f_text, [255, 255, 255, 255 * ms_classes.antiaim.alpha], font)
            Render.Circle(((ms_classes.antiaim.x_2 - ms_classes.antiaim.width_1) - 31) + Render.TextSizeCustom(f_text, font)[0] + 12 + 1, 18 + 22 * off, 1, [255, 255, 255, 255 * ms_classes.antiaim.alpha])

            Render.GradientRect((ms_classes.antiaim.x_2 - ms_classes.antiaim.width_1) - 30 + 12 + 1, y - 1 + 22 * off, 2, 17 / 2, 0, [color_fake[0], color_fake[1], color_fake[2], 0 * ms_classes.antiaim.alpha], [color_fake[0], color_fake[1], color_fake[2], 255 * ms_classes.antiaim.alpha]);
            Render.GradientRect((ms_classes.antiaim.x_2 - ms_classes.antiaim.width_1) - 30 + 12 + 1, y + 1 + 22 * off + 17 / 2 - 4, 2, 17 / 2, 0, [color_fake[0], color_fake[1], color_fake[2], 255 * ms_classes.antiaim.alpha], [color_fake[0], color_fake[1], color_fake[2], 0 * ms_classes.antiaim.alpha]);

            ms_classes.antiaim.Arc((ms_classes.antiaim.x_2 - ms_classes.antiaim.width_1) - 25 + 5 + 12 + 1, y + 7 + 22 * off, 5, 0, ms_classes.antiaim.delta * 6, 2, [89, 119, 239, 255 * ms_classes.antiaim.alpha]);
        }
    },

    ilstate: {
        frequency: 0,
        request_time: Globals.Curtime(),
        frametime: Globals.Frametime(),
        frametimes: [],

        width_1: 0,
        width_2: 0,

        height: [],
        alpha: 0,
        ms_text: 0,

        x_1: Global.GetScreenSize()[0],
        x_2: Global.GetScreenSize()[0],

        offset: 0,

        g_paint_handler: function() {
            if (menu.DropdownValue(menu.GetValue("Elements"), 1)) {
                ms_classes.ilstate.alpha = easing.lerp(ms_classes.ilstate.alpha, 1, Globals.Frametime() * 12)
            } else {
                ms_classes.ilstate.alpha = easing.lerp(ms_classes.ilstate.alpha, 0, Globals.Frametime() * 12)
            }

            if (ms_classes.ilstate.alpha == 0)
                return

            var font = fonts().verdana

            if (ms_classes.ilstate.request_time + 1 < Globals.Curtime()) {
                ms_classes.ilstate.frametime = Globals.Frametime()
                ms_classes.ilstate.request_time = Globals.Curtime()
                ms_classes.ilstate.frametimes.unshift(ms_classes.ilstate.frametime)

                if (ms_classes.ilstate.frametimes.length > 4)
                    ms_classes.ilstate.frametimes.pop()
            }

            ms_classes.ilstate.offset = easing.lerp(ms_classes.ilstate.offset, ms_classes.position.offset, Globals.Frametime() * 8)
            var off = ms_classes.ilstate.offset

            var io_text = "IO | "
            ms_classes.ilstate.ms_text = easing.lerp(ms_classes.ilstate.ms_text, Math.abs((ms_classes.ilstate.frametime * 1000)), Globals.Frametime() * 8)
            ms_classes.ilstate.frequency = menu.GetValue("HZ")
            var freq_text = String.format("{0}ms / {1}hz", ms_classes.ilstate.ms_text.toFixed(1), ms_classes.ilstate.frequency)

            var y = menu.DropdownValue(menu.GetValue("Elements"), 0) ? 4 : 8
            ms_classes.ilstate.width_1 = easing.lerp(ms_classes.ilstate.width_1, Render.TextSizeCustom(io_text, font)[0] + 24, Globals.Frametime() * 12)
            ms_classes.ilstate.x_1 = easing.lerp(ms_classes.ilstate.x_1, Global.GetScreenSize()[0] - 24 - ms_classes.ilstate.width_1 - Render.TextSizeCustom(freq_text, font)[0], Globals.Frametime() * 8)
        
            Render.FilledRect(ms_classes.ilstate.x_1 - 4, y + 28 * off, Math.floor(ms_classes.ilstate.width_1 + 4), 17, [17, 17, 17, 100 * ms_classes.ilstate.alpha])
            Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](ms_classes.ilstate.x_1, y + 1 + 28 * off, 0, io_text, [255, 255, 255, 255 * ms_classes.ilstate.alpha], font)

            for (var i in ms_classes.ilstate.frametimes) {
                var ft = ms_classes.ilstate.frametimes[i]
                var color = menu.GetColor("Global color")

                if (ms_classes.ilstate.height[i] == null) { ms_classes.ilstate.height[i] = 0 }
                ms_classes.ilstate.height[i] = easing.lerp(ms_classes.ilstate.height[i], Math.floor(Math.min(12, ft / 1 * 1000)), Globals.Frametime() * 8)

                Render.GradientRect(ms_classes.ilstate.x_1 + ms_classes.ilstate.width_1 - 9 - (5 * i), y + 28 * off + 14 - ms_classes.ilstate.height[i], 5, ms_classes.ilstate.height[i], 0, [color[0], color[1], color[2], 0 * ms_classes.ilstate.alpha], [color[0], color[1], color[2], 255 * ms_classes.ilstate.alpha])
            }

            ms_classes.ilstate.width_2 = easing.lerp(ms_classes.ilstate.width_2, Render.TextSizeCustom(freq_text, font)[0], Globals.Frametime() * 12)
            ms_classes.ilstate.x_2 = easing.lerp(ms_classes.ilstate.x_2, Global.GetScreenSize()[0] - 10 - ms_classes.ilstate.width_2 - 4, Globals.Frametime() * 8)

            var color = [0, 255, 0]
            var ft = ms_classes.ilstate.frametime * 1000
            if (ft > 15)
                color = [255, 0, 0]
            else if (ft > 12)
                color = [255, 170, 0]
            else if (ft > 10)
                color = [255, 255, 0]
            else if (ft > 7.5)
                color = [150, 255, 0]
            else if (ft > 5)
                color = [70, 255, 0]

            Render.FilledRect(ms_classes.ilstate.x_2 - 4, y + 28 * off, Math.floor(ms_classes.ilstate.width_2 + 8), 17, [17, 17, 17, 100 * ms_classes.ilstate.alpha])
            Render[menu.GetValue("Enable text shadow") ? "ShadowStringCustom" : "StringCustom"](ms_classes.ilstate.x_2, y + 1 + 28 * off, 0, freq_text, [255, 255, 255, 255 * ms_classes.ilstate.alpha], font)

            Render.GradientRect(ms_classes.ilstate.x_2 - 3, y + 17 + 28 * off, ms_classes.ilstate.width_2 / 2 + 4, 1, 1, color.concat(0), color.concat(255 * ms_classes.ilstate.alpha))
            Render.GradientRect(ms_classes.ilstate.x_2 + ms_classes.ilstate.width_2 / 2, y + 17 + 28 * off, ms_classes.ilstate.width_2 / 2 + 4, 1, 1, color.concat(255 * ms_classes.ilstate.alpha), color.concat(0))
        }
    },

    menu_set: {
        g_paint_handler: function() {
            var palette = menu.GetValue("Palette")
            var elements = menu.GetValue("Elements")

            menu.SetVisible("Global color", palette != 0 ? false : true)
            menu.SetVisible("Fade offset", palette != 0 ? true : false)
            menu.SetVisible("Fade frequency", palette != 0 ? true : false)
            menu.SetVisible("Fade split ratio", palette != 0 ? true : false)
            menu.SetVisible("  ", palette != 0 ? true : false)

            menu.SetVisible(" ", menu.DropdownValue(elements, 0))
            menu.SetVisible("Watermark name", menu.DropdownValue(elements, 0))
            menu.SetVisible("Watermark suffix", menu.DropdownValue(elements, 0))
            menu.SetVisible("Watermark prefix", menu.DropdownValue(elements, 0))

            menu.SetVisible("HZ", menu.DropdownValue(elements, 1))

            menu.SetVisible("Enable 'Avatars'", menu.DropdownValue(elements, 4))
        }
    }
}
Cheat.RegisterCallback("Draw", "ms_classes.position.g_paint_handler")
Cheat.RegisterCallback("Draw", "ms_classes.watermark.g_paint_handler")
Cheat.RegisterCallback("Draw", "ms_classes.spectators.g_paint_handler")
Cheat.RegisterCallback("Draw", "ms_classes.keybinds.g_paint_handler")
Cheat.RegisterCallback("Draw", "ms_classes.antiaim.g_paint_handler")
Cheat.RegisterCallback("Draw", "ms_classes.ilstate.g_paint_handler")
Cheat.RegisterCallback("Draw", "ms_classes.menu_set.g_paint_handler")
ms_classes.spectators.on_load()