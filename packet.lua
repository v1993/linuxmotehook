--[[
   Copyright 2019 [Valeri Ochinski]

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

local crc32 = require 'crc32'.crc32
local maxPver = 1001

local socket = ...

-- Incoming messages
local IMessage = {
	Version = 0x100000;
	Ports = 0x100001;
	Data = 0x100002;
}

-- Outcoming messages (constants have happened to be the same)
local OMessage = IMessage

local function crcTable(tab)
	local crc =  ''
	for k,v in ipairs(tab) do
		crc = crc32(crc, v)
	end
	return crc
end

local function getBatteryEnum(percent)
	if percent >= 70 then
		return 0x05 -- Full
	elseif percent >= 50 then
		return 0x04 -- High
	elseif percent >= 30 then
		return 0x03 -- Medium
	elseif percent >= 15 then
		return 0x02 -- Low
	else
		return 0x01 -- Dying
	end
end

-- TODO: use string.(un)pack instead where possible (full bytes)

local function num2bytestring(num, len)
	if len == 1 then
		return string.char(num)
	end
	local arr = {}
	for i=1,len do
		arr[i] = (num >> ((i-1) * 8)) & 0xFF
	end
	return string.char(table.unpack(arr))
end

local function bytestring2num(str)
	local arr = {str:byte(1, -1)}
	local num = arr[1]
	for i=2,#str do
		num = (arr[i] << ((i-1) * 8)) | num
	end
	return num
end

--[[
	Package structure (both sides):
	bytes 1-4	DSUC/DSUS — magic number
	bytes 5-6	protocol version number
	bytes 7-8	length of package without header
	bytes 9-12	CRC32 of package (while this was 0's)
	bytes 13-16	client/server ID
	bytes 17-20	message type
	bytes 21-∞	other data
]]--

local getServerId
do
	local sId
	getServerId = function()
		if sId then return sId end

		math.randomseed(os.time())
		sId = num2bytestring(math.random(1, 0xffffff), 4)
		return sId
	end
end

local function addHeader(data, msgtype, pVer)
	local packet = {
		'DSUS',						-- DSU Server, I suppose?
		num2bytestring(pVer, 2),	-- Protocol version
		num2bytestring(#data+4, 2),	-- Size without header (add four for message type as it isn't part of header)
		'\0\0\0\0',					-- Placeholder for CRC (index 4)
		getServerId(),				-- Server ID (already string)

		num2bytestring(msgtype, 4),	-- Message type
		data						-- Other
	}

	-- Calculate CRC string
	packet[4] = crcTable(packet):reverse() -- Big endian order or something?

	return table.concat(packet)
end

-- Ports and Data packages have the same start
-- It have length of 11 bytes and 4 fields
local deviceStateHeaderLen = 11
local function deviceStateHeader(id, desc, battery)
	return ('< B BBB I6 B'):pack(
		id,										-- ID
		0x02,									-- State: connected
		desc.mplus_connected and 0x02 or 0x01,	-- Device model: full or no gyro
		0x02,									-- Connection type: Bluetooth
		desc.mac,								-- MAC address
		getBatteryEnum(battery)					-- Battery
	)
end

local function processIncoming(data, sendcb, endpoint, wiistate)
	-- Basic sanity check
	-- DSUC = DSU Client?
	if #data < 16 or data:sub(1, 4) ~= 'DSUC' then
		return nil
	end
	local pVer = bytestring2num(data:sub(5, 6))
	-- Check if we speak it
	if pVer > maxPver then
		return nil
	end

	local pSize = bytestring2num(data:sub(7, 8)) + 16
	if pSize > #data then
		-- Package is incomplete
		log.warning(('Data underflow: expected %d bytes, got %d'):format(pSize, #data))
		return nil
	elseif pSize < #data then
		-- Probably we're screwed, but let's don't give up yet
		data = data:sub(1, pSize)
	end

	-- We calculate CRC string, so no need to convert to number
	local crc = data:sub(9, 12)
	local realCrc = crcTable({data:sub(1, 8), '\0\0\0\0', data:sub(13)}):reverse()

	-- Calculate CRC of message without CRC
	if crc ~= realCrc then
		return nil
	end

	local clientID = bytestring2num(data:sub(13, 16))
	local messageType = bytestring2num(data:sub(17, 20))

	-- Cut down header data for fancier indexes
	local data = data:sub(21, -1)

	if messageType == IMessage.Version then
		print('Sending version')
		sendcb(addHeader(num2bytestring(maxPver, 2), OMessage.Version, 1001))
	elseif messageType == IMessage.Ports then
		--print('Ports requested')
		local numPadRequests = ('<I4'):unpack(data:sub(1, 4))

		if numPadRequests > 4 then return nil end

		-- Check sanity first
		for i=1+4, numPadRequests+4 do
			if bytestring2num(data:sub(i, i)) >= 4 then return nil end
		end

		for i=1+4, numPadRequests+4 do
			local curRequest = bytestring2num(data:sub(i, i))

			local desc = wiistate[curRequest + 1]
			if desc then
				local answer = deviceStateHeader(curRequest, desc, desc.iface:get_battery() or 0)..'\0'
				sendcb(addHeader(answer, OMessage.Ports, 1001))
			else
				-- Looks like fine answer anyways
				sendcb(addHeader(num2bytestring(i-5, 1)..('\0'):rep(12), OMessage.Ports, 1001))
			end
		end
	elseif messageType == IMessage.Data then
		--print('Data requested')
		local regFlags = bytestring2num(data:sub(1, 1))
		local regId = bytestring2num(data:sub(2, 2))
		local regMac = bytestring2num(data:sub(3, 8))
		local newdat = {time = getTime(); endpoint = endpoint; id = clientID}
		if regFlags == 0 then
			wiistate.all[clientID] = newdat
		elseif (regFlags & 0x01) ~= 0 then
			local desc = wiistate[regId + 1]
			if desc then
				desc.clients[clientID] = newdat
			end
		elseif (regFlags & 0x02) ~= 0 then
			for k,desc in ipairs(wiistate) do
				if desc.mac == regMac then
					desc.clients[clientID] = newdat
					break
				end
			end
		end
	else
		print('Unknown message')
	end
end

local config = config
local ACCEL_G	= config.ACCEL_G
local GYRO_DEG_PER_S	= config.GYRO_DEG_PER_S

local function sendReport(id, desc, wiistate, clients, battery)
	local ckeys = config.keys
	local dkeys = desc.keys
	local caccel = config.accel
	local daccel = desc.accel
	local cgyro = config.gyro
	local dgyro = desc.mplus

	if #clients == 0 then
		return
	end

	-- Wrappers
	local function key(k)
		return dkeys[ckeys[k]]
	end
	local function keyA(k)
		return dkeys[ckeys[k]] and 0xFF or 0x00
	end
	local function stick(name, axis)
		local conf = ckeys[name][axis]
		if dkeys[conf.plus] then
			return 255
		elseif dkeys[conf.minus] then
			return  001
		else
			return 128
		end
	end
	local function accel(axis)
		local info = caccel[axis]
		return (info[2] * daccel[info[1]]) / ACCEL_G
	end
	local function gyro(axis)
		local info = cgyro[axis]
		return (info[2] * dgyro[info[1]]) / GYRO_DEG_PER_S
	end

	-- Struct: answerStart, package count (different for each client), answerEnd

	local answerStart = deviceStateHeader(id, desc, battery)..'\x01'

	local answerEnd = ('<BB c2 BBBB BBBBBBBBBBBB c12 I8 fff fff'):pack(
		-- Common keys
		(key 'left'		and 0x80 or 0x00) |
		(key 'down'		and 0x40 or 0x00) |
		(key 'right'	and 0x20 or 0x00) |
		(key 'up'		and 0x10 or 0x00) |
		(key 'options'	and 0x08 or 0x00) |
		(key 'R3'		and 0x04 or 0x00) |
		(key 'L3'		and 0x02 or 0x00) |
		(key 'share'	and 0x01 or 0x00) ,

		(key 'Y'		and 0x80 or 0x00) |
		(key 'B'		and 0x40 or 0x00) |
		(key 'A'		and 0x20 or 0x00) |
		(key 'X'		and 0x10 or 0x00) |
		(key 'R1'		and 0x08 or 0x00) |
		(key 'L1'		and 0x04 or 0x00) |
		(key 'R2'		and 0x02 or 0x00) |
		(key 'L2'		and 0x01 or 0x00) ,

		-- PS and Touch
		'\0\0',

		-- Joysticks
		stick('leftjoy', 'x'),
		stick('leftjoy', 'y'),

		stick('rightjoy', 'x'),
		stick('rightjoy', 'y'),

		-- Keys doubled as analogs
		keyA 'left',
		keyA 'down',
		keyA 'right',
		keyA 'up',

		keyA 'Y',
		keyA 'B',
		keyA 'A',
		keyA 'X',

		keyA 'R1',
		keyA 'L1',
		keyA 'R2',
		keyA 'L2',

		'\0\0\0\0\0\0\0\0\0\0\0\0', -- Touch data (add IR? Sadly, no Cemuhook side support :\)

		desc.mvtime,

		accel 'x',
		accel 'y',
		accel 'z',

		gyro 'p',
		gyro 'y',
		gyro 'r'
	)

	for k,client in ipairs(clients) do
		local pkgcnt = wiistate.pkgcnt[client.id]
		wiistate.pkgcnt[client.id] = pkgcnt + 1
		socket:send_to(client.endpoint, addHeader(table.concat({answerStart, ('<I4'):pack(pkgcnt), answerEnd}), OMessage.Data, 1001))
	end
end

return {
	process = processIncoming;
	send = sendReport;
}
