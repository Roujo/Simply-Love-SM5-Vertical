local xOffset = _screen.cx-12.5
local yOffset = 16
local barLength = _screen.w-45

return Def.ActorFrame{
	Name="SongMeter",
	InitCommand=function(self) self:xy(xOffset, yOffset) end,

	Def.SongMeterDisplay{
		StreamWidth=(barLength),
		Stream=Def.Quad{ InitCommand=function(self) self:zoomy(14):diffuse(GetCurrentColor()) end }
	},

	Border( barLength, 18, 2 ),

	-- Song Title
	LoadFont("Common Normal")..{
		Name="SongTitle",
		InitCommand=function(self) self:zoom(0.6):shadowlength(0.6):maxwidth(barLength) end,
		CurrentSongChangedMessageCommand=function(self)
			local song = GAMESTATE:GetCurrentSong()
			self:settext( song and song:GetDisplayFullTitle() or "" )
		end

	}
}
