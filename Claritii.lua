--==============================================================================================
-- Arkii
-- Claritii - Even has it's own song \o/ - http://www.youtube.com/watch?v=bJbdMqspODQ
--==============================================================================================

require "string";
require "math";
require "table";
require "lib/lib_Debug";
require 'lib/lib_Slash';
require "lib/lib_InterfaceOptions"
require "lib/lib_Callback2";
require "./libs/Lokii";
require "./libs/Uii";
require "./libs/misc"
require "./Fonts"


--=====================
--		Constants    --
--=====================
local ADDONNAME = "Claritii";
local FRAME = Component.GetFrame("Main");
local ON_LOAD_SHOW_DUR = 10;
local FPS_FRAME = Component.GetFrame("FPS_FRAME");
local FPS_BACKPLATE = Component.GetWidget("FPS_BackPlate");
local FPS_TEXT = Component.GetWidget("FPS_TEXT");
local FPS_POLL_RATE = 0.25;

--=====================
--		Varables     --
--=====================
local ShowCallbacks = {};

local ActivityTracker = nil;
local EXPBar = nil;
local Boosts = nil;
local UBar = nil;
local OutPost = nil;
local Announcer = nil;
local ChatButtons = nil;
local ChatScroll = nil;
local Glider = nil;

local CurrentOutPost = nil;
local LastPwrLvl = 0;
local LastMW = 0;
local LastUnderAttack = false;

local LastHealth = 0;
local LastClip = 0;
local LastHKMPct = 0;
local LastCalldown = 0;

local AblityFadeCB = nil;
local AblityFadeDoneCB = nil;
local UBarDontFade = false;

local actvitys = {};

local WorldObjList = nil;

local LastAnounceTime = 0;
local AnouncerZoneCB = nil;

local FPS_CB = nil;
local FPS_Show_CB = nil;
local hasCreatedMoveableFPS = false;
local uiDisplayMode = false;

-- The users configuration settings
local conf =
{
	AT = 
	{
		Enabled = true,
		AlwaysShow = false,
		FadeOut = 0.5,
		FadeHold = 10,
		ShowOnMission = true,
		ShowOnActivity = true,
		ShowOnInputModeChange = false,
		IsReady = false,
		SinToggle = true,
	},
	
	UBAR = 
	{
		Enabled = true,
		AlwaysShow = false,
		FadeOut = 0.5,
		FadeHold = 10,
		ShowOnHealthPct = 0,
		ShowOnAmmoPct = 0,
		ShowOnHKMPct = 25,
		ShowOnReload = true,
		ShowOnWeaponChange = true,
		ShowOnAblityChange = true,
		ShowOnAblityUsed = true,
		ShowOnCDDone = true,
		ShowOnCDChange = true,
		DontHideOnCD = false,
		ShowOnInputModeChange = true,
		IsReady = false,
		SinToggle = true,
	},
	
	EXP = 
	{
		Enabled = true,
		AlwaysShow = false,
		ShowOnBfChange = true,
		ShowOnEXPChange = true,
		ShowOnBoostChange = true,
		ShowOnInputModeChange = true,
		FadeOut = 0.5,
		FadeHold = 10,
		IsReady = false,
		SinToggle = true,
	},
	
	OS = 
	{
		Enabled = true,
		AlwaysShow = false,
		FadeOut = 0.5,
		FadeHold = 10,
		ShowOnEnter = true,
		ShowOnPowerLvl = true,
		ShowUnderAttack = true,
		ShowOnMWChangePct = 0,
		ShowOnInputModeChange = false,
		IsReady = false,
		SinToggle = true,
	},
	
	ANC = 
	{
		Enabled = true,
		ZoneMinTime = 5,
		ZoneMsgDisabled = false,
	},
	
	R5Chat = 
	{
		ShowOnLoadingScreen = true,
		ButtonHidemode = "",
		ScrollHideMode = "",
	},
	
	FPS = 
	{
		Enabled = false,
		Font = "Demi_18",
		FontColor = {tint="29FF00", alpha=1.0, exposure=1},
		BGColor = {tint="000000", alpha=0.4, exposure=1},
		Prefix = "FPS: ",
		SinToggle = false,
		FadeOut = 0.5,
		FadeHold = 10,
	},

	Glider = 
	{
		Show = true,
	},
};

--=====================
--		Events       --
--=====================
function OnComponentLoad()
	Debug.EnableLogging(true);
	
	InterfaceOptions.SetCallbackFunc(UII.CheckCallbacks, ADDONNAME);
	InterfaceOptions.NotifyOnLoaded(true);
	UII.AddUICallback("__LOADED", OnSettingsLoad);
	InterfaceOptions.NotifyOnDisplay(true);
	UII.AddUICallback("__DISPLAY", OnUIDisplay);
	UII.RegisterSettingsTable(conf);
	
	-- Lokii
	Lokii.ForceLocalFiles(true);
	Lokii.SetLocalVersion(5);
	Lokii.AddLang("en", "./lang/EN");
	Lokii.SetBaseLang("en");
	Lokii.LoadWebPack("http://arkii.eu01.aws.af.cm/FireFall/Claritii/langs");
	Lokii.RegisterCallback(OnLokiiWeb);
	Lokii.SetToLocale();
	
	-- Hook the Ui Elements
	ActivityTracker = HookActivityTracker();
	EXPBar,Boosts = HookEXP();
	UBar = HookUBar();
	OutPost = HookOutPost();
	Announcer = HookAnnouncer();
	ChatButtons, ChatScroll = HookChat();
	Glider = HookGlider();

	PositionHookedFrames();
	
	FPS_CB = Callback2.CreateCycle(SetFPS, nil);
	
	CreateUIOptions();
end

function OnLokiiWeb()
	Lokii.SetToLocale();
end

function OnSettingsLoad()
	if not (conf.AT.AlwaysShow) then
		ActivityTracker:SetParam("alpha", 1);
		Callback2.FireAndForget(function() ActivityTracker:ParamTo("alpha", 0, conf.AT.FadeOut); conf.AT.IsReady = true; end, nil, ON_LOAD_SHOW_DUR);
	end
	
	if not (conf.OS.AlwaysShow) then
		OutPost:SetParam("alpha", 1);
		Callback2.FireAndForget(function() OutPost:ParamTo("alpha", 0, conf.OS.FadeOut); conf.OS.IsReady = true; end, nil, ON_LOAD_SHOW_DUR);
	end
	
	if not (conf.EXP.AlwaysShow) then
		EXPBar:SetParam("alpha", 1);
		
		-- DWMods suport, I wish I had a nicer way to do this :/
		if (Boosts) then
			Boosts:SetParam("alpha", 1);
		end
		
		Callback2.FireAndForget(function() EXPBar:ParamTo("alpha", 0, conf.EXP.FadeOut); conf.EXP.IsReady = true; if (Boosts) then Boosts:ParamTo("alpha", 0, conf.EXP.FadeOut); end end, nil, ON_LOAD_SHOW_DUR);
	end
	
	if not (conf.UBAR.AlwaysShow) then
		UBar:SetParam("alpha", 1);
		Callback2.FireAndForget(function() UBar:ParamTo("alpha", 0, conf.UBAR.FadeOut); conf.UBAR.IsReady = true; end, nil, ON_LOAD_SHOW_DUR);
	end
	
	if (conf.FPS.SinToggle) then
		FPS_FRAME:SetParam("alpha", 0);
	end
