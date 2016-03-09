--[[
	StonedSeries
	by uhGery
]]--

local version = 1
local AUTOUPDATE = true
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/uhGery/BoL/master/StonedSeries.lua".."?rand="..math.random(1,10000)
local UPDATE_FILE_PATH = SCRIPT_PATH..GetCurrentEnv().FILE_NAME
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local lastRG = 0
local lastICFJ = 0
local lastIDCF = 0
local lastICF = 0
local Target = nil
local UdyrLoaded, WWLoaded = false

function _AutoupdaterMsg(msg) print("<font color=\"#1C942A\">Stoned</font><font color =\"#DBD142\">Series</font> <font color=\"#FFFFFF\">"..msg..".</font>") end

require "AllClass"

if myHero.charName == "Udyr" then UdyrLoaded = true
elseif myHero.charName == "Warwick" then WWLoaded = true
else return end

function OnLoad()
	if not loaded then
		loaded = true
		Menu()
		if UdyrLoaded then
			PrintChat("Welcome to StonedSeries Udyr. GL & HF!")
		elseif WWLoaded then
			PrintChat("Welcome to StonedSeries Warwick. GL & HF!")
		end
		
		AddApplyBuffCallback(Buff_Add)
		AddRemoveBuffCallback(Buff_Rem)
		ts = TargetSelector(TARGET_LESS_CAST_PRIORITY, 800)

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

if AUTOUPDATE then
	local ServerData = GetWebResult(UPDATE_HOST, "/uhGery/BoL/master/Version/StonedBundle.version")
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

function GetTarget()
	ts:update()
	if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
	if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
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

function AutoPotion()
if os.clock() - lastRG < 15 then return end
	for SLOT = ITEM_1, ITEM_6 do
		if myHero:GetSpellData(SLOT).name == "RegenerationPotion"  then
			if myHero:CanUseSpell(SLOT) == READY and getHealthPercent() <= Config.PotionsSettings.lifeRG then
				CastSpell(SLOT)	
				lastRG = os.clock()				
			end
		end
	end

if os.clock() - lastICF < 12 then return end
	for SLOT = ITEM_1, ITEM_6 do
		if myHero:GetSpellData(SLOT).name == "ItemCrystalFlask"  then
			if myHero:CanUseSpell(SLOT) == READY and getHealthPercent() <= Config.PotionsSettings.lifeICF then
				CastSpell(SLOT)	
				lastICF = os.clock()				
			end
		end
	end
if os.clock() - lastICFJ < 8 then return end
	for SLOT = ITEM_1, ITEM_6 do
		if myHero:GetSpellData(SLOT).name == "ItemCrystalFlaskJungle"  then
			if myHero:CanUseSpell(SLOT) == READY and getHealthPercent() <= Config.PotionsSettings.lifeICFJ then
				CastSpell(SLOT)	
				lastICFJ = os.clock()				
			end
		end
	end
if os.clock() - lastIDCF < 12 then return end
	for SLOT = ITEM_1, ITEM_6 do
		if myHero:GetSpellData(SLOT).name == "ItemDarkCrystalFlask"  then
			if myHero:CanUseSpell(SLOT) == READY and getHealthPercent() <= Config.PotionsSettings.lifeIDCF then
				CastSpell(SLOT)	
				lastIDCF = os.clock()				
			end
		end
	end
end

