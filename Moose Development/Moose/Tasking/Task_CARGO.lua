--- **Tasking (Release 2.1)** -- The TASK_CARGO models tasks for players to transport @{Cargo}.
-- 
-- ![Banner Image](..\Presentations\TASK_CARGO\Dia1.JPG)
-- 
-- ====
--
-- Cargo are units or cargo objects within DCS world that allow to be transported or sling loaded by other units.
-- The CARGO class, as part of the moose core, is able to Board, Load, UnBoard and UnLoad from Carrier units.
-- This collection of classes in this module define tasks for human players to handle cargo objects.
-- Cargo can be transported, picked-up, deployed and sling-loaded from and to other places.
-- 
-- The following classes are important to consider:
-- 
--   * @{#TASK_CARGO_TRANSPORT}: Defines a task for a human player to transport a set of cargo between various zones.
--
-- ==
-- 
-- # **API CHANGE HISTORY**
--
-- The underlying change log documents the API changes. Please read this carefully. The following notation is used:
--
--   * **Added** parts are expressed in bold type face.
--   * _Removed_ parts are expressed in italic type face.
--
-- Hereby the change log:
--
-- 2017-03-09: Revised version.
--
-- ===
--
-- # **AUTHORS and CONTRIBUTIONS**
--
-- ### Contributions:
--
-- ### Authors:
--
--   * **FlightControl**: Concept, Design & Programming.
--   
-- @module Task_Cargo

do -- TASK_CARGO

  --- @type TASK_CARGO
  -- @extends Tasking.Task#TASK

  ---
  -- # TASK_CARGO class, extends @{Task#TASK}
  -- 
  -- The TASK_CARGO class defines @{Cargo} transport tasks, 
  -- based on the tasking capabilities defined in @{Task#TASK}.
  -- The TASK_CARGO is implemented using a @{Statemachine#FSM_TASK}, and has the following statuses:
  -- 
  --   * **None**: Start of the process.
  --   * **Planned**: The cargo task is planned.
  --   * **Assigned**: The cargo task is assigned to a @{Group#GROUP}.
  --   * **Success**: The cargo task is successfully completed.
  --   * **Failed**: The cargo task has failed. This will happen if the player exists the task early, without communicating a possible cancellation to HQ.
  -- 
  -- # 1.1) Set the scoring of achievements in a cargo task.
  -- 
  -- Scoring or penalties can be given in the following circumstances:
  -- 
  -- ===
  -- 
  -- @field #TASK_CARGO TASK_CARGO
  --   
  TASK_CARGO = {
    ClassName = "TASK_CARGO",
  }
  
  --- Instantiates a new TASK_CARGO.
  -- @param #TASK_CARGO self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_CARGO SetCargo The scope of the cargo to be transported.
  -- @param #string TaskType The type of Cargo task.
  -- @return #TASK_CARGO self
  function TASK_CARGO:New( Mission, SetGroup, TaskName, SetCargo, TaskType )
    local self = BASE:Inherit( self, TASK:New( Mission, SetGroup, TaskName, TaskType ) ) -- #TASK_CARGO
    self:F( {Mission, SetGroup, TaskName, SetCargo, TaskType})
  
    self.SetCargo = SetCargo
    self.TaskType = TaskType
    
    self.DeployZones = {} -- setmetatable( {}, { __mode = "v" } ) -- weak table on value

    Mission:AddTask( self )
    
    local Fsm = self:GetUnitProcess()
    

    Fsm:AddProcess   ( "Planned", "Accept", ACT_ASSIGN_ACCEPT:New( self.TaskBriefing ), { Assigned = "SelectAction", Rejected = "Reject" }  )
    
    Fsm:AddTransition( "*", "SelectAction", "WaitingForCommand" )

    Fsm:AddTransition( "WaitingForCommand", "RouteToPickup", "RoutingToPickup" )
    Fsm:AddProcess   ( "RoutingToPickup", "RouteToPickupPoint", ACT_ROUTE_POINT:New(), { Arrived = "ArriveAtPickup" } )
    Fsm:AddTransition( "Arrived", "ArriveAtPickup", "ArrivedAtPickup" )

    Fsm:AddTransition( "WaitingForCommand", "RouteToDeploy", "RoutingToDeploy" )
    Fsm:AddProcess   ( "RoutingToDeploy", "RouteToDeployZone", ACT_ROUTE_ZONE:New(), { Arrived = "ArriveAtDeploy" } )
    Fsm:AddTransition( "Arrived", "ArriveAtDeploy", "ArrivedAtDeploy" )
    
    Fsm:AddTransition( { "ArrivedAtPickup", "ArrivedAtDeploy", "Landing" }, "Land", "Landing" )
    Fsm:AddTransition( "Landing", "Landed", "Landed" )
    
    Fsm:AddTransition( "WaitingForCommand", "PrepareBoarding", "AwaitBoarding" )
    Fsm:AddTransition( "AwaitBoarding", "Board", "Boarding" )
    Fsm:AddTransition( "Boarding", "Boarded", "Boarded" )

    Fsm:AddTransition( "WaitingForCommand", "PrepareUnBoarding", "AwaitUnBoarding" )
    Fsm:AddTransition( "AwaitUnBoarding", "UnBoard", "UnBoarding" )
    Fsm:AddTransition( "UnBoarding", "UnBoarded", "UnBoarded" )
    
    
    Fsm:AddTransition( "Deployed", "Success", "Success" )
    Fsm:AddTransition( "Rejected", "Reject", "Aborted" )
    Fsm:AddTransition( "Failed", "Fail", "Failed" )
    

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnEnterWaitingForCommand( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      TaskUnit.Menu = MENU_GROUP:New( TaskUnit:GetGroup(), Task:GetName() .. " @ " .. TaskUnit:GetName() )
      
      Task.SetCargo:Flush()
      
      Task.SetCargo:ForEachCargo(
        
        --- @param Core.Cargo#CARGO Cargo
        function( Cargo ) 
          if Cargo:IsUnLoaded() then
            if Cargo:IsInRadius( TaskUnit:GetPointVec2() ) then
              MENU_GROUP_COMMAND:New(
                TaskUnit:GetGroup(),
                "Pickup cargo " .. Cargo.Name,
                TaskUnit.Menu,
                self.MenuBoardCargo,
                self,
                Cargo
              )
            else
              MENU_GROUP_COMMAND:New(
                TaskUnit:GetGroup(),
                "Route to cargo " .. Cargo.Name,
                TaskUnit.Menu,
                self.MenuRouteToPickup,
                self,
                Cargo
              )
            end
          end
          
          if Cargo:IsLoaded() then
            for DeployZoneName, DeployZone in pairs( Task.DeployZones ) do
              if Cargo:IsInZone( DeployZone ) then
                MENU_GROUP_COMMAND:New(
                  TaskUnit:GetGroup(),
                  "Deploy cargo " .. Cargo.Name,
                  TaskUnit.Menu,
                  self.MenuUnBoardCargo,
                  self,
                  Cargo,
                  DeployZone
                )
              else
                MENU_GROUP_COMMAND:New(
                  TaskUnit:GetGroup(),
                  "Route to deploy zone " .. DeployZoneName,
                  TaskUnit.Menu,
                  self.MenuRouteToDeploy,
                  self,
                  DeployZone
                )
              end
            end
          end
        
        end
      )
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnLeaveWaitingForCommand( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      TaskUnit.Menu:Remove()
    end
    
    function Fsm:MenuBoardCargo( Cargo )
      self:__PrepareBoarding( 1.0, Cargo )
    end
    
    function Fsm:MenuUnBoardCargo( Cargo, DeployZone )
      self:__PrepareUnBoarding( 1.0, Cargo, DeployZone )
    end
    
    function Fsm:MenuRouteToPickup( Cargo )
      self:__RouteToPickup( 1.0, Cargo )
    end
    
    function Fsm:MenuRouteToDeploy( DeployZone )
      self:__RouteToDeploy( 1.0, DeployZone )
    end
    
    --- Route to Cargo
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterRouteToPickup( TaskUnit, Task, From, Event, To, Cargo )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      
      self.Cargo = Cargo
      Task:SetCargoPickup( self.Cargo, TaskUnit )
      self:__RouteToPickupPoint( -0.1 )
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterArriveAtPickup( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if TaskUnit:IsAir() then
        self:__Land( -0.1, "Pickup" )
      else
        self:__SelectAction( -0.1 )
      end
    end


    --- Route to DeployZone
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    function Fsm:onafterRouteToDeploy( TaskUnit, Task, From, Event, To, DeployZone )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      
      self.DeployZone = DeployZone
      Task:SetDeployZone( self.DeployZone, TaskUnit )
      self:__RouteToDeployZone( -0.1 )
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:onafterArriveAtDeploy( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if TaskUnit:IsAir() then
        self:__Land( -0.1, "Deploy" )
      else
        self:__SelectAction( -0.1 )
      end
    end



    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnAfterLand( TaskUnit, Task, From, Event, To, Action )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if self.Cargo:IsInRadius( TaskUnit:GetPointVec2() ) then
        if TaskUnit:InAir() then
          Task:GetMission():GetCommandCenter():MessageToGroup( "Land", TaskUnit:GetGroup() )
          self:__Land( -10, Action )
        else
          Task:GetMission():GetCommandCenter():MessageToGroup( "Landed ...", TaskUnit:GetGroup() )
          self:__Landed( -0.1, Action )
        end
      else
        if Action == "Pickup" then
          self:__RouteToPickupZone( -0.1 )
        else
          self:__RouteToDeployZone( -0.1 )
        end
      end
    end

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnAfterLanded( TaskUnit, Task, From, Event, To, Action )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      if self.Cargo:IsInRadius( TaskUnit:GetPointVec2() ) then
        if TaskUnit:InAir() then
          self:__Land( -0.1, Action )
        else
          self:__SelectAction( -0.1 )
        end
      else
        if Action == "Pickup" then
          self:__RouteToPickupZone( -0.1 )
        else
          self:__RouteToDeployZone( -0.1 )
        end
      end
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnAfterPrepareBoarding( TaskUnit, Task, From, Event, To, Cargo )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self.Cargo = Cargo -- Core.Cargo#CARGO_GROUP
      self:__Board( -0.1 )
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnAfterBoard( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      function self.Cargo:OnEnterLoaded( From, Event, To, TaskUnit, TaskProcess )
      
        self:E({From, Event, To, TaskUnit, TaskProcess })
        
        TaskProcess:__Boarded( 0.1 )
      
      end

      
      if self.Cargo:IsInRadius( TaskUnit:GetPointVec2() ) then
        if TaskUnit:InAir() then
          --- ABORT the boarding. Split group if any and go back to select action.
        else
          self.Cargo:MessageToGroup( "Boarding ...", TaskUnit:GetGroup() ) 
          self.Cargo:Board( TaskUnit, 20, self )
        end
      else
        --self:__ArriveAtCargo( -0.1 )
      end
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnAfterBoarded( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self.Cargo:MessageToGroup( "Boarded ...", TaskUnit:GetGroup() )
      self:__SelectAction( 1 )
    end
    

    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnAfterPrepareUnBoarding( TaskUnit, Task, From, Event, To, Cargo, DeployZone )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      self.Cargo = Cargo
      self.DeployZone = DeployZone      
      self:__UnBoard( -0.1 )
    end
    
    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnAfterUnBoard( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )

      function self.Cargo:OnEnterUnLoaded( From, Event, To, DeployZone, TaskProcess )
      
        self:E({From, Event, To, TaskUnit, TaskProcess })
        
        TaskProcess:__UnBoarded( -0.1 )
      
      end

      self.Cargo:MessageToGroup( "UnBoarding ...", TaskUnit:GetGroup() )
      self.Cargo:UnBoard( self.DeployZone:GetPointVec2(), 20, self )
    end


    --- 
    -- @param #FSM_PROCESS self
    -- @param Wrapper.Unit#UNIT TaskUnit
    -- @param Tasking.Task_Cargo#TASK_CARGO Task
    function Fsm:OnAfterUnBoarded( TaskUnit, Task )
      self:E( { TaskUnit = TaskUnit, Task = Task and Task:GetClassNameAndID() } )
      
      self.Cargo:MessageToGroup( "UnBoarded ...", TaskUnit:GetGroup() )
      self:__SelectAction( 1 )
    end

    
    return self
 
  end
  
  --- @param #TASK_CARGO self
  function TASK_CARGO:GetPlannedMenuText()
    return self:GetStateString() .. " - " .. self:GetTaskName() .. " ( " .. self.TargetSetUnit:GetUnitTypesText() .. " )"
  end


  --- @param #TASK_CARGO self
  -- @param AI.AI_Cargo#AI_CARGO Cargo The cargo.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetCargoPickup( Cargo, TaskUnit  )
  
    self:F({Cargo, TaskUnit})
    local ProcessUnit = self:GetUnitProcess( TaskUnit )
  
    local ActRouteCargo = ProcessUnit:GetProcess( "RoutingToPickup", "RouteToPickupPoint" ) -- Actions.Act_Route#ACT_ROUTE_POINT
    ActRouteCargo:SetPointVec2( Cargo:GetPointVec2() )
    ActRouteCargo:SetRange( Cargo:GetBoardingRange() )
    return self
  end
  

  --- @param #TASK_CARGO self
  -- @param Core.Zone#ZONE DeployZone
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetDeployZone( DeployZone, TaskUnit )
  
    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteDeployZone = ProcessUnit:GetProcess( "RoutingToDeploy", "RouteToDeployZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    ActRouteDeployZone:SetZone( DeployZone )
    return self
  end
   
  
  --- @param #TASK_CARGO self
  -- @param Core.Zone#ZONE DeployZone
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:AddDeployZone( DeployZone, TaskUnit )
  
    self.DeployZones[DeployZone:GetName()] = DeployZone

    return self
  end
  
  --- @param #TASK_CARGO self
  -- @param Core.Zone#ZONE DeployZone
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:RemoveDeployZone( DeployZone, TaskUnit )
  
    self.DeployZones[DeployZone:GetName()] = nil

    return self
  end
  
  --- @param #TASK_CARGO self
  -- @param @list<Core.Zone#ZONE> DeployZones
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetDeployZones( DeployZones, TaskUnit )
  
    for DeployZoneID, DeployZone in pairs( DeployZones ) do
      self.DeployZones[DeployZone:GetName()] = DeployZone
    end

    return self
  end
  
  

  --- @param #TASK_CARGO self
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return Core.Zone#ZONE_BASE The Zone object where the Target is located on the map.
  function TASK_CARGO:GetTargetZone( TaskUnit )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    local ActRouteTarget = ProcessUnit:GetProcess( "Engaging", "RouteToTargetZone" ) -- Actions.Act_Route#ACT_ROUTE_ZONE
    return ActRouteTarget:GetZone()
  end

  --- Set a score when a target in scope of the A2G attack, has been destroyed .
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when the target has been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnDestroy( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScoreProcess( "Engaging", "Account", "Account", Text, Score )
    
    return self
  end

  --- Set a score when all the targets in scope of the A2G attack, have been destroyed.
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when all targets hav been destroyed.
  -- @param #number Score The score in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetScoreOnSuccess( Text, Score, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Success", Text, Score )
    
    return self
  end

  --- Set a penalty when the A2G attack has failed.
  -- @param #TASK_CARGO self
  -- @param #string Text The text to display to the player, when the A2G attack has failed.
  -- @param #number Penalty The penalty in points.
  -- @param Wrapper.Unit#UNIT TaskUnit
  -- @return #TASK_CARGO
  function TASK_CARGO:SetPenaltyOnFailed( Text, Penalty, TaskUnit )
    self:F( { Text, Score, TaskUnit } )

    local ProcessUnit = self:GetUnitProcess( TaskUnit )

    ProcessUnit:AddScore( "Failed", Text, Penalty )
    
    return self
  end

  
end 


do -- TASK_CARGO_TRANSPORT

  --- The TASK_CARGO_TRANSPORT class
  -- @type TASK_CARGO_TRANSPORT
  -- @extends #TASK_CARGO
  TASK_CARGO_TRANSPORT = {
    ClassName = "TASK_CARGO_TRANSPORT",
  }
  
  --- Instantiates a new TASK_CARGO_TRANSPORT.
  -- @param #TASK_CARGO_TRANSPORT self
  -- @param Tasking.Mission#MISSION Mission
  -- @param Set#SET_GROUP SetGroup The set of groups for which the Task can be assigned.
  -- @param #string TaskName The name of the Task.
  -- @param Core.Set#SET_CARGO SetCargo The scope of the cargo to be transported.
  -- @return #TASK_CARGO_TRANSPORT self
  function TASK_CARGO_TRANSPORT:New( Mission, SetGroup, TaskName, SetCargo )
    local self = BASE:Inherit( self, TASK_CARGO:New( Mission, SetGroup, TaskName, SetCargo, "Transport" ) ) -- #TASK_CARGO_TRANSPORT
    self:F()
    
    return self
  end 

end

