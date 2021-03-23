--[[

2 October 2020
FrozenDroid:
- Added error handling to all event handler and scheduled functions. Lua script errors can no longer bring the server down.
- Added some extra checks to which weapons to handle, make sure they actually have a warhead (how come S-8KOM's don't have a warhead field...?)
28 October 2020
FrozenDroid: 
- Uncommented error logging, actually made it an error log which shows a message box on error.
- Fixed the too restrictive weapon filter (took out the HE warhead requirement)
--]]

explTable = {
	["FAB_100"]	=	45,
	["FAB_250"]	=	100,
	["FAB_500"]	=	213,
	["FAB_1500"]	=	675,
	["BetAB_500"]	=	98,
	["M_117"]	=	201,
	["Mk_81"]	=	60,
	["Mk_82"]	=	118,
	["AN_M64"]	=	121,
	["Mk_83"]	=	274,
	["Mk_84"]	=	582,
	["MK_82AIR"]	=	118,
	["MK_82SNAKEYE"]=	118,
	["GBU_10"]	=	582,
	["GBU_12"]	=	118,
	["GBU_16"]	=	274,
	["KAB_1500Kr"]	=	675,
	["KAB_500Kr"]	=	213,
	["KAB_500"]	=	213,
	["GBU_31"]	=	582,
	["GBU_31_V_3B"]	=	582,
	["GBU_31_V_2B"]	=	582,
	["GBU_31_V_4B"]	=	582,
	["GBU_32_V_2B"]	=	582,
	["GBU_38"]	=	118,
	["AGM_62"]	=	153,
	["GBU_24"]	=	582,
	["X_23"]	=	111,
	["X_23L"]	=	111,
	["X_28"]	=	160,
	["X_25ML"]	=	89,
	["X_25MP"]	=	89,
	["X_25MR"]	=	140,
	["X_58"]	=	140,
	["X_29L"]	=	320,
	["X_29T"]	=	320,
	["X_29TE"]	=	320,
	["AGM_84A"]	=	300,
	["AGM_84E"]	=	488,
	["AGM_88C"]	=	89,
	["AGM_122"]	=	15,
	["AGM_123"]	=	274,
	["AGM_130"]	=	582,
	["AGM_119"]	=	176,
	["AGM_154C"]	=	305,
	["S_25L"]	=	190,
	["C_8"]		=	4,
	["C_8OFP2"]	=	3,
	["C_13"]	=	21,
	["C_24"]	=	123,
	["C_25"]	=	151,
	["HYDRA_70M15"]	=	2,
	["Zuni_127"]	=	5,
	["ARAKM70BE"]	=	4,
	["BR_500"]	=	118,
	["Rb 05A"]	=	217,
	["Rb_15F"]	=	271,
	["Rb_04E"]	=	407,
	["Sea_Eagle"]	=	312,
}

local weaponDamageEnable = 1
WpnHandler = {}

local function getDistance(point1, point2)
  local x1 = point1.x
  local y1 = point1.y
  local z1 = point1.z
  local x2 = point2.x
  local y2 = point2.y
  local z2 = point2.z
  local dX = math.abs(x1-x2)
  local dZ = math.abs(z1-z2)
  local distance = math.sqrt(dX*dX + dZ*dZ)
  return distance
end

local function getDistance3D(point1, point2)
  local x1 = point1.x
  local y1 = point1.y
  local z1 = point1.z
  local x2 = point2.x
  local y2 = point2.y
  local z2 = point2.z
  local dX = math.abs(x1-x2)
  local dY = math.abs(y1-y2)
  local dZ = math.abs(z1-z2)
  local distance = math.sqrt(dX*dX + dZ*dZ + dY*dY)
  return distance
end

local function track_wpns()
--  env.info("Weapon Track Start")
	for wpn_id_, wpnData in pairs(tracked_weapons) do   
		if wpnData.wpn:isExist() then  -- just update position and direction.
			wpnData.pos = wpnData.wpn:getPosition().p
			wpnData.dir = wpnData.wpn:getPosition().x
      --wpnData.lastIP = land.getIP(wpnData.pos, wpnData.dir, 50)
		else -- wpn no longer exists, must be dead.
--      trigger.action.outText("Weapon impacted, mass of weapon warhead is " .. wpnData.exMass, 2)
			local ip = land.getIP(wpnData.pos, wpnData.dir, 20)  -- terrain intersection point with weapon's nose.  Only search out 20 meters though.
			local impactPoint
			if not ip then -- use last calculated IP
				impactPoint = wpnData.pos
	--      	trigger.action.outText("Impact Point:\nPos X: " .. impactPoint.x .. "\nPos Z: " .. impactPoint.z, 2)
			else -- use intersection point
				impactPoint = ip
	--        trigger.action.outText("Impact Point:\nPos X: " .. impactPoint.x .. "\nPos Z: " .. impactPoint.z, 2)
			end
			--env.info("Weapon is gone") -- Got to here -- 
			--trigger.action.outText("Weapon Type was: ".. wpnData.name, 20)
			if explTable[wpnData.name] then
					--env.info("triggered explosion size: "..explTable[wpnData.name])
					trigger.action.explosion(impactPoint, explTable[wpnData.name])
					trigger.action.smoke(impactPoint, 0)
			end
			tracked_weapons[wpn_id_] = nil -- remove from tracked weapons first.         
		end
	end
--  env.info("Weapon Track End")
end

function onWpnEvent(event)
  if event.id == world.event.S_EVENT_SHOT then
    if event.weapon then
      local ordnance = event.weapon
      local weapon_desc = ordnance:getDesc()
      if (weapon_desc.category ~= 0) and event.initiator then
		if (weapon_desc.category == 1) then
			if (weapon_desc.MissileCategory ~= 1 and weapon_desc.MissileCategory ~= 2) then
				tracked_weapons[event.weapon.id_] = { wpn = ordnance, init = event.initiator:getName(), pos = ordnance:getPoint(), dir = ordnance:getPosition().x, name = ordnance:getTypeName() }
			end
		else
			tracked_weapons[event.weapon.id_] = { wpn = ordnance, init = event.initiator:getName(), pos = ordnance:getPoint(), dir = ordnance:getPosition().x, name = ordnance:getTypeName() }
		end
      end
    end
  end
end

function WpnHandler:onEvent(event)
  protectedCall(onWpnEvent, event)
end

function protectedCall(...)
  local status, retval = pcall(...)
  if not status then
    env.error("Splash damage script error... gracefully caught! " .. retval, true)
  end
end

if (weaponDamageEnable == 1) then
  timer.scheduleFunction(function() 
      protectedCall(track_wpns)
      return timer.getTime() + 0.1
    end, 
    {}, 
    timer.getTime() + 0.1
  )
  world.addEventHandler(WpnHandler)
end
