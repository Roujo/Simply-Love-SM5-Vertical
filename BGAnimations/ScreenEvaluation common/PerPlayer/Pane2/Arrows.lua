local player = ...
local pn = ToEnumShortString(player)
local track_missbcheld = SL[pn].ActiveModifiers.MissBecauseHeld

local ps = GAMESTATE:GetPlayerState(player)
-- NOTESKIN:LoadActorForNoteSkin() expects the noteskin name to be all lowercase
local noteskin = ps:GetCurrentPlayerOptions():NoteSkin():lower()
local style = ToEnumShortString(GAMESTATE:GetCurrentStyle():GetStyleType())

local game = GAMESTATE:GetCurrentGame():GetName()
local columns = {
	dance = { "Left", "Down", "Up", "Right" },
	pump = { "DownLeft", "UpLeft", "Center", "UpRight", "DownRight" },
	techno = { "DownLeft", "Left", "UpLeft", "Down", "Up", "UpRight", "Right", "DownRight" },
	para = { "Left", "UpLeft", "Up", "UpRight", "Right" },
	kb7 = { "Key1", "Key2", "Key3", "Key4", "Key5", "Key6", "Key7" },

	-- these games aren't supported by SL right now
	beat = { "Key1", "Key2", "Key3", "Key4", "Key5", "Key6", "Key7", "Scratch up", "Scratch down" },
	kickbox = { "Down Left Foot", "Up Left Foot", "Up Left Fist", "Down Left Fist", "Down Right Fist", "Up Right Fist", "Up Right Foot", "Down Right Foot" }
}

local rows = { "W1", "W2", "W3", "W4", "W5", "Miss" }

local function ShouldDisplayJudgmentNumber(judgment)
	if not SL[pn].ActiveModifiers.DoNotJudgeMe then return true end
	-- Show judgments worse than Great to help debug pad errors.
	-- Hide others to reduce pressure.
	if judgment > 3 then return true end
	return false
end

local box_width = 140
local box_height = 96
local column_width = box_width/#columns[game]
local row_height = box_height/#rows

-- need to store the number of columns PRIOR to looping
-- otherwise we enter an infinite loop because the upper bound keeps growing!
local num_columns = #columns[game]

if style == "OnePlayerTwoSides" then
	for i=1,num_columns do
		table.insert(columns[game], columns[game][i])
	end
end

local af = Def.ActorFrame{
	InitCommand=function(self) self:xy(-box_width/2 + 15, _screen.cy-38) end
}

local gmods = SL.Global.ActiveModifiers

for i,column in ipairs( columns[game] ) do

	-- GetNoteSkinActor() is defined in ./Scripts/SL-Helpers.lua, and performs some
	-- rudimentary error handling because NoteSkins From The Internet™ may contain Lua errors
	af[#af+1] = GetNoteSkinActor(noteskin, column)..{
		OnCommand=function(self)
			self:x( i*column_width ):zoom(0.35):visible(true)
		end
	}

	local miss_bmt = nil

	-- for each possible judgment
	for j, judgment in ipairs(rows) do
		-- don't add rows for TimingWindows that were turned off, but always add Miss
		if j <= gmods.WorstTimingWindow or j==#rows then
			local judgmentText
			if ShouldDisplayJudgmentNumber(j) then
				judgmentText=SL[pn].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].column_judgments[i][judgment]
			else
				judgmentText = "*"
			end
			-- add a BitmapText actor to be the number for this column
			af[#af+1] = LoadFont("Common Normal")..{
				Text=judgmentText,
				InitCommand=function(self)
					self:xy(i*column_width, j*row_height + 4)
						:zoom(0.8)
					if j == #rows then miss_bmt = self end
				end
			}
		end
	end

	if track_missbcheld then
		-- the number of MissBecauseHeld judgments for this column
		af[#af+1] = LoadFont("Common Normal")..{
			Text=SL[pn].Stages.Stats[SL.Global.Stages.PlayedThisGame + 1].column_judgments[i].MissBecauseHeld,
			InitCommand=function(self)
				self:xy(i*column_width - 1, 95):zoom(0.65):halign(1)
			end,
			OnCommand=function(self)
				self:x( self:GetX() - miss_bmt:GetWidth()/2 )
			end
		}
	end
end

return af
