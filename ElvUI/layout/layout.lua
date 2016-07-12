local E, L, V, P, G = unpack(select(2, ...)); --Inport: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local LO = E:NewModule('Layout', 'AceEvent-3.0');

--Cache global variables
--Lua functions
--WoW API / Variables
local CreateFrame = CreateFrame
local UIFrameFadeIn, UIFrameFadeOut = UIFrameFadeIn, UIFrameFadeOut

--Global variables that we don't cache, list them here for the mikk's Find Globals script
-- GLOBALS: HideLeftChat, HideRightChat, HideBothChat, LeftChatPanel, RightChatPanel, Minimap
-- GLOBALS: GameTooltip, LeftChatTab, RightChatTab
-- GLOBALS: LeftChatDataPanel, LeftMiniPanel, RightChatDataPanel, RightMiniPanel, ElvConfigToggle

local PANEL_HEIGHT = 22;

E.Layout = LO;

local function Panel_OnShow(self)
	self:SetFrameLevel(200)
	self:SetFrameStrata('BACKGROUND')
end

function LO:Initialize()
	self:CreateChatPanels()
	self:CreateMinimapPanels()


	self.BottomPanel = CreateFrame('Frame', 'ElvUI_BottomPanel', E.UIParent)
	self.BottomPanel:SetTemplate('Transparent')
	self.BottomPanel:Point('BOTTOMLEFT', E.UIParent, 'BOTTOMLEFT', -1, -1)
	self.BottomPanel:Point('BOTTOMRIGHT', E.UIParent, 'BOTTOMRIGHT', 1, -1)
	self.BottomPanel:Height(PANEL_HEIGHT)
	self.BottomPanel:SetScript('OnShow', Panel_OnShow)
	E.FrameLocks['ElvUI_BottomPanel'] = true;
	Panel_OnShow(self.BottomPanel)
	self:BottomPanelVisibility()

	self.TopPanel = CreateFrame('Frame', 'ElvUI_TopPanel', E.UIParent)
	self.TopPanel:SetTemplate('Transparent')
	self.TopPanel:Point('TOPLEFT', E.UIParent, 'TOPLEFT', -1, 1)
	self.TopPanel:Point('TOPRIGHT', E.UIParent, 'TOPRIGHT', 1, 1)
	self.TopPanel:Height(PANEL_HEIGHT)
	self.TopPanel:SetScript('OnShow', Panel_OnShow)
	Panel_OnShow(self.TopPanel)
	E.FrameLocks['ElvUI_TopPanel'] = true;
	self:TopPanelVisibility()
end

function LO:BottomPanelVisibility()
	if E.db.general.bottomPanel and not E.global.tukuiMode then
		self.BottomPanel:Show()
	else
		self.BottomPanel:Hide()
	end
end

function LO:TopPanelVisibility()
	if E.db.general.topPanel then
		self.TopPanel:Show()
	else
		self.TopPanel:Hide()
	end
end

local function ChatPanelLeft_OnFade(self)
	LeftChatPanel:Hide()
end

local function ChatPanelRight_OnFade(self)
	RightChatPanel:Hide()
end

local function ChatButton_OnEnter(self, ...)
	if E.db[self.parent:GetName()..'Faded'] then
		self.parent:Show()
		UIFrameFadeIn(self.parent, 0.2, self.parent:GetAlpha(), 1)
		UIFrameFadeIn(self, 0.2, self:GetAlpha(), 1)
	end

	if not self.parent.editboxforced then
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT', 0, 4)
		GameTooltip:ClearLines()
		GameTooltip:AddDoubleLine(L["Left Click:"], L["Toggle Chat Frame"], 1, 1, 1)
		GameTooltip:Show()
	end
end

local function ChatButton_OnLeave(self, ...)
	if E.db[self.parent:GetName()..'Faded'] then
		UIFrameFadeOut(self.parent, 0.2, self.parent:GetAlpha(), 0)
		UIFrameFadeOut(self, 0.2, self:GetAlpha(), 0)
		self.parent.fadeInfo.finishedFunc = self.parent.fadeFunc
	end
	GameTooltip:Hide()
end

function LO:ToggleChatTabPanels(rightOverride, leftOverride)
	if leftOverride or not E.db.chat.panelTabBackdrop then
		LeftChatTab:Hide()
	else
		LeftChatTab:Show()
	end

	if rightOverride or not E.db.chat.panelTabBackdrop then
		RightChatTab:Hide()
	else
		RightChatTab:Show()
	end
