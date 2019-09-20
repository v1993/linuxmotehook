#!/usr/bin/env lua5.3

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

-- Required for "bundle" mode
do
	local dir = debug.getinfo(1).source:match("@(.*)autocalibrate.lua$")
	package.path = table.concat({dir, 'deps/share/lua/5.3/?.lua;', dir, 'deps/share/lua/5.3/?/init.lua;', package.path})
	package.cpath = dir..'deps/lib/lua/5.3/?.so;'..package.cpath
end

local wii = require 'xwiimote'
local lgi = require 'lgi'
local	GLib,		Gdk,		GObject,		Gio =
		lgi.GLib,	lgi.Gdk,	lgi.GObject,	lgi.Gio

local app = Gio.Application { application_id = 'org.v1993.linuxmotehook-autocalibrate', flags = 'NON_UNIQUE' }

local monitor = wii.monitor()
local path = assert(monitor:poll(), 'Please plug wiimote before running autocalibration')

if monitor:poll() then
	print('WARNING: few wiimotes connected, only first will be calibrated. Connect only one to remove this warning.')
end

local iface = wii.iface(path)
print(('Calibrating wiimote with MAC 0x%012X'):format(path,
tonumber(table.concat({path:match(':%x%x/(%x%x%x%x):(%x%x%x%x):(%x%x%x%x).%x%x%x%x$')}), 16)))

assert(iface:open(wii.mplus), "Can't open motion plus!")

print('Please leave your wiimote on any surface and make sure it will not move in next 30 seconds.')
print('You can interrupt program before, but results may be worse.')
print('Press ENTER when ready')
io.read()
print()

-- 30 seconds
local CALIBRATION_MAXTIME = 30 * 1000000
local startTime, lastTimestamp

-- Values to hand out
local x, y, z = 0, 0, 0

local function getMvTimestamp(ev)
	-- Convert event timestamp to microseconds (accurate)
	local ts = ev.timestamp_full
	return ts.sec * 1000000 + ts.usec
end

local fd = iface:get_fd()
local stream = lgi.Gio.UnixInputStream.new(fd, false)
local source = stream:create_source()

source:set_callback(function()
	for event in iface:iter() do
		if event.watch then
			print('WiiMote disconnected, cancelling calibration')
			os.exit(1)
		elseif event.mplus then
			local gyro = event.mplus

			local timeDiff
			if not lastTimestamp then
				lastTimestamp = getMvTimestamp(event)
				startTime = lastTimestamp
				goto continue
			else
				local newtime = getMvTimestamp(event)
				timeDiff = newtime - lastTimestamp
				lastTimestamp = newtime
				if timeDiff <= 0 then
					goto continue
				end
			end

			x = x + gyro.x*timeDiff
			y = y + gyro.y*timeDiff
			z = z + gyro.z*timeDiff

			if lastTimestamp - startTime > CALIBRATION_MAXTIME then
				print('Done!')
				app:release()
			end
		end
		::continue::
	end
	return true
end)
source:attach(lgi.GLib.MainContext.default())

local function exitNormal()
	print('Exiting early, results may be less accurate')
	app:release()
end

function app:on_activate()
	app:hold()
end

GLib.unix_signal_add(GLib.PRIORITY_HIGH, 1, exitNormal)
GLib.unix_signal_add(GLib.PRIORITY_HIGH, 2, exitNormal)
GLib.unix_signal_add(GLib.PRIORITY_HIGH, 15, exitNormal)

app:run({arg[0], ...})

local time = lastTimestamp - startTime

local res = {x//time, y//time, z//time}

print(('Calibration data: %d, %d, %d'):format(table.unpack(res)))
print('Use it as first three values in motion plus calibration (leave factor zero and multipliers ones)')