function Menu()
	if UdyrLoaded then
		Config = scriptConfig("StonedUdyr", "stonedudyr")
		
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
		
		Config:addSubMenu("[Auto]", "AutoSettings")
			Config.AutoSettings:addParam("upgradeTB", "Buy Trinket Blue", SCRIPT_PARAM_ONOFF, true)
			Config.AutoSettings:addParam("autolevel","Auto level", SCRIPT_PARAM_ONOFF, false)
			Config.AutoSettings:addParam("levels","Select style", SCRIPT_PARAM_LIST, 1, {"Tiger","Phoenix"})
				
		Config:addSubMenu("[Auto Potions]", "PotionsSettings")
			Config.PotionsSettings:addParam("useRG", "Auto use Regeneration Potions", SCRIPT_PARAM_ONOFF, true)
			Config.PotionsSettings:addParam("lifeRG", "% life min for RG", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			Config.PotionsSettings:addParam("useICFJ", "Auto use Crystal Flask Junle", SCRIPT_PARAM_ONOFF, true)
			Config.PotionsSettings:addParam("lifeICFJ", "% life min for CFJ", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			Config.PotionsSettings:addParam("useIDCF", "Auto use Dark Crystal Flask", SCRIPT_PARAM_ONOFF, true)
			Config.PotionsSettings:addParam("lifeIDCF", "% life min for DCF", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			Config.PotionsSettings:addParam("useICF", "Auto use Crystal Flask", SCRIPT_PARAM_ONOFF, true)
			Config.PotionsSettings:addParam("lifeICF", "% life min for CF", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			
	elseif WWLoaded then
		Config = scriptConfig("StonedWarwick", "stonedww")
		
		Config:addSubMenu("[Key Binding]", "KeySettings")
			Config.KeySettings:addParam("Combo", "Combo Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte ("32"))
			Config.KeySettings:addParam("Harass", "Harass Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte ("C"))
			Config.KeySettings:addParam("Clear", "Clear Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte ("V"))
			Config.KeySettings:addParam("LastHit", "LastHit Key", SCRIPT_PARAM_ONKEYDOWN, false, string.byte ("X"))
		
		
		Config:addSubMenu("[Combo]", "ComboSettings")
			Config.ComboSettings:addParam("useQ", "Use Q in combo", SCRIPT_PARAM_ONOFF, true)
			Config.ComboSettings:addParam("useW", "Use W in combo", SCRIPT_PARAM_ONOFF, true)
			Config.ComboSettings:addParam("rangeW", "Use W if enemy in range", SCRIPT_PARAM_SLICE, 400, 50, 800, 0)
			Config.ComboSettings:addParam("useR", "Use R in combo", SCRIPT_PARAM_ONOFF, true)
			Config.ComboSettings:addParam("modeR", "R usage", SCRIPT_PARAM_LIST, 1, {"Always", "Killable", "Smart"}) 
	
		Config:addSubMenu("[Harass]", "HarassSettings")
			Config.HarassSettings:addParam("UseQ", "Use Q in Harass", SCRIPT_PARAM_ONOFF, true)
			Config.HarassSettings:addParam("manaQ", "% mana min for use Q", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
				
		Config:addSubMenu("[Laneclear]", "LaneclearSettings")
			Config.LaneclearSettings:addParam("UseQ", "Use Q in Laneclear", SCRIPT_PARAM_ONOFF, true)
			Config.LaneclearSettings:addParam("manaQ", "% mana min for use Q", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			Config.LaneclearSettings:addParam("UseW", "Use W in Laneclear", SCRIPT_PARAM_ONOFF, true)
			Config.LaneclearSettings:addParam("manaW", "% mana min for use W", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		
		Config:addSubMenu("[Jungleclear]", "JungleclearSettings")
			Config.JungleclearSettings:addParam("UseQ", "Use Q in jungleclear", SCRIPT_PARAM_ONOFF, true)
			Config.JungleclearSettings:addParam("manaQ", "% mana min for use Q", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			Config.JungleclearSettings:addParam("UseW", "Use W in jungleclear", SCRIPT_PARAM_ONOFF, true)
			Config.JungleclearSettings:addParam("manaW", "% mana min for use W", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
		
		Config:addSubMenu("[Killsteal]", "KS")
			Config.KS:addParam("ksQ", "Use Q to KS", SCRIPT_PARAM_ONOFF, true)
			Config.KS:addParam("ksR", "Use R to KS", SCRIPT_PARAM_ONOFF, true)
		
		Config:addSubMenu("[Draws]", "DrawsSettings")
			Config.DrawsSettings:addParam("DDraw", "Disable All Draws", SCRIPT_PARAM_ONOFF, false)
			Config.DrawsSettings:addParam("DrawQ", "Draw Q range", SCRIPT_PARAM_ONOFF, true)
			Config.DrawsSettings:addParam("DrawR", "Draw R range", SCRIPT_PARAM_ONOFF, true)
			Config.DrawsSettings:addParam("DrawAA", "Draw AA range", SCRIPT_PARAM_ONOFF, true)
			Config.DrawsSettings:addParam("Target", "Draw Circle on Target", SCRIPT_PARAM_ONOFF, true)
	
		Config:addSubMenu("[Auto]", "AutoSettings")
			Config.AutoSettings:addParam("upgradeTB", "Buy Trinket Blue", SCRIPT_PARAM_ONOFF, true)
			Config.AutoSettings:addParam("autolevel","Auto level", SCRIPT_PARAM_ONOFF, false)
		
		Config:addSubMenu("[Auto Potions]", "PotionsSettings")
			Config.PotionsSettings:addParam("useRG", "Auto use Regeneration Potions", SCRIPT_PARAM_ONOFF, true)
			Config.PotionsSettings:addParam("lifeRG", "% life min for RG", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			Config.PotionsSettings:addParam("useICFJ", "Auto use Crystal Flask Junle", SCRIPT_PARAM_ONOFF, true)
			Config.PotionsSettings:addParam("lifeICFJ", "% life min for CFJ", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			Config.PotionsSettings:addParam("useIDCF", "Auto use Dark Crystal Flask", SCRIPT_PARAM_ONOFF, true)
			Config.PotionsSettings:addParam("lifeIDCF", "% life min for DCF", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)
			Config.PotionsSettings:addParam("useICF", "Auto use Crystal Flask", SCRIPT_PARAM_ONOFF, true)
			Config.PotionsSettings:addParam("lifeICF", "% life min for CF", SCRIPT_PARAM_SLICE, 75, 0, 100, 0)

	end
end

function OnDraw()
	if myHero.dead then return end
		if UdyrLoaded then
			DrawCircle(myHero.x, myHero.y, myHero.z, 190, ARGB(255, 255, 0, 0))
			if Target ~= nil then 
				DrawHitBox(Target)
			end
		elseif WWLoaded then
			if not Config.DrawsSettings.DDraw then
			if Config.DrawsSettings.DrawQ and QREADY then
				DrawCircle(myHero.x, myHero.y, myHero.z, 400, ARGB(255, 255, 0, 0))
			end
			if Config.DrawsSettings.DrawR and RREADY then
				DrawCircle(myHero.x, myHero.y, myHero.z, 700, ARGB(255, 255, 0, 0))
			end
			if Config.DrawsSettings.DrawAA then
				DrawCircle(myHero.x, myHero.y, myHero.z, 190, ARGB(255, 255, 0, 0))
			end
			if Target ~= nil then 
				DrawHitBox(Target)
			end
		end
	end
end

function readyCheck()
	QREADY, WREADY, EREADY, RREADY = (myHero:CanUseSpell(_Q) == READY), (myHero:CanUseSpell(_W) == READY), (myHero:CanUseSpell(_E) == READY), (myHero:CanUseSpell(_R) == READY)
end

function OnTick()
	readyCheck()
	Target = GetTarget()
	if Config.KeySettings.Combo then Combo() end
	if Config.KeySettings.Clear then Laneclear() end
	if Config.KeySettings.Clear then Jungleclear() end
	if Config.KeySettings.Harass then Harass() end
	AutoPotion() 
	StunCheck()
	KillSteal()
	if VIP_USER and Config.AutoSettings.autolevel then
		if UdyrLoaded then
			local levelSequenceT = {nil,2,3,1,1,2,1,2,1,2,3,2,3,3,3,4,4,4}
			local levelSequenceP = {nil,2,3,4,4,2,4,2,4,2,3,2,3,3,3,1,1,1}
			if Config.AutoSettings.levels == 1 then
				autoLevelSetSequence(levelSequenceT)
			else 
				autoLevelSetSequence(levelSequenceP)
			end
		elseif WWLoaded then
			local levelSequence = {2,1,3,1,1,4,1,2,3,3,4,3,2,1,2,4,3,2}
			autoLevelSetSequence(levelSequence)
		end
	end	
end

function Combo()
	if UdyrLoaded then
				if Config.ComboSettings.StyleCombo == 1 and ValidTarget(Target) and not Target.dead then
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
			
				if Config.ComboSettings.StyleCombo == 2 and ValidTarget(Target) and not Target.dead then
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
	elseif WWLoaded then

				if ValidTarget(Target) and not Target.dead then
					if Config.ComboSettings.useQ then
						CastQ(Target)
					end
					if WREADY and Config.ComboSettings.useW and GetDistance(Target) <= Config.ComboSettings.rangeW then
						CastSpell(_W)
					end
					if RREADY and Config.ComboSettings.useR then
						if Config.ComboSettings.modeR == 1 then
							CastR(Target)
						end 
						if Config.ComboSettings.modeR == 2 then
								if getDmg("R", Target, myHero) * 0.95 > Target.health then
									CastR(Target)
								end
						end
						if Config.ComboSettings.modeR == 3 then
							if getDmg("R", Target, myHero) * 0.95 > Target.health or (getHealthPercent(Target) - getDmg("R",Target,myHero) <= 20) then
								CastR(Target)
							end
						end
					end
				end
	end
end

function Jungleclear()
	if UdyrLoaded then
		Target = nil
			for _, minion in pairs(minionManager(MINION_JUNGLE, 600, myHero, MINION_SORT_MAXHEALTH_DEC).objects) do
				if ValidTarget(minion) and not minion.dead then
					if Target == nil then
						Target = minion
					elseif GetDistance(minion) < GetDistance(Target) then
						Target = minion
					end
				end
			if Target ~= nil and ValidTarget(Target) and Config.JungleclearSettings.StyleJC == 1 then
				if not tiger and QREADY and GetDistance(Target) <= 190 and getManaPercent() >= Config.JungleclearSettings.manaQ then 
					CastSpell(_Q)
					turtle = false
					phoenix = false
					bear = false
				end
				if not turtle and WREADY and GetDistance(Target) <= 190 and getManaPercent() >= Config.JungleclearSettings.manaW then
					if turtle then return end
						CastSpell(_W)
						tiger = false
						phoenix = false		
						bear = false
					end
				end
				if Target ~= nil and ValidTarget(Target) and Config.JungleclearSettings.StyleJC == 2 then
					if RREADY and not phoenix and GetDistance(Target) <= 190 and getManaPercent() >= Config.JungleclearSettings.manaR then
						CastSpell(_R)
						turtle = false
						bear = false
						tiger = false
					end
					if not turtle and WREADY and GetDistance(Target) <= 190 and getManaPercent() >= Config.JungleclearSettings.manaW then
						CastSpell(_W)
						tiger = false
						phoenix = false	
						bear = false					
					end
				end
			end
	elseif WWLoaded then
		Target = nil
			for _, minion in pairs(minionManager(MINION_JUNGLE, 600, myHero, MINION_SORT_MAXHEALTH_DEC).objects) do
				if ValidTarget(minion) and not minion.dead then
					if Target == nil then
						Target = minion
					elseif GetDistance(minion) < GetDistance(Target) then
						Target = minion
					end
				end
			if Target ~= nil and ValidTarget(Target) then
				if Config.JungleclearSettings.UseQ and QREADY and GetDistance(Target) <= 400 and getManaPercent() >= Config.JungleclearSettings.manaQ then
					CastSpell(_Q, Target)
				end
				if Config.JungleclearSettings.UseW and WREADY and GetDistance(Target) <= 400 and getManaPercent() >= Config.JungleclearSettings.manaW then
					CastSpell(_W)
				end
			end
			end
		
	end
end

function Laneclear()
	if UdyrLoaded then
		if Config.KeySettings.Clear then
			for i, minion in pairs(minionManager(MINION_ENEMY, 600, myHero, MINION_SORT_HEALTH_DEC).objects) do
				if ValidTarget(minion) and not minion.dead then
					if GetDistance(minion) < 190 then 
						if Target == nil then
							Target = minion
						elseif GetDistance(minion) < GetDistance(Target) then
							Target = minion
						end
					end
				end
			if Target ~= nil and ValidTarget(Target) then
				if not tiger and QREADY and Config.LaneclearSettings.UseQ and GetDistance(Target) <= 190 and getManaPercent() >= Config.LaneclearSettings.manaQ then
					CastSpell(_Q)
					turtle = false
					phoenix = false
					bear = false
				end
				if not turtle and WREADY and Config.LaneclearSettings.UseW and GetDistance(Target) <= 190 and getManaPercent() >= Config.LaneclearSettings.manaW then 
					CastSpell(_W)
					tiger = false
					phoenix = false
					bear = false
				end
				if not bear and EREADY and Config.LaneclearSettings.UseE and GetDistance(Target) <= 190 and getManaPercent() >= Config.LaneclearSettings.manaE then 
					CastSpell(_E)
					turtle = false
					phoenix = false
					tiger = false
				end
				if not phoenix and RREADY and Config.LaneclearSettings.UseR and GetDistance(Target) <= 190 and getManaPercent() >= Config.LaneclearSettings.manaR then 
					CastSpell(_R)
					turtle = false
					bear = false
					tiger = false
				end
			end
		end
	end
	elseif WWLoaded then
		if Config.KeySettings.Clear then
			for i, minion in pairs(minionManager(MINION_ENEMY, 600, myHero, MINION_SORT_HEALTH_DEC).objects) do
				if ValidTarget(minion) and not minion.dead then
					if GetDistance(minion) < 500 then 
						if Target == nil then
							Target = minion
						elseif GetDistance(minion) < GetDistance(Target) then
							Target = minion
						end
					end
				end
				if Target ~= nil and ValidTarget(Target) then
					if Config.LaneclearSettings.UseQ and QREADY and GetDistance(Target) <= 400 and getManaPercent() >= Config.LaneclearSettings.manaQ and Target.health <= getDmg("Q",Target,myHero) then
						CastSpell(_Q, Target)
					end
					if Config.LaneclearSettings.UseW and WREADY and GetDistance(Target) <= 400 and getManaPercent() >= Config.LaneclearSettings.manaW then
						CastSpell(_W)
					end
				end
			end
		end
	end
end

function Harass()
	if UdyrLoaded then
			if Target and ValidTarget(Target) and not Target.dead then
				if not bear and EREADY and Config.HarassSettings.UseE and GetDistance(Target) <= 190 then CastSpell(_E) end
				if not tiger and QREADY and Config.HarassSettings.UseQ and GetDistance(Target) <= 190 then CastSpell(_Q) end
				if not phoenix and RREADY and Config.HarassSettings.UseR and GetDistance(Target) <= 190 then CastSpell(_R) end
				if not turtle and WREADY and Config.HarassSettings.UseW and GetDistance(Target) <= 190 then CastSpell(_W) end
			end
	elseif WWLoaded then
			if Target and ValidTarget(Target) and not Target.dead then
				if QREADY and Config.HarassSettings.UseQ and GetDistance(Target) <= 400 and getManaPercent() >= Config.HarassSettings.manaQ then CastSpell(_Q, Target) end
			end
	end
end

function StunCheck()
	if UdyrLoaded then
		if TargetHaveBuff("udyrbearstuncheck", Target) then
			stuned = true
			end
		if not TargetHaveBuff("udyrbearstuncheck", Target) then
			stuned = false
		end
	end
end

function Buff_Add(unit, buff)
	if UdyrLoaded then
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
	elseif WWLoaded then
		for i = 1, myHero.buffCount do
			local tBuff = myHero:getBuff(i)
			if BuffIsValid(tBuff) then
			end
		end
	end
end	

function Buff_Rem(unit, buff)
	if UdyrLoaded then
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
	elseif WWLoaded then
		for i = 1, myHero.buffCount do
			local tBuff = myHero:getBuff(i)
			if BuffIsValid(tBuff) then
				
			end
		end
	end
	if buff.name == "recall" and unit.isMe then
		if myHero.level >= 9 then
			if Config.AutoSettings.UpgradeTB then
				BuyItem(3363)
			end
		end
	end
end	

function KillSteal()
	if WWLoaded then
		if not Config.KS.ksQ and not Config.KS.ksR then return end
		for i,enemy in pairs(GetEnemyHeroes()) do
			if Config.KS.ksQ and ValidTarget(enemy, 400) and not enemy.dead and enemy.visible then
				if getDmg("Q",enemy,myHero) * 0.95 > enemy.health then
					CastQ(ememy)
				end
			end
			if Config.KS.ksR and ValidTarget(enemy, 700) and not enemy.dead and enemy.visible then
				if getDmg("R",enemy,myHero) * 0.95 > enemy.health then
					CastR(ememy)
				end
			end
		end
	end
end	

function CastQ(Target)
	if WWLoaded then
		if ValidTarget(Target) and GetDistance(Target) <= 400 and QREADY then
			CastSpell(_Q, Target)
		end
	end
end

function CastR(unit)
	if WWLoaded then
		if ValidTarget(Target) and GetDistance(unit) <= 700 and QREADY then
			CastSpell(_R, unit)
		end
	end
end
