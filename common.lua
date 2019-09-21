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

return {
	pathToMac = function(path)
		return tonumber(table.concat({path:match(':%x%x/(%x%x%x%x):(%x%x%x%x):(%x%x%x%x).%x%x%x%x$')}), 16)
	end;
	makeLoader = function()
		local scriptdir = lgi.Gio.File.new_for_path(debug.getinfo(1).source:match("@(.*)$")):get_parent()
		return function(name)
			local file = scriptdir:get_child(name)
			assert(file:query_exists(), 'Uable to open load script ' .. name)
			return assert(loadfile(file:get_path()))
		end
	end;
}
