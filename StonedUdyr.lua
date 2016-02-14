--[[
	StonedUdyr
	by uhGery
	V 0.8
]]--
local version = "0.8"

local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/uhGery/BoL/master/StonedUdyr.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local lastRG = 0
local lastICFJ = 0
local lastIDCF = 0
local lastICF = 0
local loaded = false
local MyTrueRange = 190
local phoenix = false
local turtle = false
local tiger = false
local bear = false
local tigerT = 0
local bearT = 0
local stuned = 0
local stunT = 0
local tigerTJC = 0
local tigerTLC = 0

if FileExist(LIB_PATH .. "/AllClass.lua") then
	require "AllClass"
end

function _AutoupdaterMsg(msg) print("<font color=\"#1C942A\">Stoned</font><font color =\"#DBD142\">Udyr</font> <font color=\"#FFFFFF\">"..msg..".</font>") end

if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/uhGery/BoL/master/Version/StonedUdyr.version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				_AutoupdaterMsg("New version available "..ServerVersion)
				_AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () _AutoupdaterMsg("Successfully updated. ("..version.." >= "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				_AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		_AutoupdaterMsg("Error downloading version info")
	end
end

if myHero.charName ~= "Udyr" then return end

Spells = {
	spellQ = {range = 190}, 
	spellW = {range = 190},
	spellE = {range = 190},
	spellR = {range = 190},
}

function readyCheck()
	QREADY, WREADY, EREADY, RREADY = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
	
end

function orbwalkCheck()
	if _G.AutoCarry then
		PrintChat("SA:C detected, support enabled.")
		SACLoaded = true
	elseif _G.MMA_Loaded then
		PrintChat("MMA detected, support enabled.")
		MMALoaded = true
	else
		PrintChat("SA:C/MMA not running, loading SxOrbWalk.")
		require("SxOrbWalk")
		SxMenu = scriptConfig("SxOrbWalk", "SxOrb")
		SxOrb:LoadToMenu(SxMenu)
		SACLoaded = false
	end
end

ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 800, DAMAGE_MAGIC)
local JungleMinions = minionManager(MINION_JUNGLE, 600, myHero, MINION_SORT_MAXHEALTH_DEC)
local EnemyMinions = minionManager(MINION_ENEMY, 600, myHero, MINION_SORT_MAXHEALTH_DEC)

function getTarg()
	ts:update()
	if _G.AutoCarry and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then _G.AutoCarry.Crosshair:SetSkillCrosshairRange(800) return _G.AutoCarry.Crosshair:GetTarget() end		
	if ValidTarget(SelectedTarget) and SelectedTarget.type == myHero.type then return SelectedTarget end
	if MMALoaded and ValidTarget(_G.MMA_Target) then return _G.MMA_Target end
	return ts.target
end

function getHealthPercent(unit)
    local obj = unit or myHero
    return (obj.health / obj.maxHealth) * 100
end

function getManaPercent(unit)
    local obj = unit or myHero
    return (obj.mana / obj.maxMana) * 100
end

function OnLoad()
	if not loaded then
		loaded = true
		DrawMenu()
		
		print("<font color=\"#1C942A\">Stoned</font><font color =\"#DBD142\">Udyr</font> <font color =\"#FF0000\">by uhGery</font> <font color =\"#000000\">V"..version.."</font>")

		Config.KeySettings:permaShow("Combo")
		Config.KeySettings:permaShow("Clear")

		if _G.Reborn_Initialised then
			orbwalkCheck()
		elseif _G.Reborn_Loaded then
			DelayAction(OnLoad, 1)
			return
		else
			orbwalkCheck()
		end
		
	end
	AddApplyBuffCallback(Buff_Add)
	AddRemoveBuffCallback(Buff_Rem)
end

