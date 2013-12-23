--[[ todo
scans
countering offscreens
cant do shit when flashed
unaware of fow
camping
reloading
picking up bomb
chasing down enemy
twitching
defusing
teleports
more tactics
]]

parse("bot_prefix \"anAI | \"")

local mapfile = "bots/tac_"..map("name")..".lua"
local f = io.open(mapfile)
if f then
	f:close()
	dofile(mapfile)
else
	print("bots have no tactics for current map")
end

dofile("bots/buf.lua")
dofile("bots/astar.lua")

roundtime = 0
function anAI_incrementtime()
	roundtime = roundtime + 1
	if tac then tac() end
end

bombplanttime = 12345
function anAI_onbombplant()
	bombplanttime = roundtime
end
addhook("bombplant", "anAI_onbombplant")

local function isalive(id)
	local h = player(id, "health")
	return h and h > 0
end

local function newbot(id)
	local currentenemy = 0
	local strafecount = 0
	local strafedirection = math.random(0,1)
	local path = {x = {}, y = {}} -- x = {destination_x, ... , source_x}, y = {destination_y, ... , source_y}
	local pathindex = 0
	local firsttarget, lasttarget --linked list
	local bestwpn = 50
	local state = 0 -- 0 - camping, 1 - moving, 2 - attacking, 3 - scanning
	local rot = 0

	local function attack(secondary) ai_attack(id, secondary) end
	local function freeline(x, y) return ai_freeline(id, x, y) end
	local function iattack() ai_iattack(id) end
	local function move(angle_deg, walk) ai_move(id, angle_deg, walk) end
	local function reload() ai_reload(id) end
	local function rotate(angle_rad) rot = angle_rad end --CUZ DC DOESNT INTO ROTATION
	local function selectweapon(itemtype) ai_selectweapon(id, itemtype) end
	local function use() ai_use(id) end

	local function getx() return player(id, "x") end
	local function gety() return player(id, "y") end

	local function onscreen(x, y)
		return math.abs(x - getx()) <= 332 and math.abs(y - gety()) <= 252
	end

	local function canseeandhit(enemy, frames)
		local ix, iy = anAI_get_past_pos(id, frames)
		local ex, ey = anAI_get_past_pos(enemy, frames)
		return ix >= 0 and ex >= 0 and math.abs(ex - ix) <= 332 and math.abs(ey - iy) <= 252 and freeline(ex, ey)
	end

	local function strafe() -- approximately perpendicular to angle
		if strafecount == 0 then
			strafecount = math.random(10, 25) -- strafe behavior controlled by this
			strafedirection = 1 - strafedirection
		end
		strafecount = strafecount - 1
		move(90 + 180 * strafedirection + 45 * math.floor(4 * rot / math.pi + 0.5))
	end

	local function shoot(enemy)
		if not isalive(enemy) then return end
		local ex, ey = anAI_get_past_pos(enemy, 5)
		if ex < 0 then return end
		local angle_rad = math.atan2(ex - getx(), gety() - ey)
		rotate(angle_rad)
		strafe()
		iattack()
	end

	local function updatepath()
		path = anAI_makepath(math.floor(getx() / 32), math.floor(gety() / 32), firsttarget.x_tile, firsttarget.y_tile)
		pathindex = #path.x
		rotate(math.atan2((16 + 32 * firsttarget.x_tile) - getx(), gety() - (16 + 32 * firsttarget.y_tile)))
	end

	local function movetonode()
		if pathindex == 0 then return 0 end
		local sx, sy = getx(), gety()
		local dx, dy = path.x[pathindex] - sx, sy - path.y[pathindex]
		while math.abs(dx) < 4 and math.abs(dy) < 4 do
			pathindex = pathindex - 1
			if pathindex == 0 then return 0 end
			dx, dy = path.x[pathindex] - sx, sy - path.y[pathindex]
		end
		move(45 * math.floor(4 * math.atan2(dx, dy) / math.pi + 0.5))
		
		return 1
	end

	local function movetotargets()
		if not firsttarget then return 0 end
		while movetonode() == 0 do
			firsttarget = firsttarget.nexttarget
			if not firsttarget then return 0 end
			updatepath()
		end
		return 1
	end

	local function searchenemy()
		for _, enemy in pairs(player(0, player(id, "team") == 1 and "team2living" or "team1living")) do
			if canseeandhit(enemy, 20) then return enemy end
		end
		return 0
	end

	local function updatebestwpn()
		local backup = 50
		for _, wpn in pairs(playerweapons(id)) do
			if wpn <=6 then backup = wpn end
			if wpn >=20 and wpn <=40 then
				bestwpn = wpn
				return
			end
		end
		bestwpn = backup
	end

	local function setstate(newstate)
		state = newstate
		if state == 1 then
			selectweapon(50)
		elseif state == 0 or state == 2 or state == 3 then
			selectweapon(bestwpn)
		end
	end

	--public
	local self = {
		extraguns = 0
	}

	function self.buy(itemtype)
		ai_buy(id, itemtype)
		updatebestwpn()
		setstate(state)
	end

	function self.drop()
		ai_drop(id)
		updatebestwpn()
		setstate(state)
	end

	function self.oncollect()
		updatebestwpn()
		setstate(state)
	end

	function self.startround()
		currentenemy = 0
		strafecount = 0
		self.extraguns = 0
		pathindex = 0
		state = 0
		firsttarget = nil
		updatebestwpn()
		setstate(state)
	end
	
	function self.addtarget(x_tile, y_tile)
		local target = {x_tile = x_tile, y_tile = y_tile, nexttarget = nil}
		if not firsttarget then
			firsttarget = target
			lasttarget = target
			updatepath()
		else
			lasttarget.nexttarget = target
			lasttarget = target
		end
		if state == 0 or state == 3 then setstate(1) end
	end

	function self.scan(angle_rad)
		rotate(angle_rad)
		setstate(3)
	end

	function self.update()
		if player(id, "ai_flash") > 1 then
			if state == 2 then
				strafe()
				attack()
				return
			end
		elseif currentenemy == 0 then
			currentenemy = searchenemy()
			if currentenemy > 0 then
				setstate(2)
			end
		elseif not isalive(currentenemy) or not canseeandhit(currentenemy, 5) then
			currentenemy = searchenemy()
			if currentenemy > 0 then
				setstate(2)
			elseif firsttarget then
				updatepath()
				setstate(1)
			else
				setstate(0)
			end
		else
			--state should be 2
		end

		if state == 0 then
			rotate(rot + 0.01)
			if player(id, "bomb") then
				if inentityzone(math.floor(getx() / 32), math.floor(gety() / 32), 5) then
					selectweapon(55)
					attack()
				end
			end
		elseif state == 1 then
			if movetotargets() == 0 then setstate(0) end
		elseif state == 2 then
			shoot(currentenemy)
		elseif state == 3 then
			iattack()
		end
		ai_rotate(id, math.deg(rot)) --if this isn't called every frame, ai_rotate isn't instant. damn it DC
	end

	return self