end

function LO:SetChatTabStyle()
	if E.db.chat.panelTabTransparency then
		LeftChatTab:SetTemplate("Transparent")
		RightChatTab:SetTemplate("Transparent")
	else
		LeftChatTab:SetTemplate("Default", true)
		RightChatTab:SetTemplate("Default", true)
	end
end

function LO:SetDataPanelStyle()
	if E.db.datatexts.panelTransparency then
		LeftChatDataPanel:SetTemplate("Transparent")
		LeftMiniPanel:SetTemplate("Transparent")
		RightChatDataPanel:SetTemplate("Transparent")
		RightMiniPanel:SetTemplate("Transparent")
		-- ElvConfigToggle:SetTemplate("Transparent")
	else
		LeftChatDataPanel:SetTemplate("Default", true)
		LeftMiniPanel:SetTemplate("Default", true)
		RightChatDataPanel:SetTemplate("Default", true)
		RightMiniPanel:SetTemplate("Default", true)
		-- ElvConfigToggle:SetTemplate("Default", true)
	end
end

function LO:ToggleChatPanels()
	LeftChatDataPanel:ClearAllPoints()
	RightChatDataPanel:ClearAllPoints()
	local SPACING = E.Border*3 - E.Spacing

	if E.db.datatexts.leftChatPanel then
		LeftChatDataPanel:Show()
	else
		LeftChatDataPanel:Hide()
	end

	if E.db.datatexts.rightChatPanel then
		RightChatDataPanel:Show()
	else
		RightChatDataPanel:Hide()
	end
	
	local panelBackdrop = E.db.chat.panelBackdrop
	if(E.global.tukuiMode) then
		panelBackdrop = 'HIDEBOTH'
	end
	
	if panelBackdrop == 'SHOWBOTH' then
		LeftChatPanel.backdrop:Show()
		RightChatPanel.backdrop:Show()
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', -SPACING, (SPACING + PANEL_HEIGHT))
		RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
		RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', -SPACING, SPACING + PANEL_HEIGHT)

		LO:ToggleChatTabPanels()
	elseif panelBackdrop == 'HIDEBOTH' then
		LeftChatPanel.backdrop:Hide()
		RightChatPanel.backdrop:Hide()
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT')
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', 0, PANEL_HEIGHT)
		RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT')
		RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', 0, PANEL_HEIGHT)
		LO:ToggleChatTabPanels(true, true)
	elseif panelBackdrop == 'LEFT' then
		LeftChatPanel.backdrop:Show()
		RightChatPanel.backdrop:Hide()
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', -SPACING, (SPACING + PANEL_HEIGHT))
		RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT')
		RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', 0, PANEL_HEIGHT)
		LO:ToggleChatTabPanels(true)
	else
		LeftChatPanel.backdrop:Hide()
		RightChatPanel.backdrop:Show()
		LeftChatDataPanel:Point('BOTTOMLEFT', LeftChatPanel, 'BOTTOMLEFT')
		LeftChatDataPanel:Point('TOPRIGHT', LeftChatPanel, 'BOTTOMRIGHT', 0, PANEL_HEIGHT)
		RightChatDataPanel:Point('BOTTOMLEFT', RightChatPanel, 'BOTTOMLEFT', SPACING, SPACING)
		RightChatDataPanel:Point('TOPRIGHT', RightChatPanel, 'BOTTOMRIGHT', -SPACING, SPACING + PANEL_HEIGHT)
		LO:ToggleChatTabPanels(nil, true)
	end
end

