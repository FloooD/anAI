local MAX = 65536 --max map width in tiles. ugly way but i think it's efficient overall

local function xy2n(x, y)
	return y * MAX + x
end

local function n2xy(n)
	local x = n % MAX
	return x, (n - x) / MAX
end

local function n2xy_pixel(n)
	local x = n % MAX
	return (32 * x + 16), (32 * (n - x) / MAX + 16)
end

local function hr_dist(na, nb)
	local ax, ay = n2xy(na)
	local bx, by = n2xy(nb)
	local delta_x = math.abs(ax - bx)
	local delta_y = math.abs(ay - by)
	return ((delta_x + delta_y) + math.abs(delta_x - delta_y) * (math.sqrt(2) - 1)) / math.sqrt(2)
end

--algorithm from wikipedia's A* article
local function astar_n(nstart, ngoal, nnn)
	local ret = {x = {}, y = {}}
	if not nnn[nstart] or not nnn[ngoal] then return ret end
	local closedset = {}
	local openset = {[nstart] = true}
	local came_from = {}
	
	local g_score = {[nstart] = 0}
	local f_score = {[nstart] = hr_dist(nstart, ngoal)}

	local next = next
	while next(openset) ~= nil do
		local cur, min_f_score
		for n, _ in pairs(openset) do
			if not min_f_score or f_score[n] < min_f_score then
				min_f_score = f_score[n]
				cur = n
			end
		end
		if cur == ngoal then
			local i = 0
			repeat
				i = i + 1
				ret.x[i], ret.y[i] = n2xy_pixel(cur)
				cur = came_from[cur]
			until not cur
			return ret
		end
		openset[cur] = nil
		closedset[cur] = true
		for i = 1, #nnn[cur] do
			local nnghbr, dist = nnn[cur][i][1], nnn[cur][i][2]
			local tg_score = g_score[cur] + dist
			local tf_score = tg_score + hr_dist(nnghbr, ngoal)
			if (not openset[nnghbr] and not closedset[nnghbr]) or tf_score < f_score[nnghbr] then
				came_from[nnghbr] = cur
				g_score[nnghbr] = tg_score
				f_score[nnghbr] = tf_score
				if not openset[nnghbr] then openset[nnghbr] = true end
			end
		end
	end
	return
end

local function get_map_nodes()
	local nn = {}
	local xsize, ysize = map("xsize"), map("ysize")
	for y = 0, ysize do
		for x = 0, xsize do
			if tile(x, y, "walkable") then
				nn[xy2n(x, y)] = {}
			end
		end
	end
	for n, nghbrs in pairs(nn) do
		local x, y = n2xy(n)
-- a b c
-- h   d
-- g f e
		local a,b,c,d,e,f,g,h = true,true,true,true,true,true,true,true

		if x <= 0 then a,g,h = false,false,false end
		if x >= xsize then c,d,e = false,false,false end
		if y <= 0 then a,b,c = false,false,false end
		if y >= ysize then e,f,g = false,false,false end

		if b then
			ng = xy2n(x,y-1)
			if nn[ng] then
				nghbrs[#nghbrs+1] = {ng,1}
			else
				a,c = false, false
			end
		end
		if d then
			ng = xy2n(x+1,y)
			if nn[ng] then
				nghbrs[#nghbrs+1] = {ng,1}
			else
				c,e = false, false
			end
		end
		if f then
			ng = xy2n(x,y+1)
			if nn[ng] then
				nghbrs[#nghbrs+1] = {ng,1}
			else
				e,g = false, false
			end
		end
		if h then
			ng = xy2n(x-1,y)
			if nn[ng] then
				nghbrs[#nghbrs+1] = {ng,1}
			else
				a,g = false, false
			end
		end
		if c then
			ng = xy2n(x+1,y-1)
			if nn[ng] then
				nghbrs[#nghbrs+1] = {ng,math.sqrt(2)}
			end
		end
		if e then
			ng = xy2n(x+1,y+1)
			if nn[ng] then
				nghbrs[#nghbrs+1] = {ng,math.sqrt(2)}
			end
		end
		if g then
			ng = xy2n(x-1,y+1)
			if nn[ng] then
				nghbrs[#nghbrs+1] = {ng,math.sqrt(2)}
			end
		end
		if a then
			ng = xy2n(x-1,y-1)
			if nn[ng] then
				nghbrs[#nghbrs+1] = {ng,math.sqrt(2)}
			end
		end
	end
	--[[ -- TODO: make bots teleport aware
	local ents = entitylist()
	for _, e in pairs(ents) do
		if entity(e.x, e.y, "type") == 70 then
			nn[txy2n(e.x, e.y)] = {{txy2n(entity(e.x, e.y, "int0"), entity(e.x, e.y, "int1")), 0}}
		end
	end
	--]]
	return nn
end
local map_nodes = get_map_nodes()

function anAI_makepath(srcx_tile, srcy_tile, destx_tile, desty_tile)
	return astar_n(xy2n(srcx_tile, srcy_tile), xy2n(destx_tile, desty_tile), map_nodes)
end
