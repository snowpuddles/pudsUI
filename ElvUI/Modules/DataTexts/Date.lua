local E, L, V, P, G = unpack(select(2, ...)); --Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local DT = E:GetModule('DataTexts')

local _G = _G
local date = date

local Locale = GetLocale()
local InCombatLockdown = InCombatLockdown
local hexColor, lastPanel

local function Click()
	if InCombatLockdown() then _G.UIErrorsFrame:AddMessage(E.InfoColor.._G.ERR_NOT_IN_COMBAT) return end
	_G.GameTimeFrame:Click()
end

local function OnEvent(self, event)
	local dateTable = date('*t')

	self.text:SetText(FormatShortDate(dateTable.day, dateTable.month, dateTable.year):gsub('%/', hexColor..'%/|r'):gsub('%.', hexColor..'%.|r'))
	lastPanel = self
end

local function ValueColorUpdate(hex)
	hexColor = hex

	if lastPanel ~= nil then OnEvent(lastPanel) end
end
E.valueColorUpdateFuncs[ValueColorUpdate] = true

DT:RegisterDatatext('Date', nil, {"UPDATE_INSTANCE_INFO"}, OnEvent, nil, Click, nil, nil)
