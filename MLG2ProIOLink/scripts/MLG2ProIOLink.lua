--[[----------------------------------------------------------------------------

  Application Name:
  MLG2ProIOLink

  Summary:
  Connecting and communicating to IO-Link device MLG-2 Pro automation lightgrid

  Description:
  This sample shows how to connect to the IO-Link device MLG-2 Pro and how to
  receive measurement data.

  How to run:
  This sample can be run on any AppSpace device which can act as an IO-Link master,
  e.g. SIM family. The IO-Link device MLG-2 Pro must be properly connected to a port
  which supports IO-Link. If the port is configured as IO-Link master, see script,
  the power LED blinks slowly. When a IO-Link device is successfully connected the
  LED blinks rapidly.

  More Information:
  See device manual of IO-Link master for according ports. See manual of IO-Link
  device MLG-2 Pro for further IO-Link specific description and device specific commands.

------------------------------------------------------------------------------]]
--Start of Global Scope---------------------------------------------------------

-- luacheck: globals gPwr gIoLinkDevice gTmr

-- Enable power on S1 port, must be adapted if another port is used
gPwr = Connector.Power.create('S1')
gPwr:enable(true)

-- Creating IO-Link device handle for S1 port, must be adapted if another port is used
-- Now S1 port is configured as an IO-Link master.
gIoLinkDevice = IOLink.RemoteDevice.create('S1')

-- Creating timer to cyclicly read process data of MLG-2 Pro device
gTmr = Timer.create()
gTmr:setExpirationTime(1000)
gTmr:setPeriodic(true)

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function handleOnConnected()
  print('IO-Link device connected')

  -- Reading product name and other product related data
  local productName = gIoLinkDevice:getProductName()
  print('Product Name: ' .. productName)
  local firmwareVersion = gIoLinkDevice:readData(23, 0) -- index 23, subindex 0,  Firmware Version
  print('Firmware Version: ' .. firmwareVersion)
  local teachQualityData = gIoLinkDevice:readData(224, 0) -- index 224, subindex 0,  Teach Quality
  local teachQuality = string.unpack('B', teachQualityData)
  print('Teach Quality: ' .. teachQuality)

  -- Set Performance Options to High-Speed-Scan
  local newPerformanceOptions = string.pack('B', 0x05) -- 5 = High-Speed-Scan
  local returnWrite = gIoLinkDevice:writeData(66, 0, newPerformanceOptions) --index 66, subindex 0,  Performance Options
  local performanceOptions,
    returnRead = gIoLinkDevice:readData(66, 0)
  local appliedPerformanceOptions = string.unpack('B', performanceOptions)
  print('Performance Option: ' .. appliedPerformanceOptions)
  print('Write Message: ' .. returnWrite .. '; Read Message: ' .. returnRead)

  --Starting timer after successfull connection
  gTmr:start()
end
IOLink.RemoteDevice.register(gIoLinkDevice, 'OnConnected', handleOnConnected)

---Stopping timer when IO-Link device gets disconnected
local function handleOnDisconnected()
  gTmr:stop()
  print('IO-Link device disconnected')
end
IOLink.RemoteDevice.register( gIoLinkDevice, 'OnDisconnected', handleOnDisconnected )

local function handleOnPowerFault()
  print('Power fault at IO-Link device')
  gTmr:stop()
end
IOLink.RemoteDevice.register(gIoLinkDevice, 'OnPowerFault', handleOnPowerFault)

---On every expiration of the timer, the process data of IO-Link device MLG-2 Pro is read
local function handleOnExpired()
  -- Reading process data
  local data,
    dataValid = gIoLinkDevice:readProcessData()
  print('Valid: ' .. dataValid .. '  Length: ' .. #data)

  -- Extracting output status, system status and RLC out of process data
  local b1, b2, rlc1, rlc2, rlc3, rlc4, rlc5, rlc6, rlc7, rlc8, rlc9, rlc10, rlc11, rlc12, rlc13, rlc14, rlc15
    = string.unpack('BBi2i2i2i2i2i2i2i2i2i2i2i2i2i2i2', data)
  print( 'output status: ' .. b1 .. ' system status: ' .. b2 .. ' RLC: ' .. rlc1 .. '-' .. rlc2 .. '-' .. rlc3 .. '-' ..
         rlc4 .. '-' .. rlc5 .. '-' .. rlc6 .. '-' .. rlc7 .. '-' .. rlc8 .. '-' .. rlc9 .. '-' .. rlc10 .. '-' ..
         rlc11 .. '-' .. rlc12 .. '-' .. rlc13 .. '-' .. rlc14 .. '-' .. rlc15 )
end
Timer.register(gTmr, 'OnExpired', handleOnExpired)

--End of Function and Event Scope-----------------------------------------------
