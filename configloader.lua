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

local common = require 'common'
local json = require 'json'

local reader = common.makeReader()

-- Strip C-style comments away
-- This feature is disabled as currently used parser understand comments and give info on position
local function StripJSON(str)
	if false then
		return (str:gsub('/*.-*/', ''):gsub('//.-\n', ''))
	else
		return str
	end
end

local function LoadConfig(fname)
	local succ, content = pcall(reader, fname)
	if not succ or not content then
		log.warning('Failed to read config file '..fname..', continuing...')
		return {}
	end

	succ, content = pcall(json.decode, StripJSON(content), {number = {hex = true}})
	if not succ or not content then
		log.warning(table.concat{'Failed to parse config file ', fname, ': "', content or 'unknown error', '", continuing...'})
		return {}
	end

	return content
end

local function shallowCopy(src, dst)
	for k,v in pairs(src) do
		dst[k] = v
	end

	return dst
end

local configRaw = {}

local function InsertConfig(fname)
	shallowCopy(LoadConfig(fname), configRaw)
end

InsertConfig('presets.json')
InsertConfig('config.json')

-- Get property from config
local resolveProperty

resolveProperty = function(tab, path, level)
	level = level or 1
	if type(path) == 'string' then
		local pstr = path
		path = {}
		for s in pstr:gmatch('[^.]+') do
			path[#path+1] = s
		end
	end

	local resolving = path[level]
	local resolved = tab[resolving]

	if resolved ~= nil then
		if #path == level then
			return resolved -- We've made it
		elseif type(resolved) == 'table' then
			resolved = resolveProperty(resolved, path, level+1)
			if resolved ~= nil then
				return resolved
			end
		else
			error('Trying to resolve into non-table object')
		end
	end

	local basetab = tab.basedOn
	if type(basetab) == 'string' then
		basetab = {basetab}
	end

	if type(basetab) == 'table' then
		for k,v in ipairs(basetab) do
			local base = configRaw[v]
			if type(base) == 'table' then
				resolved = resolveProperty(base, path, level)
				if resolved ~= nil then
					return resolved
				end
			end
		end
	end
end

-- Resolve property with default value and type checking
local function resolvePropertyDT(tab, path, T, default)
	local function pathToString()
		if type(path) == 'table' then
			path = table.concat(path, '.')
		end
	end
	local res = resolveProperty(tab, path)
	if res == nil then
		if default then
			return default
		end

		pathToString()
		error('Property `'..path..'` not found in config but is required')
	end
	if type(res) ~= T then
		pathToString()
		error(table.concat {'Property `', path, '` have type ', type(res), ', but must have type ', T})
	end

	return res
end

local function compileProfile(profname)
	local prof = configRaw[profname]

	if not prof then
		error('Profile `'..profname..'` not found')
	end

	local function key(nam)
		return resolvePropertyDT(prof, {'keys', nam}, 'string', '')
	end

	local function joy(path)
		return resolvePropertyDT(prof, path, 'string', '')
	end

	local function motion(path)
		return resolvePropertyDT(prof, path, 'table', {'x', 0})
	end

	local function numconst(path)
		return resolvePropertyDT(prof, path, 'number')
	end

	local res = {keys = {}, accel = {}, gyro = {}}
	local keys = res.keys

	for _, kname in ipairs(common.keys) do
		keys[kname] = key(kname)
	end

	for _, jname in ipairs(common.joys.list) do
		keys[jname] = {}
		for _, axisname in ipairs(common.joys.axis) do
			keys[jname][axisname] = {}
			for _, dirname in ipairs(common.joys.dirs) do
				keys[jname][axisname][dirname] = joy({'keys', jname, axisname, dirname})
			end
		end
	end

	local accel = res.accel
	for _, axisname in ipairs(common.accel) do
		accel[axisname] = motion({'accel', axisname})
	end

	local gyro = res.gyro
	for _, axisname in ipairs(common.gyro) do
		gyro[axisname] = motion({'gyro', axisname})
	end

	res.ACCEL_G = numconst 'ACCEL_GRAV_WII' / numconst 'ACCEL_GRAV_REAL'
	res.GYRO_DEG_PER_S = numconst 'GYRO_MAX_WII' / numconst 'GYRO_MAX_REAL'

	res.MPlusCalibration = resolvePropertyDT(configRaw, {'DefaultCalibration'}, 'table')
	res.MPlusCalibrationOverrides = resolvePropertyDT(configRaw, {'Calibration'}, 'table', {})

	return res
end

return compileProfile(resolvePropertyDT(configRaw, {'UseProfile'}, 'string'))
