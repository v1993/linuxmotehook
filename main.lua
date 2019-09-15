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

if arg[1] == '--version' then
	print('0.1.2')
	return true
elseif arg[1] == '--help' then
	print[[
linuxmotehook - cemuhook-compatible motion provider based on XWiimote.
Edit config.lua to set options.

Supported command line args:

--help      Show this information and exit
--version   Print version and exit
]]
	return true
end

-- Required for "bundle" mode
do
	local dir = debug.getinfo(1).source:match("@(.*)main.lua$")
	package.path = table.concat({dir, 'deps/share/lua/5.3/?.lua;', dir, 'deps/share/lua/5.3/?/init.lua;', package.path})
	package.cpath = dir..'deps/lib/lua/5.3/?.so;'..package.cpath
end

local wii = require 'xwiimote'
local lgi = require 'lgi'
local	GLib,		Gdk,		GObject,		Gio =
		lgi.GLib,	lgi.Gdk,	lgi.GObject,	lgi.Gio

log = lgi.log.domain('xwiimote-cemu')
getTime = require 'lgi'.GLib.get_monotonic_time

local scriptdir = Gio.File.new_for_path(debug.getinfo(1).source:match("@(.*)$")):get_parent()

local function loadfromdata(name)
	local file = scriptdir:get_child(name)
	assert(file:query_exists(), 'Uable to open load script ' .. name)
	return assert(loadfile(file:get_path()))
end

config = loadfromdata('config.lua')(loadfromdata('presets.lua')())

local wiistate = { all = {}, pkgcnt = setmetatable({}, {__index = function() return 0 end}) }

local app = Gio.Application { application_id = 'org.v1993.xwiimote-cemu', flags = 'NON_UNIQUE' }

local socket = lgi.Gio.Socket.new('IPV4', 'DATAGRAM', 'UDP')
socket.blocking = false
local sa = lgi.Gio.InetSocketAddress.new(Gio.InetAddress.new_loopback('IPV4'), 26760)
assert(socket:bind(sa, true))

local packet = loadfromdata('packet.lua')(socket)
local wiiUtils = loadfromdata('wiimote.lua')()

-- Setup network handler. Actual processing is done in `packet.lua`.
do
	-- To avoid extra allocations
	-- I assume this is long enough
	local buf = require("lgi.core").bytes.new(4096)
	local source = socket:create_source('IN')
	source:set_callback(function()
		local len, src = socket:receive_from(buf)
		if len > 0 then
			local function sendcb(data)
				assert(socket:send_to(src, data)) -- Send data back
			end

			local success, msg = xpcall(packet.process, debug.traceback,
				tostring(buf):sub(1, len),
				sendcb,
				src,
				wiistate
			)
			if not success then
				-- Debug here
				log.warning('Error when processing packet: '..msg)
			end
		end
		return true
	end)

	source:attach(lgi.GLib.MainContext.default())
end

-- Setup WiiMotes and handler new ones

local wiimonitor = assert(wii.monitor(true))

do
	for path in wiimonitor:iter() do
		wiiUtils.setup(wiistate, path, config.MPlusCalibration, packet.send)
	end

	local res, fd = wiimonitor:set_blocking(false)
	assert(res)
	local stream = Gio.UnixInputStream.new(fd, false)
	source = stream:create_source()
	source:set_callback(function()
		-- It sometimes fires as false alarm
		for path in wiimonitor:iter() do
			-- It errors if I try to open it immedeately, so wait a second first
			GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, function()
				wiiUtils.setup(wiistate, path, config.MPlusCalibration, packet.send)
			end)
		end
		return true
	end)
	source:attach(GLib.MainContext.default())
end

-- Setup handler to periodically clean up inactive clients

local function cleanupClients(clients, now, connected)
	local todelete = {}
	-- 5 seconds
	local timeout = 5000000
	for k,v in pairs(clients) do
		if (v.time + timeout) < now then
			todelete[#todelete+1] = k
		else
			connected[k] = true
		end
	end
end

GLib.timeout_add(GLib.PRIORITY_DEFAULT, 1000, function()
	local now, connected = getTime(), {}

	for k,desc in ipairs(wiistate) do
		cleanupClients(desc.clients, now, connected)
	end

	cleanupClients(wiistate.all, connected)

	local todelete = {}

	for k,v in pairs(wiistate.pkgcnt) do
		if not connected[k] then
			todelete[#todelete+1] = k
		end
	end

	for k,v in ipairs(todelete) do
		todelete[v] = nil
	end

	return true
end)

local function exitNormal()
	print('Exiting')
	app:release()
end

function app:on_activate()
	app:hold()
end

GLib.unix_signal_add(GLib.PRIORITY_HIGH, 1, exitNormal)
GLib.unix_signal_add(GLib.PRIORITY_HIGH, 2, exitNormal)
GLib.unix_signal_add(GLib.PRIORITY_HIGH, 15, exitNormal)

app:run({arg[0]})
