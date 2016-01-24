digipad = {}
if minetest.setting_getbool("digipad_terminal") then
	dofile(minetest.get_modpath("digipad").."/terminal.lua")  -- add terminal to mod
end
-- ========================
--Declare shared variables / functions
-- ========================
digipad.digipad_formspec =	-- Defines the grid of buttons
	"size[4,6]"..
	"button[0,1;1,1;dc1;1]button[1,1;1,1;dc2;2]button[2,1;1,1;dc3;3]"..
	"button[0,2;1,1;dc4;4]button[1,2;1,1;dc5;5]button[2,2;1,1;dc6;6]"..
	"button[0,3;1,1;dc7;7]button[1,3;1,1;dc8;8]button[2,3;1,1;dc9;9]"..
	"button_exit[0,4;1,1;dcC;Cancel]button[1,4;1,1;dc0;0]button_exit[2,4;1,1;dcA;Submit]"..
	"button[3,1;1,1;chan1;Chan 1]button[3,2;1,1;chan2;Chan 2]button[3,3;1,1;chan3;Chan 3]"

digipad.hidecode = function(len)
	assert(len, "[digipad] hidecode: missing code length")
	if len == 0 then
		return "" -- not sure if needed
	end
	return string.rep("*", len)
end

digipad.submit = function (pos, channel, number)
	--minetest.chat_send_player("singleplayer", "Code is "..number)
	digiline:receptor_send(pos, digiline.rules.default, channel, tonumber(number))
end

