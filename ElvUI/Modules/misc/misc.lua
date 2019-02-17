local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local M = E:NewModule('Misc', 'AceEvent-3.0', 'AceTimer-3.0');
E.Misc = M;

--Lua functions
local _G = _G
local format, gsub = format, gsub
--WoW API / Variables
local AcceptGroup = AcceptGroup
local BNGetFriendGameAccountInfo = BNGetFriendGameAccountInfo
local BNGetFriendInfo = BNGetFriendInfo
local BNGetNumFriendGameAccounts = BNGetNumFriendGameAccounts
local BNGetNumFriends = BNGetNumFriends
local CanGuildBankRepair = CanGuildBankRepair
local CanMerchantRepair = CanMerchantRepair
local GetCVarBool, SetCVar = GetCVarBool, SetCVar
local GetFriendInfo = GetFriendInfo
local GetGuildBankWithdrawMoney = GetGuildBankWithdrawMoney
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumFriends = GetNumFriends
local GetNumGroupMembers = GetNumGroupMembers
local GetNumGuildMembers = GetNumGuildMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetRepairAllCost = GetRepairAllCost
local GuildRoster = GuildRoster
local InCombatLockdown = InCombatLockdown
local IsActiveBattlefieldArena = IsActiveBattlefieldArena
local IsAddOnLoaded = IsAddOnLoaded
local IsArenaSkirmish = IsArenaSkirmish
local IsInGroup, IsInRaid = IsInGroup, IsInRaid
local IsInGuild = IsInGuild
local IsPartyLFG, IsInInstance = IsPartyLFG, IsInInstance
local IsShiftKeyDown = IsShiftKeyDown
local LeaveParty = LeaveParty
local RaidNotice_AddMessage = RaidNotice_AddMessage
local RepairAllItems = RepairAllItems
local SendChatMessage = SendChatMessage
local ShowFriends = ShowFriends
local StaticPopup_Hide = StaticPopup_Hide
local StaticPopupSpecial_Hide = StaticPopupSpecial_Hide
local UninviteUnit = UninviteUnit
local UnitExists = UnitExists
local UnitGUID = UnitGUID
local UnitInRaid = UnitInRaid
local UnitName = UnitName
local CreateFrame = CreateFrame
local RegisterStateDriver = RegisterStateDriver

local BNET_CLIENT_WOW = BNET_CLIENT_WOW
local C_Timer_After = C_Timer.After
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY = LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY
local LE_GAME_ERR_NOT_ENOUGH_MONEY = LE_GAME_ERR_NOT_ENOUGH_MONEY
local MAX_PARTY_MEMBERS = MAX_PARTY_MEMBERS
local UIErrorsFrame = UIErrorsFrame

local INTERRUPT_MSG = INTERRUPTED.." %s's \124cff71d5ff\124Hspell:%d:0\124h[%s]\124h\124r!"

function M:ErrorFrameToggle(event)
	if not E.db.general.hideErrorFrame then return end
	if event == 'PLAYER_REGEN_DISABLED' then
		UIErrorsFrame:UnregisterEvent('UI_ERROR_MESSAGE')
	else
		UIErrorsFrame:RegisterEvent('UI_ERROR_MESSAGE')
	end
end

function M:COMBAT_LOG_EVENT_UNFILTERED()
	local _, event, _, sourceGUID, _, _, _, _, destName, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
	if E.db.general.interruptAnnounce == "NONE" then return end -- No Announcement configured, exit.
	if not (event == "SPELL_INTERRUPT" and (sourceGUID == E.myguid or sourceGUID == UnitGUID('pet'))) then return end -- No announce-able interrupt from player or pet, exit.

	local inGroup, inRaid, inPartyLFG = IsInGroup(), IsInRaid(), IsPartyLFG()
	if not inGroup then return end -- not in group, exit.

	--Skirmish/non-rated arenas need to use INSTANCE_CHAT but IsPartyLFG() returns "false"
	local _, instanceType = IsInInstance()
	if instanceType and instanceType == "arena" then
		local skirmish = IsArenaSkirmish()
		local _, isRegistered = IsActiveBattlefieldArena()
		if skirmish or not isRegistered then
			inPartyLFG = true
		end
		inRaid = false --IsInRaid() returns true for arenas and they should not be considered a raid
	end

	if E.db.general.interruptAnnounce == "PARTY" then
		SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), inPartyLFG and "INSTANCE_CHAT" or "PARTY")
	elseif E.db.general.interruptAnnounce == "RAID" then
		if inRaid then
			SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), inPartyLFG and "INSTANCE_CHAT" or "RAID")
		else
			SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), inPartyLFG and "INSTANCE_CHAT" or "PARTY")
		end
	elseif E.db.general.interruptAnnounce == "RAID_ONLY" then
		if inRaid then
			SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), inPartyLFG and "INSTANCE_CHAT" or "RAID")
		end
	elseif E.db.general.interruptAnnounce == "SAY" then
		SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), "SAY")
	elseif E.db.general.interruptAnnounce == "EMOTE" then
		SendChatMessage(format(INTERRUPT_MSG, destName, spellID, spellName), "EMOTE")
	end
