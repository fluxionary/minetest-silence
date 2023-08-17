silence = fmod.create()

local radius = silence.settings.radius
local delta = vector.new(radius, radius, radius)

minetest.register_node("silence:silencer", {
	description = "Sound Silencer",
	tiles = { "silence.png" },
	groups = { oddly_breakable_by_hand = 2 },
})

if minetest.get_modpath("wool") then
	minetest.register_craft({
		output = "silence:silencer",
		recipe = {
			{ "wool:white", "wool:white", "wool:white" },
			{ "wool:white", "wool:white", "wool:white" },
			{ "wool:white", "wool:white", "wool:white" },
		},
	})
end

local find_nodes_in_area = minetest.find_nodes_in_area

local function should_silence_in_area(pos)
	local p1 = vector.subtract(pos, delta)
	local p2 = vector.add(pos, delta)
	local found = find_nodes_in_area(p1, p2, { "silence:silencer" }, true)
	return #found > 0
end

local old_sound_play = minetest.sound_play

-- luacheck: push globals minetest.sound_play
function minetest.sound_play(spec, parameters, ephemeral)
	if parameters then
		if parameters.pos then
			local pos = parameters.pos
			if should_silence_in_area(pos) then
				silence.log(
					"info",
					"[silence] silenced %s at %s",
					tostring(minetest.write_json(spec)),
					minetest.pos_to_string(pos)
				)
				return
			end
		elseif parameters.object then
			local pos = parameters.object:get_pos()
			if not pos then
				silence.log(
					"warning",
					"[silence] sound object has no position? %s",
					tostring(minetest.write_json(spec))
				)
				return
			elseif should_silence_in_area(pos) then
				silence.log(
					"info",
					"[silence] silenced %s at %s",
					tostring(minetest.write_json(spec)),
					minetest.pos_to_string(pos)
				)
				return
			end
		elseif parameters.to_player then
			local player = minetest.get_player_by_name(parameters.to_player)
			if player then
				local pos = player:get_pos()
				if should_silence_in_area(pos) then
					silence.log(
						"info",
						"[silence] silenced %s at %s",
						tostring(minetest.write_json(spec)),
						minetest.pos_to_string(pos)
					)
					return
				end
			end
		end
	end
	return old_sound_play(spec, parameters, ephemeral)
end
-- luacheck: pop