end

function OnUIDisplay(args)
	uiDisplayMode = args;
	
	if (not args) then
		PositionHookedFrames();
	end
end

function OnPlayerReady()
	WorldObjList = Game.GetWorldObjectList();
	CurrentOutPost = Player.GetCurrentOutpostId();
	LastAnounceTime = math.ceil(tonumber(System.GetClientTime())/1000);
	
	if (CurrentOutPost) then
		OnEnterOutpost({objectId = CurrentOutPost});
		OnWorldObjectUpdate({objectId = CurrentOutPost});
	end
	
	local stats = Player.GetLifeInfo();
	LastHealth = stats.Health;
	
	LastClip = Player.GetWeaponState(true).Clip;
end

function OnHudShow(args)
	FRAME:Show(args.show);

	if (args.ignore or not conf.R5Chat.ShowOnLoadingScreen) then
		return;
	end

	if (args.loading_screen ) then
		args.loading_screen = not args.loading_screen; -- Muhahaha :3c
		args.ignore = true;
		Component.GenerateEvent("MY_HUD_SHOW", args);
	end
end

function OnSIN()
	if (conf.AT.SinToggle and not conf.AT.AlwaysShow) then
		ShowWidget(ActivityTracker, "AT");
	end
	
	if (conf.OS.SinToggle and not conf.OS.AlwaysShow) then
		ShowWidget(OutPost, "OS");
	end
	
	if (conf.EXP.SinToggle and not conf.EXP.AlwaysShow) then
		ShowWidget(EXPBar, "EXP");
	end
	
	if (conf.UBAR.SinToggle and not conf.UBAR.AlwaysShow and not UBarDontFade) then
		ShowWidget(UBar, "UBAR");
	end
	
	if (conf.FPS.SinToggle) then
		FPS_FRAME:ParamTo("alpha", 1, conf.FPS.FadeOut);
		if (FPS_Show_CB) then
			FPS_Show_CB:Cancel();
		else
			FPS_Show_CB = Callback2.Create();
		end
		FPS_Show_CB:Bind(function() FPS_FRAME:ParamTo("alpha", 0, conf.FPS.FadeOut); end);
		FPS_Show_CB:Schedule(conf.FPS.FadeHold);
	end
end

--	Outpost
function OnEnterOutpost(args)
	if (conf.OS.AlwaysShow or conf.OS.IsReady == false or not WorldObjList[args.objectId]) then return; end
	
	CurrentOutPost = args.objectId;
	
	--[[warn(CurrentOutPost);
	warn(tostring(Game.GetWorldObjectInfo(CurrentOutPost)));
	warn(tostring(Game.GetWorldObjectStatus(CurrentOutPost)));]]
	
	local objInfo = Game.GetWorldObjectInfo(CurrentOutPost);
	if (objInfo.type == "outpost") then
		local status = Game.GetWorldObjectStatus(CurrentOutPost);
		LastPwrLvl = status.power_level;
		LastMW = status.mw_current;
		LastUnderAttack = status.under_attack;
	end
	
	if (conf.OS.ShowOnEnter) then
		ShowWidget(OutPost, "OS");
	end
end

function OnWorldObjectUpdate(args)
	if (conf.OS.AlwaysShow or conf.OS.IsReady == false) then return; end
	
	if (isequal(CurrentOutPost, args.objectId)) then
		local status = Game.GetWorldObjectStatus(CurrentOutPost);
		local powerLevel = status.power_level;
		local maxMW = status.mw_max;
		local mw = status.mw_current;
		local underAttack = status.under_attack;
		
		if (powerLevel ~= LastPwrLvl and conf.OS.ShowOnPowerLvl) then
			LastPwrLvl = powerLevel;
			ShowWidget(OutPost, "OS");
		end
		
		if (underAttack ~= LastUnderAttack and conf.OS.ShowUnderAttack) then
			LastUnderAttack = underAttack; 
			ShowWidget(OutPost, "OS");
		end
		
		if (HasMWChanged(mw, maxMW)) then
			LastMW = mw;
			ShowWidget(OutPost, "OS");
		end
	end
end	
	
--	EXP BAR
function OnBattleframeChanged(args)
	if (conf.EXP.AlwaysShow) then
		return;
	end
	
	if (conf.EXP.IsReady == false or conf.EXP.ShowOnBfChange) then
		ShowWidget(EXPBar, "EXP");
	end
end

function OnExperienceChanged(args)
	if (conf.EXP.AlwaysShow) then
		return;
	end
	
	if (conf.EXP.IsReady == false or conf.EXP.ShowOnEXPChange) then
		ShowWidget(EXPBar, "EXP");
	end
end

function OnXpModifierChanged(args)
	if (conf.EXP.AlwaysShow) then
		return;
	end
	
	if (conf.EXP.IsReady == false or conf.EXP.ShowOnBoostChange) then
		ShowWidget(EXPBar, "EXP");
	end
end

