local vertical = {
--[[
Button mapping
Key is emulated button, value is real WiiMote button
Possible WiiMote buttons (keep quotes):

	"left"
	"right"
	"up"
	"down"
	"A"
	"B"
	"plus"
	"minus"
	"home"
	"one"
	"two"

Set value to empty string to disable button completely.
]]--

	keys = {
		-- dpad = {
			up = 'up';
			right = 'right';
			down = 'down';
			left = 'left';
		--};

		A = 'A';
		B = 'B';
		X = '';
		Y = '';

		L1 = '';
		R1 = '';
		L2 = '';
		R2 = '';
		L3 = '';
		R3 = '';

		options = 'home';
		share = '';

		-- Joysticks

		leftjoy = {
			x = {
				plus = '';
				minus = '';
			};
			y = {
				plus = '';
				minus = '';
			}
		};
		rightjoy = {
			x = {
				plus = '';
				minus = '';
			};
			y = {
				plus = '';
				minus = '';
			}
		};
	};

	-- Accelerometer and gyroscope
	-- Each entry represent one axis
	-- Key is which emulated axis is configured
	-- First field encodes what real axis is mapped
	-- Second field sets multiplier (1 and -1 are most useful values)
	-- It is useful in cases when you want to hold WiiMote sideways or do something unusual

	accel = {
		x = { 'x', 1 };
		y = { 'y', 1 };
		z = { 'z', -1 };
	};

	gyro = {
		p = { 'z', 1 };
		y = { 'y', -1 };
		r = { 'x', 1 };
	};
};

local horizontal = {
	keys = {
		-- dpad = {
			up = 'right';
			right = 'down';
			down = 'left';
			left = 'up';
		--};

		A = 'two';
		B = 'one';
		X = '';
		Y = '';

		L1 = '';
		R1 = '';
		L2 = '';
		R2 = '';
		L3 = '';
		R3 = '';

		options = 'home';
		share = '';

		-- Joysticks

		leftjoy = {
			x = {
				plus = '';
				minus = '';
			};
			y = {
				plus = '';
				minus = '';
			}
		};
		rightjoy = {
			x = {
				plus = '';
				minus = '';
			};
			y = {
				plus = '';
				minus = '';
			}
		};
	};

	-- Accelerometer and gyroscope

	accel = {
		x = { 'y', -1 };
		y = { 'z', -1 };
		z = { 'x', -1 };
	};

	gyro = {
		p = { 'y', -1 };
		y = { 'x', 1 };
		r = { 'z', 1 };
	};
};

return {
	vertical = vertical;
	horizontal = horizontal;
}
