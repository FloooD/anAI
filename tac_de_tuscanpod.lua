local a_site	= {75, 21}
local b_site	= {75, 72}
local t_1_top	= {52, 13}
local t_1_mid	= {52, 27}
local t_1_down	= {48, 58}
local a_camp_1	= {76, 23}
local a_camp_2	= {76, 16}
local a_camp_3	= {68, 23}
local a_camp_4	= {75, 39}
local a_camp_5	= {70, 29}

local function tac_t()
	if roundtime == 0 then
		anAI_tt.teambuy()
		anAI_tt.fivebots[1].addtarget(t_1_top[1], t_1_top[2])
		anAI_tt.fivebots[2].addtarget(t_1_top[1]+1, t_1_top[2])
		anAI_tt.fivebots[3].addtarget(t_1_mid[1], t_1_mid[2])
		anAI_tt.fivebots[4].addtarget(t_1_down[1]-2, t_1_down[2]+5)
		anAI_tt.fivebots[5].addtarget(t_1_down[1]-1, t_1_down[2])
	elseif roundtime == 14 then
		anAI_tt.fivebots[4].scan(math.rad(120))
		anAI_tt.fivebots[5].scan(math.rad(136))
	elseif roundtime == 20 then
		anAI_tt.fivebots[4].addtarget(a_camp_4[1], a_camp_4[2])
		anAI_tt.fivebots[5].addtarget(a_camp_5[1], a_camp_5[2])
	elseif roundtime == 22 then
		anAI_tt.fivebots[1].addtarget(a_site[1], a_site[2])
		anAI_tt.fivebots[2].addtarget(a_camp_1[1], a_camp_1[2])
	elseif roundtime == 25 then
		anAI_tt.fivebots[3].addtarget(a_camp_3[1], a_camp_3[2])
	elseif roundtime == bombplanttime + 30 then
		anAI_tt.fivebots[1].addtarget(t_1_top[1], t_1_top[2])
		anAI_tt.fivebots[2].addtarget(t_1_top[1]-1, t_1_top[2])
		anAI_tt.fivebots[3].addtarget(t_1_top[1]+1, t_1_top[2])
		anAI_tt.fivebots[4].addtarget(t_1_top[1], t_1_top[2]+1)
		anAI_tt.fivebots[5].addtarget(t_1_top[1], t_1_top[2]-1)
	end
end

local function tac_ct()

end

function tac()
	tac_t()
	tac_ct()
end