function DrawMenu()
	Config = scriptConfig("StonedUdyr", "uhGery")
	TargetSelector.name = "Udyr"
	Config:addTS(ts)
	
	Config:addSubMenu("[Key Binding]", "KeySettings")
		Config.KeySettings:addParam("Combo", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte ("32"))
		Config.KeySettings:addParam("Harass", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte ("C"))
		Config.KeySettings:addParam("Clear", "Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte ("V"))
		Config.KeySettings:addParam("LastHit", "LastHit Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte ("X"))
	
	Config:addSubMenu("[Combo]", "ComboSettings")
		Config.ComboSettings:addParam("StyleCombo", "Style Combo", SCRIPT_PARAM_LIST, 1, {"Tiger", "Phoenix"})
		Config.ComboSettings:addParam("manaQ", "% mana min for use Q", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.ComboSettings:addParam("manaW", "% mana min for use W", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.ComboSettings:addParam("lifeW", "% life min for use W", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.ComboSettings:addParam("manaE", "% mana min for use E", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.ComboSettings:addParam("manaR", "% mana min for use R", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
	
	Config:addSubMenu("[Harass]", "HarassSettings")
		Config.HarassSettings:addParam("UseQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, true)
		Config.HarassSettings:addParam("UseW", "Use W in Harass", SCRIPT_PARAM_ONOFF, true)
		Config.HarassSettings:addParam("UseE", "Use E in Harass", SCRIPT_PARAM_ONOFF, true)
		Config.HarassSettings:addParam("UseR", "Use R in Harass", SCRIPT_PARAM_ONOFF, true)
	
	Config:addSubMenu("[Laneclear]", "LaneclearSettings")
		Config.LaneclearSettings:addParam("UseQ", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
		Config.LaneclearSettings:addParam("manaQ", "% mana min for use Q", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.LaneclearSettings:addParam("UseW", "Use W in Laneclear", SCRIPT_PARAM_ONOFF, true)
		Config.LaneclearSettings:addParam("manaW", "% mana min for use W", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.LaneclearSettings:addParam("UseE", "Use E in Laneclear", SCRIPT_PARAM_ONOFF, true)
		Config.LaneclearSettings:addParam("manaE", "% mana min for use E", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.LaneclearSettings:addParam("UseR", "Use R in Laneclear", SCRIPT_PARAM_ONOFF, true)
		Config.LaneclearSettings:addParam("manaR", "% mana min for use R", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		
	Config:addSubMenu("[Jungleclear]", "JungleclearSettings")
		Config.JungleclearSettings:addParam("StyleJC", "Style Jungleclear", SCRIPT_PARAM_LIST, 1, {"Tiger", "Phoenix"})
		Config.JungleclearSettings:addParam("manaQ", "% mana min for use Q", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.JungleclearSettings:addParam("manaW", "% mana min for use W", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.JungleclearSettings:addParam("manaR", "% mana min for use R", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		
	Config:addSubMenu("[Auto]", "Auto")
		Config.Auto:addParam("autoPots", "Auto Potions usage", SCRIPT_PARAM_ONOFF, true)
		Config.Auto:addParam("autoPotsHealth", "% Health for autopots", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		Config.Auto:addParam("upgradeTB", "Buy Trinket Blue", SCRIPT_PARAM_ONOFF, true)
		Config.Auto:addParam("autolevel","Auto level", SCRIPT_PARAM_ONOFF, false)
		Config.Auto:addParam("levels","Select style", SCRIPT_PARAM_LIST, 1, {"Tiger","Phoenix"})
	
end

function OnDraw()
	if myHero.dead then return end
		DrawCircle(myHero.x, myHero.y, myHero.z, MyTrueRange, ARGB(255, 255, 0, 0))
end

function OnTick()
	readyCheck()
	Target = getTarg()
	Combo()	
	Laneclear()
	Jungleclear()
	Harass()
	AutoPotion() 
	StunCheck()
	if VIP_USER and Config.Auto.autolevel then
		local levelSequenceT = {nil,2,3,1,1,2,1,2,1,2,3,2,3,3,3,4,4,4}
		local levelSequenceP = {nil,2,3,4,4,2,4,2,4,2,3,2,3,3,3,1,1,1}
		if Config.Auto.levels == 1 then
			autoLevelSetSequence(levelSequenceT)
		else 
			autoLevelSetSequence(levelSequenceP)
		end
	end
end

function Combo()
	if Config.KeySettings.Combo and  Config.ComboSettings.StyleCombo == 1 and ValidTarget(Target) and not Target.dead then
		if myHero.level >= 3 then
			if not stuned then
				if not bear and EREADY and GetDistance(Target) <= 650 and getManaPercent() >= Config.ComboSettings.manaE then
						CastSpell(_E)
						tiger = false
						turtle = false
						phoenix = false
						stunT = os.clock()
					end
			if stuned then
				if os.clock() - stunT < 6 then return end
					if GetDistance(Target) <= 650 and not bear and getManaPercent() >= Config.ComboSettings.manaE then
						CastSpell(_E)
						phoenix = false
						turtle = false
						tiger = false
						stunT = os.clock()
					end
			end
		end
			if not tiger and QREADY and GetDistance(Target) <= 250 and getManaPercent() >= Config.ComboSettings.manaQ and stuned then
					CastSpell(_Q)
					phoenix = false
					turtle = false
					bear = false
				end
			if not turtle and WREADY and getHealthPercent() <= Config.ComboSettings.lifeW and getManaPercent() >= Config.ComboSettings.manaW then
					CastSpell(_W)
					phoenix = false
					tiger = false
					bear = false
			end
		end
		if myHero.level <= 2 then
			if not tiger and QREADY and GetDistance(Target) <= 250 and getManaPercent() >= Config.ComboSettings.manaQ then
					CastSpell(_Q)
					phoenix = false
					turtle = false
					bear = false
				end
			if not turtle and WREADY and getHealthPercent() <= Config.ComboSettings.lifeW and getManaPercent() >= Config.ComboSettings.manaW then
					CastSpell(_W)
					phoenix = false
					tiger = false
					bear = false
			end
		end
	end
	
	if Config.KeySettings.Combo and  Config.ComboSettings.StyleCombo == 2 and ValidTarget(Target) and not Target.dead then
		if myHero.level >= 3 then
			if not stuned then
				if not bear and EREADY and GetDistance(Target) <= 650 and getManaPercent() >= Config.ComboSettings.manaE then
					CastSpell(_E)
					tiger = false
					turtle = false
					phoenix = false
					stunT = os.clock()
				end
				if stuned then
					if os.clock() - stunT < 6 then return end
						if GetDistance(Target) <= 650 and not bear and getManaPercent() >= Config.ComboSettings.manaE then
							CastSpell(_E)
							phoenix = false
							turtle = false
							tiger = false
							stunT = os.clock()
						end
				end
			end
			if not phoenix and RREADY and GetDistance(Target) <= 250 and getManaPercent() >= Config.ComboSettings.manaR and stuned then
				CastSpell(_R)
				turtle = false
				tiger = false
				bear = false
			end
			if not turtle and WREADY and getHealthPercent() <= Config.ComboSettings.lifeW and getManaPercent() >= Config.ComboSettings.manaW then
				CastSpell(_W)
				phoenix = false
				tiger = false
				bear = false
			end
		end
	
	if myHero.level <= 2 then
			if not phoenix and RREADY and GetDistance(Target) <= 250 and getManaPercent() >= Config.ComboSettings.manaR then
				CastSpell(_R)
				turtle = false
				tiger = false
				bear = false
			end
			if not turtle and WREADY and getHealthPercent() <= Config.ComboSettings.lifeW and getManaPercent() >= Config.ComboSettings.manaW then
				CastSpell(_W)
				phoenix = false
				tiger = false
				bear = false
			end
		end
	end
end

function Jungleclear()
	if Config.KeySettings.Clear then
		JungleMinions:update()
		Target = nil
		for i, minion in pairs(JungleMinions.objects) do
				if ValidTarget(minion) and not minion.dead then
					if Target == nil then
						Target = minion
					elseif GetDistance(minion) < GetDistance(Target) then
						Target = minion
					end
				end
		end
			if Target ~= nil and ValidTarget(Target) and Config.JungleclearSettings.StyleJC == 1 then
					if not tiger and QREADY and GetDistance(Target) <= Spells.spellQ.range and getManaPercent() >= Config.JungleclearSettings.manaQ then 
						CastSpell(_Q)
						turtle = false
						phoenix = false
						bear = false
					end
				if not turtle and WREADY and GetDistance(Target) <= Spells.spellW.range and getManaPercent() >= Config.JungleclearSettings.manaW then
					if turtle then return end
						CastSpell(_W)
						tiger = false
						phoenix = false		
						bear = false
				end
			end
			if Target ~= nil and ValidTarget(Target) and Config.JungleclearSettings.StyleJC == 2 then
				if RREADY and not phoenix and GetDistance(Target) <= Spells.spellR.range and getManaPercent() >= Config.JungleclearSettings.manaR then
					CastSpell(_R)
					turtle = false
					bear = false
					tiger = false
				end
				if not turtle and WREADY and GetDistance(Target) <= Spells.spellW.range and getManaPercent() >= Config.JungleclearSettings.manaW then
					CastSpell(_W)
					tiger = false
					phoenix = false	
					bear = false					
				end
			end
		end
end

function Laneclear()
	if Config.KeySettings.Clear then
		EnemyMinions:update()
			for i, minion in pairs(EnemyMinions.objects) do
				if ValidTarget(minion) and not minion.dead then
					if GetDistance(minion) < Spells.spellE.range then 
						if Target == nil then
							Target = minion
						elseif GetDistance(minion) < GetDistance(Target) then
							Target = minion
						end
					end
				end
			end
			if Target ~= nil and ValidTarget(Target) then
				if not tiger and QREADY and Config.LaneclearSettings.UseQ and GetDistance(Target) <= Spells.spellQ.range and getManaPercent() >= Config.LaneclearSettings.manaQ then
					CastSpell(_Q)
					turtle = false
					phoenix = false
					bear = false
				end
				if not turtle and WREADY and Config.LaneclearSettings.UseW and GetDistance(Target) <= Spells.spellW.range and getManaPercent() >= Config.LaneclearSettings.manaW then 
					CastSpell(_W)
					tiger = false
					phoenix = false
					bear = false
				end
				if not bear and EREADY and Config.LaneclearSettings.UseE and GetDistance(Target) <= Spells.spellE.range and getManaPercent() >= Config.LaneclearSettings.manaE then 
					CastSpell(_E)
					turtle = false
					phoenix = false
					tiger = false
				end
				if not phoenix and RREADY and Config.LaneclearSettings.UseR and GetDistance(Target) <= Spells.spellR.range and getManaPercent() >= Config.LaneclearSettings.manaR then 
					CastSpell(_R)
					turtle = false
					bear = false
					tiger = false
				end
			end
	end
end

function Harass()
	if Config.KeySettings.Harass then
		if Target and ValidTarget(Target) and not Target.dead then
			if not bear and EREADY and Config.HarassSettings.UseE and GetDistance(Target) <= Spells.spellE.range then CastSpell(_E) end
			if not tiger and QREADY and Config.HarassSettings.UseQ and GetDistance(Target) <= Spells.spellQ.range then CastSpell(_Q) end
			if not phoenix and RREADY and Config.HarassSettings.UseR and GetDistance(Target) <= Spells.spellR.range then CastSpell(_R) end
			if not turtle and WREADY and Config.HarassSettings.UseW and GetDistance(Target) <= Spells.spellW.range then CastSpell(_W) end
		end
	end
end

function ValidRequest()
    if os.clock() - LastRequest < TimeRequest() then
        return false
    else
        LastRequest = os.clock()
        return true
    end
end

function AutoPotion()

if os.clock() - lastRG < 15 then return end
	for SLOT = ITEM_1, ITEM_6 do
		if myHero:GetSpellData(SLOT).name == "RegenerationPotion"  then
			if myHero:CanUseSpell(SLOT) == READY and getHealthPercent() <= Config.Auto.autoPotsHealth then
				CastSpell(SLOT)	
				lastRG = os.clock()				
			end
		end
	end

if os.clock() - lastICF < 12 then return end
	for SLOT = ITEM_1, ITEM_6 do
		if myHero:GetSpellData(SLOT).name == "ItemCrystalFlask"  then
			if myHero:CanUseSpell(SLOT) == READY and getHealthPercent() <= Config.Auto.autoPotsHealth then
				CastSpell(SLOT)	
				lastICF = os.clock()				
			end
		end
	end
if os.clock() - lastICFJ < 8 then return end
	for SLOT = ITEM_1, ITEM_6 do
		if myHero:GetSpellData(SLOT).name == "ItemCrystalFlaskJungle"  then
			if myHero:CanUseSpell(SLOT) == READY and getHealthPercent() <= Config.Auto.autoPotsHealth then
				CastSpell(SLOT)	
				lastICFJ = os.clock()				
			end
		end
	end
if os.clock() - lastIDCF < 12 then return end
	for SLOT = ITEM_1, ITEM_6 do
		if myHero:GetSpellData(SLOT).name == "ItemDarkCrystalFlask"  then
			if myHero:CanUseSpell(SLOT) == READY and getHealthPercent() <= Config.Auto.autoPotsHealth then
				CastSpell(SLOT)	
				lastIDCF = os.clock()				
			end
		end
	end
end

function StunCheck()
	if TargetHaveBuff("udyrbearstuncheck", Target) then
		stuned = true
		end
	if not TargetHaveBuff("udyrbearstuncheck", Target) then
		stuned = false
	end
end

function Buff_Add(unit, buff)
	for i = 1, myHero.buffCount do
        local tBuff = myHero:getBuff(i)
        if BuffIsValid(tBuff) then
			if tBuff.name == "udyrtigerpunch" then
				tiger = true
			end
			if tBuff.name == "udyrturtleactivation" then
				turtle = true
			end
			if tBuff.name == "udyrbearactivation" then
				bear = true
			end
			if tBuff.name =="udyrphoenixactivation" then
				phoenix = true
			end
		end
	end
end	

function Buff_Rem(unit, buff)
	for i = 1, myHero.buffCount do
        local tBuff = myHero:getBuff(i)
        if BuffIsValid(tBuff) then
			if tBuff.name == "udyrtigerpunch" then
				tiger = false
			end
			if tBuff.name == "udyrturtleactivation" then
				turtle = false
			end
			if tBuff.name == "udyrbearactivation" then
				bear = false
			end
			if tBuff.name =="udyrphoenixactivation" then
				phoenix = false
			end
		end
	end
	if buff.name == "recall" and unit.isMe then
		if myHero.level >= 9 then
			if Config.Auto.UpgradeTB then
				BuyItem(3363)
			end
		end
	end
end		

