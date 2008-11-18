
Accomplishment = LibStub("AceAddon-3.0"):NewAddon("Accomplishment")

local registry = {}
local db

function Accomplishment:OnEnable()
	self.db = LibStub("AceDB-3.0"):New("AccomplishmentDB", { profile = { whisper = false, message = "Congratulations %s!" }}, "Default")

	db = self.db.profile

	LibStub("AceConfig-3.0"):RegisterOptionsTable("Accomplishment", {
		name = "Accomplishment",
		desc = "Allows for easy congratulations for when someone earns an Achievement.",
		type = "group",
		get = function(key) return db[key.arg] end,
		set = function(key, value) db[key.arg] = value end,
		args = {
			whisper = {
				name = "Whisper User",
				desc = "Send a congratulatory whisper to the user. Will use /say or /guild if disabled.",
				type = "toggle", order = 1, arg = "whisper",
			},
			message = {
				name = "Congratulatory Message",
				desc = "Choose what to say to the user. Use '%s' where you want the user's name to be.",
				type = "input", order = 2, arg = "message",
			},
		}, 
	})

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Accomplishment", "Accomplishment")
end


local F = CreateFrame("Frame", "AccomplishmentFrame", UIParent)
F:Hide()
F:SetWidth(180)
F:SetHeight(260)
F:SetPoint("CENTER", UIParent, "CENTER")
F:EnableMouse()
F:SetMovable(true)
F:SetFrameStrata("FULLSCREEN_DIALOG")
F:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
	edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
	tile = true, tileSize = 32, edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
F:SetBackdropColor(0, 0, 0, 1)
F:SetToplevel(true)
F:SetScript("OnDragStart", function(self) self:StartMoving() end)
F:SetScript("OnMouseDown", function(self) self:StartMoving() end)
F:SetScript("OnMouseUp", function(self) self:StopMovingOrSizing() self:SetUserPlaced(true) end)
F:RegisterForDrag("LeftButton")

local BG = F:CreateTexture(nil, "OVERLAY")
BG:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
BG:SetPoint("CENTER", F, "TOP", 0, -20)
BG:SetWidth(275)
BG:SetHeight(70)

local Title = F:CreateFontString(nil, "OVERLAY", "GameFontNormal")
Title:SetPoint("CENTER", F, "TOP", 0, -7)
Title:SetText("Accomplishment")

local CB = CreateFrame("Button", nil, F, "UIPanelButtonTemplate")
CB:SetPoint("BOTTOM", F, "BOTTOM", 0, 12)
CB:SetHeight(20)
CB:SetWidth(100)
CB:SetText("Close")
CB:SetScript("OnClick", function()
	for key, value in pairs(registry) do registry[key] = nil end
	for i=1, 10 do _G["AccomplishmentButton"..i]:Hide() end

	F:Hide()
end)


local function buttOnClick(self, button)
	local user = self.text:GetText()

	if button == "LeftButton" then
		local msg = db.message:format(user)

		if self.type == "WHISPER" then
			SendChatMessage(msg, self.type, GetDefaultLanguage("player"), user)
		else
			SendChatMessage(msg, self.type)
		end
	end

	self.type = nil
	registry[user] = nil
	self:Hide()
end


for i=1, 10 do
	local butt = CreateFrame("Button", "AccomplishmentButton"..i, F)
	butt:Hide()
	butt:SetWidth(150)
	butt:SetHeight(20)
	butt:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	butt:SetPoint("TOP", F, "TOP", 0, (-20*i) -5)
	butt:RegisterForClicks("LeftButtonDown", "RightButtonDown")
	butt:SetScript("OnClick", buttOnClick)

	local text = butt:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	butt.text = text
	text:SetPoint("CENTER", butt, "CENTER")
end


F:SetScript("OnEvent", function(self, event, achievement, name)
	registry[name] = true

	local i = 1
	for user, _ in pairs(registry) do
		local butt =  _G["AccomplishmentButton"..i]

		if not db.whisper then
			if event:find("_GUILD_") then butt.type = "GUILD" else butt.type = "SAY" end
		else
			butt.type = "WHISPER"
		end

		butt.text:SetText(user)
		butt:Show()

		if i == 10 then break end -- bail out on the 10th name as we only have 10 buttons
		i = i +1
	end

	F:SetHeight((20*i) +60)
	F:Show()
end)

F:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
F:RegisterEvent("CHAT_MSG_ACHIEVEMENT")

