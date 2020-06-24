-- this difficulty grid doesn't support CourseMode
-- CourseContentsList.lua should be used instead
if GAMESTATE:IsCourseMode() then return end
-- ----------------------------------------------

local num_rows    = 5
local num_columns = 20
local GridZoomX = 0.39
local RowHeight = 14
local StepsToDisplay, SongOrCourse, StepsOrTrails
local quadHeight = 75
local quadWidth = 125

local GetStepsToDisplay = LoadActor("./StepsToDisplay.lua")

local t = Def.ActorFrame{
	Name="StepsDisplayList",
	InitCommand=function(self) self:vertalign(top):xy(quadWidth/2, _screen.cy) end,

	OnCommand=function(self) self:queuecommand("RedrawStepsDisplay") end,
	CurrentSongChangedMessageCommand=function(self)    self:queuecommand("RedrawStepsDisplay") end,
	CurrentStepsP1ChangedMessageCommand=function(self) self:queuecommand("RedrawStepsDisplay") end,
	CurrentStepsP2ChangedMessageCommand=function(self) self:queuecommand("RedrawStepsDisplay") end,

	RedrawStepsDisplayCommand=function(self)

		local song = GAMESTATE:GetCurrentSong()

		if song then
			local steps = SongUtil.GetPlayableSteps( song )

			if steps then
				local StepsToDisplay = GetStepsToDisplay(steps)

				for i=1,num_rows do
					chart = StepsToDisplay[i]
					if chart then
						-- if this particular song has a stepchart for this row, update the Meter
						-- and BlockRow coloring appropriately
						local meter = chart:GetMeter()
						local difficulty = chart:GetDifficulty()
						self:GetChild("Grid"):GetChild("Meter_"..i):playcommand("Set", {Meter=meter, Difficulty=difficulty})
						self:GetChild("Grid"):GetChild("Blocks_"..i):playcommand("Set", {Chart=chart})
					else
						-- otherwise, set the meter to an empty string and hide this particular colored BlockRow
						self:GetChild("Grid"):GetChild("Meter_"..i):playcommand("Unset")
						self:GetChild("Grid"):GetChild("Blocks_"..i):playcommand("Unset")

					end
				end
			end
		else
			self:playcommand("Unset")
		end
	end,

	-- - - - - - - - - - - - - -

	-- background
	Def.Quad{
		Name="Background",
		InitCommand=function(self)
			self:diffuse(color("#1e282f")):zoomto(quadWidth, quadHeight)
			if ThemePrefs.Get("RainbowMode") then
				self:diffusealpha(0.9)
			end
		end
	},

	Def.Quad{
		Name="Cursor",
		InitCommand=function(self)
			self:x(0)
			self:diffuse(color("#ffffff")):diffusealpha(0.3):zoomto(quadWidth, RowHeight)
		end,
		OnCommand=function(self) self:queuecommand("Set") end,
		CurrentSongChangedMessageCommand=function(self) self:queuecommand("Set") end,
		CurrentCourseChangedMessageCommand=function(self) self:queuecommand("Set") end,
		CurrentStepsP1ChangedMessageCommand=function(self) self:queuecommand("Set") end,
		CurrentTrailP1ChangedMessageCommand=function(self) self:queuecommand("Set") end,
		CurrentStepsP2ChangedMessageCommand=function(self) self:queuecommand("Set") end,
		CurrentTrailP2ChangedMessageCommand=function(self) self:queuecommand("Set") end,

		SetCommand=function(self)
			local song = GAMESTATE:GetCurrentSong()

			if song then
				local player = GAMESTATE:GetMasterPlayerNumber()
				local allSteps = SongUtil.GetPlayableSteps(song)
				local stepsToDisplay = GetStepsToDisplay(allSteps)
				local currentSteps = GAMESTATE:GetCurrentSteps(player)

				for i,chart in pairs(stepsToDisplay) do
					if chart == currentSteps then
						RowIndex = i
						break
					end
				end
			end

			-- keep within reasonable limits because Edit charts are a thing
			RowIndex = clamp(RowIndex, 1, 5)

			-- update cursor y position
			local animationSpeed = self:GetVisible() and 0.1 or 0
			self:stoptweening():linear(animationSpeed):y(RowHeight * (RowIndex - 3))
			if song then self:visible(true) else self:visible(false) end
		end
	}
}


local Grid = Def.ActorFrame{
	Name="Grid",
	InitCommand=function(self) self:horizalign(left):vertalign(top):xy(8, -quadHeight/2-5) end,
}

for RowNumber=1,num_rows do

	Grid[#Grid+1] =	LoadFont("Common Normal")..{
		Name="StepArtist_"..RowNumber,

		OnCommand=function(self)
			self:y(RowNumber * RowHeight)
			self:x(-quadWidth/2+13)
			self:horizalign(left)
			self:maxwidth(195)
			self:zoom(0.5)
		end,
		SetCommand=function(self, params)
			-- Display stepartist name.
			-- TODO: Display other available chart data.
			stepartist = params.Chart:GetAuthorCredit()
			self:settext(stepartist)
			DiffuseEmojis(self, stepartist)
		end,
		UnsetCommand=function(self)
			self:settext("")
		end,
		OffCommand=function(self) self:stoptweening() end
	}

	Grid[#Grid+1] = LoadFont("_wendy small")..{
		Name="Meter_"..RowNumber,
		InitCommand=function(self)
			self:horizalign(right)
			self:y(RowNumber * RowHeight)
			self:x(-quadWidth/2+7)
			self:zoom(0.2)
		end,
		SetCommand=function(self, params)
			-- diffuse and set each chart's difficulty meter
			self:diffuse( DifficultyColor(params.Difficulty) )
			self:settext(params.Meter)
		end,
		UnsetCommand=function(self) self:settext(""):diffuse(color("#182025")) end,
	}
end

t[#t+1] = Grid

return t
