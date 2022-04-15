/*

    name: Solus UI
    author: Klient#1690
    version: 2.0.0

*/

var input_mouse_on_object = function(x, y, length, height) {var cursor = Input.GetCursorPosition();if (cursor[0] > x && cursor[0] < x + length && cursor[1] > y && cursor[1] < y + height) {return true;}return false;}
var create_integer = function(b,c,d,e){return{min:b,max:c,init_val:d,scale:e,value:d};}
var hsv_to_rgb = function(h, s, v) {var r, g, b, i, f, p, q, t;if (arguments.length === 1) {s = h.s, v = h.v, h = h.h;};i = Math.floor(h * 6);f = h * 6 - i;p = v * (1 - s);q = v * (1 - f * s);t = v * (1 - (1 - f) * s);switch (i % 6) {case 0: r = v, g = t, b = p; break;case 1: r = q, g = v, b = p; break;case 2: r = p, g = v, b = t; break;case 3: r = p, g = q, b = v; break;case 4: r = t, g = p, b = v; break;case 5: r = v, g = p, b = q; break;};return {r: Math.round(r * 255),g: Math.round(g * 255),b: Math.round(b * 255)};}
var rgb_to_hsv = function(r, g, b) {if (arguments.length === 1) {g = r.g, b = r.b, r = r.r;};var max = Math.max(r, g, b), min = Math.min(r, g, b),d = max - min,h,s = (max === 0 ? 0 : d / max),v = max / 255;switch (max) {case min: h = 0; break;case r: h = (g - b) + d * (g < b ? 6: 0); h /= 6 * d; break;case g: h = (b - r) + d * 2; h /= 6 * d; break;case b: h = (r - g) + d * 4; h /= 6 * d; break;};return {h: h,s: s,v: v};}
var lerp = function(a, b, percentage) {return a + (b - a) * percentage;}
var lerp_color = function(r1, g1, b1, a1, r2, g2, b2, a2, percentage) {if (percentage == 0) {return [r1, g1, b1, a1];} else if (percentage == 1) {return [r2, g2, b2, a2];};var h1_color = rgb_to_hsv(r1, g1, b1);var h2_color = rgb_to_hsv(r2, g2, b2);var h1 = h1_color.h; var s1 = h1_color.s; var v1 = h1_color.v;var h2 = h2_color.h; var s2 = h2_color.s; var v2 = h2_color.v;var r_color = hsv_to_rgb(lerp(h1, h2, percentage), lerp(s1, s2, percentage), lerp(v1, v2, percentage));var r = r_color.r; var g = r_color.g; var b = r_color.b;var a = lerp(a1, a2, percentage);return [r, g, b, a];}
var item_count = function(b){if (b == null) { return 0 };if (b.length == 0) { var c = 0;for (var i = 0; i < b.length; i++) {c = c + 1;};return c;};return b.length }
var get_screen_size = function(){var screen_size = Render.GetScreenSize();var screen_size = [screen_size[0] - screen_size[0] * Convar.GetFloat("safezonex"),screen_size[1] * Convar.GetFloat("safezoney")];return screen_size;}
var text_is_empty = function(str) {if (str.trim() == "") {return true;};return false;}
var can_attack = function() {var me = Entity.GetLocalPlayer();var wpn = Entity.GetWeapon(me);if (me == null || wpn == null) {return false;};var curtime = Globals.Curtime();if (curtime < Entity.GetProp(me, "CCSPlayer", "m_flNextAttack")) {return false;};if (curtime < Entity.GetProp(wpn, "CBaseCombatWeapon", "m_flNextPrimaryAttack")) {return false;};return true;}
var gram_create = function(value, count) {var gram = new Array;for (var i = 0; i < count; i++) {gram[i] = value;}return gram;}
var gram_update = function(tab, value, forced) {var new_tab = tab; if (forced || new_tab[new_tab.length] != value) { new_tab.push(value); new_tab.shift();}; tab = new_tab;}
var get_average = function(tab) {var elements = 0; var sum = 0; for (var i in tab) { sum = sum + tab[i]; elements = elements + 1; };return sum / elements;}
var get_desync = function() {var RealYaw = Local.GetRealYaw();var FakeYaw = Local.GetFakeYaw();var delta = Math.min(Math.abs(RealYaw - FakeYaw) / 2, 58);return delta;}
var render_arc = function(x, y, radius, start_angle, percent, thickness, color) {var precision = (2 * Math.PI) / 30;var step = Math.PI / 180;var inner = radius - thickness;var end_angle = (start_angle + percent) * step;var start_angle = (start_angle * Math.PI) / 180;for (; radius > inner; --radius) {for (var angle = start_angle; angle < end_angle; angle += precision) {var cx = Math.round(x + radius * Math.cos(angle));var cy = Math.round(y + radius * Math.sin(angle));var cx2 = Math.round(x + radius * Math.cos(angle + precision));var cy2 = Math.round(y + radius * Math.sin(angle + precision));Render.Line(cx, cy, cx2, cy2, color);};};}
if (!String.prototype.format) {String.prototype.format = function () {var args = arguments; return this.replace(/{(\d+)}/g, function (match, number) {return typeof args[number] != 'undefined' ? args[number] : match;});};}
if (!String.format) {String.format = function(format) {var args = Array.prototype.slice.call(arguments, 1);return format.replace(/{(\d+)}/g, function(match, number) { return typeof args[number] != "undefined" ? args[number] : match;});};}

var script_name = "solus"
var database_name = "solus"
var menu_tab_items = ["Visuals", "Solus Items", "Solus Items"]; UI.AddSubTab(["Visuals", "SUBTAB_MGR"], "Solus Items")
var menu_tab_settings = ["Visuals", "Solus Settings", "Solus Settings"]; UI.AddSubTab(["Visuals", "SUBTAB_MGR"], "Solus Settings")
var menu_tab_commands = ["Visuals", "Solus Commands", "Solus Commands"]; UI.AddSubTab(["Visuals", "SUBTAB_MGR"], "Solus Commands")
var menu_palette = ["Solid", "Fade", "Gradient", "Dynamic gradient"]
var m_hotkeys = new Array; var m_hotkeys_update = true; var m_hotkeys_create

