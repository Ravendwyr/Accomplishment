
Accomplishment = LibStub("AceAddon-3.0"):NewAddon("Accomplishment")

local playerLanguage =  GetDefaultLanguage("player")
local playerName = UnitName("player")
local registry = {}
local db, numShown

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
		Accomplishment:Congratulate(self.type, user)
	else
		registry[user] = nil
	end

	self.type = nil
	self:Hide()

	numShown = numShown -1

	if numShown <= 0 then F:Hide() end
end


F:SetScript("OnEvent", function(self, event, achievement, name)
	if name == playerName then return end -- we don't want to congratulate ourselves 

	registry[name] = true

	local channel
	if db.whisper then channel = "WHISPER"
	else
		if event:find("_GUILD_") then channel = "GUILD" else channel = "SAY" end
	end

	if db.autoGrats then
		Accomplishment:Congratulate(channel, name)
		return
	end

	local i = 1
	for user, _ in pairs(registry) do
		local butt =  _G["AccomplishmentButton"..i]

		butt.type = channel
		butt.text:SetText(user)
		butt:Show()

		numShown = i

		if i == db.numToShow then break end -- bail out if we've used all the available buttons
		i = i +1
	end

	F:SetHeight((20*i) +45)
	F:Show()
end)


function Accomplishment:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("AccomplishmentDB", { profile = { guildieGrats = true, strangerGrats = false, whisper = false, autoGrats = false, message = "Congratulations %s!", numToShow = 10 }}, "Default")

	db = self.db.profile

	LibStub("AceConfig-3.0"):RegisterOptionsTable("Accomplishment", {
		name = "Accomplishment",
		desc = "Allows for easy congratulations for when someone earns an Achievement.",
		type = "group",
		get = function(key) return db[key.arg] end,
		set = function(key, value) db[key.arg] = value end,
		args = {
			guildieGrats = {
				name = "Congratulate Guildies",
				desc = "Congratulate members of your guild when they earn Achievements.",
				type = "toggle", order = 1, arg = "guildieGrats",
				set = function(_, value)
					db.guildieGrats = value

					if value then F:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT")
					else F:UnregisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT") end
				end,
			},
			strangerGrats = {
				name = "Congratulate Strangers",
				desc = "Congratulate the random players around you when they earn Achievements.",
				type = "toggle", order = 2, arg = "strangerGrats",
				set = function(_, value)
					db.strangerGrats = value

					if value then F:RegisterEvent("CHAT_MSG_ACHIEVEMENT")
					else F:UnregisterEvent("CHAT_MSG_ACHIEVEMENT") end
				end,
			},
			whisper = {
				name = "Whisper User",
				desc = "Send a congratulatory whisper to the user. Will use /say or /guild if disabled.",
				type = "toggle", order = 3, arg = "whisper",
			},
			autoGrats = {
				name = "Automatically Congratulate",
				desc = "Automatically congratulate those who earn Achievements instead of clicking on a button.",
				type = "toggle", order = 4, arg = "autoGrats",
			},
			message = {
				name = "Congratulatory Message",
				desc = "Choose what to say to the user. Use '%s' where you want the user's name to be.",
				type = "input", order = 5, arg = "message",
			},
			numToShow = {
				name = "Number of People",
				desc = "Choose the maximum number of people to display in the window.",
				type = "range", order = 6, arg = "numToShow",
				min = 1, max = 50, step = 1,
			},	
		}, 
	})

	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Accomplishment", "Accomplishment")

	for i=1, db.numToShow do
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

	if db.guildieGrats then F:RegisterEvent("CHAT_MSG_GUILD_ACHIEVEMENT") end
	if db.strangerGrats then F:RegisterEvent("CHAT_MSG_ACHIEVEMENT") end
end

function Accomplishment:Congratulate(channel, name)
	local message = db.message:format(name)

	if channel == "WHISPER" then
		SendChatMessage(message, channel, playerLanguage, name)
	else
		SendChatMessage(message, channel)
	end

	registry[name] = nil
end