end

local autoRepairStatus
local function AttemptAutoRepair(playerOverride)
	autoRepairStatus = ""
	local autoRepair = E.db.general.autoRepair
	local cost, possible = GetRepairAllCost()
	local withdrawLimit = GetGuildBankWithdrawMoney();
	--This check evaluates to true even if the guild bank has 0 gold, so we add an override
	if autoRepair == 'GUILD' and ((not CanGuildBankRepair() or cost > withdrawLimit) or playerOverride) then
		autoRepair = 'PLAYER'
	end

	if cost > 0 then
		if possible then
			RepairAllItems(autoRepair == 'GUILD')

			--Delay this a bit so we have time to catch the outcome of first repair attempt
			C_Timer_After(0.5, function()
				if autoRepair == 'GUILD' then
					if autoRepairStatus == "GUILD_REPAIR_FAILED" then
						AttemptAutoRepair(true) --Try using player money instead
					else
						E:Print(L["Your items have been repaired using guild bank funds for: "]..E:FormatMoney(cost, "SMART", true)) --Amount, style, textOnly
					end
				elseif autoRepair == "PLAYER" then
					if autoRepairStatus == "PLAYER_REPAIR_FAILED" then
						E:Print(L["You don't have enough money to repair."])
					else
						E:Print(L["Your items have been repaired for: "]..E:FormatMoney(cost, "SMART", true)) --Amount, style, textOnly
					end
				end
			end)
		end
	end
end

local function VendorGrays()
	E:GetModule('Bags'):VendorGrays()
end

function M:UI_ERROR_MESSAGE(_, messageType)
	if messageType == LE_GAME_ERR_GUILD_NOT_ENOUGH_MONEY then
		autoRepairStatus = "GUILD_REPAIR_FAILED"
	elseif messageType == LE_GAME_ERR_NOT_ENOUGH_MONEY then
		autoRepairStatus = "PLAYER_REPAIR_FAILED"
	end
end

function M:MERCHANT_CLOSED()
	self:UnregisterEvent("UI_ERROR_MESSAGE")
	self:UnregisterEvent("UPDATE_INVENTORY_DURABILITY")
	self:UnregisterEvent("MERCHANT_CLOSED")
end

function M:MERCHANT_SHOW()
	if E.db.bags.vendorGrays.enable then
		C_Timer_After(0.5, VendorGrays)
	end

	local autoRepair = E.db.general.autoRepair
	if IsShiftKeyDown() or autoRepair == 'NONE' or not CanMerchantRepair() then return end

	--Prepare to catch "not enough money" messages
	self:RegisterEvent("UI_ERROR_MESSAGE")
	--Use this to unregister events afterwards
	self:RegisterEvent("MERCHANT_CLOSED")

	AttemptAutoRepair()
end

function M:DisbandRaidGroup()
	if InCombatLockdown() then return end -- Prevent user error in combat

	if UnitInRaid("player") then
		for i = 1, GetNumGroupMembers() do
			local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
			if online and name ~= E.myname then
				UninviteUnit(name)
			end
		end
	else
		for i = MAX_PARTY_MEMBERS, 1, -1 do
			if UnitExists("party"..i) then
				UninviteUnit(UnitName("party"..i))
			end
		end
	end
	LeaveParty()
end

function M:PVPMessageEnhancement(_, msg)
	if not E.db.general.enhancedPvpMessages then return end
	local _, instanceType = IsInInstance()
	if instanceType == 'pvp' or instanceType == 'arena' then
		RaidNotice_AddMessage(_G.RaidBossEmoteFrame, msg, _G.ChatTypeInfo["RAID_BOSS_EMOTE"]);
	end
end