var ms_watermark = UI.AddCheckbox(menu_tab_items, "Watermark")
var ms_spectators = UI.AddCheckbox(menu_tab_items, "Spectators")
var ms_keybinds = UI.AddCheckbox(menu_tab_items, "Hotkey list")
var ms_doubletap = UI.AddCheckbox(menu_tab_items, "Double tap indication")
var ms_antiaim = UI.AddCheckbox(menu_tab_items, "Anti-aimbot indication")
var ms_ieinfo = UI.AddCheckbox(menu_tab_items, "Frequency update information")

var ms_palette = UI.AddDropdown(menu_tab_settings, "Solus Palette", menu_palette, 0)
var ms_color = UI.AddColorPicker(menu_tab_settings, "Solus Global color"); UI.SetColor(ms_color, [142, 165, 229, 85])

var ms_fade_offset = UI.AddSliderInt(menu_tab_settings, "Fade offset", 1, 1000); UI.SetValue(ms_fade_offset, 825)
var ms_fade_frequency = UI.AddSliderInt(menu_tab_settings, "Fade frequency", 1, 100); UI.SetValue(ms_fade_frequency, 10)
var ms_fade_split_ratio = UI.AddSliderInt(menu_tab_settings, "Fade split ratio", 0, 100); UI.SetValue(ms_fade_split_ratio, 100)

var specs_x = UI.AddSliderInt(menu_tab_settings, "Spectators window position x", 0, 10000); UI.SetValue(specs_x, get_screen_size()[0] / 1.385); UI.SetEnabled(specs_x, 0);
var specs_y = UI.AddSliderInt(menu_tab_settings, "Spectators window position y", 0, 10000); UI.SetValue(specs_y, get_screen_size()[1] / 2); UI.SetEnabled(specs_y, 0);

var keys_x = UI.AddSliderInt(menu_tab_settings, "Keybinds window position x", 0, 10000); UI.SetValue(keys_x, get_screen_size()[0] / 1.385); UI.SetEnabled(keys_x, 0);
var keys_y = UI.AddSliderInt(menu_tab_settings, "Keybinds window position y", 0, 10000); UI.SetValue(keys_y, get_screen_size()[1] / 2.5); UI.SetEnabled(keys_y, 0);

var dt_ind_x = UI.AddSliderInt(menu_tab_settings, "Doubletap window position x", 0, 10000); UI.SetValue(dt_ind_x, get_screen_size()[0] / 1.385); UI.SetEnabled(dt_ind_x, 0);
var dt_ind_y = UI.AddSliderInt(menu_tab_settings, "Doubletap window position y", 0, 10000); UI.SetValue(dt_ind_y, get_screen_size()[1] / 3.2); UI.SetEnabled(dt_ind_y, 0);

var ms_watermark_name = UI.AddTextbox(menu_tab_commands, "Watermark name")
var ms_watermark_prefix = UI.AddTextbox(menu_tab_commands, "Watermark prefix")
var ms_watermark_suffix = UI.AddTextbox(menu_tab_commands, "Watermark suffix")

var ms_frequency = UI.AddSliderInt(menu_tab_commands, "Monitor frequency", 1, 360); UI.SetValue(ms_frequency, 60)

DataFile.SetKey(database_name + ".data", database_name, JSON.stringify({
    "watermark": {
        "nickname": "",      
        "beta_status": true,
        "gc_state": true,
        "style": create_integer(4, 5, 4, 4),
        "suffix": null,
    },

    "spectators": {
        "avatars": true,
        "auto_position": true,
    },
})); var script_db = JSON.parse(DataFile.GetKey(database_name + ".data", database_name));

var get_bar_color = function() {
    var color = UI.GetColor(ms_color)
    var palette = UI.GetValue(ms_palette)

    if (palette != 0 && palette != 1) {
        var rgb_split_ratio = UI.GetValue(ms_fade_split_ratio) / 100
        var h = palette == 3 ? Globals.Realtime() * (UI.GetValue(ms_fade_frequency) / 100) : UI.GetValue(ms_fade_offset) / 1000

        color = hsv_to_rgb(h, 1, 1)
        color = [
            color.r * rgb_split_ratio, 
            color.g * rgb_split_ratio, 
            color.b * rgb_split_ratio
        ]
    }

    return [color[0], color[1], color[2], UI.GetColor(ms_color)[3]]
}

