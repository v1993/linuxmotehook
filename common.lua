--[[
   Copyright 2019 Valeri Ochinski

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
]]--

local lgi = require 'lgi'
local scriptdir = lgi.Gio.File.new_for_path(debug.getinfo(1).source:match("@(.*)$")):get_parent()

return {
	scriptdir = scriptdir;

	keys = {'up', 'right', 'down', 'left', 'A', 'B', 'X', 'Y', 'L1', 'R1', 'L2', 'R2', 'L3', 'R3', 'options', 'share'};

	joys = {
		list = {'leftjoy', 'rightjoy'};
		axis = {'x', 'y'};
		dirs = {'minus', 'plus'};
	};

	accel	= {'x', 'y', 'z'};

	gyro	= {'p', 'y', 'r'};

	pathToMac = function(path)
		return tonumber(table.concat({path:match('(%x%x%x%x):(%x%x%x%x):(%x%x%x%x).%x%x%x%x$')}), 16)
	end;
	makeLoader = function()
		return function(name, msg)
			local file = scriptdir:get_child(name)
			assert(file:query_exists(), msg or 'Uable to open load script ' .. name)
			return assert(loadfile(file:get_path()))
		end
	end;
	makeReader = function()
		return function(name, msg)
			local file = scriptdir:get_child(name)
			assert(file:query_exists(), msg or 'Uable to open load file ' .. name)
			local stream = assert(file:read())
			local info = assert(file:query_info('standard::size', 'NONE'))
			assert(info:get_size() > 0, "Bad file size")
			return assert(stream:read_bytes(info:get_size())).data
		end
	end;
}
