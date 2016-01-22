digipad = {}
dofile(minetest.get_modpath("digipad").."/terminal.lua")  -- add terminal to mod
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
	digiline:receptor_send(pos, digiline.rules.default, channel, number)
end

digipad.cons = function (pos)
	local meta = minetest.get_meta(pos)
	meta:set_string("formspec", digipad.digipad_formspec.."label[0,0;Enter Code:]")
	meta:set_string("code", "")
	meta:set_string("baseChannel", "keypad");
	meta:set_int("channelExt",1)
end

digipad.recvFields = function(pos,formname,fields,sender)
	local meta = minetest.get_meta(pos)
	if fields.dcC then -- Cancel button
		meta:set_string("formspec", digipad.digipad_formspec.."label[0,0;Enter Code:]")
		meta:set_string("code", "")
		return
	end
	for i = 1,3 do -- Channel button
		if fields["chan"..i] then
			meta:set_int("channelExt", i)
			return
		end
	end
	local code = meta:get_string("code")
	if fields.dcA then  --Accept button
		if code == "" then
			return
		end
		digipad.submit(pos, meta:get_string("baseChannel")..meta:get_string("channelExt"), code)
		meta:set_string("formspec", digipad.digipad_formspec.."label[0,0;Enter Code:]")
		meta:set_string("code", "")
		return
	end
	-- Number button
	local codelen = string.len(code)
	for button = 0,9 do
		button = tostring(button)
		if fields["dc"..button] then
			if codelen < 10 then
				meta:set_string("code", code..button)
				codelen = codelen+1
			else -- If code is really long, submit & start over
				digipad.submit(pos, meta:get_string("baseChannel")..meta:get_string("channelExt"), code)
				meta:set_string("code", button)
				codelen = 1
			end
			meta:set_string("formspec", digipad.digipad_formspec.."label[1,0;"..digipad.hidecode(codelen).."]")
			return
		end
	end
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
		fixed = { -6/16, -.5, 6/17, 6/16, .5, .5 }
	},
	digiline = {
		receptor = {},
	},
	groups = {choppy = 3, dig_immediate = 2},
	sounds = default.node_sound_stone_defaults(),
	on_construct = function(pos)	--Initialize some variables (local per instance)
		digipad.cons(pos)
		minetest.get_meta(pos):set_string("infotext", "Digipad")
	end,
	on_receive_fields = function(...)
		digipad.recvFields(...)
	end

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
	end
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
