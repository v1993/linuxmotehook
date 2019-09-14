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
local wii = require 'xwiimote'

local function getMvTimestamp(ev)
	-- Convert event timestamp to microseconds (accurate)
	local ts = ev.timestamp_full
	return ts.sec * 1000000 + ts.usec
end

local function getClients(desc, wiistate)
	local merged = {}
	for k,v in pairs(wiistate.all) do
		merged[#merged+1] = v
	end
	for k,v in pairs(desc.clients) do
		merged[#merged+1] = v
	end

	return merged
end

-- Adjust this value depending on various stuff
-- 64 almost never triggers, 32 seems fairly good, 16 sometimes overflows

local EVENT_OVERFLOW = 64

local function eventCallback(desc, wiistate, source, sendcb)
	local sendRequired = false -- Is there any unsent info at the time of leaving the loop

	local clients = getClients(desc, wiistate)
	local battery = desc.iface:get_battery()
	local cnt = 0

	local function send()
		sendRequired = not pcall(sendcb, desc.id, desc, wiistate, clients, battery)
	end

	local function sendMotion(ev)
		local ts = getMvTimestamp(ev)
		if ts ~= desc.mvtime then
			--print('Sending ', desc.mvtime)
			send()
			desc.mvtime = ts
			desc.accel = desc.accel_last or desc.accel
			desc.mplus = desc.mplus_last or desc.mplus
			return true
		end
	end

	for ev in desc.iface:iter() do
		cnt=cnt+1
		if ev.watch then
			-- Hot(un)plug
			local available = desc.iface:available()
			if not available or available == 0 then
				-- Lookup failed so we're likely disconnected
				local idx = desc.id + 1
				table.remove(wiistate, idx)
				-- Update IDs of shifted WiiMotes
				for i = idx, #wiistate do
					wiistate[i].id = i - 1
				end
				source:destroy()
				print('WiiMote successfully disconnected')
				return
			elseif (available & wii.mplus) ~= 0 and (desc.iface:opened() & wii.mplus) == 0 then
				-- Motion plus got connected
				desc.mplus_connected = desc.iface:open(wii.mplus)
				if not desc.mplus_connected then
					log.warning('MotionPlus was connected but cannot be opened')
				else
					print('MotionPlus is successfuly registered and will be used')
				end
			elseif (available & wii.mplus) == 0 and desc.mplus_connected then
				-- Motion plus got disconnected
				-- NOTE: this routine is untested
				desc.mplus_connected = false
				desc.mplus = {x = 0, y = 0, z = 0}	-- Reset gyro data to zero
				desc.mplus_new = nil
				print('MotionPlus is successfuly disconnected, providen data will be limited to acceleration only')
			end
		elseif ev.key then
			-- Key pressed/released (don't loose keypresses!)
			desc.keys[ev.key] = (ev.state ~= 0)
			-- Resend on error
			send()
		elseif ev.accel then
			sendMotion(ev)
			desc.accel_last = ev.accel
		elseif ev.mplus then
			-- TODO: it breaks PadTest and I have no idea why
			--sendMotion(ev)
			desc.mplus_last = ev.mplus
		end
		if cnt == EVENT_OVERFLOW then
			log.critical('Event loop got overflown! Dropping remaining events.')
			for ev in desc.iface:iter() do
				-- FIXME: don't drop watch events!
				if ev.watch then
					log.error("Trying to drop watch event. This is a serious problem which I was too lazy to handle, so we're gonna crash.")
				end
			end
			goto tofinal
		end
	end

	::tofinal::
	if sendRequired then
		local res,err = xpcall(sendcb, debug.traceback, desc.id, desc, wiistate, clients, battery)
		if not res then
			log.warning('Failed to send data: '..err)
		end
	end
end

local function setup(wiistate, path, MPlusCalibration, sendcb)
	local iface = assert(wii.iface(path))
	assert(iface:open(wii.core | wii.accel))
	iface:watch(true) -- To detect mplus connection/disconnection
	local desc = {
		-- Metainfo
		iface = iface;
		clients = {};
		id = #wiistate;

		-- Actual state
		keys =		{};						-- Pressed keys (none initially)
		accel =		{x = 0, y = 0, z = 0};	-- Acceleration data
		mplus =		{x = 0, y = 0, z = 0};	-- Gyro data (if present)
		mvtime =	0;						-- When last gyro/accel event was fired
	}
	-- Try to open MotionPlus and don't fail if we can't
	iface:set_mp_normalization(table.unpack(MPlusCalibration))
	desc.mplus_connected = iface:open(wii.mplus)
	if not desc.mplus_connected then
		print('Note: no MotionPlus detected, providen data will be limited to acceleration only')
		print('If you have one, it can be hotplugged now')
		print()
	end

	-- Not sure if it's dec or hex, go with hex for safety
	-- desc.id = tonumber(path:match(':(%x%x)/%x%x%x%x:%x%x%x%x:%x%x%x%x.%x%x%x%x$'), 16)
	desc.mac = tonumber(table.concat({path:match(':%x%x/(%x%x%x%x):(%x%x%x%x):(%x%x%x%x).%x%x%x%x$')}), 16)
	local devgen = iface:get_devtype():match('gen(%d+)')
	desc.devgen = devgen and tonumber(devgen) or 0xff

	wiistate[desc.id+1] = desc
	local fd = iface:get_fd()
	local stream = lgi.Gio.UnixInputStream.new(fd, false)
	local source = stream:create_source()
	source:set_callback(function()
		local res, err = xpcall(eventCallback, debug.traceback, desc, wiistate, source, sendcb)
		if not res then
			log.warning('Error in WiiRemote event callback: '..err)
		end
		return true
	end)
	source:attach(lgi.GLib.MainContext.default())
	print('WiiMote successfully registered')
end

return {
	setup = setup;
}
