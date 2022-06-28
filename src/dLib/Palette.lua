--[[
@name Palette
@description Easy color picker using Google Material's color system to pick colors.
@author dig1t

Functions
	Palette(color, shade: 500) => Color3 Creates a Color3 object from the given color

Examples
local button = Instance.new('TextButton')
local btnColor = Palette('blue', 500)
local btnHover = Palette('blue', 300)

button.BackgroundColor3 = btnColor

button.MouseEnter:Connect(function()
	btn.BackgroundColor3 = btnHover
end)

button.MouseLeave:Connect(function()
	btn.BackgroundColor3 = btnColor
end)
]]

local shadeIndex = {
	[50] = 1, [100] = 2, [200] = 3, [300] = 4, [400] = 5, [500] = 6, [600] = 7, [700] = 8, [800] = 9, [900] = 10
}

local palette = {
	red = {
		{255, 255, 255},
		{252, 218, 216},
		{250, 183, 180},
		{247, 149, 144},
		{245, 115, 109},
		{242, 81, 73},
		{239, 47, 37},
		{223, 26, 16},
		{187, 22, 13},
		{151, 17, 11}
	};
	
	orange = {
		{253, 242, 230},
		{251, 216, 181},
		{248, 197, 145},
		{246, 178, 109},
		{244, 159, 73},
		{242, 140, 37},
		{227, 121, 14},
		{191, 102, 11},
		{155, 82, 9},
		{119, 63, 7}
	};
	
	yellow = {
		{255, 255, 255},
		{255, 251, 212},
		{255, 247, 174},
		{255, 243, 136},
		{255, 239, 97},
		{255, 235, 59},
		{255, 231, 21},
		{238, 213, 0},
		{199, 179, 0},
		{161, 145, 0}
	};
	
	gold = {
		{253, 246, 218},
		{250, 235, 170},
		{248, 226, 134},
		{246, 217, 97},
		{244, 209, 61},
		{242, 200, 25},
		{217, 177, 12},
		{180, 147, 10},
		{144, 118, 8},
		{108, 88, 6}
	};
	
	green = {
		{198, 238, 205},
		{159, 226, 170},
		{130, 217, 144},
		{100, 208, 118},
		{71, 199, 92},
		{54, 178, 74},
		{45, 149, 62},
		{36, 119, 50},
		{27, 90, 37},
		{18, 61, 25}
	};
	
	blue = {
		{250, 247, 254},
		{192, 223, 251},
		{156, 205, 249},
		{120, 187, 247},
		{84, 168, 244},
		{48, 150, 242},
		{15, 132, 237},
		{13, 112, 201},
		{10, 92, 165},
		{8, 72, 129}
	};
	
	purple = {
		{247, 240, 250},
		{226, 200, 239},
		{210, 171, 230},
		{194, 141, 221},
		{178, 112, 213},
		{162, 82, 204},
		{145, 56, 191},
		{123, 48, 162},
		{100, 39, 132},
		{78, 30, 103}
	};
	
	['blue-grey'] = {
		{237, 239, 242},
		{209, 212, 219},
		{187, 193, 203},
		{165, 173, 186},
		{144, 153, 170},
		{122, 133, 153},
		{103, 114, 134},
		{86, 95, 112},
		{70, 77, 91},
		{53, 59, 69}
	};
	
	grey = {
		{224, 224, 224},
		{199, 199, 199},
		{179, 179, 179},
		{160, 160, 160},
		{141, 141, 141},
		{122, 122, 122},
		{103, 103, 103},
		{84, 84, 84},
		{65, 65, 65},
		{46, 46, 46}
	};
}

return function(color, shade)
	shade = shade or 500 -- Default shade
	
	assert(palette[color], color .. ' is not a valid color')
	assert(palette[color][shadeIndex[shade]], color .. ' ' .. shade .. ' is not a valid shade')
	
	return Color3.fromRGB(unpack(palette[color][shadeIndex[shade]]))
end