--	UBAR
function OnHealthChanged(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end
	
	local stats = Player.GetLifeInfo();
	local pct = math.ceil((math.abs(stats.Health-LastHealth)/stats.MaxHealth)*100);
	
	if (pct >= conf.UBAR.ShowOnHealthPct) then
		ShowWidget(UBar, "UBAR");
	end
end

function OnWeaponReload(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end
	
	LastClip = Player.GetWeaponState(true).Clip;
	
	if (conf.UBAR.ShowOnReload) then
		ShowWidget(UBar, "UBAR");
	end
end

function OnWeaponChanged(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end
	
	LastClip = Player.GetWeaponState(true).Clip;
	
	if (conf.UBAR.ShowOnWeaponChange) then
		ShowWidget(UBar, "UBAR");
	end
end

function OnWeaponStateChnaged(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end
	
	local wInfo = Player.GetWeaponInfo(true);
	local MaxAmmo = 0;
	if (wInfo) then
		MaxAmmo = wInfo.ClipSize;
	end
	
	local wState = Player.GetWeaponState(true);
	local clip = 0;
	if (wState) then
		clip = wState.Clip;
	end
	
	if (clip == 0 and MaxAmmo == 0) then
		return;
	end
	
	local pct = math.ceil((math.abs(clip-LastClip)/MaxAmmo)*100);
	
	if (conf.UBAR.ShowOnAmmoPct == 0) then
		if (LastClip ~= clip) then
			LastClip = clip;
			ShowWidget(UBar, "UBAR");
		end
	else
		if (pct >= conf.UBAR.ShowOnAmmoPct) then
			LastClip = clip;
			ShowWidget(UBar, "UBAR");
		end
	end
end

function OnAblitySelect(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end
	
	if (conf.UBAR.ShowOnAblityChange and not UBarDontFade) then
		ShowWidget(UBar, "UBAR");
	end
end

function OnAblityUsed(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end
	
	local cd = Player.GetAbilityInfo(args.id).cooldown;
	if (cd == 0) then -- Some abilitys report 0 for a cool down so default to 30
		cd = 30;
	end
		
	if (not conf.UBAR.DontHideOnCD and conf.UBAR.ShowOnAblityUsed) then
		Debug.Log("ShowWidget");
		ShowWidget(UBar, "UBAR");
	end
	
	-- Cancel any lingering effects
	if (ShowCallbacks["UBAR"]) then
		ShowCallbacks["UBAR"]:Cancel();
	end
	
	if (conf.UBAR.DontHideOnCD) then
		UBar:ParamTo("alpha", 1, conf.UBAR.FadeOut);
			
		if (AblityFadeCB) then
			local time = AblityFadeCB:GetRemainingTime();		
			if (not time or time < cd) then
				AblityFadeCB:Reschedule(cd);
			end
		else
			AblityFadeCB = Callback2.Create();
			AblityFadeCB:Bind(function() 
					UBar:ParamTo("alpha", 0, conf.UBAR.FadeOut);
					UBarDontFade = false;
				end,
			nil);
			AblityFadeCB:Schedule(cd);
		end
		UBarDontFade = true;
	elseif (conf.UBAR.ShowOnCDDone) then
		if (AblityFadeDoneCB) then
			local time = AblityFadeDoneCB:GetRemainingTime();
			if (not time or time < cd) then
				AblityFadeDoneCB:Reschedule(cd);
			end
		else
			AblityFadeDoneCB = Callback2.Create();
			AblityFadeDoneCB:Bind(function() ShowWidget(UBar, "UBAR"); end, nil);
			AblityFadeDoneCB:Schedule(cd);
		end
	end
end

function OnSuperChargeChanged(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end
	
	local pct = math.abs(LastHKMPct - args.amount);
	
	if (pct >= conf.UBAR.ShowOnHKMPct) then
		LastHKMPct = args.amount;
		ShowWidget(UBar, "UBAR");
	end
end

function OnAlilitiesChanged(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end

	if (conf.UBAR.ShowOnCDChange and LastCalldown ~= Player.GetAbilities().action.abilityId) then
		LastCalldown = Player.GetAbilities().action.abilityId
		ShowWidget(UBar, "UBAR");
	end
end

function OnVehicleUpdate(args)
	if (args.role == "VEHICLE_DRIVER") then
		UBar:Show(false);
	elseif (args.role == "ROLE_NONE") then
		UBar:Show(true);
	end
end

function OnInputModeChanged(args)
	if (conf.UBAR.AlwaysShow) then
		return;
	end
	
	if args.mode == "cursor" then

		-- UBAR
		if (conf.UBAR.ShowOnInputModeChange) then
			ShowWidget(UBar, "UBAR");
		end

		--	ACTIVITY_TRACKER
		if conf.AT.ShowOnInputModeChange then
			ShowWidget(ActivityTracker, "AT");
		end

		--	EXP
		if conf.EXP.ShowOnInputModeChange then
			ShowWidget(EXPBar, "EXP");
		end

		--	out post
		if (conf.OS.ShowOnInputModeChange) then
			ShowWidget(OutPost, "OS");
		end

	end

	-- Chat
	if args.mode == "cursor" and conf.R5Chat.ButtonHidemode == "input" then
		ChatButtons:Show(true);
	elseif conf.R5Chat.ButtonHidemode == "input" then
		ChatButtons:Show(false);
	end

	if args.mode == "cursor" and conf.R5Chat.ScrollHideMode == "input" then
		ChatScroll:Show(true);
	elseif conf.R5Chat.ScrollHideMode == "input" then
		ChatScroll:Show(false);
	end
end

--	ACTIVITY_TRACKER
function OnTrackerUpdateMission(args)
	if (conf.AT.AlwaysShow or conf.AT.IsReady == false) then return; end
	
	if (conf.AT.ShowOnMission) then
		local str = tostring(args.json);
		local cs = MISC.Alder32(str);
		local id = jsontotable(str).id;
		
		if (actvitys[id] ~= cs) then
			actvitys[id] = cs;
			ShowWidget(ActivityTracker, "AT");
		end
	end
end

function OnTrackerUpdateMissionRemove(args)
	if (conf.AT.AlwaysShow or conf.AT.IsReady == false) then return; end
	
	local id = jsontotable(args.json).id;
	if (actvitys[id]) then
		actvitys[id] = nil;
		ShowWidget(ActivityTracker, "AT");
	end
end

function OnTrackerUpdate(args)
	if (conf.AT.AlwaysShow or conf.AT.IsReady == false) then return; end
	
	if (conf.AT.ShowOnActivity) then
		local str = tostring(args.json);
		local cs = MISC.Alder32(str);
		local id = jsontotable(str).id;
		
		if (actvitys[id] ~= cs) then
			actvitys[id] = cs;
			ShowWidget(ActivityTracker, "AT");
		end
	end
end

function OnTrackerRemove(args)
	if (conf.AT.AlwaysShow or conf.AT.IsReady == false) then return; end
	
	local id = jsontotable(args.json).id;
	if (actvitys[id]) then
		actvitys[id] = nil;
		ShowWidget(ActivityTracker, "AT");
	end
end

--	Announcer
function OnNotify(args)
	if (not conf.ANC.Enabled) then return; end
	
	local text = args.text;
	local pos = Player.GetPosition();
	local SubZone = Game.GetSubzoneNameAt(pos.x, pos.y);
	local time = math.ceil(tonumber(System.GetClientTime())/1000);
	local HideDurr = 4;
	
	--[[
	log("Text: " .. text);
	log("SubZone: " .. SubZone);
	
	log("LastAnounceTime: " .. LastAnounceTime);
	log("time: " .. time);
	log("LastAnounceTime + conf.ANC.ZoneMinTime: " .. (LastAnounceTime + conf.ANC.ZoneMinTime));
	]]
	
	if (text == SubZone and not conf.ANC.ZoneMsgDisabled) then
		if ((LastAnounceTime + conf.ANC.ZoneMinTime) >= time) then
			Announcer:Show(false);
			if (AnouncerZoneCB) then
				AnouncerZoneCB:Reschedule(HideDurr);
			else
				AnouncerZoneCB = Callback2.Create();
				AnouncerZoneCB:Bind(function() 
					Announcer:Show(true);
					end,
				nil);
				AnouncerZoneCB:Schedule(HideDurr);
			end
		end
			LastAnounceTime = time;
	else
	end
end

function LogTest(args)
	warn("-== ON_ENTER_ZONE ==-");
	log(tostring(args));
end

-- FPS
function SetFPS()
	if (not hasCreatedMoveableFPS or uiDisplayMode) then
		return;
	end
	
	FPS_TEXT:SetText(string.format("%s%.0f", conf.FPS.Prefix, System.GetCurrentFps()));
	local dims = FPS_TEXT:GetTextDims();
	local width = (dims.width+4);
	local height = (dims.height+4);
	FPS_FRAME:SetDims("width:"..width.."; height:"..height..";");
	InterfaceOptions.ChangeFrameWidth(FPS_FRAME, width);
	InterfaceOptions.ChangeFrameHeight(FPS_FRAME, height);
end

--=====================
--[[.##.....##.....####
.##.....##......##.
.##.....##......##.
.##.....##......##.
.##.....##......##.
.##.....##.###..##.
..#######..###.####]]
--=====================
function CreateUIOptions()
	-- Logo
	InterfaceOptions.AddMultiArt({id="LOGO", url="http://arkii.eu01.aws.af.cm/FireFall/Claritii/media/Logo.png", width=327, height=75, y_offset="5", OnClickUrl="http://forums.firefallthegame.com/community/threads/addon-claritii-context-aware-ui.1709241/"})
	
	--	ACTIVITY_TRACKER
	InterfaceOptions.StartGroup({label=Lokii.GetString("ACTIVITY_TRACKER"), tooltip=Lokii.GetString("ENABLE_DISABLE_MSG"), checkbox=true, id="ACTIVITY_TRACKER", default=conf.AT.Enabled});
	InterfaceOptions.AddCheckBox({id="AT_ALWAYS_SHOW", label=Lokii.GetString("ALWAYS_SHOW"), tooltip=Lokii.GetString("ALWAYS_SHOW_TT"), default=conf.AT.AlwaysShow});
	UII.AddUIVal("AT_ALWAYS_SHOW", "AT.AlwaysShow", function(args) if (args) then ActivityTracker:SetParam("alpha", 1); else ActivityTracker:SetParam("alpha", 0); end end);
	
	InterfaceOptions.AddCheckBox({id="AT_SIN_TOGGLE", label=Lokii.GetString("SIN_TOGGLE"), tooltip=Lokii.GetString("SIN_TOGGLE_TT"), default=conf.AT.SinToggle});
	UII.AddUIVal("AT_SIN_TOGGLE", "AT.SinToggle");
	
	InterfaceOptions.AddSlider({id="AT_FADE_OUT", label=Lokii.GetString("FADE_OUT_TIME"), tooltip=Lokii.GetString("FADE_OUT_TIME_TT"), default=conf.AT.FadeOut, min=0.5, max=10, inc=0.5, suffix=" S"});
	UII.AddUIVal("AT_FADE_OUT", "AT.FadeOut");
	
	InterfaceOptions.AddSlider({id="AT_FADE_HOLD", label=Lokii.GetString("FADE_HOLD"), tooltip=Lokii.GetString("FADE_HOLD_TT"), default=conf.AT.FadeHold, min=0.5, max=30, inc=0.5, suffix=" S"});
	UII.AddUIVal("AT_FADE_HOLD", "AT.FadeHold");
	
	InterfaceOptions.AddCheckBox({id="AT_SHOW_ON_MISSION", label=Lokii.GetString("AT_SHOW_ON_MISSION"), tooltip=Lokii.GetString("AT_SHOW_ON_MISSION_TT"), default=conf.AT.ShowOnMission});
	UII.AddUIVal("AT_SHOW_ON_MISSION", "AT.ShowOnMission");
	
	InterfaceOptions.AddCheckBox({id="AT_SHOW_ON_ACTIVITY", label=Lokii.GetString("AT_SHOW_ON_ACTIVITY"), tooltip=Lokii.GetString("AT_SHOW_ON_ACTIVITY_TT"), default=conf.AT.ShowOnActivity});
	UII.AddUIVal("AT_SHOW_ON_ACTIVITY", "AT.ShowOnActivity");

	InterfaceOptions.AddCheckBox({id="AT_SHOW_INPUTCHNAGED", label=Lokii.GetString("SHOW_INPUTCHNAGED"), tooltip=Lokii.GetString("SHOW_INPUTCHNAGED_TT"), default=conf.AT.ShowOnInputModeChange});
	UII.AddUIVal("AT_SHOW_INPUTCHNAGED", "AT.ShowOnInputModeChange");
	
	InterfaceOptions.StopGroup();
	UII.AddUIVal("ACTIVITY_TRACKER", "AT.Enabled", function(args) ActivityTracker:Show(args); end);
	
	
	--	UBAR
	InterfaceOptions.StartGroup({label=Lokii.GetString("UBAR"), tooltip=Lokii.GetString("ENABLE_DISABLE_MSG"),checkbox=true, id="UBAR", default=conf.UBAR.Enabled});
	InterfaceOptions.AddCheckBox({id="UBAR_ALWAYS_SHOW", label=Lokii.GetString("ALWAYS_SHOW"), tooltip=Lokii.GetString("ALWAYS_SHOW_TT"), default=conf.UBAR.AlwaysShow});
	UII.AddUIVal("UBAR_ALWAYS_SHOW", "UBAR.AlwaysShow", function(args)
		if (args) then
			UBar:SetParam("alpha", 1);
			if (ShowCallbacks["UBAR"]) then
				ShowCallbacks["UBAR"]:Cancel();
			end
		else
			UBar:SetParam("alpha", 0);
		end
	end);
	
	InterfaceOptions.AddCheckBox({id="UBAR_SIN_TOGGLE", label=Lokii.GetString("SIN_TOGGLE"), tooltip=Lokii.GetString("SIN_TOGGLE_TT"), default=conf.UBAR.SinToggle});
	UII.AddUIVal("UBAR_SIN_TOGGLE", "UBAR.SinToggle");
	
	InterfaceOptions.AddSlider({id="UBAR_FADE_OUT", label=Lokii.GetString("FADE_OUT_TIME"), tooltip=Lokii.GetString("FADE_OUT_TIME_TT"), default=conf.UBAR.FadeOut, min=0.5, max=10, inc=0.5, suffix=" S"});
	UII.AddUIVal("UBAR_FADE_OUT", "UBAR.FadeOut");
	
	InterfaceOptions.AddSlider({id="UBAR_FADE_HOLD", label=Lokii.GetString("FADE_HOLD"), tooltip=Lokii.GetString("FADE_HOLD_TT"), default=conf.UBAR.FadeHold, min=0.5, max=30, inc=0.5, suffix=" S"});
	UII.AddUIVal("UBAR_FADE_HOLD", "UBAR.FadeHold");
	
	InterfaceOptions.AddSlider({id="UBAR_SHOW_HEALTH_PCT", label=Lokii.GetString("UBAR_SHOW_HEALTH_PCT"), tooltip=Lokii.GetString("UBAR_SHOW_HEALTH_PCT_TT"), default=conf.UBAR.ShowOnHealthPct, min=0, max=100, inc=1, suffix=" S"});
	UII.AddUIVal("UBAR_SHOW_HEALTH_PCT", "UBAR.ShowOnHealthPct");
	
	InterfaceOptions.AddSlider({id="UBAR_SHOW_AMMO_PCT", label=Lokii.GetString("UBAR_SHOW_AMMO_PCT"), tooltip=Lokii.GetString("UBAR_SHOW_AMMO_PCT_TT"), default=conf.UBAR.ShowOnAmmoPct, min=0, max=100, inc=1, suffix=" S"});
	UII.AddUIVal("UBAR_SHOW_AMMO_PCT", "UBAR.ShowOnAmmoPct");
	
	InterfaceOptions.AddSlider({id="UBAR_SHOW_HKM_PCT", label=Lokii.GetString("UBAR_SHOW_HKM_PCT"), tooltip=Lokii.GetString("UBAR_SHOW_HKM_PCT_TT"), default=conf.UBAR.ShowOnHKMPct, min=0, max=100, inc=1, suffix=" S"});
	UII.AddUIVal("UBAR_SHOW_HKM_PCT", "UBAR.ShowOnHKMPct");
	
	InterfaceOptions.AddCheckBox({id="UBAR_SHOW_RELOAD", label=Lokii.GetString("UBAR_SHOW_RELOAD"), default=conf.UBAR.ShowOnReload});
	UII.AddUIVal("UBAR_SHOW_RELOAD", "UBAR.ShowOnReload");
	
	InterfaceOptions.AddCheckBox({id="UBAR_SHOW_CHNAGE", label=Lokii.GetString("UBAR_SHOW_WEAP_CHNAGE"), default=conf.UBAR.ShowOnWeaponChange});
	UII.AddUIVal("UBAR_SHOW_CHNAGE", "UBAR.ShowOnWeaponChange");
	
	InterfaceOptions.AddCheckBox({id="UBAR_SHOW_ABLITY_CHNAGE", label=Lokii.GetString("UBAR_SHOW_ABLITY_CHNAGE"), default=conf.UBAR.ShowOnAblityChange});
	UII.AddUIVal("UBAR_SHOW_ABLITY_CHNAGE", "UBAR.ShowOnAblityChange");
	
	InterfaceOptions.AddCheckBox({id="UBAR_SHOW_ABLITY_USED", label=Lokii.GetString("UBAR_SHOW_ABLITY_USED"), default=conf.UBAR.ShowOnAblityUsed});
	UII.AddUIVal("UBAR_SHOW_ABLITY_USED", "UBAR.ShowOnAblityUsed");
	
	InterfaceOptions.AddCheckBox({id="UBAR_SHOW_CD_DONE", label=Lokii.GetString("UBAR_SHOW_CD_DONE"), default=conf.UBAR.ShowOnCDDone});
	UII.AddUIVal("UBAR_SHOW_CD_DONE", "UBAR.ShowOnCDDone");
	
	InterfaceOptions.AddCheckBox({id="UBAR_DONT_HIDE_CD", label=Lokii.GetString("UBAR_DONT_HIDE_CD"), tooltip=Lokii.GetString("UBAR_DONT_HIDE_CD_TT"), default=conf.UBAR.DontHideOnCD});
	UII.AddUIVal("UBAR_DONT_HIDE_CD", "UBAR.DontHideOnCD");
	
	InterfaceOptions.AddCheckBox({id="UBAR_SHOW_CD_CHANGE", label=Lokii.GetString("UBAR_SHOW_CD_CHANGE"), tooltip=Lokii.GetString("UBAR_SHOW_CD_CHANGE_TT"), default=conf.UBAR.ShowOnCDChange});
	UII.AddUIVal("UBAR_SHOW_CD_CHANGE", "UBAR.ShowOnCDChange");
	
	InterfaceOptions.AddCheckBox({id="UBAR_SHOW_INPUTCHNAGED", label=Lokii.GetString("SHOW_INPUTCHNAGED"), tooltip=Lokii.GetString("SHOW_INPUTCHNAGED_TT"), default=conf.UBAR.ShowOnInputModeChange});
	UII.AddUIVal("UBAR_SHOW_INPUTCHNAGED", "UBAR.ShowOnInputModeChange");
	
	InterfaceOptions.StopGroup();
	UII.AddUIVal("UBAR", "UBAR.Enabled", function(args) UBar:Show(args); end);
	
	
	--	XP_BAR
	InterfaceOptions.StartGroup({label=Lokii.GetString("XP_BAR"), tooltip=Lokii.GetString("ENABLE_DISABLE_MSG"),checkbox=true, id="XP_BAR", default=conf.EXP.Enabled});
	InterfaceOptions.AddCheckBox({id="EXP_ALWAYS_SHOW", label=Lokii.GetString("ALWAYS_SHOW"), tooltip=Lokii.GetString("ALWAYS_SHOW_TT"), default=conf.EXP.AlwaysShow});
	UII.AddUIVal("EXP_ALWAYS_SHOW", "EXP.AlwaysShow", function(args) if (args) then EXPBar:SetParam("alpha", 1); else EXPBar:SetParam("alpha", 0); end end);
	
	InterfaceOptions.AddCheckBox({id="EXP_SIN_TOGGLE", label=Lokii.GetString("SIN_TOGGLE"), tooltip=Lokii.GetString("SIN_TOGGLE_TT"), default=conf.EXP.SinToggle});
	UII.AddUIVal("EXP_SIN_TOGGLE", "EXP.SinToggle");
	
	InterfaceOptions.AddSlider({id="EXP_FADE_OUT", label=Lokii.GetString("FADE_OUT_TIME"), tooltip=Lokii.GetString("FADE_OUT_TIME_TT"), default=conf.EXP.FadeOut, min=0.5, max=10, inc=0.5, suffix=" S"});
	UII.AddUIVal("EXP_FADE_OUT", "EXP.FadeOut");
	
	InterfaceOptions.AddSlider({id="EXP_FADE_HOLD", label=Lokii.GetString("FADE_HOLD"), tooltip=Lokii.GetString("FADE_HOLD_TT"), default=conf.EXP.FadeHold, min=0.5, max=30, inc=0.5, suffix=" S"});
	UII.AddUIVal("EXP_FADE_HOLD", "EXP.FadeHold");
	
	InterfaceOptions.AddCheckBox({id="EXP_SHOW_BF_CHNAGE", label=Lokii.GetString("EXP_SHOW_BF_CHNAGE"), tooltip=Lokii.GetString("EXP_SHOW_BF_CHNAGE_TT"), default=conf.EXP.ShowOnBfChange});
	UII.AddUIVal("EXP_SHOW_BF_CHNAGE", "EXP.ShowOnBfChange");
	
	InterfaceOptions.AddCheckBox({id="EXP_SHOW_EXP_CHNAGE", label=Lokii.GetString("EXP_SHOW_EXP_CHNAGE"), default=conf.EXP.ShowOnEXPChange});
	UII.AddUIVal("EXP_SHOW_EXP_CHNAGE", "EXP.ShowOnEXPChange");
	
	InterfaceOptions.AddCheckBox({id="EXP_SHOW_BOOST_CHNAGE", label=Lokii.GetString("EXP_SHOW_BOOST_CHNAGE"), default=conf.EXP.ShowOnBoostChange});
	UII.AddUIVal("EXP_SHOW_BOOST_CHNAGE", "EXP.ShowOnBoostChange");

	InterfaceOptions.AddCheckBox({id="EXP_SHOW_INPUTCHNAGED", label=Lokii.GetString("SHOW_INPUTCHNAGED"), tooltip=Lokii.GetString("SHOW_INPUTCHNAGED_TT"), default=conf.EXP.ShowOnInputModeChange});
	UII.AddUIVal("EXP_SHOW_INPUTCHNAGED", "EXP.ShowOnInputModeChange");
	
	InterfaceOptions.StopGroup();
	UII.AddUIVal("XP_BAR", "EXP.Enabled", function(args) EXPBar:Show(args); end);
	
	
	--	OUTPOST_STATUS
	InterfaceOptions.StartGroup({label=Lokii.GetString("OUTPOST_STATUS"), tooltip=Lokii.GetString("ENABLE_DISABLE_MSG"),checkbox=true, id="OUTPOST_STATUS", default=conf.OS.Enabled});
	InterfaceOptions.AddCheckBox({id="OS_ALWAYS_SHOW", label=Lokii.GetString("ALWAYS_SHOW"), tooltip=Lokii.GetString("ALWAYS_SHOW_TT"), default=conf.OS.AlwaysShow});
	UII.AddUIVal("OS_ALWAYS_SHOW", "OS.AlwaysShow", function(args) if (args) then OutPost:SetParam("alpha", 1); else OutPost:SetParam("alpha", 0); end end);
	
	InterfaceOptions.AddCheckBox({id="OS_SIN_TOGGLE", label=Lokii.GetString("SIN_TOGGLE"), tooltip=Lokii.GetString("SIN_TOGGLE_TT"), default=conf.OS.SinToggle});
	UII.AddUIVal("OS_SIN_TOGGLE", "OS.SinToggle");
	
	InterfaceOptions.AddSlider({id="OS_FADE_OUT", label=Lokii.GetString("FADE_OUT_TIME"), tooltip=Lokii.GetString("FADE_OUT_TIME_TT"), default=conf.OS.FadeOut, min=0.5, max=10, inc=0.5, suffix=" S"});
	UII.AddUIVal("OS_FADE_OUT", "OS.FadeOut");
	
	InterfaceOptions.AddSlider({id="OS_FADE_HOLD", label=Lokii.GetString("FADE_HOLD"), tooltip=Lokii.GetString("FADE_HOLD_TT"), default=conf.OS.FadeHold, min=0.5, max=30, inc=0.5, suffix=" S"});
	UII.AddUIVal("OS_FADE_HOLD", "OS.FadeHold");
	
	InterfaceOptions.AddCheckBox({id="OS_SHOW_ON_ENTER", label=Lokii.GetString("OS_SHOW_ON_ENTER"), tooltip=Lokii.GetString("OS_SHOW_ON_ENTER_TT"), default=conf.OS.ShowOnEnter});
	UII.AddUIVal("OS_SHOW_ON_ENTER", "OS.ShowOnEnter");
	
	InterfaceOptions.AddCheckBox({id="OS_SHOW_POWER_LEVEL_CHANGE", label=Lokii.GetString("OS_SHOW_POWER_LEVEL_CHANGE"), default=conf.OS.ShowOnPowerLvl});
	UII.AddUIVal("OS_SHOW_POWER_LEVEL_CHANGE", "OS.ShowOnPowerLvl");
	
	InterfaceOptions.AddCheckBox({id="OS_SHOW_UNDER_ATTACK", label=Lokii.GetString("OS_SHOW_UNDER_ATTACK"), default=conf.OS.ShowUnderAttack});
	UII.AddUIVal("OS_SHOW_UNDER_ATTACK", "OS.ShowUnderAttack");
	
	InterfaceOptions.AddSlider({id="OS_SHOW_MW_CHNAGE_PCT", label=Lokii.GetString("OS_SHOW_MW_CHNAGE_PCT"), tooltip=Lokii.GetString("OS_SHOW_MW_CHNAGE_PCT_TT"), default=conf.OS.ShowOnMWChangePct, min=0, max=100, inc=1, suffix=" S"});
	UII.AddUIVal("OS_SHOW_MW_CHNAGE_PCT", "OS.ShowOnMWChangePct");

	InterfaceOptions.AddCheckBox({id="OS_SHOW_INPUTCHNAGED", label=Lokii.GetString("SHOW_INPUTCHNAGED"), tooltip=Lokii.GetString("SHOW_INPUTCHNAGED_TT"), default=conf.OS.ShowOnInputModeChange});
	UII.AddUIVal("OS_SHOW_INPUTCHNAGED", "OS.ShowOnInputModeChange");
	
	InterfaceOptions.StopGroup();
	UII.AddUIVal("OUTPOST_STATUS", "OS.Enabled", function(args) OutPost:Show(args); end);
	
	--	OUTPOST_STATUS
	InterfaceOptions.StartGroup({label=Lokii.GetString("ANNOUNCER"), checkbox=true, id="ANNOUNCER", default=true});
	
	InterfaceOptions.AddCheckBox({id="ANNOUNCER_ZONE_DISABLE", label=Lokii.GetString("ANNOUNCER_ZONE_DISABLE"), tooltip=Lokii.GetString("ANNOUNCER_ZONE_DISABLE_TT"), default=conf.ANC.ZoneMsgDisabled});
	UII.AddUIVal("ANNOUNCER_ZONE_DISABLE", "ANC.ZoneMsgDisabled", function(args) Announcer:Show(not args); end);
	
	InterfaceOptions.AddSlider({id="ANNOUNCER_ZONE_TIME", label=Lokii.GetString("ANNOUNCER_ZONE_TIME"), tooltip=Lokii.GetString("ANNOUNCER_ZONE_TIME_TT"), default=conf.ANC.ZoneMinTime, min=1, max=60, inc=1, suffix=" S"});
	UII.AddUIVal("ANNOUNCER_ZONE_TIME", "ANC.ZoneMinTime");
	
	InterfaceOptions.StopGroup();
	UII.AddUIVal("ANNOUNCER", "ANC.Enabled");
	
	local tab = Lokii.GetString("EXTRAS");
	InterfaceOptions.StartGroup({label=Lokii.GetString("RCHAT"), checkbox=false, id="RCHAT", subtab={tab}});

	InterfaceOptions.AddCheckBox({label=Lokii.GetString("R5CHAT_SHOW_LOADING"), tooltip=Lokii.GetString("R5CHAT_SHOW_LOADING_TT"), id="R5CHAT_SHOW_LOADING", default=conf.R5Chat.ShowOnLoadingScreen, subtab={tab}});
	UII.AddUIVal("R5CHAT_SHOW_LOADING", "R5Chat.ShowOnLoadingScreen");

	-- Chat buttons
	InterfaceOptions.AddChoiceMenu({id="R5CHAT_HIDE_BUTTONS", label=Lokii.GetString("R5CHAT_HIDE_BUTTONS"), default=conf.R5Chat.ButtonHidemode, subtab={tab}});
	InterfaceOptions.AddChoiceEntry({menuId="R5CHAT_HIDE_BUTTONS", label=Lokii.GetString("R5CHAT_INPUT"), val="input"});
	InterfaceOptions.AddChoiceEntry({menuId="R5CHAT_HIDE_BUTTONS", label=Lokii.GetString("R5CHAT_NEVER"), val="never"});
	UII.AddUIVal("R5CHAT_HIDE_BUTTONS", "R5Chat.ButtonHidemode", 
		function(args)
			if args == "never" then
				ChatButtons:Show(false);
			else
				ChatButtons:Show(true);
			end
		end);

	-- Chat Scrollbar
	InterfaceOptions.AddChoiceMenu({id="R5CHAT_HIDE_SCROLL", label=Lokii.GetString("R5CHAT_HIDE_SCROLL"), default=conf.R5Chat.ScrollHideMode, subtab={tab}});
	InterfaceOptions.AddChoiceEntry({menuId="R5CHAT_HIDE_SCROLL", label=Lokii.GetString("R5CHAT_INPUT"), val="input"});
	InterfaceOptions.AddChoiceEntry({menuId="R5CHAT_HIDE_SCROLL", label=Lokii.GetString("R5CHAT_NEVER"), val="never"});
	UII.AddUIVal("R5CHAT_HIDE_SCROLL", "R5Chat.ScrollHideMode", 
		function(args)
			if args == "never" then
				ChatScroll:Show(false);
			else
				ChatScroll:Show(true);
			end
		end);

	InterfaceOptions.StopGroup({subtab={tab}});

	-- Glider
	InterfaceOptions.StartGroup({label=Lokii.GetString("GLIDER"), checkbox=false, id="GLIDER", subtab={tab}});

	InterfaceOptions.AddCheckBox({label=Lokii.GetString("GLIDER_SHOW"), tooltip=Lokii.GetString("GLIDER_SHOW_TT"), id="GLIDER_SHOW", default=conf.Glider.Show, subtab={tab}});
	UII.AddUIVal("GLIDER_SHOW", "Glider.Show", function(args) Glider:Show(args); end);

	InterfaceOptions.StopGroup({subtab={tab}});
	
	--==============================--
	-- 			FPS Counter			--
	--==============================--
	
	InterfaceOptions.StartGroup({label=Lokii.GetString("FPS_COUNTER"), tooltip=Lokii.GetString("FPS_COUNTER_TT"), checkbox=true, id="FPS_COUNTER", default=conf.FPS.Enabled, subtab={tab}});
	
	InterfaceOptions.AddCheckBox({id="FPS_SIN_TOGGLE", label=Lokii.GetString("SIN_TOGGLE"), tooltip=Lokii.GetString("SIN_TOGGLE_TT"), default=conf.FPS.SinToggle, subtab={tab}});
	UII.AddUIVal("FPS_SIN_TOGGLE", "FPS.SinToggle", function(args)
			if (args) then
				FPS_FRAME:SetParam("alpha", 0);
			else
				FPS_FRAME:SetParam("alpha", 1);
				if (FPS_Show_CB) then
					FPS_Show_CB:Cancel();
				end
			end
		end);
	
	InterfaceOptions.AddSlider({id="FPS_FADE_OUT", label=Lokii.GetString("FADE_OUT_TIME"), tooltip=Lokii.GetString("FADE_OUT_TIME_TT"), default=conf.FPS.FadeOut, min=0.5, max=10, inc=0.5, suffix=" S", subtab={tab}});
	UII.AddUIVal("FPS_FADE_OUT", "FPS.FadeOut");
	
	InterfaceOptions.AddSlider({id="FPS_FADE_HOLD", label=Lokii.GetString("FADE_HOLD"), tooltip=Lokii.GetString("FADE_HOLD_TT"), default=conf.FPS.FadeHold, min=0.5, max=30, inc=0.5, suffix=" S", subtab={tab}});
	UII.AddUIVal("FPS_FADE_HOLD", "FPS.FadeHold");
	
	InterfaceOptions.AddChoiceMenu({id="FPS_FONT", label=Lokii.GetString("FONT"), default=conf.FPS.Font, subtab={tab}});
	
	for i=1, #FONTS, 1 do
		InterfaceOptions.AddChoiceEntry({menuId="FPS_FONT", label=FONTS[i], val=FONTS[i], subtab={tab}});
	end
	
	UII.AddUIVal("FPS_FONT", "FPS.Font", function (args) FPS_TEXT:SetFont(args); end);
	
	InterfaceOptions.AddColorPicker({id="FPS_FONT_COLOR", label=Lokii.GetString("FONT_COLOUR"), default=conf.FPS.FontColor, subtab={tab}});
	UII.AddUIVal("FPS_FONT_COLOR", "FPS.FontColor", function (args)
			FPS_TEXT:SetText("Test");
			FPS_TEXT:SetTextColor(args.tint);
		end);
	
	InterfaceOptions.AddColorPicker({id="FPS_BG_COLOR", label=Lokii.GetString("BACKGROUND_COLOUR"), default=conf.FPS.BGColor, subtab={tab}});
	UII.AddUIVal("FPS_BG_COLOR", "FPS.BGColor", function (args) FPS_BACKPLATE:SetParam("tint", args.tint); FPS_BACKPLATE:SetParam("alpha", args.alpha); FPS_BACKPLATE:SetParam("exposure", args.exposure); end);
	
	InterfaceOptions.AddTextInput({id="FPS_PREFIX", label=Lokii.GetString("PREFIX"), default=conf.FPS.Prefix, subtab={tab}});
	UII.AddUIVal("FPS_PREFIX", "FPS.Prefix");
	
	InterfaceOptions.StopGroup({subtab={tab}});
	UII.AddUIVal("FPS_COUNTER", "FPS.Enabled", function (args)
			if (args == false and FPS_CB) then
				FPS_CB:Stop();
			else
				FPS_CB:Run(FPS_POLL_RATE);
			end 
			FPS_FRAME:Show(args);
			
			if (not hasCreatedMoveableFPS and args == true) then
				hasCreatedMoveableFPS = true;
				InterfaceOptions.AddMovableFrame({
					frame = FPS_FRAME,
					label = Lokii.GetString("FPS_COUNTER"),
					scalable = true
				});
			end
		end);
end

--=====================
--		Functions    --
--=====================
function ShowWidget(WIDGET, ID)
	WIDGET:ParamTo("alpha", 1, conf[ID].FadeOut);
	
	if (ShowCallbacks[ID]) then
		ShowCallbacks[ID]:Cancel();
	else
		ShowCallbacks[ID] = Callback2.Create();
	end
	
	ShowCallbacks[ID]:Bind(function()
		WIDGET:ParamTo("alpha", 0, conf[ID].FadeOut);
		if (ID == "EXP" and Boosts) then
			Boosts:ParamTo("alpha", 0, conf[ID].FadeOut);
		end
	end);
	
	ShowCallbacks[ID]:Schedule(conf[ID].FadeHold);
	
	-- Hacky Dwmods support :/
	if (ID == "EXP" and Boosts) then
		Boosts:ParamTo("alpha", 1, conf[ID].FadeOut);
	end
end

function GetWidgetPos(ID)
	local dummyWidget = Component.CreateWidget('<group dimensions="dock:fill;"/>', FRAME);
	Component.FosterWidget(dummyWidget, ID);
	local dims = dummyWidget:GetBounds();
	Component.RemoveWidget(dummyWidget);
	return dims;
end

function HasMWChanged(currentMW, maxMW)
	if (maxMW == 0) then
		return false;
	end
	
	local pct = (currentMW/maxMW)*100;
	local pct2 = (LastMW/maxMW)*100;
	pct = math.ceil(math.abs(pct2-pct));
	
	--[[log("PCT: " .. tostring(pct));
	log("conf.OS.ShowOnMWChangePct: " .. tostring(conf.OS.ShowOnMWChangePct));]]
	
	if (pct >= conf.OS.ShowOnMWChangePct) then
		return true;
	end
	
	return false;
end

-- Hook functions for the UI elements
function HookActivityTracker()
	local at_id = "ActivityTracker:ActivityMainGroup";
	local dummyWidget = Component.CreateWidget('<group dimensions="dock:fill;"/>', FRAME);
	Component.FosterWidget(dummyWidget, at_id);
	
	Component.FosterWidget("ActivityTracker:ActivityLabel", dummyWidget);
	Component.FosterWidget("ActivityTracker:Activities", dummyWidget);
	return dummyWidget;
end

function HookEXP()
	dummyWidget = Component.CreateWidget('<group dimensions="left:0; width:300; top:2; height:44;"/>', FRAME);
		
	Component.FosterWidget("EXPBar:BattleframeIcon", dummyWidget);
	Component.FosterWidget("EXPBar:PlayerName", dummyWidget);
	Component.FosterWidget("EXPBar:XP", dummyWidget);
	
	-- Check if DWMods is installed, for now just force them into stock locations
	local dummyWidget2 = Component.CreateWidget('<group dimensions="dock:fill;"/>', dummyWidget);
	if (Component.FosterWidget(dummyWidget2, "EXPBar:Boosts.container")) then
		Component.FosterWidget("EXPBar:xp_group", dummyWidget2);
		Component.FosterWidget("EXPBar:res_group", dummyWidget2);
	else
		Component.FosterWidget("EXPBar:boost_layout", dummyWidget);
		Component.FosterWidget("EXPBar:VIP", dummyWidget);
		Component.FosterWidget("Interact:vip_group", dummyWidget);
		Component.RemoveWidget(dummyWidget2);
		dummyWidget2 = nil;
	end
	
	return dummyWidget,dummyWidget2;
end

function HookUBar()
	local dummyWidget = Component.CreateWidget('<group dimensions="center-x:50%; bottom:100%-10; width:600; height:70" style="scale:1.0;"/>', FRAME);
	
	local dummyWidget2 = Component.CreateWidget('<group dimensions="center-x:50%; bottom:100%-10; width:600; height:70" />', dummyWidget);
	local dummyWidget3 = Component.CreateWidget('<group dimensions="center-x:50%; width:400; bottom:100%-2; height:8" />', dummyWidget);
	
	Component.FosterWidget("UBar:main.{1}", dummyWidget2);
	Component.FosterWidget("UBar:main.{2}", dummyWidget2);
	Component.FosterWidget("UBar:main.{3}", dummyWidget2);
	
	Component.FosterWidget("Abilities:SuperBarHUD.{1}", dummyWidget3);
	return dummyWidget;
end

function HookOutPost()
	--local dummyWidget = Component.CreateWidget('<group dimensions="center-x:50%; top:0%; height:120; width:300" />', FRAME);
	
	--Component.FosterWidget("ow_OutpostState:hud_info", dummyWidget);
	
	local dummyWidget = Component.CreateWidget('<group dimensions="dock:fill;" />', FRAME);
	
	Component.FosterWidget("ow_OutpostState:hud_info.{1}", dummyWidget);
	Component.FosterWidget("ow_OutpostState:hud_info.{2}", dummyWidget);
	
	Component.FosterWidget(dummyWidget, "ow_OutpostState:hud_info");
	return dummyWidget;
end

function HookAnnouncer()
	local dummyWidget = Component.CreateWidget('<group dimensions="dock:fill;" />', FRAME);
	
	Component.FosterWidget(dummyWidget, "Announcer:PopupNotification.{1}");
	Component.FosterWidget("Announcer:PopupNotification.{1}.{1}", dummyWidget);
	Component.FosterWidget("Announcer:PopupNotification.{1}.{2}", dummyWidget);
	
	return dummyWidget;
end

function HookChat()
	local dummyWidget = Component.CreateWidget('<group dimensions="dock:fill;" />', FRAME);

	Component.FosterWidget(dummyWidget, "R5Chat:TabGroup");
	Component.FosterWidget("R5Chat:TabGroup.{1}", dummyWidget);
    Component.FosterWidget("R5Chat:TabGroup.{2}", dummyWidget);
    Component.FosterWidget("R5Chat:TabGroup.{3}", dummyWidget);
    Component.FosterWidget("R5Chat:TabGroup.{4}", dummyWidget);

    local dummyWidget2 = Component.CreateWidget('<group dimensions="dock:fill;"/>', FRAME);
    Component.FosterWidget(dummyWidget2, "R5Chat:MainGroup");
    Component.FosterWidget("R5Chat:Slider", dummyWidget2);

    return dummyWidget, dummyWidget2;
end

function HookGlider()
	local dummyWidget = Component.CreateWidget('<group dimensions="dock:fill;" />', FRAME);

	Component.FosterWidget(dummyWidget, "Glider:Main.{1}");
	Component.FosterWidget("Glider:yaw", dummyWidget);
    Component.FosterWidget("Glider:pitch_group", dummyWidget);
    
    return dummyWidget;
end

function PositionHookedFrames()
	--EXP
	--==================================================================================
	local pos = Component.GetSetting("EXPBar", "framedims:main");
	if (pos) then
		local str = string.format('%s:%f%%; %s:%f%%; width:300; height:44;', pos.Xbound, pos.Xpct, pos.Ybound, pos.Ypct);
		EXPBar:SetDims(str);
	end
	
	-- UBAR
	--==================================================================================
	local pos = Component.GetSetting("UBar", "framedims:main");
	local scale = Component.GetSetting("UBar", "framescale:main");
	
	if (pos) then
		local str = string.format('%s:%f%%; %s:%f%%; width:600; height:70;', pos.Xbound, pos.Xpct, pos.Ybound, pos.Ypct);
		UBar:SetDims(str);
	end
	
	if (scale) then
		scale = tonumber(scale)/100;
		UBar:SetParam("scaleX", scale);
		UBar:SetParam("scaleY", scale);
	end
end