var ms_classes = {
    "position": {
        "offset": 0,

        g_paint_handler: function() {
            this.offset = 0
        }
    },

    "watermark": {
        "cstyle": ["gamesense", "gamesense.pub", "skeet", "skeet.cc", "onetap", "onetap.com"],
        "width": 0,

        has_beta: function() { return false },
        get_name: function() { return Cheat.GetUsername() },
        get_gc_state: function() { return true },

        g_paint_handler: function() {
            if (!UI.GetValue(ms_watermark)) return
            if (UI.GetValue(ms_watermark)) { ms_classes.position.offset++ }                

            var font = Render.GetFont("Verdana.ttf", 10, true)
            var r = get_bar_color()[0]; var g = get_bar_color()[1]; var b = get_bar_color()[2]; var a = get_bar_color()[3]

            var data_wm = script_db.watermark || {}
            var data_nickname = data_wm.nickname.length == 0 ? Cheat.GetUsername() : data_wm.nickname.toString()
            var data_suffix = ((data_wm.suffix == null ? false : true) ? data_wm.suffix.toString() : "").replace("beta", "")

            if (data_wm.beta_status && this.has_beta() && (!data_suffix || data_suffix.length < 1)) {
                data_suffix = "beta"
            }

            if (!text_is_empty(UI.GetString(ms_watermark_suffix))) { 
                data_suffix = UI.GetString(ms_watermark_suffix) 
            }
            if (!text_is_empty(UI.GetString(ms_watermark_name))) { 
                data_nickname = UI.GetString(ms_watermark_name) 
            }

            var today = new Date(); today = today.toTimeString().substring(0, 8); var sys_time = ("{0}").format(today)
            var actual_time = ("{0}").format(sys_time)

            var is_connected_to_gc = !data_wm.gc_state || this.get_gc_state()
            var gc_state = !is_connected_to_gc ? "\x20\x20\x20\x20\x20" : ""

            var nickname = data_nickname.length > 0 ? data_nickname : this.get_name()
            var suffix = ("{0}{1}").format(
                !text_is_empty(UI.GetString(ms_watermark_prefix)) ? UI.GetString(ms_watermark_prefix) : this.cstyle[data_wm.style && data_wm.style.value || 0] || this.cstyle[0], 
                data_suffix.length > 0 && (" [{0}]").format(data_suffix) || ""
            )

            var text = ("{0}{1} | {2} | {3}").format(gc_state, suffix, nickname, actual_time)

            if (World.GetServerString()) {
                var latency = Math.floor(Entity.GetProp(Entity.GetLocalPlayer(), "CPlayerResource", "m_iPing"))
                var latency_text = latency > 5 ? (" | delay: {0}ms").format(latency) : ""

                text = ("{0}{1} | {2}{3} | {4}").format(gc_state, suffix, nickname, latency_text, actual_time)
            }

            var h = 18; this.width = lerp(this.width, Render.TextSize(text, font)[0] + 8, Globals.Frametime() * 12); var w = this.width
            var x = Render.GetScreenSize()[0]; var y = 10 + (25*0)
    
            x = x - w - 10

            if (UI.GetValue(ms_palette) == 0) {
                Render.FilledRect(x, y, w, 2, [r, g, b, 255])
            } else if (UI.GetValue(ms_palette) == 1) {
                Render.GradientRect(x, y, (w / 2) + 1, 2, 1, [r, g, b, 0], [r, g, b, 255])
                Render.GradientRect(x + (w / 2), y, (w / 2) + 1, 2, 1, [r, g, b, 255], [r, g, b, 0])
            } else {
                Render.GradientRect(x, y, (w / 2) + 1, 2, 1, [g, b, r, 255], [r, g, b, 255])
                Render.GradientRect(x + w / 2, y, w - w / 2, 2, 1, [r, g, b, 255], [b, r, g, 255])
            }

            Render.FilledRect(x, y + 2, w, h, [17, 17, 17, a])
            Render.String(x + 4, y + 3, 0, text, [255, 255, 255, 255], font)
        }
    },

    "spectators": {
        "dragging": new Array(0, 0, 0),

        "m_alpha": 0,
        "m_active": new Array,
        "m_contents": new Array,
        "unsorted": new Array,

        "width": 0,

        get_spectating_players: function() {
            var me = Entity.GetLocalPlayer(); var all_players = Entity.GetPlayers()

            var players = new Array; var observing = me

            for (var i = 0; i < all_players.length; i++) {
                var entity = all_players[i]
                if (Entity.GetClassName(entity) == "CCSPlayer") {
                    var m_iObserverMode = Entity.GetProp(entity, "CCSPlayer", "m_iObserverMode")
                    var m_hObserverTarget = Entity.GetProp(entity, "CCSPlayer", "m_hObserverTarget")

                    if (m_hObserverTarget != null && m_hObserverTarget <= 64 && !Entity.IsAlive(entity)) {
                        if (players[m_hObserverTarget] == null) { players[m_hObserverTarget] = new Array }
                        if (entity == me) { observing = m_hObserverTarget }

                        players[m_hObserverTarget].push(i)
                    }
                }
            }

            return [players, observing]
        },

        g_load_handler: function() {
            for (var i = 0; i < 64; i++) {
                this.m_contents[i] = 0
            }
        },

        g_paint_handler: function() {
            if (!UI.GetValue(ms_spectators)) return

            var data_sp = script_db.spectators || {}

            var font = Render.GetFont("Verdana.ttf", 10, true); var font_s = Render.GetFont("Tahoma.ttf", 8, true)

            var master_switch = UI.GetValue(ms_spectators)
            var is_menu_open = UI.IsMenuOpen()
            var frames = 8 * Globals.Frametime()
        
            var latest_item = false
            var maximum_offset = 85
        
            var me = Entity.GetLocalPlayer()
            var spectators = this.get_spectating_players()[0]; var player = this.get_spectating_players()[1]

            var unsorted = this.unsorted

            for (var i = 0; i < 64; i++) {
                unsorted[i] = [i, false]
            }

            if (spectators[player] != null) {
                for (var i in spectators[player]) {
                    var spectator = spectators[player][i]

                    var active = (function(){
                        if ((spectator + 1) == me) {
                            return false
                        }

                        return true
                    })()

                    var avatar = (function() {
                        if (!data_sp.avatars) {
                            return false
                        }

                        return true
                    })()

                    unsorted[spectator] = [i, active, avatar]
                }
            }

            for (var i = 0; i < this.unsorted.length; i++) {
                if (this.unsorted[i][1]) {
                    var name = Entity.GetName(i + 1).toString();
                    if (Render.TextSize(name, font)[0] > maximum_offset) {
                        maximum_offset = Render.TextSize(name, font)[0];
                    };
                };
            }
        
            var text = "spectators"
            var x = UI.GetValue(specs_x); var y = UI.GetValue(specs_y)
            var r = get_bar_color()[0]; var g = get_bar_color()[1]; var b = get_bar_color()[2]; var a = get_bar_color()[3]
        
            var height_offset = 23; this.width = lerp(this.width, 55 + maximum_offset, Globals.Frametime() * 12)
            var w = this.width; var h = 50
        
            w = w - (data_sp.avatars ? 0 : 17)

            var right_offset = data_sp.auto_position && (x + w / 2) > (([Render.GetScreenSize()[0], Render.GetScreenSize()[1]])[0] / 2) ? true : false

            if (UI.GetValue(ms_palette) == 0) {
                Render.FilledRect(x, y, w, 2, [r, g, b, this.m_alpha*255])
            } else if (UI.GetValue(ms_palette) == 1) {
                Render.GradientRect(x, y, (w / 2) + 1, 2, 1, [r, g, b, this.m_alpha*0], [r, g, b, this.m_alpha*255])
                Render.GradientRect(x + (w / 2), y, (w / 2) + 1, 2, 1, [r, g, b, this.m_alpha*255], [r, g, b, this.m_alpha*0])
            } else {
                Render.GradientRect(x, y, (w / 2) + 1, 2, 1, [g, b, r, this.m_alpha*255], [r, g, b, this.m_alpha*255])
                Render.GradientRect(x + w / 2, y, w - w / 2, 2, 1, [r, g, b, this.m_alpha*255], [b, r, g, this.m_alpha*255])
            }

            Render.FilledRect(x, y + 2, w, 18, [17, 17, 17, this.m_alpha*a])
            Render.String(x - Render.TextSize(text, font)[0] / 2 + w/2, y + 4, 0, text, [255, 255, 255, this.m_alpha*255], font)

            for (var i = 0; i < this.unsorted.length; i++) {
                var c_ref = this.unsorted[i]; var name = Entity.GetName(i + 1).toString()
                var text_h = Render.TextSize(name, font)[1]

                this.m_contents[i] = lerp(this.m_contents[i], c_ref[1] ? 1 : 0, frames)

                Render.String(x + ((c_ref[2] && !right_offset) ? text_h : -5) + 10, y + height_offset - 2, 0, name, [255, 255, 255, this.m_alpha*this.m_contents[i]*255], font)

                if (c_ref[2] != false) {
                    Render.FilledRect(x + (right_offset ? w - 15 : 5), y + height_offset, text_h, text_h, [40, 45, 50, this.m_alpha*this.m_contents[i]*255])
                    Render.String(x + (right_offset ? w - 15 : 5) + 3, y + height_offset, 0, "?", [255, 255, 255, this.m_alpha*this.m_contents[i]*255], font_s)
                }

                height_offset += 15 * this.m_contents[i]
            }

            var cursor = Input.GetCursorPosition();
            if(input_mouse_on_object(x, y, w, 18)){
                if ((Input.IsKeyPressed(0x01)) && (this.dragging[0] == 0)) {
                    this.dragging[0] = 1;
                    this.dragging[1] = UI.GetValue(specs_x) - cursor[0];
                    this.dragging[2] = UI.GetValue(specs_y) - cursor[1];
                }
            }
            if (!Input.IsKeyPressed(0x01)) this.dragging[0] = 0;
            if (this.dragging[0] == 1 && UI.IsMenuOpen()) {
                var q = Math.max(0, Math.min(Render.GetScreenSize()[0] - w, cursor[0] + this.dragging[1]));
                var r = Math.max(0, Math.min(Render.GetScreenSize()[1] - 18, cursor[1] + this.dragging[2]));
                UI.SetValue(specs_x, q)
                UI.SetValue(specs_y, r)
            }

            this.m_alpha = lerp(this.m_alpha, (spectators[player] != null || UI.IsMenuOpen()) ? 1 : 0, frames)
        }
    },

    "keybinds": {
        "dragging": new Array(0, 0, 0),
        "kb": new Array,

        "m_alpha": 0,
        "width": 0,

        "m_contents": [
            {"reference": ["Rage", "Exploits", "Keys", "Key assignment", "Double tap"], "custom_name": "", "mode": "", "alpha": 0},
            {"reference": ["Rage", "Exploits", "Keys", "Key assignment", "Hide shots"], "custom_name": "On shot anti-aim", "mode": "", "alpha": 0},
            {"reference": ["Rage", "General", "General", "Key assignment", "Damage override"], "custom_name": "", "mode": "", "alpha": 0},
            {"reference": ["Rage", "Anti Aim", "General", "Key assignment", "Fake duck"], "custom_name": "Duck peek assist", "mode": "", "alpha": 0},
            {"reference": ["Misc.", "Keys", "Keys", "Key assignment", "Auto peek"], "custom_name": "Quick peek assist", "mode": "", "alpha": 0},
            {"reference": ["Rage", "Anti Aim", "General", "Key assignment", "Slow walk"], "custom_name": "Slow motion", "mode": "", "alpha": 0},
        ],

        "get_state": {"Hold": "[holding]", "Toggle": "[toggled]", "Always": "[enabled]"},

        g_paint_handler: function() {
            if (!UI.GetValue(ms_keybinds)) return

            var font = Render.GetFont("Verdana.ttf", 10, true)

            var master_switch = UI.GetValue(ms_keybinds)
            var is_menu_open = UI.IsMenuOpen()
            var frames = 8 * Globals.Frametime()
        
            var latest_item = false
            var maximum_offset = 66

            for (var i = 0; i < this.m_contents.length; i++) {
                if (UI.GetValue(this.m_contents[i].reference)) {
                    var name = this.m_contents[i].reference[this.m_contents[i].reference.length - 1]
                    if (!text_is_empty(this.m_contents[i].custom_name)) {name = this.m_contents[i].custom_name}

                    if (Render.TextSize(name, font)[0] > maximum_offset) {
                        maximum_offset = Render.TextSize(name, font)[0];
                    };
                };
            }

            var text = "keybinds"
            var x = UI.GetValue(keys_x); var y = UI.GetValue(keys_y)
            var r = get_bar_color()[0]; var g = get_bar_color()[1]; var b = get_bar_color()[2]; var a = get_bar_color()[3]
        
            var height_offset = 23; this.width = lerp(this.width, 75 + maximum_offset, Globals.Frametime() * 12)
            var w = this.width; var h = 50
        
            if (UI.GetValue(ms_palette) == 0) {
                Render.FilledRect(x, y, w, 2, [r, g, b, this.m_alpha*255])
            } else if (UI.GetValue(ms_palette) == 1) {
                Render.GradientRect(x, y, (w / 2) + 1, 2, 1, [r, g, b, this.m_alpha*0], [r, g, b, this.m_alpha*255])
                Render.GradientRect(x + (w / 2), y, (w / 2) + 1, 2, 1, [r, g, b, this.m_alpha*255], [r, g, b, this.m_alpha*0])
            } else {
                Render.GradientRect(x, y, (w / 2) + 1, 2, 1, [g, b, r, this.m_alpha*255], [r, g, b, this.m_alpha*255])
                Render.GradientRect(x + w / 2, y, w - w / 2, 2, 1, [r, g, b, this.m_alpha*255], [b, r, g, this.m_alpha*255])
            }

            Render.FilledRect(x, y + 2, w, 18, [17, 17, 17, this.m_alpha*a])
            Render.String(x - Render.TextSize(text, font)[0] / 2 + w/2, y + 4, 0, text, [255, 255, 255, this.m_alpha*255], font)

            for (var i = 0; i < this.m_contents.length; i++) {
                var c_ref = this.m_contents[i]; c_ref.mode = UI.GetHotkeyState(c_ref.reference)
                var key_type = this.get_state[c_ref.mode]; var name = c_ref.reference[c_ref.reference.length - 1]
                if (!text_is_empty(c_ref.custom_name)) {name = c_ref.custom_name}
                if (key_type == undefined) { key_type = "[enabled]" }

                c_ref.alpha = lerp(c_ref.alpha, UI.GetValue(c_ref.reference) ? 1 : 0, frames)
                if (UI.GetValue(c_ref.reference)) {if (this.kb.indexOf(name) == -1) {this.kb.push(name);};} else {this.kb.splice(i);}

                Render.String(x + 5, y + height_offset, 0, name, [255, 255, 255, c_ref.alpha*this.m_alpha*255], font)
                Render.String(x + w - Render.TextSize(key_type, font)[0] - 5, y + height_offset, 0, key_type, [255, 255, 255, c_ref.alpha*this.m_alpha*255], font)
                height_offset = height_offset + 15 * c_ref.alpha
            }

            var cursor = Input.GetCursorPosition();
            if(input_mouse_on_object(x, y, w, 18)){
                if ((Input.IsKeyPressed(0x01)) && (this.dragging[0] == 0)) {
                    this.dragging[0] = 1;
                    this.dragging[1] = UI.GetValue(keys_x) - cursor[0];
                    this.dragging[2] = UI.GetValue(keys_y) - cursor[1];
                }
            }
            if (!Input.IsKeyPressed(0x01)) this.dragging[0] = 0;
            if (this.dragging[0] == 1 && UI.IsMenuOpen()) {
                var q = Math.max(0, Math.min(Render.GetScreenSize()[0] - w, cursor[0] + this.dragging[1]));
                var r = Math.max(0, Math.min(Render.GetScreenSize()[1] - 18, cursor[1] + this.dragging[2]));
                UI.SetValue(keys_x, q)
                UI.SetValue(keys_y, r)
            }

            this.m_alpha = lerp(this.m_alpha, (this.kb.length > 0 || UI.IsMenuOpen()) ? 1 : 0, frames)
        }
    },

    "doubletap": {
        "dragging": new Array(0, 0, 0),

        "tickbase": 0,
        "bar": 0,

        "bullet_alpha": new Array(0, 0),

        "m_icons" : {
            "bayonet": "1", "flip knife": "2", "gut knife": "3", "karambit": "4", "m9 bayonet": "5", "huntsman knife": "6", "bowie knife" : "7", "butterfly knife": "8", "shadow daggers": "9", "falchion knife": "0", "ursus knife": "1", "navaja knife": "1", "stiletto knife": "1", "skeleton knife": "1", "talon knife": "1", "classic knife": "1", "paracord knife": "1", "survival knife": "1", "nomad knife": "1",
            "galil ar": "Q", "ak 47": "W", "p2000": "E", "famas": "R", "m4a1 s": "T", "scar 20": "Y", "aug": "U", "cz75 auto": "I", "mp9": "O", "p90": "P", "knife": "]",
            "desert eagle": "A", "m4a4": "S", "glock 18": "D", "p250": "F", "usp s": "G", "tec 9": "H", "r8 revolver": "J", "mac 10": "K", "ump 45": "L",
            "awp": "Z", "g3sg1": "X", "five seven": "C", "sg 553": "V", "dual berettas": "B", "mp7": "N", "pp bizon": "M",
            "nova": "e", "flashbang": "i", "c4 explosive": "o", "ssg 08": "a", "mag 7": "d", "negev": "f", "m249": "g", "zeus x27": "h", "high explosive grenade": "j", "smoke grenade": "k", "molotov": "l", "sawed off": "c", "xm1014": "b", "incendiary grenade": "n", "decoy grenade": "m"
        },
        "m_speed": {[0]: "Reliable", [1]: "Fast", [2]: "Faster", [3]: "Fastest"},

        "width": 0,
        "m_alpha": 0,

        allowed_weapons: function(g_Local_classname, weapon_name) {
            if ((g_Local_classname == "CKnife" || g_Local_classname == "CWeaponSSG08" || g_Local_classname == "CWeaponAWP" || weapon_name == "r8 revolver" || g_Local_classname == "CHEGrenade" || g_Local_classname == "CMolotovGrenade" || g_Local_classname == "CIncendiaryGrenade" || g_Local_classname == "CFlashbang" || g_Local_classname == "CSmokeGrenade" || g_Local_classname == "CDecoyGrenade" || g_Local_classname == "CWeaponTaser" || g_Local_classname == "CC4")) {
                return false
            } else {
                return true
            }
        },

        g_paint_handler: function() {
            if (!UI.GetValue(ms_doubletap)) return

            var font = Render.GetFont("Verdana.ttf", 10, true); var bullet_font = Render.GetFont("bullet.ttf", 22, true); var weapon_font = Render.GetFont("undefeated.ttf", 20, true)

            var master_switch = UI.GetValue(ms_doubletap)
            var is_menu_open = UI.IsMenuOpen()
            var frames = 8 * Globals.Frametime()

            var active_weapon = Entity.GetWeapon(Entity.GetLocalPlayer())
            var weapon_name = Entity.GetName(active_weapon)
            var g_Local_classname = Entity.GetClassName(active_weapon)

            this.bar = lerp(this.bar, Exploit.GetCharge() < 1 ? 0 : 1, frames)
            if (can_attack() && Exploit.GetCharge() > 0.7 && UI.GetValue(["Rage", "Exploits", "Keys", "Key assignment", "Double tap"])) {
                this.tickbase = lerp(this.tickbase, 14, Globals.Frametime() * 12)
            } else if (can_attack() && Exploit.GetCharge() > 0.7 && UI.GetValue(["Rage", "Exploits", "Keys", "Key assignment", "Hide shots"])) {
                this.tickbase = lerp(this.tickbase, 7, Globals.Frametime() * 12)
            } else {
                this.tickbase = lerp(this.tickbase, 0, Globals.Frametime() * 12)
            }

            var text = ("DT [{0}] | tickbase: {1}").format(this.m_speed[UI.GetValue(["Rage", "Exploits", "General", "Speed"])], Math.round(this.tickbase))
            var x = UI.GetValue(dt_ind_x); var y = UI.GetValue(dt_ind_y)
            var r = get_bar_color()[0]; var g = get_bar_color()[1]; var b = get_bar_color()[2]; var a = get_bar_color()[3]
        
            var height_offset = 23; this.width = lerp(this.width, Render.TextSize(text, font)[0] + 8, Globals.Frametime() * 12)
            var w = this.width; var h = 50

            Render.FilledRect(x, y, w, 2, [255, 255, 255, this.m_alpha*20])
            if (UI.GetValue(ms_palette) == 0) {
                Render.FilledRect(x, y, w * this.bar, 2, [r, g, b, this.m_alpha*255])
            } else if (UI.GetValue(ms_palette) == 1) {
                Render.GradientRect(x, y, (w / 2) * this.bar + 1, 2, 1, [r, g, b, this.m_alpha*0], [r, g, b, this.m_alpha*255])
                Render.GradientRect(x + (w / 2) * this.bar, y, (w / 2) * this.bar + 1, 2, 1, [r, g, b, this.m_alpha*255], [r, g, b, this.m_alpha*0])
            } else {
                Render.GradientRect(x, y, (w / 2) * this.bar + 1, 2, 1, [g, b, r, this.m_alpha*255], [r, g, b, this.m_alpha*255])
                Render.GradientRect(x + (w / 2) * this.bar, y,  w * this.bar / 2, 2, 1, [r, g, b, this.m_alpha*255], [b, r, g, this.m_alpha*255])
            }

            Render.FilledRect(x, y + 2, w, 18, [17, 17, 17, this.m_alpha*a])
            Render.String(x + 4, y + 3, 0, text, [255, 255, 255, this.m_alpha*255], font)

            Render.String(x + 4, y + 22, 0, this.m_icons[weapon_name] == undefined ? "" : this.m_icons[weapon_name], [255, 255, 255, this.m_alpha*255], weapon_font)

            if (this.allowed_weapons(g_Local_classname, weapon_name)) {
                this.bullet_alpha[0] = lerp(this.bullet_alpha[0], can_attack() ? 1 : 0, frames)
                this.bullet_alpha[1] = lerp(this.bullet_alpha[1], can_attack() && Exploit.GetCharge() == 1 && UI.GetValue(["Rage", "Exploits", "Keys", "Key assignment", "Double tap"]) ? 1 : 0, frames)

                if (can_attack()) {
                    Render.String(x + 8 + Render.TextSize(this.m_icons[weapon_name] == undefined ? "" : this.m_icons[weapon_name], weapon_font)[0], y + 18, 0, "A", [255, 255, 255, this.bullet_alpha[0]*this.m_alpha*255], bullet_font)
                }
                if (can_attack() && Exploit.GetCharge() == 1 && UI.GetValue(["Rage", "Exploits", "Keys", "Key assignment", "Double tap"])) {
                    Render.String(x + 22 + Render.TextSize(this.m_icons[weapon_name] == undefined ? "" : this.m_icons[weapon_name], weapon_font)[0], y + 18, 0, "A", [255, 255, 255, this.bullet_alpha[1]*this.m_alpha*255], bullet_font)
                }
            }

            var cursor = Input.GetCursorPosition();
            if(input_mouse_on_object(x, y, w, 18)){
                if ((Input.IsKeyPressed(0x01)) && (this.dragging[0] == 0)) {
                    this.dragging[0] = 1;
                    this.dragging[1] = UI.GetValue(dt_ind_x) - cursor[0];
                    this.dragging[2] = UI.GetValue(dt_ind_y) - cursor[1];
                }
            }
            if (!Input.IsKeyPressed(0x01)) this.dragging[0] = 0;
            if (this.dragging[0] == 1 && UI.IsMenuOpen()) {
                var q = Math.max(0, Math.min(Render.GetScreenSize()[0] - w, cursor[0] + this.dragging[1]));
                var r = Math.max(0, Math.min(Render.GetScreenSize()[1] - 18, cursor[1] + this.dragging[2]));
                UI.SetValue(dt_ind_x, q)
                UI.SetValue(dt_ind_y, r)
            }

            this.m_alpha = lerp(this.m_alpha, (UI.IsMenuOpen() || UI.GetValue(["Rage", "Exploits", "Keys", "Key assignment", "Double tap"]) || UI.GetValue(["Rage", "Exploits", "Keys", "Key assignment", "Hide shots"])) ? 1 : 0, frames)
        }
    },

    "antiaim": {
        "offset": 0, "m_alpha": 0,
        "width": 0, "width_second": 0, "fake_amount": 0,

        "gram_fyaw": gram_create(0, 2),
        "teleport_data": gram_create(0, 3),

        "ind_phase": 0, "ind_num": 0, "ind_time": 0,
        "last_sent": 0, "current_choke": 0,
        "teleport": 0, "last_origin": new Array(0, 0, 0), "last_origin_sqr": 0, "origin_sqr": 0,
        "breaking_lc": 0,

        g_setup_command: function() {
            var me = Entity.GetLocalPlayer()

            if (Globals.ChokedCommands() == 0) {
                var m_origin = Entity.GetRenderOrigin(me)
                this.last_origin_sqr = this.last_origin[0] * this.last_origin[0] + this.last_origin[1] * this.last_origin[1]
                this.origin_sqr = m_origin[0] * m_origin[0] + m_origin[1] * m_origin[1]

                if (this.last_origin != null) {
                    this.teleport = this.last_origin_sqr - this.origin_sqr
        
                    gram_update(this.teleport_data, this.teleport, true)
                }

                this.last_sent = this.current_choke
                this.last_origin = m_origin

                gram_update(this.gram_fyaw, Math.abs(get_desync().toFixed(1)), true)
            }

            this.breaking_lc = 
                get_average(this.teleport_data) > 3200 ? 1 :
                    (Exploit.GetCharge() > 0.7 ? 2 : 0)
        
            this.current_choke = Globals.ChokedCommands()
        },

        g_paint_handler: function() {
            this.offset = lerp(this.offset, ms_classes.position.offset, Globals.Frametime() * 8)

            var me = Entity.GetLocalPlayer()
            if (me == null || !Entity.IsAlive(me)) return

            var a = get_bar_color()[3]

            this.m_alpha = lerp(this.m_alpha, UI.GetValue(ms_antiaim) ? 1 : 0, Globals.Frametime() * 12)
            if (this.m_alpha == 0) return

            if (UI.GetValue(ms_antiaim)) { ms_classes.position.offset++ }
            var font = Render.GetFont("Verdana.ttf", 10, true)

            var ms_clr = UI.GetColor(ms_color)
        
            var addr = ""; var nval = false
            var r = 150; var g = 150; var b = 150

            var fr = Globals.Frametime() * 3.75
            var min_offset = 1200 + Math.max(0, get_average(this.teleport_data) - 3800)
            var teleport_mt = Math.abs(Math.min(this.teleport - 3800, min_offset) / min_offset * 100)

            if (this.ind_num != teleport_mt && this.ind_time < Globals.Realtime()) {
                this.ind_time = Globals.Realtime() + 0.005
                this.ind_num = this.ind_num + (this.ind_num > teleport_mt ? -1 : 1)
            }

            this.ind_phase = this.ind_phase + (this.breaking_lc == 1 ? fr : -fr)
            this.ind_phase = this.ind_phase > 1 ? 1 : this.ind_phase
            this.ind_phase = this.ind_phase < 0 ? 0 : this.ind_phase

            if (this.breaking_lc == 2) {
                addr = " | SHIFTING"; this.ind_phase = 0; this.ind_num = 0
                r = 228; g = 126; b = 10
            } else if (this.ind_phase > 0.1) {
                addr = " | dst: \x20\x20\x20\x20\x20\x20\x20"
            }

            var fl = this.last_sent
            if (this.last_sent < 10) {
                fl = "\x20\x20" + this.last_sent
            }
            var text = ("FL: {0}{1}").format(fl, addr)

            var h = 17; this.width = lerp(this.width, Render.TextSize(text, font)[0] + 8, Globals.Frametime() * 8); var w = this.width
            var x = Render.GetScreenSize()[0]; var y = 10 + (25*this.offset)
    
            x = x - w - 10

            Render.GradientRect(x, y + h, w/2, 1, 1, [0, 0, 0, this.m_alpha*25], [r, g, b, this.m_alpha*255])
            Render.GradientRect(x + w/2, y + h, w - w/2, 1, 1, [r, g, b, this.m_alpha*255], [0, 0, 0, this.m_alpha*25])
    
            Render.FilledRect(x, y, w, h, [17, 17, 17, this.m_alpha*a])
            Render.String(x + 4, y + 2, 0, text, [255, 255, 255, this.m_alpha*255], font)

            if (this.ind_phase > 0) {
                Render.GradientRect(
                    x + w - Render.TextSize(" | dst: ", font)[0] + 4, 
                    y + 8, Math.min(100, this.ind_num) / 100 * 24, 5,
                    
                    1,

                    [ms_clr[1], ms_clr[2], ms_clr[3], this.m_alpha*this.ind_phase*220],
                    [ms_clr[1], ms_clr[2], ms_clr[3], this.m_alpha*this.ind_phase * 25]
                )
            }

            var color = [170 + (154 - 186) * get_desync().toFixed(1) / 58, 0 + (255 - 0) * get_desync().toFixed(1) / 58, 16 + (0 - 16) * get_desync().toFixed(1) / 58]
            var r = color[0]; var g = color[1]; var b = color[2]

            var add_text = (get_desync().toFixed(1) > 0) ? "\x20\x20\x20\x20\x20" : ""
            this.fake_amount = lerp(this.fake_amount, get_average(this.gram_fyaw), Globals.Frametime() * 5)
            var text = ('{0}FAKE ({1})').format(add_text, this.fake_amount.toFixed(1))
            var h = 18; this.width_second = lerp(this.width_second, Render.TextSize(text, font)[0] + 8, Globals.Frametime() * 8); var w = this.width_second

            var dec = [r - (r/100 * 50), g - (g/100 * 50), b - (b/100 * 50)]

            Render.GradientRect(x - w - 6, y, 2, h / 2, 0, [dec[0], dec[1], dec[2], this.m_alpha*0], [r, g, b, this.m_alpha*255])
            Render.GradientRect(x - w - 6, y + h/2, 2, h / 2, 0, [r, g, b, this.m_alpha*255], [dec[0], dec[1], dec[2], this.m_alpha*0])
    
            Render.GradientRect(x - w - 4, y, w / 2, h, 1, [17, 17, 17, this.m_alpha*25], [17, 17, 17, this.m_alpha*a])
            Render.GradientRect(x - w - 4 + w / 2, y, w / 2, h, 1, [17, 17, 17, this.m_alpha*a], [17, 17, 17, this.m_alpha*25])
            Render.String(x - w, y + 2, 0, text, [255, 255, 255, this.m_alpha*255], font)

            if (get_desync().toFixed(1) > 0) {
                render_arc(x - w + 7, y + 8, 5, 0, this.fake_amount * 6, 2, [89, 119, 239, this.m_alpha*255])
            }
        }
    },

    "ilstate": {
        "request_time": Globals.Frametime(),
        "frametime": Globals.Curtime(),

        "frametimes": new Array,
        "height": new Array,

        "m_alpha": 0, "width": 0, "offset": 0,

        get_color: function(frametime) {
            switch (true) {
                case frametime > 15:
                    return [255, 0, 0];
                break;
                case frametime > 12:
                    return [255, 170, 0];
                break;
                case frametime > 10:
                    return [255, 255, 0];
                break;
                case frametime > 7.5:
                    return [150, 255, 0];
                break;
                case frametime > 5:
                    return [70, 255, 0];
                break;
                default:
                    return [0, 255, 0];
                break;
            }
        },

        formatting: function(avg) {
            if (avg < 1) { return avg.toFixed(2) }
            if (avg < 10) { return avg.toFixed(1) }
            return Math.floor(avg)
        },

        g_paint_handler: function() {
            this.offset = lerp(this.offset, ms_classes.position.offset, Globals.Frametime() * 8)
            var a = get_bar_color()[3]

            this.m_alpha = lerp(this.m_alpha, UI.GetValue(ms_ieinfo) ? 1 : 0, Globals.Frametime() * 12)
            if (this.m_alpha == 0) return

            var font = Render.GetFont("Verdana.ttf", 10, true)

            var avg = Math.abs((this.frametime * 1000) - 5)
            var display_frequency = UI.GetValue(ms_frequency)
            avg = avg > display_frequency ? display_frequency : avg
            var text = ("{0}ms / {1}hz").format(this.formatting(avg), display_frequency)

            var interp = this.get_color(avg)

            var h = 18; this.width = lerp(this.width, Render.TextSize(text, font)[0] + 8, Globals.Frametime() * 8); var w = this.width
            var x = Render.GetScreenSize()[0]; var y = 10 + (25*this.offset)
    
            x = x - w - 10

            Render.GradientRect(x + 1, y+h, (w/2), 1, 1, [0, 0, 0, this.m_alpha*25], [interp[0], interp[1], interp[2], this.m_alpha*255])
            Render.GradientRect(x + w/2, y+h, w-w/2, 1, 1, [interp[0], interp[1], interp[2], this.m_alpha*255], [0, 0, 0, this.m_alpha*25])

            Render.FilledRect(x, y, w, h, [17, 17, 17, this.m_alpha*a])
            Render.String(x+4, y + 2, 0, text, [255, 255, 255, this.m_alpha*255], font)

            var text = "IO | "
            var sub = text + "\x20\x20\x20\x20\x20"
            var h = 18; var w = Render.TextSize(sub, font)[0] + 8
            var ie_w = Render.TextSize(text, font)[0] + 4
            var r = UI.GetColor(ms_color)[0]; var g = UI.GetColor(ms_color)[1]; var b = UI.GetColor(ms_color)[2]

            if (this.request_time + 1 < Globals.Curtime()) {
                this.frametime = Globals.Frametime()
                this.request_time = Globals.Curtime()
                this.frametimes.unshift(this.frametime)

                if (this.frametimes.length > 4) {
                    this.frametimes.pop()
                }
            }

            Render.FilledRect(x - w - 4, y, w, h, [17, 17, 17, this.m_alpha*a])
            Render.String(x - w, y + 2, 0, sub, [255, 255, 255, this.m_alpha*255], font)

            for (var i = 0; i < this.frametimes.length; i++) {
                if (this.height[i] == null) { this.height[i] = 0 }
                this.height[i] = lerp(this.height[i], Math.floor(Math.min(12, this.frametimes[i] / 1 * 1000)), Globals.Frametime() * 8)

                Render.GradientRect(x - w - 4 + ie_w - (5 * i) + 15, y + 15 - (this.height[i] - 1), 5, this.height[i] - 1, 0, [r, g, b, this.m_alpha*0], [r, g, b, this.m_alpha*255])
            }
        }
    }
}

var callbacks = {
    g_paint_handler: function() {
        ms_classes.position.g_paint_handler()
        ms_classes.watermark.g_paint_handler()
        ms_classes.spectators.g_paint_handler()
        ms_classes.keybinds.g_paint_handler()
        ms_classes.doubletap.g_paint_handler()
        ms_classes.antiaim.g_paint_handler()
        ms_classes.ilstate.g_paint_handler()
    },

    g_load_handler: function() {
        ms_classes.spectators.g_load_handler()
    },

    g_setup_command: function() {
        ms_classes.antiaim.g_setup_command()
    }
}
Cheat.RegisterCallback("CreateMove", "callbacks.g_setup_command")
Cheat.RegisterCallback("Draw", "callbacks.g_paint_handler")
callbacks.g_load_handler()