end

local function newbotteam(side) -- side == 1 for t, 2 for ct
	local side = side
--	local round = 0
	local eco = false

	--public
	local self = {
		bots = {},
		fivebots = {}
	}
	
	function self.startround()
--		round = round + 1
		local i = 1
		local bomber = 0
		for id, bot in pairs(self.bots) do
			if player(id, "bomb") then
				self.fivebots[i] = bot
				i = i + 1
				bomber = id
				break
			end
		end
		for id, bot in pairs(self.bots) do 
			if id ~= bomber then
				self.fivebots[i] = bot
				i = i + 1
				if i > 5 then break end
			end
		end
	end
	
	function self.teambuy()
		local gunprice = (side == 1) and 2500 or 3100
		local guntype = (side == 1) and 30 or 32
		local extra, need = 0, 0

		for id, bot in pairs(self.bots) do
			local hasgun = 0
			for _, wpn in pairs(playerweapons(id)) do
				if wpn == 32 or wpn == 30 then
					hasgun = 1
					break
				end
			end
			bot.extraguns = math.floor(player(id, "money") / gunprice) + hasgun - 1
			if bot.extraguns < 0 then
				need = need + 1
			else
				extra = extra + bot.extraguns
			end
		end

		eco = need > extra
		if eco then return end

		for id, bot in pairs(self.bots) do
			if bot.extraguns >= 0 then bot.buy(guntype) end
		end

		while need > 0 do
			local dropper
			for id, bot in pairs(self.bots) do
				if bot.extraguns > 0 then
					bot.drop()
					bot.buy(guntype)
					bot.extraguns = bot.extraguns - 1
					dropper = id
					break
				end
			end
			for id, bot in pairs(self.bots) do
				if bot.extraguns < 0 then
					bot.extraguns = 0
					bot.addtarget(player(dropper, "xtile"), player(dropper, "ytile"))
					break
				end
			end
			need = need - 1
		end

		for id, bot in pairs(self.bots) do
			if side == 2 then bot.buy(56) end
			bot.buy(57)
			bot.buy(61)
		end
	end

	return self
end

anAI_tt, anAI_ct = newbotteam(1), newbotteam(2)

addhook("startround", "anAI_startround")
function anAI_startround()
	for id = 1, 32 do
		if player(id, "bot") then
			local team = player(id, "team")
			if team == 1 then
				if not anAI_tt.bots[id] then anAI_tt.bots[id] = newbot(id) end
				if anAI_ct.bots[id] then anAI_ct.bots[id] = nil end
				anAI_tt.bots[id].startround()
			elseif team == 2 then
				if not anAI_ct.bots[id] then anAI_ct.bots[id] = newbot(id) end
				if anAI_tt.bots[id] then anAI_tt.bots[id] = nil end
				anAI_ct.bots[id].startround()
			else
				if anAI_tt.bots[id] then anAI_tt.bots[id] = nil end
				if anAI_ct.bots[id] then anAI_ct.bots[id] = nil end
			end
		else
			if anAI_tt.bots[id] then anAI_tt.bots[id] = nil end
			if anAI_ct.bots[id] then anAI_ct.bots[id] = nil end
		end
	end
	anAI_tt.startround()
	anAI_ct.startround()

	freetimer("anAI_incrementtime")
	roundtime = -game("mp_freezetime")
	timer(1000, "anAI_incrementtime", "", 0)
end

function ai_update_living(id)
	local bot = anAI_tt.bots[id] or anAI_ct.bots[id]
	if bot then bot.update() end
end

function ai_onspawn(id) end
function ai_update_dead(id) end
function ai_hear_radio(id) end
function ai_hear_chat(id) end

addhook("collect", "anAI_oncollect")
function anAI_oncollect(id)
	local bot = anAI_tt.bots[id] or anAI_ct.bots[id]
	if bot then bot.oncollect() end
end

--[
addhook("serveraction", "wat")
function wat()
	local bot = anAI_tt.bots[2] or anAI_ct.bots[2]
	if not bot then return end
	bot.addtarget(player(1, "tilex"), player(1, "tiley"))
end
--]]
