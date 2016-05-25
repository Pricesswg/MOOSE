--- GROUP class. 
-- 
-- @{GROUP} class
-- ==============
-- The @{GROUP} class is a wrapper class to handle the DCS Group objects:
-- 
--  * Support all DCS Group APIs.
--  * Enhance with Group specific APIs not in the DCS Group API set.
--  * Handle local Group Controller.
--  * Manage the "state" of the DCS Group.
--  
--  
-- GROUP reference methods
-- ======================= 
-- For each DCS Group object alive within a running mission, a GROUP wrapper object (instance) will be created within the _@{DATABASE} object.
-- This is done at the beginning of the mission (when the mission starts), and dynamically when new DCS Group objects are spawned (using the @{SPAWN} class).
--  
-- The GROUP class does not contain a :New() method, rather it provides :Find() methods to retrieve the object reference
-- using the DCS Group or the DCS GroupName.
-- 
-- Another thing to know is that GROUP objects do not "contain" the DCS Group object. 
-- The GROUP methods will reference the DCS Group object by name when it is needed during API execution.
-- If the DCS Group object does not exist or is nil, the GROUP methods will return nil and log an exception in the DCS.log file.
--  
-- The GROUP class provides the following functions to retrieve quickly the relevant GROUP instance:
-- 
--  * @{#GROUP.Find}(): Find a GROUP instance from the _DATABASE object using a DCS Group object.
--  * @{#GROUP.FindByName}(): Find a GROUP instance from the _DATABASE object using a DCS Group name.
--  
-- IMPORTANT: ONE SHOULD NEVER SANATIZE these GROUP OBJECT REFERENCES! (make the GROUP object references nil).
-- @module Group
-- @author FlightControl

Include.File( "Routines" )
Include.File( "Base" )
Include.File( "Message" )
Include.File( "Unit" )

--- The GROUP class
-- @type GROUP
-- @extends Base#BASE
-- @field DCSGroup#Group DCSGroup The DCS group class.
-- @field #string GroupName The name of the group.
GROUP = {
	ClassName = "GROUP",
	GroupName = "",
	GroupID = 0,
	Controller = nil,
	DCSGroup = nil,
	WayPointFunctions = {},
	}
	
--- A DCSGroup
-- @type DCSGroup
-- @field id_ The ID of the group in DCS

--- Create a new GROUP from a DCSGroup
-- @param #GROUP self
-- @param DCSGroup#Group GroupName The DCS Group name
-- @return #GROUP self
function GROUP:Register( GroupName )
	local self = BASE:Inherit( self, BASE:New() )
	self:F2( GroupName )
	self.GroupName = GroupName
	return self
end

-- Reference methods.

--- Find the GROUP wrapper class instance using the DCS Group.
-- @param #GROUP self
-- @param DCSGroup#Group DCSGroup The DCS Group.
-- @return #GROUP The GROUP.
function GROUP:Find( DCSGroup )

  local GroupName = DCSGroup:getName() -- Group#GROUP
  local GroupFound = _DATABASE:FindGroup( GroupName )
  return GroupFound
end

--- Find the created GROUP using the DCS Group Name.
-- @param #GROUP self
-- @param #string GroupName The DCS Group Name.
-- @return #GROUP The GROUP.
function GROUP:FindByName( GroupName )

  local GroupFound = _DATABASE:FindGroup( GroupName )
  return GroupFound
end

-- DCS Group methods support.

--- Returns the DCS Group.
-- @param #GROUP self
-- @return DCSGroup#Group The DCS Group.
function GROUP:GetDCSGroup()
  local DCSGroup = Group.getByName( self.GroupName )
  
  if DCSGroup then
    return DCSGroup
  end
    
  return nil
end


--- Returns if the DCS Group is alive.
-- When the group exists at run-time, this method will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean true if the DCS Group is alive.
function GROUP:IsAlive()
  self:F2( self.GroupName )
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupIsAlive = DCSGroup:isExist()
    self:T3( GroupIsAlive )
    return GroupIsAlive
  end
  
  return nil
end

--- Destroys the DCS Group and all of its DCS Units. 
-- Note that this destroy method also raises a destroy event at run-time.
-- So all event listeners will catch the destroy event of this DCS Group.
-- @param #GROUP self
function GROUP:Destroy()
  self:F2( self.GroupName )
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    for Index, UnitData in pairs( DCSGroup:getUnits() ) do
      self:CreateEventCrash( timer.getTime(), UnitData )
    end
    DCSGroup:destroy()
    DCSGroup = nil
  end
  
  return nil
end

--- Returns category of the DCS Group. 
-- @param #GROUP self
-- @return DCSGroup#Group.Category The category ID
function GROUP:GetCategory()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T3( GroupCategory )
    return GroupCategory
  end
  
  return nil
end

--- Returns the category name of the DCS Group.
-- @param #GROUP self
-- @return #string Category name = Helicopter, Airplane, Ground Unit, Ship
function GROUP:GetCategoryName()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local CategoryNames = {
      [Group.Category.AIRPLANE] = "Airplane",
      [Group.Category.HELICOPTER] = "Helicopter",
      [Group.Category.GROUND] = "Ground Unit",
      [Group.Category.SHIP] = "Ship",  
    }
    local GroupCategory = DCSGroup:getCategory()
    self:T3( GroupCategory )
  
    return CategoryNames[GroupCategory]
  end
  
  return nil
end


--- Returns the coalition of the DCS Group.
-- @param #GROUP self
-- @return DCSCoalitionObject#coalition.side The coalition side of the DCS Group.
function GROUP:GetCoalition()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local GroupCoalition = DCSGroup:getCoalition()
    self:T3( GroupCoalition )
    return GroupCoalition
  end
  
  return nil
end

--- Returns the name of the DCS Group.
-- @param #GROUP self
-- @return #string The DCS Group name.
function GROUP:GetName()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupName = DCSGroup:getName()
    self:T3( GroupName )
    return GroupName
  end
  
  return nil
end

--- Returns the DCS Group identifier.
-- @param #GROUP self
-- @return #number The identifier of the DCS Group.
function GROUP:GetID()
  self:F2( self.GroupName )
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupID = DCSGroup:getID()
    self:T3( GroupID )
    return GroupID
  end
  
  return nil
end

--- Returns the UNIT wrapper class with number UnitNumber. 
-- If the underlying DCS Unit does not exist, the method will return nil. .
-- @param #GROUP self
-- @param #number UnitNumber The number of the UNIT wrapper class to be returned.
-- @return Unit#UNIT The UNIT wrapper class.
function GROUP:GetUnit( UnitNumber )
  self:F2( { self.GroupName, UnitNumber } )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local UnitFound = UNIT:Find( DCSGroup:getUnit( UnitNumber ) )
    self:T3( UnitFound.UnitName )
    self:T2( UnitFound )
    return UnitFound
  end

  return nil
end

--- Returns the DCS Unit with number UnitNumber. 
-- If the underlying DCS Unit does not exist, the method will return nil. .
-- @param #GROUP self
-- @param #number UnitNumber The number of the DCS Unit to be returned.
-- @return DCSUnit#Unit The DCS Unit.
function GROUP:GetDCSUnit( UnitNumber )
  self:F2( { self.GroupName, UnitNumber } )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local DCSUnitFound = DCSGroup:getUnit( UnitNumber )
    self:T3( DCSUnitFound )
    return DCSUnitFound
  end

  return nil
end

--- Returns current size of the DCS Group. 
-- If some of the DCS Units of the DCS Group are destroyed the size of the DCS Group is changed. 
-- @param #GROUP self
-- @return #number The DCS Group size.
function GROUP:GetSize()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupSize = DCSGroup:getSize()
    self:T3( GroupSize )
    return GroupSize
  end

  return nil
end

--- 
--- Returns the initial size of the DCS Group. 
-- If some of the DCS Units of the DCS Group are destroyed, the initial size of the DCS Group is unchanged. 
-- @param #GROUP self
-- @return #number The DCS Group initial size.
function GROUP:GetInitialSize()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupInitialSize = DCSGroup:getInitialSize()
    self:T3( GroupInitialSize )
    return GroupInitialSize
  end

  return nil
end

--- Returns the UNITs wrappers of the DCS Units of the DCS Group.
-- @param #GROUP self
-- @return #table The UNITs wrappers.
function GROUP:GetUnits()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local DCSUnits = DCSGroup:getUnits()
    local Units = {}
    for Index, UnitData in pairs( DCSUnits ) do
      Units[#Units+1] = UNIT:Find( UnitData )
    end
    self:T3( Units )
    return Units
  end

  return nil
end


--- Returns the DCS Units of the DCS Group.
-- @param #GROUP self
-- @return #table The DCS Units.
function GROUP:GetDCSUnits()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local DCSUnits = DCSGroup:getUnits()
    self:T3( DCSUnits )
    return DCSUnits
  end

  return nil
end

--- Get the controller for the GROUP.
-- @param #GROUP self
-- @return DCSController#Controller
function GROUP:_GetController()
  self:F2( { self.GroupName } )
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupController = DCSGroup:getController()
    self:T3( GroupController )
    return GroupController
  end

  return nil
end


--- Retrieve the group mission and allow to place function hooks within the mission waypoint plan.
-- Use the method @{Group#GROUP:WayPointFunction} to define the hook functions for specific waypoints.
-- Use the method @{Group@GROUP:WayPointExecute) to start the execution of the new mission plan.
-- Note that when WayPointInitialize is called, the Mission of the group is RESTARTED!
-- @param #GROUP self
-- @return #GROUP
function GROUP:WayPointInitialize()

  self.WayPoints = self:GetTaskRoute()
  
  return self
end


--- Registers a waypoint function that will be executed when the group moves over the WayPoint.
-- @param #GROUP self
-- @param #number WayPoint The waypoint number. Note that the start waypoint on the route is WayPoint 1!
-- @param #number WayPointIndex When defining multiple WayPoint functions for one WayPoint, use WayPointIndex to set the sequence of actions.
-- @param #function WayPointFunction The waypoint function to be called when the group moves over the waypoint. The waypoint function takes variable parameters.
-- @return #GROUP
function GROUP:WayPointFunction( WayPoint, WayPointIndex, WayPointFunction, ... )
  self:F2( { WayPoint, WayPointIndex, WayPointFunction } )
  
  table.insert( self.WayPoints[WayPoint].task.params.tasks, WayPointIndex )
  self.WayPoints[WayPoint].task.params.tasks[WayPointIndex] = self:TaskFunction( WayPoint, WayPointIndex, WayPointFunction, arg )
  return self
end


function GROUP:TaskFunction( WayPoint, WayPointIndex, FunctionString, FunctionArguments )

  local DCSTask
  
  local DCSScript = {}
  DCSScript[#DCSScript+1] = "local MissionGroup = GROUP:Find( ... ) "

  if FunctionArguments.n > 0 then
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionGroup, " .. table.concat( FunctionArguments, "," ) .. ")"
  else
    DCSScript[#DCSScript+1] = FunctionString .. "( MissionGroup )"
  end  
  
  DCSTask = self:TaskWrappedAction( 
    self:CommandDoScript(
      table.concat( DCSScript )
    ), WayPointIndex
  )
  
  self:T3( DCSTask )
  
  return DCSTask

end



--- Executes the WayPoint plan.
-- The function gets a WayPoint parameter, that you can use to restart the mission at a specific WayPoint.
-- Note that when the WayPoint parameter is used, the new start mission waypoint of the group will be 1!
-- @param #GROUP self
-- @param #number WayPoint The WayPoint from where to execute the mission.
-- @param #WaitTime The amount seconds to wait before initiating the mission.
-- @return #GROUP
function GROUP:WayPointExecute( WayPoint, WaitTime )

  if not WayPoint then
    WayPoint = 1
  end
  
  -- When starting the mission from a certain point, the TaskPoints need to be deleted before the given WayPoint.
  for TaskPointID = 1, WayPoint - 1 do
    table.remove( self.WayPoints, 1 )
  end

  self:T3( self.WayPoints )
  
  self:SetTask( self:TaskRoute( self.WayPoints ), WaitTime )

  return self
end


--- Activates a GROUP.
-- @param #GROUP self
function GROUP:Activate()
	self:F2( { self.GroupName } )
	trigger.action.activateGroup( self:GetDCSGroup() )
	return self:GetDCSGroup()
end


--- Gets the type name of the group.
-- @param #GROUP self
-- @return #string The type name of the group.
function GROUP:GetTypeName()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupTypeName = DCSGroup:getUnit(1):getTypeName()
    self:T3( GroupTypeName )
    return( GroupTypeName )
  end
  
  return nil
end

--- Gets the CallSign of the first DCS Unit of the DCS Group.
-- @param #GROUP self
-- @return #string The CallSign of the first DCS Unit of the DCS Group.
function GROUP:GetCallsign()
  self:F2( self.GroupName )
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupCallSign = DCSGroup:getUnit(1):getCallsign()
    self:T3( GroupCallSign )
    return GroupCallSign
  end
  
  return nil
end

--- Returns the current point (Vec2 vector) of the first DCS Unit in the DCS Group.
-- @return DCSTypes#Vec2 Current Vec2 point of the first DCS Unit of the DCS Group.
function GROUP:GetPointVec2()
	self:F2( self.GroupName )
	
	local GroupPointVec2 = self:GetUnit(1):GetPointVec2()
	self:T3( GroupPointVec2 )
	return GroupPointVec2
end

--- Returns the current point (Vec3 vector) of the first DCS Unit in the DCS Group.
-- @return DCSTypes#Vec3 Current Vec3 point of the first DCS Unit of the DCS Group.
function GROUP:GetPointVec3()
	self:F2( self.GroupName )
  
  local GroupPointVec3 = self:GetUnit(1):GetPointVec3()
  self:T3( GroupPointVec3 )
  return GroupPointVec3
end



-- Is Functions

--- Returns if the group is of an air category.
-- If the group is a helicopter or a plane, then this method will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean Air category evaluation result.
function GROUP:IsAir()
	self:F2( self.GroupName )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
  	local IsAirResult = DCSGroup:getCategory() == Group.Category.AIRPLANE or DCSGroup:getCategory() == Group.Category.HELICOPTER
  	self:T3( IsAirResult )
  	return IsAirResult
  end
  
  return nil
end

--- Returns if the DCS Group contains Helicopters.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Helicopters.
function GROUP:IsHelicopter()
  self:F2( self.GroupName )
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T2( GroupCategory )
    return GroupCategory == Group.Category.HELICOPTER
  end
  
  return nil
end

--- Returns if the DCS Group contains AirPlanes.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains AirPlanes.
function GROUP:IsAirPlane()
  self:F2()
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T2( GroupCategory )
    return GroupCategory == Group.Category.AIRPLANE
  end
  
  return nil
end

--- Returns if the DCS Group contains Ground troops.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Ground troops.
function GROUP:IsGround()
  self:F2()
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T2( GroupCategory )
    return GroupCategory == Group.Category.GROUND
  end
  
  return nil
end

--- Returns if the DCS Group contains Ships.
-- @param #GROUP self
-- @return #boolean true if DCS Group contains Ships.
function GROUP:IsShip()
  self:F2()
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupCategory = DCSGroup:getCategory()
    self:T2( GroupCategory )
    return GroupCategory == Group.Category.SHIP
  end
  
  return nil
end

--- Returns if all units of the group are on the ground or landed.
-- If all units of this group are on the ground, this function will return true, otherwise false.
-- @param #GROUP self
-- @return #boolean All units on the ground result.
function GROUP:AllOnGround()
	self:F2()

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
  	local AllOnGroundResult = true
  
  	for Index, UnitData in pairs( DCSGroup:getUnits() ) do
  		if UnitData:inAir() then
  			AllOnGroundResult = false
  		end
  	end
  	
  	self:T3( AllOnGroundResult )
  	return AllOnGroundResult
  end
  
  return nil
end

--- Returns the current maximum velocity of the group.
-- Each unit within the group gets evaluated, and the maximum velocity (= the unit which is going the fastest) is returned.
-- @param #GROUP self
-- @return #number Maximum velocity found.
function GROUP:GetMaxVelocity()
	self:F2()

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
  	local MaxVelocity = 0
  	
  	for Index, UnitData in pairs( DCSGroup:getUnits() ) do
  
  		local Velocity = UnitData:getVelocity()
  		local VelocityTotal = math.abs( Velocity.x ) + math.abs( Velocity.y ) + math.abs( Velocity.z )
  
  		if VelocityTotal < MaxVelocity then
  			MaxVelocity = VelocityTotal
  		end 
  	end
  	
  	return MaxVelocity
  end
 
  return nil
end

--- Returns the current minimum height of the group.
-- Each unit within the group gets evaluated, and the minimum height (= the unit which is the lowest elevated) is returned.
-- @param #GROUP self
-- @return #number Minimum height found.
function GROUP:GetMinHeight()
	self:F2()

end

--- Returns the current maximum height of the group.
-- Each unit within the group gets evaluated, and the maximum height (= the unit which is the highest elevated) is returned.
-- @param #GROUP self
-- @return #number Maximum height found.
function GROUP:GetMaxHeight()
	self:F2()

end

-- Tasks

--- Popping current Task from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:PopCurrentTask()
	self:F2()

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local Controller = self:_GetController()
    Controller:popTask()
    return self
  end
  
  return nil
end

--- Pushing Task on the queue from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:PushTask( DCSTask, WaitTime )
	self:F2()

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local Controller = self:_GetController()
    
    -- When a group SPAWNs, it takes about a second to get the group in the simulator. Setting tasks to unspawned groups provides unexpected results.
    -- Therefore we schedule the functions to set the mission and options for the Group.
    -- Controller:pushTask( DCSTask )
  
    if WaitTime then
      routines.scheduleFunction( Controller.pushTask, { Controller, DCSTask }, timer.getTime() + WaitTime )
    else
      Controller:pushTask( DCSTask )
    end
  
    return self
  end
  
  return nil
end

--- Clearing the Task Queue and Setting the Task on the queue from the group.
-- @param #GROUP self
-- @return Group#GROUP self
function GROUP:SetTask( DCSTask, WaitTime )
  self:F2( { DCSTask } )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
  
    local Controller = self:_GetController()
    
    -- When a group SPAWNs, it takes about a second to get the group in the simulator. Setting tasks to unspawned groups provides unexpected results.
    -- Therefore we schedule the functions to set the mission and options for the Group.
    -- Controller.setTask( Controller, DCSTask )
  
    if not WaitTime then
      WaitTime = 1
    end
    routines.scheduleFunction( Controller.setTask, { Controller, DCSTask }, timer.getTime() + WaitTime )
    
    return self
  end
  
  return nil
end


--- Return a condition section for a controlled task
-- @param #GROUP self
-- @param DCSTime#Time time
-- @param #string userFlag 
-- @param #boolean userFlagValue 
-- @param #string condition
-- @param DCSTime#Time duration 
-- @param #number lastWayPoint 
-- return DCSTask#Task
function GROUP:TaskCondition( time, userFlag, userFlagValue, condition, duration, lastWayPoint )
	self:F2( { time, userFlag, userFlagValue, condition, duration, lastWayPoint } )
  
  local DCSStopCondition = {}
  DCSStopCondition.time = time
  DCSStopCondition.userFlag = userFlag
  DCSStopCondition.userFlagValue = userFlagValue
  DCSStopCondition.condition = condition
  DCSStopCondition.duration = duration
  DCSStopCondition.lastWayPoint = lastWayPoint
  
  self:T3( { DCSStopCondition } )
  return DCSStopCondition 
end

--- Return a Controlled Task taking a Task and a TaskCondition
-- @param #GROUP self
-- @param DCSTask#Task DCSTask
-- @param #DCSStopCondition DCSStopCondition
-- @return DCSTask#Task
function GROUP:TaskControlled( DCSTask, DCSStopCondition )
	self:F2( { DCSTask, DCSStopCondition } )

  local DCSTaskControlled
  
  DCSTaskControlled = { 
    id = 'ControlledTask', 
    params = { 
      task = DCSTask, 
      stopCondition = DCSStopCondition 
    } 
  }
  
  self:T3( { DCSTaskControlled } )
  return DCSTaskControlled
end

--- Return a Combo Task taking an array of Tasks
-- @param #GROUP self
-- @param #list<DCSTask#Task> DCSTasks
-- @return DCSTask#Task
function GROUP:TaskCombo( DCSTasks )
  self:F2( { DCSTasks } )

  local DCSTaskCombo
  
  DCSTaskCombo = { 
    id = 'ComboTask', 
    params = { 
      tasks = DCSTasks
    } 
  }
  
  self:T3( { DCSTaskCombo } )
  return DCSTaskCombo
end

--- Return a WrappedAction Task taking a Command 
-- @param #GROUP self
-- @param DCSCommand#Command DCSCommand
-- @return DCSTask#Task
function GROUP:TaskWrappedAction( DCSCommand, Index )
  self:F2( { DCSCommand } )

  local DCSTaskWrappedAction
  
  DCSTaskWrappedAction = { 
    id = "WrappedAction",
    enabled = true,
    number = Index,
    auto = false,
    params = {
      action = DCSCommand,
    },
  }

  self:T3( { DCSTaskWrappedAction } )
  return DCSTaskWrappedAction
end

--- Executes a command action
-- @param #GROUP self
-- @param DCSCommand#Command DCSCommand
-- @return #GROUP self
function GROUP:SetCommand( DCSCommand )
  self:F2( DCSCommand )
  
  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local Controller = self:_GetController()
    Controller:setCommand( DCSCommand )
    return self
  end
  
  return nil
end

--- Perform a switch waypoint command
-- @param #GROUP self
-- @param #number FromWayPoint
-- @param #number ToWayPoint
-- @return DCSTask#Task
function GROUP:CommandSwitchWayPoint( FromWayPoint, ToWayPoint, Index )
  self:F2( { FromWayPoint, ToWayPoint, Index } )
  
  local CommandSwitchWayPoint = {
    id = 'SwitchWaypoint', 
    params = { 
      fromWaypointIndex = FromWayPoint,  
      goToWaypointIndex = ToWayPoint, 
    },
  }
  
  self:T3( { CommandSwitchWayPoint } )
  return CommandSwitchWayPoint
end
  

--- Orbit at a specified position at a specified alititude during a specified duration with a specified speed.
-- @param #GROUP self
-- @param DCSTypes#Vec2 Point The point to hold the position.
-- @param #number Altitude The altitude to hold the position.
-- @param #number Speed The speed flying when holding the position.
-- @return #GROUP self
function GROUP:TaskOrbitCircleAtVec2( Point, Altitude, Speed )
	self:F2( { self.GroupName, Point, Altitude, Speed } )

--  pattern = enum AI.Task.OribtPattern,
--    point = Vec2,
--    point2 = Vec2,
--    speed = Distance,
--    altitude = Distance
    
  local LandHeight = land.getHeight( Point )
  
  self:T3( { LandHeight } )

  local DCSTask = { id = 'Orbit', 
                   params = { pattern = AI.Task.OrbitPattern.CIRCLE, 
                              point = Point, 
                              speed = Speed, 
                              altitude = Altitude + LandHeight
                            } 
                 } 

  
--  local AITask = { id = 'ControlledTask', 
--                   params = { task = { id = 'Orbit', 
--                                       params = { pattern = AI.Task.OrbitPattern.CIRCLE, 
--                                                  point = Point, 
--                                                  speed = Speed, 
--                                                  altitude = Altitude + LandHeight
--                                                } 
--                                     }, 
--                              stopCondition = { duration = Duration 
--                                              } 
--                            } 
--                 }
--               )
               
  return DCSTask
end

--- Orbit at the current position of the first unit of the group at a specified alititude
-- @param #GROUP self
-- @param #number Altitude The altitude to hold the position.
-- @param #number Speed The speed flying when holding the position.
-- @return #GROUP self
function GROUP:TaskOrbitCircle( Altitude, Speed )
	self:F2( { self.GroupName, Altitude, Speed } )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
    local GroupPoint = self:GetPointVec2()
    return self:TaskOrbitCircleAtVec2( GroupPoint, Altitude, Speed )
  end
  
  return nil
end



--- Hold position at the current position of the first unit of the group.
-- @param #GROUP self
-- @param #number Duration The maximum duration in seconds to hold the position.
-- @return #GROUP self
function GROUP:TaskHoldPosition()
	self:F2( { self.GroupName } )

  return self:TaskOrbitCircle( 30, 10 )
end


--- Land the group at a Vec2Point.
-- @param #GROUP self
-- @param DCSTypes#Vec2 Point The point where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #GROUP self
function GROUP:TaskLandAtVec2( Point, Duration )
	self:F2( { self.GroupName, Point, Duration } )

  local DCSTask
  
	if Duration and Duration > 0 then
		DCSTask = { id = 'Land', params = { point = Point, durationFlag = true, duration = Duration } }
	else
		DCSTask = { id = 'Land', params = { point = Point, durationFlag = false } }
	end

  self:T3( DCSTask )
	return DCSTask
end

--- Land the group at a @{Zone#ZONE).
-- @param #GROUP self
-- @param Zone#ZONE Zone The zone where to land.
-- @param #number Duration The duration in seconds to stay on the ground.
-- @return #GROUP self
function GROUP:TaskLandAtZone( Zone, Duration, RandomPoint )
  self:F2( { self.GroupName, Zone, Duration, RandomPoint } )

  local Point
  if RandomPoint then
    Point = Zone:GetRandomPointVec2()
  else
    Point = Zone:GetPointVec2()
  end
  
  local DCSTask = self:TaskLandAtVec2( Point, Duration )

  self:T3( DCSTask )
  return DCSTask
end


--- Attack the Unit.
-- @param #GROUP self
-- @param Unit#UNIT The unit.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskAttackUnit( AttackUnit )
	self:F2( { self.GroupName, AttackUnit } )

--  AttackUnit = { 
--    id = 'AttackUnit', 
--    params = { 
--      unitId = Unit.ID, 
--      weaponType = number, 
--      expend = enum AI.Task.WeaponExpend
--      attackQty = number, 
--      direction = Azimuth, 
--      attackQtyLimit = boolean, 
--      groupAttack = boolean, 
--    } 
--  }
  
  local DCSTask    
  DCSTask = { id = 'AttackUnit', 
              params = { unitId = AttackUnit:GetID(), 
                         expend = AI.Task.WeaponExpend.TWO,
                         groupAttack = true, 
                       }, 
            }, 
  
  self:T3( { DCSTask } )
  return DCSTask
end

--- Attack a Group.
-- @param #GROUP self
-- @param Group#GROUP AttackGroup The Group to be attacked.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskAttackGroup( AttackGroup )
  self:F2( { self.GroupName, AttackGroup } )

--  AttackGroup = { 
--   id = 'AttackGroup', 
--   params = { 
--     groupId = Group.ID,
--     weaponType = number,
--     expend = enum AI.Task.WeaponExpend,
--     attackQty = number,
--     directionEnabled = boolean,
--     direction = Azimuth,
--     altitudeEnabled = boolean,
--     altitude = Distance,
--     attackQtyLimit = boolean,
--   } 
-- }  

  local DCSTask    
  DCSTask = { id = 'AttackGroup', 
              params = { groupId = AttackGroup:GetID(), 
                         expend = AI.Task.WeaponExpend.TWO,
                       }, 
            }, 
  
  self:T3( { DCSTask } )
  return DCSTask
end

--- Fires at a VEC2 point.
-- @param #GROUP self
-- @param DCSTypes#Vec2 The point to fire at.
-- @param DCSTypes#Distance Radius The radius of the zone to deploy the fire at.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskFireAtPoint( PointVec2, Radius )
  self:F2( { self.GroupName, PointVec2, Radius } )

-- FireAtPoint = { 
--   id = 'FireAtPoint', 
--   params = { 
--     point = Vec2,
--     radius = Distance, 
--   } 
-- }
   
  local DCSTask    
  DCSTask = { id = 'FireAtPoint', 
              params = { point = PointVec2, 
                         radius = Radius, 
                       } 
            } 
  
  self:T3( { DCSTask } )
  return DCSTask
end



--- Move the group to a Vec2 Point, wait for a defined duration and embark a group.
-- @param #GROUP self
-- @param DCSTypes#Vec2 Point The point where to wait.
-- @param #number Duration The duration in seconds to wait.
-- @param #GROUP EmbarkingGroup The group to be embarked.
-- @return DCSTask#Task The DCS task structure
function GROUP:TaskEmbarkingAtVec2( Point, Duration, EmbarkingGroup )
	self:F2( { self.GroupName, Point, Duration, EmbarkingGroup.DCSGroup } )

	local DCSTask 
	DCSTask =  { id = 'Embarking', 
	             params = { x = Point.x, 
    	                    y = Point.y, 
    		  							  duration = Duration, 
    			  						  groupsForEmbarking = { EmbarkingGroup.GroupID },
    				  					  durationFlag = true,
    					  				  distributionFlag = false,
    						  			  distribution = {},
    						  			} 
    				 }
	
	self:T3( { DCSTask } )
	return DCSTask
end

--- Move to a defined Vec2 Point, and embark to a group when arrived within a defined Radius.
-- @param #GROUP self
-- @param DCSTypes#Vec2 Point The point where to wait.
-- @param #number Radius The radius of the embarking zone around the Point.
-- @return DCSTask#Task The DCS task structure.
function GROUP:TaskEmbarkToTransportAtVec2( Point, Radius )
	self:F2( { self.GroupName, Point, Radius } )

  local DCSTask --DCSTask#Task
	DCSTask = { id = 'EmbarkToTransport', 
	            params = { x = Point.x, 
				  	             y = Point.y, 
		    							   zoneRadius = Radius,
						           } 
						} 

  self:T3( { DCSTask } )
	return DCSTask
end

--- Return a Misson task from a mission template.
-- @param #GROUP self
-- @param #table TaskMission A table containing the mission task.
-- @return DCSTask#Task 
function GROUP:TaskMission( TaskMission )
	self:F2( Points )
  
  local DCSTask
  DCSTask = { id = 'Mission', params = { TaskMission, }, }
  
  self:T3( { DCSTask } )
  return DCSTask
end

--- Return a Misson task to follow a given route defined by Points.
-- @param #GROUP self
-- @param #table Points A table of route points.
-- @return DCSTask#Task 
function GROUP:TaskRoute( Points )
  self:F2( Points )
  
  local DCSTask
  DCSTask = { id = 'Mission', params = { route = { points = Points, }, }, }
  
  self:T3( { DCSTask } )
  return DCSTask
end

--- Make the DCS Group to fly to a given point and hover.
-- @param #GROUP self
-- @param DCSTypes#Vec3 Point The destination point in Vec3 format.
-- @param #number Speed The speed to travel.
-- @return #GROUP self
function GROUP:TaskRouteToVec2( Point, Speed )
  self:F2( { Point, Speed } )

  local GroupPoint = self:GetUnit( 1 ):GetPointVec2()
  
  local PointFrom = {}
  PointFrom.x = GroupPoint.x
  PointFrom.y = GroupPoint.y
  PointFrom.type = "Turning Point"
  PointFrom.action = "Turning Point"
  PointFrom.speed = Speed  
  PointFrom.speed_locked = true
  PointFrom.properties = {
        ["vnav"] = 1,
        ["scale"] = 0,
        ["angle"] = 0,
        ["vangle"] = 0,
        ["steer"] = 2,
  }
  

  local PointTo = {}
  PointTo.x = Point.x
  PointTo.y = Point.y
  PointTo.type = "Turning Point"
  PointTo.action = "Fly Over Point"
  PointTo.speed = Speed
  PointTo.speed_locked = true
  PointTo.properties = {
        ["vnav"] = 1,
        ["scale"] = 0,
        ["angle"] = 0,
        ["vangle"] = 0,
        ["steer"] = 2,
  }

  
  local Points = { PointFrom, PointTo }
  
  self:T3( Points )
  
  self:Route( Points )

  return self
end

--- Make the DCS Group to fly to a given point and hover.
-- @param #GROUP self
-- @param DCSTypes#Vec3 Point The destination point in Vec3 format.
-- @param #number Speed The speed to travel.
-- @return #GROUP self
function GROUP:TaskRouteToVec3( Point, Speed )
  self:F2( { Point, Speed } )

  local GroupPoint = self:GetUnit( 1 ):GetPointVec3()
  
  local PointFrom = {}
  PointFrom.x = GroupPoint.x
  PointFrom.y = GroupPoint.z
  PointFrom.alt = GroupPoint.y
  PointFrom.alt_type = "BARO"
  PointFrom.type = "Turning Point"
  PointFrom.action = "Turning Point"
  PointFrom.speed = Speed  
  PointFrom.speed_locked = true
  PointFrom.properties = {
        ["vnav"] = 1,
        ["scale"] = 0,
        ["angle"] = 0,
        ["vangle"] = 0,
        ["steer"] = 2,
  }
  

  local PointTo = {}
  PointTo.x = Point.x
  PointTo.y = Point.z
  PointTo.alt = Point.y  
  PointTo.alt_type = "BARO"
  PointTo.type = "Turning Point"
  PointTo.action = "Fly Over Point"
  PointTo.speed = Speed
  PointTo.speed_locked = true
  PointTo.properties = {
        ["vnav"] = 1,
        ["scale"] = 0,
        ["angle"] = 0,
        ["vangle"] = 0,
        ["steer"] = 2,
  }

  
  local Points = { PointFrom, PointTo }
  
  self:T3( Points )
  
  self:Route( Points )

  return self
end



--- Make the group to follow a given route.
-- @param #GROUP self
-- @param #table GoPoints A table of Route Points.
-- @return #GROUP self 
function GROUP:Route( GoPoints )
	self:F2( GoPoints )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
  	local Points = routines.utils.deepCopy( GoPoints )
  	local MissionTask = { id = 'Mission', params = { route = { points = Points, }, }, }
  	local Controller = self:_GetController()
    --Controller.setTask( Controller, MissionTask )
  	routines.scheduleFunction( Controller.setTask, { Controller, MissionTask}, timer.getTime() + 1 )
  	return self
  end
  
  return nil
end



--- Route the group to a given zone.
-- The group final destination point can be randomized.
-- A speed can be given in km/h.
-- A given formation can be given.
-- @param #GROUP self
-- @param Zone#ZONE Zone The zone where to route to.
-- @param #boolean Randomize Defines whether to target point gets randomized within the Zone.
-- @param #number Speed The speed.
-- @param Base#FORMATION Formation The formation string.
function GROUP:TaskRouteToZone( Zone, Randomize, Speed, Formation )
	self:F2( Zone )

  local DCSGroup = self:GetDCSGroup()
  
  if DCSGroup then
  	
  	local GroupPoint = self:GetPointVec2()
  	
  	local PointFrom = {}
  	PointFrom.x = GroupPoint.x
  	PointFrom.y = GroupPoint.y
  	PointFrom.type = "Turning Point"
  	PointFrom.action = "Cone"
  	PointFrom.speed = 20 / 1.6
  	
  
  	local PointTo = {}
  	local ZonePoint 
  	
  	if Randomize then
  		ZonePoint = Zone:GetRandomPointVec2()
  	else
  		ZonePoint = Zone:GetPointVec2()
  	end
  
  	PointTo.x = ZonePoint.x
  	PointTo.y = ZonePoint.y
  	PointTo.type = "Turning Point"
  	
  	if Formation then
  		PointTo.action = Formation
  	else
  		PointTo.action = "Cone"
  	end
  	
  	if Speed then
  		PointTo.speed = Speed
  	else
  		PointTo.speed = 20 / 1.6
  	end
  	
  	local Points = { PointFrom, PointTo }
  	
  	self:T3( Points )
  	
  	self:Route( Points )
  	
  	return self
  end
  
  return nil
end

-- Commands

--- Do Script command
-- @param #GROUP self
-- @param #string DoScript
-- @return #DCSCommand
function GROUP:CommandDoScript( DoScript )

  local DCSDoScript = {
    id = "Script",
    params = {
      command = DoScript,
    },
  }

  self:T3( DCSDoScript )
  return DCSDoScript
end


--- Return the mission template of the group.
-- @param #GROUP self
-- @return #table The MissionTemplate
function GROUP:GetTaskMission()
  self:F2( self.GroupName )

  return routines.utils.deepCopy( _DATABASE.Templates.Groups[self.GroupName].Template )
end

--- Return the mission route of the group.
-- @param #GROUP self
-- @return #table The mission route defined by points.
function GROUP:GetTaskRoute()
  self:F2( self.GroupName )

  return routines.utils.deepCopy( _DATABASE.Templates.Groups[self.GroupName].Template.route.points )
end

--- Return the route of a group by using the @{Database#DATABASE} class.
-- @param #GROUP self
-- @param #number Begin The route point from where the copy will start. The base route point is 0.
-- @param #number End The route point where the copy will end. The End point is the last point - the End point. The last point has base 0.
-- @param #boolean Randomize Randomization of the route, when true.
-- @param #number Radius When randomization is on, the randomization is within the radius. 
function GROUP:CopyRoute( Begin, End, Randomize, Radius )
	self:F2( { Begin, End } )

	local Points = {}
	
	-- Could be a Spawned Group
	local GroupName = string.match( self:GetName(), ".*#" )
	if GroupName then
		GroupName = GroupName:sub( 1, -2 )
	else
		GroupName = self:GetName()
	end
	
	self:T3( { GroupName } )
	
	local Template = _DATABASE.Templates.Groups[GroupName].Template
	
	if Template then
		if not Begin then
			Begin = 0
		end
		if not End then
			End = 0
		end
	
		for TPointID = Begin + 1, #Template.route.points - End do
			if Template.route.points[TPointID] then
				Points[#Points+1] = routines.utils.deepCopy( Template.route.points[TPointID] )
				if Randomize then
					if not Radius then
						Radius = 500
					end
					Points[#Points].x = Points[#Points].x + math.random( Radius * -1, Radius )
					Points[#Points].y = Points[#Points].y + math.random( Radius * -1, Radius )
				end	
			end
		end
		return Points
	end
	
	return nil
end


function GROUP:GetDetectedTargets()
  self:F2( self.GroupName )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    return self:_GetController():getDetectedTargets()
  end
  
  return nil
end

function GROUP:IsTargetDetected( DCSObject )
  self:F2( self.GroupName )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
  
    local TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity
          = self:_GetController().isTargetDetected( self:_GetController(), DCSObject, 
                                                    Controller.Detection.VISUAL,
                                                    Controller.Detection.OPTIC,
                                                    Controller.Detection.RADAR,
                                                    Controller.Detection.IRST,
                                                    Controller.Detection.RWR,
                                                    Controller.Detection.DLINK
                                                  )
    return TargetIsDetected, TargetIsVisible, TargetLastTime, TargetKnowType, TargetKnowDistance, TargetLastPos, TargetLastVelocity
  end
   
  return nil
end

-- Options

--- Can the GROUP hold their weapons?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEHoldFirePossible()
  self:F2( { self.GroupName } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    if self:IsAir() or self:IsGround() or self:IsShip() then
      return true
    end
    
    return false
  end
  
  return nil
end

--- Holding weapons.
-- @param Group#GROUP self
-- @return Group#GROUP self
function GROUP:OptionROEHoldFire()
	self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local Controller = self:_GetController()
    
    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD )
    elseif self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.WEAPON_HOLD )
    elseif self:IsShip() then
      Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.WEAPON_HOLD )
    end
    
    return self
  end
  
  return nil
end

--- Can the GROUP attack returning on enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEReturnFirePossible()
  self:F2( { self.GroupName } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    if self:IsAir() or self:IsGround() or self:IsShip() then
      return true
    end
    
    return false
  end
  
  return nil
end

--- Return fire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEReturnFire()
	self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local Controller = self:_GetController()
    
    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.RETURN_FIRE )
    elseif self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.RETURN_FIRE )
    elseif self:IsShip() then
      Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.RETURN_FIRE )
    end
     
    return self
  end
  
  return nil
end

--- Can the GROUP attack designated targets?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEOpenFirePossible()
  self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    if self:IsAir() or self:IsGround() or self:IsShip() then
      return true
    end
    
    return false
  end
  
  return nil
end

--- Openfire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEOpenFire()
	self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local Controller = self:_GetController()
    
    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.OPEN_FIRE )
    elseif self:IsGround() then
      Controller:setOption( AI.Option.Ground.id.ROE, AI.Option.Ground.val.ROE.OPEN_FIRE )
    elseif self:IsShip() then
      Controller:setOption( AI.Option.Naval.id.ROE, AI.Option.Naval.val.ROE.OPEN_FIRE )
    end
  
    return self
  end
  
  return nil
end

--- Can the GROUP attack targets of opportunity?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROEWeaponFreePossible()
  self:F2( { self.GroupName } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    if self:IsAir() then
      return true
    end
    
    return false
  end
  
  return nil
end

--- Weapon free.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROEWeaponFree()
	self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local Controller = self:_GetController()
    
    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_FREE )
    end
    
    return self
  end
  
  return nil
end

--- Can the GROUP ignore enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTNoReactionPossible()
  self:F2( { self.GroupName } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    if self:IsAir() then
      return true
    end
    
    return false
  end
  
  return nil
end


--- No evasion on enemy threats.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTNoReaction()
	self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local Controller = self:_GetController()
    
    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.NO_REACTION )
    end
    
    return self
  end
  
  return nil
end

--- Can the GROUP evade using passive defenses?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTPassiveDefensePossible()
  self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    if self:IsAir() then
      return true
    end
    
    return false
  end
  
  return nil
end

--- Evasion passive defense.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTPassiveDefense()
	self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local Controller = self:_GetController()
    
    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.PASSIVE_DEFENCE )
    end
    
    return self
  end
  
  return nil
end

--- Can the GROUP evade on enemy fire?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTEvadeFirePossible()
  self:F2( { self.GroupName } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    if self:IsAir() then
      return true
    end
    
    return false
  end
  
  return nil
end


--- Evade on fire.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTEvadeFire()
	self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local Controller = self:_GetController()
    
    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.EVADE_FIRE )
    end
    
    return self
  end
  
  return nil
end

--- Can the GROUP evade on fire using vertical manoeuvres?
-- @param #GROUP self
-- @return #boolean
function GROUP:OptionROTVerticalPossible()
  self:F2( { self.GroupName } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    if self:IsAir() then
      return true
    end
    
    return false
  end
  
  return nil
end


--- Evade on fire using vertical manoeuvres.
-- @param #GROUP self
-- @return #GROUP self
function GROUP:OptionROTVertical()
	self:F2( { self.GroupName } )

  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    local Controller = self:_GetController()
    
    if self:IsAir() then
      Controller:setOption( AI.Option.Air.id.REACTION_ON_THREAT, AI.Option.Air.val.REACTION_ON_THREAT.BYPASS_AND_ESCAPE )
    end
    
    return self
  end
  
  return nil
end

-- Message APIs

--- Returns a message for a coalition or a client.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
-- @return Message#MESSAGE
function GROUP:Message( Message, Duration )
  self:F2( { Message, Duration } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    return MESSAGE:New( Message, self:GetCallsign() .. " (" .. self:GetTypeName() .. ")", Duration, self:GetClassNameAndID() )
  end
  
  return nil
end

--- Send a message to all coalitions.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToAll( Message, Duration )
  self:F2( { Message, Duration } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    self:Message( Message, Duration ):ToAll()
  end
  
  return nil
end

--- Send a message to the red coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToRed( Message, Duration )
  self:F2( { Message, Duration } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    self:Message( Message, Duration ):ToRed()
  end
  
  return nil
end

--- Send a message to the blue coalition.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
function GROUP:MessageToBlue( Message, Duration )
  self:F2( { Message, Duration } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    self:Message( Message, Duration ):ToBlue()
  end
  
  return nil
end

--- Send a message to a client.
-- The message will appear in the message area. The message will begin with the callsign of the group and the type of the first unit sending the message.
-- @param #GROUP self
-- @param #string Message The message text
-- @param #Duration Duration The duration of the message.
-- @param Client#CLIENT Client The client object receiving the message.
function GROUP:MessageToClient( Message, Duration, Client )
  self:F2( { Message, Duration } )
  
  local DCSGroup = self:GetDCSGroup()
  if DCSGroup then
    self:Message( Message, Duration ):ToClient( Client )
  end
  
  return nil
end
