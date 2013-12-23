local buf_x, buf_y = {}, {}
local buf_size = 32
local buf_index = buf_size
for i = 1, buf_size do
	buf_x[i] = {}
	buf_y[i] = {}
end

function anAI_update_buf()
	buf_index = (buf_index % buf_size) + 1
	for id = 1, 32 do
		buf_x[buf_index][id], buf_y[buf_index][id] = player(id, "x") or -1, player(id, "y") or -1
	end
end
addhook("always", "anAI_update_buf")

function anAI_get_past_pos(id, frames)
	if frames < 1 then return player(id, "x"), player(id, "y") end
	if frames >= buf_size then frames = 0 end
	local ind = (buf_index - frames) % buf_size + 1
	return buf_x[ind][id], buf_y[ind][id]
end
