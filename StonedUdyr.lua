--[[
	StonedUdyr
	by uhGery
	V0.1
]]--
local version = "0.1"

local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/uhGery/BoL/master/StonedUdyr.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH

function _AutoupdaterMsg(msg) print("<font color=\"#1C942A\">Stoned</font><font color =\"#DBD142\">Udyr</font> <font color=\"#FFFFFF\">"..msg..".</font>") end
if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/uhGery/BoL/master/Version/StonedUdyr.version")
	if ServerData then
		ServerVersion = type(tonumber(ServerData)) == "number" and tonumber(ServerData) or nil
		if ServerVersion then
			if tonumber(version) < ServerVersion then
				_AutoupdaterMsg("New version available "..ServerVersion)
				_AutoupdaterMsg("Updating, please don't press F9")
				DelayAction(function() DownloadFile(UPDATE_URL, UPDATE_FILE_PATH, function () _AutoupdaterMsg("Successfully updated. ("..version.." => "..ServerVersion.."), press F9 twice to load the updated version.") end) end, 3)
			else
				_AutoupdaterMsg("You have got the latest version ("..ServerVersion..")")
			end
		end
	else
		_AutoupdaterMsg("Error downloading version info")
	end
end

if FileExist(LIB_PATH .. "/VPrediction.lua") then require "VPrediction" end

if myHero.charName ~= "Udyr" then return end

--------------------------------
--          VARIABLES         --
--------------------------------
Tiger = false
Turtle = false
Bear = false
Phoenix = false
loaded = false
MyTrueRange = 190

Spells = {
	spellQ = {range = 190}, 
	spellW = {range = 190},
	spellE = {range = 600},
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
	if _G.AutoCarry and ValidTarget(_G.AutoCarry.Crosshair:GetTarget()) then _G.AutoCarry.Crosshair:SetSkillCrosshairRange(300) return _G.AutoCarry.Crosshair:GetTarget() end		
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

function isRecall(hero)
	if hero ~= nil and ValidTarget(hero) then 
		for i = 1, hero.buffCount, 1 do
			local buff = hero:getBuff(i)
			if buff == "Recall" or buff == "SummonerTeleport" or buff == "RecallImproved" then return true end
		end
    end
	return false
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
		Config.ComboSettings:addParam("UseQ", "Use Q in Combo", SCRIPT_PARAM_ONOFF, true)
		Config.ComboSettings:addParam("UseW", "Use W in Combo", SCRIPT_PARAM_ONOFF, true)
		Config.ComboSettings:addParam("UseE", "Use E in Combo", SCRIPT_PARAM_ONOFF, true)
		Config.ComboSettings:addParam("UseR", "Use R in Combo", SCRIPT_PARAM_ONOFF, true)
	
	Config:addSubMenu("[Harass]", "HarassSettings")
		Config.HarassSettings:addParam("UseQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, true)
		Config.HarassSettings:addParam("UseW", "Use W in Harass", SCRIPT_PARAM_ONOFF, true)
		Config.HarassSettings:addParam("UseE", "Use E in Harass", SCRIPT_PARAM_ONOFF, true)
		Config.HarassSettings:addParam("UseR", "Use R in Harass", SCRIPT_PARAM_ONOFF, true)
	
	Config:addSubMenu("[Laneclear]", "LaneclearSettings")
		Config.LaneclearSettings:addParam("UseQ", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
		Config.LaneclearSettings:addParam("UseW", "Use W in Laneclear", SCRIPT_PARAM_ONOFF, true)
		Config.LaneclearSettings:addParam("UseE", "Use E in Laneclear", SCRIPT_PARAM_ONOFF, true)
		Config.LaneclearSettings:addParam("UseR", "Use R in Laneclear", SCRIPT_PARAM_ONOFF, true)
	
	Config:addSubMenu("[Jungleclear]", "JungleclearSettings")
		Config.JungleclearSettings:addParam("StyleJC", "Style Jungleclear", SCRIPT_PARAM_LIST, 1, {"Tiger", "Phoenix"})
	
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
end

function Combo()
	if Config.KeySettings.Combo and ValidTarget(Target) and not Target.dead then
		if Config.ComboSettings.UseE then
			castE()
		end
		if Config.ComboSettings.UseQ then
			castQ()
		end
		if Config.ComboSettings.UseR then
			castR()
		end
		if Config.ComboSettings.UseW and getHealthPercent() <= 75 then
			castW()
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
				if QREADY and Config.JungleclearSettings.UseQ and GetDistance(Target) < Spells.spellQ.range then CastSpell(_Q) return end
				if WREADY and Config.JungleclearSettings.UseW and GetDistance(Target) < Spells.spellW.range then CastSpell(_W) return end
			end
			if Target ~= nil and ValidTarget(Target) and Config.JungleclearSettings.StyleJC == 2 then
				if RREADY and Config.JungleclearSettings.UseE and GetDistance(Target) < Spells.spellE.range then CastSpell(_R) return end
				if WREADY and Config.JungleclearSettings.UseW and GetDistance(Target) < Spells.spellW.range then CastSpell(_W) return end
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
				if QREADY and Config.LaneclearSettings.UseQ and GetDistance(Target) > Spells.spellQ.range then CastSpell(_Q) return end
				if WREADY and Config.LaneclearSettings.UseW and GetDistance(Target) > Spells.spellW.range then CastSpell(_W) return end
				if EREADY and Config.LaneclearSettings.UseE and GetDistance(Target) > Spells.spellE.range then CastSpell(_E) return end
				if RREADY and Config.LaneclearSettings.UseR and GetDistance(Target) > Spells.spellR.range then CastSpell(_R) return end
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

function castQ()
	if QREADY and GetDistance(Target) < Spells.spellQ.range then
		CastSpell(_Q)
	end
end

function castW()
	if WREADY and GetDistance(Target) < Spells.spellW.range then
		CastSpell(_W)
	end
end

function castE()
	if EREADY and GetDistance(Target) < Spells.spellE.range then
		CastSpell(_E)
	end
end

function castR()
	if RREADY and GetDistance(Target) < Spells.spellR.range then
		CastSpell(_R)
	end
end