local hideStatic = false;
local PLAYER_REALM = gsub(E.myrealm,'[%s%-]','');
function M:AutoInvite(event, leaderName)
	if not E.db.general.autoAcceptInvite then return; end

	if event == "PARTY_INVITE_REQUEST" then
		if _G.QueueStatusMinimapButton:IsShown() then return end -- Prevent losing que inside LFD if someone invites you to group
		if IsInGroup() then return end
		hideStatic = true

		-- Update Guild and Friendlist
		if GetNumFriends() > 0 then ShowFriends() end
		if IsInGuild() then GuildRoster() end

		local friendName, guildMemberName, memberName, numGameAccounts, isOnline, accountName, bnToonName, bnClient, bnRealm, bnAcceptedInvite, _;
		local inGroup = false;

		for friendIndex = 1, GetNumFriends() do
			friendName = GetFriendInfo(friendIndex) --this is already stripped of your own realm
			if friendName and (friendName == leaderName) then
				AcceptGroup()
				inGroup = true
				break
			end
		end

		if not inGroup then
			for guildIndex = 1, GetNumGuildMembers(true) do
				guildMemberName = GetGuildRosterInfo(guildIndex)
				memberName = guildMemberName and gsub(guildMemberName, '%-'..PLAYER_REALM, '')
				if memberName and (memberName == leaderName) then
					AcceptGroup()
					inGroup = true
					break
				end
			end
		end

		if not inGroup then
			for bnIndex = 1, BNGetNumFriends() do
				_, accountName, _, _, _, _, _, isOnline = BNGetFriendInfo(bnIndex);
				if isOnline then
					if accountName and (accountName == leaderName) then
						AcceptGroup()
						bnAcceptedInvite = true
					end
					if not bnAcceptedInvite then
						numGameAccounts = BNGetNumFriendGameAccounts(bnIndex);
						if numGameAccounts > 0 then
							for toonIndex = 1, numGameAccounts do
								_, bnToonName, bnClient, bnRealm = BNGetFriendGameAccountInfo(bnIndex, toonIndex);
								if bnClient == BNET_CLIENT_WOW then
									if bnRealm and bnRealm ~= '' and bnRealm ~= PLAYER_REALM then
										bnToonName = format('%s-%s', bnToonName, bnRealm)
									end
									if bnToonName and (bnToonName == leaderName) then
										AcceptGroup()
										bnAcceptedInvite = true
										break
									end
								end
							end
						end
					end
					if bnAcceptedInvite then
						break
					end
				end
			end
		end
	elseif event == "GROUP_ROSTER_UPDATE" and hideStatic == true then
		StaticPopupSpecial_Hide(_G.LFGInvitePopup) --New LFD popup when invited in custom created group
		StaticPopup_Hide("PARTY_INVITE")
		hideStatic = false
	end
end

function M:ForceCVars()
	if not GetCVarBool('lockActionBars') and E.private.actionbar.enable then
		SetCVar('lockActionBars', 1)
	end
end

function M:PLAYER_ENTERING_WORLD()
	self:ForceCVars()
	self:ToggleChatBubbleScript()
end

function M:ADDON_LOADED(_, addon)
	if addon == "Blizzard_InspectUI" then
		M:SetupInspectPageInfo()
		self:UnregisterEvent("ADDON_LOADED")
	end
end

function M:ManageQuestObjectives()
	local frame = CreateFrame('Frame', 'ObjectiveHider', _G.ObjectiveTrackerFrame, 'SecureHandlerStateTemplate');
	RegisterStateDriver(frame, "objectiveHider", "[@arena1,exists][@arena2,exists][@arena3,exists][@arena4,exists][@arena5,exists][@boss1,exists][@boss2,exists][@boss3,exists][@boss4,exists] 1;0")
	frame:SetAttribute("_onstate-objectiveHider", [[
		local parent = self:GetParent()
		local shown = parent:IsShown()

		if newstate == 1 and shown then
			self:GetParent():Hide()
		elseif not shown then
			self:GetParent():Show()
		end
	]])
end

function M:Initialize()
	self:LoadRaidMarker()
	self:LoadLootRoll()
	self:LoadChatBubbles()
	self:LoadLoot()
	self:ToggleItemLevelInfo(true)
	self:RegisterEvent('MERCHANT_SHOW')
	self:RegisterEvent('PLAYER_REGEN_DISABLED', 'ErrorFrameToggle')
	self:RegisterEvent('PLAYER_REGEN_ENABLED', 'ErrorFrameToggle')
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent('CHAT_MSG_BG_SYSTEM_HORDE', 'PVPMessageEnhancement')
	self:RegisterEvent('CHAT_MSG_BG_SYSTEM_ALLIANCE', 'PVPMessageEnhancement')
	self:RegisterEvent('CHAT_MSG_BG_SYSTEM_NEUTRAL', 'PVPMessageEnhancement')
	self:RegisterEvent('PARTY_INVITE_REQUEST', 'AutoInvite')
	self:RegisterEvent('GROUP_ROSTER_UPDATE', 'AutoInvite')
	self:RegisterEvent('CVAR_UPDATE', 'ForceCVars')
	self:RegisterEvent('PLAYER_ENTERING_WORLD')

	self:ManageQuestObjectives()
	if IsAddOnLoaded("Blizzard_InspectUI") then
		M:SetupInspectPageInfo()
	else
		self:RegisterEvent("ADDON_LOADED")
	end
end

local function InitializeCallback()
	M:Initialize()
end

E:RegisterModule(M:GetName(), InitializeCallback)