function LO:CreateChatPanels()
	local SPACING = E.Border*3 - E.Spacing

	--Left Chat
	local lchat = CreateFrame('Frame', 'LeftChatPanel', E.UIParent)
	lchat:SetFrameStrata('BACKGROUND')
	lchat:SetFrameLevel(300)
	lchat:Size(E.db.chat.panelWidth, E.db.chat.panelHeight)
	lchat:Point('BOTTOMLEFT', E.UIParent, 4, 4)
	lchat:CreateBackdrop('Transparent')
	lchat.backdrop:SetAllPoints()
	E:CreateMover(lchat, "LeftChatMover", L["Left Chat"])


	--Background Texture
	lchat.tex = lchat:CreateTexture(nil, 'OVERLAY')
	lchat.tex:SetInside()
	lchat.tex:SetTexture(E.db.chat.panelBackdropNameLeft)
	lchat.tex:SetAlpha(E.db.general.backdropfadecolor.a - 0.7 > 0 and E.db.general.backdropfadecolor.a - 0.7 or 0.5)

	--Left Chat Tab
	local lchattab = CreateFrame('Frame', 'LeftChatTab', LeftChatPanel)
	lchattab:Point('TOPLEFT', lchat, 'TOPLEFT', SPACING, -SPACING)
	lchattab:Point('BOTTOMRIGHT', lchat, 'TOPRIGHT', -SPACING, -(SPACING + PANEL_HEIGHT))
	lchattab:SetTemplate(E.db.chat.panelTabTransparency == true and 'Transparent' or 'Default', true)

	--Left Chat Data Panel
	local lchatdp = CreateFrame('Frame', 'LeftChatDataPanel', LeftChatPanel)
	lchatdp:Point('BOTTOMLEFT', lchat, 'BOTTOMLEFT', SPACING, SPACING)
	lchatdp:Point('TOPRIGHT', lchat, 'BOTTOMRIGHT', -SPACING, (SPACING + PANEL_HEIGHT))
	lchatdp:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	
	E:GetModule('DataTexts'):RegisterPanel(lchatdp, 3, 'ANCHOR_TOPLEFT', -17, 4)


	--Right Chat
	local rchat = CreateFrame('Frame', 'RightChatPanel', E.UIParent)
	rchat:SetFrameStrata('BACKGROUND')
	rchat:SetFrameLevel(300)
	rchat:Size(E.db.chat.separateSizes and E.db.chat.panelWidthRight or E.db.chat.panelWidth, E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight)
	rchat:Point('BOTTOMRIGHT', E.UIParent, -4, 4)
	rchat:CreateBackdrop('Transparent')
	rchat.backdrop:SetAllPoints()
	E:CreateMover(rchat, "RightChatMover", L["Right Chat"])

	--Background Texture
	rchat.tex = rchat:CreateTexture(nil, 'OVERLAY')
	rchat.tex:SetInside()
	rchat.tex:SetTexture(E.db.chat.panelBackdropNameRight)
	rchat.tex:SetAlpha(E.db.general.backdropfadecolor.a - 0.7 > 0 and E.db.general.backdropfadecolor.a - 0.7 or 0.5)

	--Right Chat Tab
	local rchattab = CreateFrame('Frame', 'RightChatTab', RightChatPanel)
	rchattab:Point('TOPRIGHT', rchat, 'TOPRIGHT', -SPACING, -SPACING)
	rchattab:Point('BOTTOMLEFT', rchat, 'TOPLEFT', SPACING, -(SPACING + PANEL_HEIGHT))
	rchattab:SetTemplate(E.db.chat.panelTabTransparency == true and 'Transparent' or 'Default', true)

	--Right Chat Data Panel
	local rchatdp = CreateFrame('Frame', 'RightChatDataPanel', RightChatPanel)
	rchatdp:Point('BOTTOMLEFT', rchat, 'BOTTOMLEFT', SPACING, SPACING)
	rchatdp:Point('TOPRIGHT', rchat, 'BOTTOMRIGHT', -SPACING, SPACING + PANEL_HEIGHT)
	rchatdp:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	E:GetModule('DataTexts'):RegisterPanel(rchatdp, 3, 'ANCHOR_TOPRIGHT', 17, 4)

	--Load Settings
	if E.db['LeftChatPanelFaded'] then
		LeftChatPanel:Hide()
	end

	if E.db['RightChatPanelFaded'] then
		RightChatPanel:Hide()
	end

	self:ToggleChatPanels()
end

