-- This is configuration file
-- It is just Lua script, so it must follow Lua syntax and rules
-- It will be MUCH easier if you know Lua, but overall
-- syntax is pretty intuitive.

--[[
You should either select a preset or write whole config from scratch.
To learn available fields and their meanings read presets.lua.

All available presets are listed below:

* `vertical`	- zero position is WiiMote pointed upwards
* `horizontal`	- zero position is one when buttons are oriented towards you and D-Pad is on the left

Also look below for game-specific configurations
]]--
local preset = ...

-- Set to preset you wish to use as base
local config = preset.vertical

-- Cutomize here
--[[
Example overrides:

config.keys.X = 'two'
config.keys.leftjoy.y.plus = 'down'
config.keys.rightjoy.x = {plus = 'right', minus = 'left'}
config.accel.x = { 'x', -0.75 }
config.gyro.p = { 'z', 1 }

]]--

-- For New Super Mario Bros: WiiU (preset `horizontal`):
--[[
config.accel.y = { 'z', -0.5 }
config.gyro.p = { 'y', -0.5 };
]]--

-- Make D-Pad act like left joystick (in vertical orientation)
--[[
config.keys.leftjoy = {
	x = {
		plus = 'right';
		minus = 'left';
	};
	y = {
		plus = 'up';
		minus = 'down';
	};
}
]]--

-- To disable D-Pad emulation (for example, if you use it for joystick instead)
--[[
config.keys.up = ''
config.keys.down = ''
config.keys.left = ''
config.keys.right = ''
]]--

-- End cusomizing here

-- Units for accelerometer and gyro.
-- Don't touch until you know what are you doing!

config.ACCEL_G			= 103/9.8;		-- 1 m/s^2 in abstract units
config.GYRO_DEG_PER_S	= 335160/1860;	-- 1 deg/s in abstract units


-- MotionPlus calibration data
-- They are applied to raw values, so orientation configuration doesn't matter
-- It's recommended to use device-specific overrides below
-- Notation: X, Y, Z calibration, factor value (?), X, Y, Z multilpiers

config.MPlusCalibration = {0, 0, 0, 0, 1, 1, 1}

-- Same, but allow overrides for individual wiimotes based on their MACs
-- To figure out MAC and recommended first three values, run `./autocalibrate.lua`
-- Factor is not really studied yet, so leave it zero
-- Sign of last three values control direction and only way to figure it out is by using PadTest
-- You can get is at https://cemuhook.sshnuke.net/padudpserver.html

config.MPlusCalibrationOverrides = {
	-- [0x0005057E0330] = {235, 1395, 223, 0, 1, 1, 1};
}

return config