digipad.cons = function(pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", digipad.digipad_formspec.."label[0,0;Enter Code:]")
	meta:set_string("baseChannel", "keypad");
	meta:set_int("channelExt",1)
end

local function beep(pos)
	minetest.sound_play("digipad_beep", {pos = pos, gain = .2})
end


-- functions from vector_extras
local set = vector.set_data_to_pos
local get = vector.get_data_from_pos
local remove = vector.remove_data_from_pos

local code_cache = {}
local function get_code(pos)
	return get(code_cache, pos.z,pos.y,pos.x) or ""
end
local function set_code(pos, code)
	set(code_cache, pos.z,pos.y,pos.x, code)
end
local function remove_code(pos)
	remove(code_cache, pos.z,pos.y,pos.x)
end

local function press_number_button(pos, meta, button)
	beep(pos)
	local code = get_code(pos)
	local codelen = #code --string.len(code)
	if codelen < 10 then
		set_code(pos, code..button)
		codelen = codelen+1
	else -- If code is really long, submit & start over
		digipad.submit(pos, meta:get_string("baseChannel")..meta:get_string("channelExt"), code)
		set_code(pos, button)
		codelen = 1
	end
	meta:set_string("formspec", digipad.digipad_formspec.."label[1,0;"..digipad.hidecode(codelen).."]")
end

-- accept or cancel
local function press_aoc(pos, meta, accept)
	if accept then
		local code = get_code(pos)
		if code == "" then
			return
		end
		digipad.submit(pos, meta:get_string("baseChannel")..meta:get_string("channelExt"), code)
		meta:set_string("formspec", digipad.digipad_formspec.."label[0,0;Enter Code:]")
		remove_code(pos)
		return
	end
	meta:set_string("formspec", digipad.digipad_formspec.."label[0,0;Enter Code:]")
	remove_code(pos)
end

digipad.recvFields = function(pos, _, fields)
	local meta = minetest.get_meta(pos)
	if fields.dcA then  --Accept button
		press_aoc(pos, meta, true)
		return
	end
	if fields.dcC -- Cancel button
	or fields.quit then
		press_aoc(pos, meta)
		return
	end
	for i = 1,3 do -- Channel button
		if fields["chan"..i] then
			meta:set_int("channelExt", i)
			return
		end
	end
	-- Number button
	local id = next(fields)
	local button = fields[id]
	if "dc"..button ~= id then
		return -- this shouldnt happen
	end
	press_number_button(pos, meta, button)
end

local button_order = {
	{1, 2, 3},
	{4, 5, 6},
	{7, 8, 9},
	{"c",0,"v"},
}

-- used for setting the code outside a formspec
local function punch_pad(pos, node, puncher, pt)
	if not (pos and node and puncher and pt) then
		return
	end
	-- abort if the node is punched not on the frontside
	if minetest.dir_to_facedir(vector.subtract(pt.under, pt.above)) ~= node.param2 then
		return
	end
	local dir = puncher:get_look_dir()
	local dist = vector.new(dir)

	local plpos = puncher:getpos()
	plpos.y = plpos.y+1.625

	local newtime,a,b,c,mpa,mpc
	b = "y"
	if node.param2 == 0 then
		a = "x"
		c = "z"
	elseif node.param2 == 1 then
		a = "z"
		c = "x"
		mpa = -1
	elseif node.param2 == 2 then
		a = "x"
		c = "z"
		mpc = -1
		mpa = -1
	elseif node.param2 == 3 then
		a = "z"
		c = "x"
		mpc = -1
	else
		return
	end

	mpa = mpa or 1
	mpc = mpc or 1
	local shpos = {[a]=pos[a], [b]=pos[b], [c]=pos[c]+6/16*mpc}

	dist[c] = shpos[c]-plpos[c]
	local m = dist[c]/dir[c]
	dist[a] = dist[a]*m
	dist[b] = dist[b]*m

	-- the exact position where it's pointed
	local newp = vector.add(plpos, dist)

	-- the exact position relative to the middle of the rect [-0.5,0.5]
	local tp = vector.subtract(newp, shpos)
	tp[a] = tp[a]*mpa
	tp[b] = -tp[b]

	local vert = tp[b]*32+16

	if vert < 6 then
		return
	end
	local line
	if vert < 12.5 then
		line = 1
	elseif vert < 18.5 then
		line = 2
	elseif vert < 24.5 then
		line = 3
	elseif vert <= 31 then
		line = 4
	else
		return
	end

	local hor = tp[a]*32+16

	if hor < 5 then
		return
	end
	local row
	if hor < 12 then
		row = 1
	elseif hor < 20 then
		row = 2
	elseif hor <= 27 then
		row = 3
	else
		return
	end

	local button = button_order[line][row]
	local meta = minetest.get_meta(pos)
	if button == "c" then
		press_aoc(pos, meta)
	elseif button == "v" then
		press_aoc(pos, meta, true)
	else
		press_number_button(pos, meta, tostring(button))
	end

	--[[ send the pressed buttons
	local pname = puncher:get_player_name()
	minetest.chat_send_player(pname, "button pressed: "..button)--]]
end


-- ========================
-- Begin node declarations
-- ========================

minetest.register_node("digipad:digipad", {
	description = "Digipad",
	tiles = {
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_front.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	walkable = true,
	inventory_image = "digicode_front.png",
	selection_box = {
		type = "fixed",
		fixed = { -6/16, -.5, 6/16, 6/16, .5, .5 }
	},
	node_box = {
		type = "fixed",
		fixed = { -6/16, -.5, 6/16, 6/16, .5, .5 }
	},
	groups = {choppy = 3, dig_immediate = 2, level = 3},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)	--Initialize some variables (local per instance)
		digipad.cons(pos)
		minetest.get_meta(pos):set_string("infotext", "Digipad")
	end,
	on_receive_fields = function(...)
		digipad.recvFields(...)
	end,
	on_punch = punch_pad,
	digiline = {receptor={action=function()end}},
})

minetest.register_node("digipad:digipad_hard", {
	description = "Hardened Digipad",
	tiles = {
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digicode_side.png",
		"digipad_hard_front.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	paramtype2 = "facedir",
	sunlight_propagates = true,
	walkable = true,
	digiline =
	{
		receptor={},
	},
	node_box = {
		type = "fixed",
		--All values -0.5 to 0.5, measured from center
		--- Left, down, depth of front, right, up, depth of back
		fixed = { -0.5, -.5, 1/4, 0.5, .5, 0.5}
	},
	inventory_image="digipad_hard_front.png",
	groups = {cracky=1,level=2},
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		digipad.cons(pos)
		meta:set_string("infotext", "Hardened Digipad")
	end,
	on_receive_fields = function(...)
		digipad.recvFields(...)
	end,
	on_punch = punch_pad,
})

-- ========================
--Crafting recipes
-- ========================

minetest.register_craft({
	output = 'digipad:digipad',
	recipe = {
		{"mesecons_button:button_off", "mesecons_button:button_off", "mesecons_button:button_off"},
		{"default:steel_ingot", "mesecons_luacontroller:luacontroller0000", "default:steel_ingot"},
		{"default:steel_ingot", "digilines:wire_std_00000000", "default:steel_ingot"},
	}
})

minetest.register_craft({
	output = 'digipad:digipad_hard',
	recipe = {
		{"default:steel_ingot", "default:steel_ingot", "default:steel_ingot"},
		{"default:steel_ingot", "digipad:digipad", "default:steel_ingot"},
		{"default:steel_ingot","digilines:wire_std_00000000","default:steel_ingot"},
	}
})