function LO:CreateMinimapPanels()
	local lminipanel = CreateFrame('Frame', 'LeftMiniPanel', Minimap)

	lminipanel:Point('TOPLEFT', Minimap, 'BOTTOMLEFT', -E.Border, -E.Spacing*3)
	lminipanel:Point('BOTTOMRIGHT', Minimap, 'BOTTOM', 0, -(E.Spacing*3 + PANEL_HEIGHT))
	lminipanel:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	E:GetModule('DataTexts'):RegisterPanel(lminipanel, 1, 'ANCHOR_BOTTOMLEFT', lminipanel:GetWidth() * 2, -4)

	local rminipanel = CreateFrame('Frame', 'RightMiniPanel', Minimap)
	rminipanel:Point('TOPRIGHT', Minimap, 'BOTTOMRIGHT', E.Border, -(E.Spacing*3))
	rminipanel:Point('BOTTOMLEFT', lminipanel, 'BOTTOMRIGHT', -E.Border + (E.Spacing*3), 0)
	rminipanel:SetTemplate(E.db.datatexts.panelTransparency and 'Transparent' or 'Default', true)
	E:GetModule('DataTexts'):RegisterPanel(rminipanel, 1, 'ANCHOR_BOTTOM', 0, -4)

	if E.db.datatexts.minimapPanels then
		LeftMiniPanel:Show()
		RightMiniPanel:Show()
	else
		LeftMiniPanel:Hide()
		RightMiniPanel:Hide()
	end

	if(E.global.tukuiMode) then
		local BottomLine = CreateFrame("Frame", nil, E.UIParent)
		BottomLine:SetTemplate()
		BottomLine:Size(2)
		BottomLine:Point("BOTTOMLEFT", 15, 15)
		BottomLine:Point("BOTTOMRIGHT", -15, 15)
		BottomLine:SetFrameStrata("BACKGROUND")
		BottomLine:SetFrameLevel(0)

		local LeftVerticalLine = CreateFrame("Frame", nil, BottomLine)
		LeftVerticalLine:SetTemplate()
		LeftVerticalLine:Point("BOTTOMLEFT", 0, 0)
		LeftVerticalLine:SetFrameLevel(0)
		LeftVerticalLine:SetFrameStrata("BACKGROUND")


		local RightVerticalLine = CreateFrame("Frame", nil, BottomLine)
		RightVerticalLine:SetTemplate()
		RightVerticalLine:Point("BOTTOMRIGHT", 0, 0)
		RightVerticalLine:SetFrameLevel(0)
		RightVerticalLine:SetFrameStrata("BACKGROUND")


		local CubeLeft = CreateFrame("Frame", nil, LeftVerticalLine)
		CubeLeft:SetTemplate()
		CubeLeft:Size(10)
		CubeLeft:Point("BOTTOM", LeftVerticalLine, "TOP", 0, 0)
		CubeLeft:EnableMouse(true)
		CubeLeft:SetFrameLevel(0)
		CubeLeft:SetScript("OnMouseDown", function(self, Button)
			if (Button == "LeftButton") then	
				ToggleFrame(ChatMenu)
			end
		end)

		local CubeRight = CreateFrame("Frame", nil, RightVerticalLine)
		CubeRight:SetTemplate()
		CubeRight:Size(10)
		CubeRight:Point("BOTTOM", RightVerticalLine, "TOP", 0, 0)
		CubeRight:EnableMouse(true)
		CubeRight:SetFrameLevel(0)
		CubeRight:SetScript("OnMouseDown", function(self, Button)
			if (Button == "LeftButton") then	
				ToggleCharacter("ReputationFrame")
			end
		end)
		
		hooksecurefunc(E:GetModule("Chat"), "PositionChat", function()
			LeftVerticalLine:Size(2, E.db.chat.panelHeight - 40)
			RightVerticalLine:Size(2, (E.db.chat.separateSizes and E.db.chat.panelHeightRight or E.db.chat.panelHeight) - 40)	
		end)
	end
	
	local f = CreateFrame("Frame", 'BottomMiniPanel', Minimap)
	f:SetPoint("BOTTOM", Minimap, "BOTTOM")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOM', 0, -10)
	
	f = CreateFrame("Frame", 'TopMiniPanel', Minimap)
	f:SetPoint("TOP", Minimap, "TOP")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOM', 0, -10)		
	
	f = CreateFrame("Frame", 'TopLeftMiniPanel', Minimap)
	f:SetPoint("TOPLEFT", Minimap, "TOPLEFT")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOMLEFT', 0, -10)	

	f = CreateFrame("Frame", 'TopRightMiniPanel', Minimap)
	f:SetPoint("TOPRIGHT", Minimap, "TOPRIGHT")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOMRIGHT', 0, -10)	
	
	f = CreateFrame("Frame", 'BottomLeftMiniPanel', Minimap)
	f:SetPoint("BOTTOMLEFT", Minimap, "BOTTOMLEFT")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOMLEFT', 0, -10)	

	f = CreateFrame("Frame", 'BottomRightMiniPanel', Minimap)
	f:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT")
	f:Width(75)
	f:Height(20)
	f:SetFrameLevel(Minimap:GetFrameLevel() + 5)
	E:GetModule('DataTexts'):RegisterPanel(f, 1, 'ANCHOR_BOTTOMRIGHT', 0, -10)
end

E:RegisterModule(LO:GetName())