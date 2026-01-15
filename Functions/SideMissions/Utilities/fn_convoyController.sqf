/*
 * Function: FLO_fnc_convoyController
 * Author: Frontline Operations Development Group
 * Description:
 *   Manages convoy vehicles with proper AI behavior.
 *   - Each vehicle crew in separate group
 *   - Driver ignores combat (CARELESS)
 *   - Cargo can dismount and fight
 *   - Monitors stuck/dead vehicles
 *
 * Based on Antistasi ConvoyTravel FSM concepts.
 *
 * Parameters:
 *   0: Convoy vehicles (ARRAY)
 *   1: Route positions (ARRAY) - waypoints to follow
 *   2: Destination position (ARRAY)
 *   3: Options (HASHMAP) - optional config
 *
 * Returns:
 *   HASHMAP - Convoy controller object
 *
 * Example:
 *   _controller = [[_veh1, _veh2], _route, _endPos] call FLO_fnc_convoyController;
 */

params [
    ["_vehicles", []],
    ["_route", []],
    ["_destination", [0,0,0]],
    ["_options", createHashMap]
];

if (count _vehicles == 0) exitWith { 
    diag_log "[FLO_CONVOY] No vehicles provided";
    nil 
};

// Options with defaults
private _speed = _options getOrDefault ["speed", "LIMITED"];
private _behavior = _options getOrDefault ["behavior", "SAFE"];
private _stuckTimeout = _options getOrDefault ["stuckTimeout", 30];
private _onComplete = _options getOrDefault ["onComplete", {}];
private _onAbort = _options getOrDefault ["onAbort", {}];

// Create controller object
private _controller = createHashMapFromArray [
    ["vehicles", _vehicles],
    ["route", _route],
    ["destination", _destination],
    ["vehicleGroups", []],
    ["vehicleStates", createHashMap],
    ["active", true],
    ["startTime", time]
];

// Setup each vehicle with its own group
private _vehicleGroups = [];
{
    private _veh = _x;
    private _idx = _forEachIndex;
    
    if (isNull _veh || !alive _veh) then { continue };
    
    // Get all crew
    private _crew = crew _veh;
    private _driver = driver _veh;
    private _cargo = _veh getVariable ["assignedCargo", []];
    if (count _cargo == 0) then { _cargo = assignedCargo _veh };
    
    // Create driver group (ignores combat)
    private _driverGrp = createGroup (side _driver);
    _driverGrp deleteGroupWhenEmpty true;
    [_driver] join _driverGrp;
    
    // Add gunner/commander to driver group if present
    private _gunner = gunner _veh;
    private _commander = commander _veh;
    if (!isNull _gunner) then { [_gunner] join _driverGrp };
    if (!isNull _commander) then { [_commander] join _driverGrp };
    
    // Driver group is CARELESS - will not stop for combat
    _driverGrp setBehaviour "CARELESS";
    _driverGrp setCombatMode "BLUE";
    _driverGrp setSpeedMode _speed;
    
    // Cargo gets own group if present (can dismount and fight)
    private _cargoGrp = grpNull;
    if (count _cargo > 0) then {
        _cargoGrp = createGroup (side (_cargo select 0));
        _cargoGrp deleteGroupWhenEmpty true;
        { [_x] join _cargoGrp } forEach _cargo;
        _cargoGrp setBehaviour "AWARE";
        _cargoGrp setCombatMode "YELLOW";
    };
    
    _vehicleGroups pushBack [_driverGrp, _cargoGrp];
    
    // Initialize vehicle state
    (_controller get "vehicleStates") set [str _idx, createHashMapFromArray [
        ["vehicle", _veh],
        ["driverGroup", _driverGrp],
        ["cargoGroup", _cargoGrp],
        ["currentNode", 0],
        ["lastPos", getPosATL _veh],
        ["lastMoveTime", time],
        ["status", "MOVING"],  // MOVING, STUCK, DEAD, ARRIVED
        ["stuckCount", 0]
    ]];
    
    // Add waypoints to driver group
    if (count _route > 0) then {
        {
            private _wp = _driverGrp addWaypoint [_x, 30];
            _wp setWaypointType "MOVE";
            _wp setWaypointBehaviour "CARELESS";
            _wp setWaypointSpeed _speed;
            _wp setWaypointCompletionRadius 50;
        } forEach _route;
    };
    
    // Final destination waypoint
    private _wp = _driverGrp addWaypoint [_destination, 30];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "CARELESS";
    _wp setWaypointSpeed _speed;
    
} forEach _vehicles;

_controller set ["vehicleGroups", _vehicleGroups];

// Start monitoring loop with convoy cohesion
[_controller, _stuckTimeout, _onComplete, _onAbort, _vehicles] spawn {
    params ["_ctrl", "_stuckTime", "_onComp", "_onAbrt", "_vehs"];
    
    private _dest = _ctrl get "destination";
    private _convoySpacing = 50;  // Desired spacing between vehicles
    private _maxSpacing = 150;    // Max distance before stopping to wait
    
    while {_ctrl get "active"} do {
        sleep 3;
        
        private _states = _ctrl get "vehicleStates";
        private _allDone = true;
        private _anyAlive = false;
        
        // Get lead vehicle position (first alive vehicle)
        private _leadVeh = objNull;
        private _leadPos = [0,0,0];
        {
            if (alive _x && canMove _x) exitWith {
                _leadVeh = _x;
                _leadPos = getPosATL _x;
            };
        } forEach _vehs;
        
        {
            private _state = _y;
            private _veh = _state get "vehicle";
            private _status = _state get "status";
            private _driverGrp = _state get "driverGroup";
            private _vehIdx = parseNumber _x;
            
            if (_status in ["DEAD", "ARRIVED"]) then { continue };
            
            // Check if vehicle destroyed
            if (!alive _veh || isNull driver _veh || !alive driver _veh) then {
                _state set ["status", "DEAD"];
                diag_log format ["[FLO_CONVOY] Vehicle %1 destroyed", _x];
                continue;
            };
            
            _anyAlive = true;
            _allDone = false;
            
            // Check if arrived
            if (_veh distance2D _dest < 100) then {
                _state set ["status", "ARRIVED"];
                diag_log format ["[FLO_CONVOY] Vehicle %1 arrived", _x];
                continue;
            };
            
            // CONVOY COHESION: Lead-based speed matching
            // Lead vehicle = closest to destination, sets pace for all
            private _baseSpeed = 15;  // Base convoy speed in m/s (~54 km/h)
            private _isLead = (_veh == _leadVeh);
            
            // Get lead vehicle's current speed
            private _leadSpeed = if (!isNull _leadVeh) then { speed _leadVeh } else { _baseSpeed * 3.6 };
            _leadSpeed = (_leadSpeed / 3.6) max 5;  // Convert km/h to m/s, minimum 5 m/s
            
            if (_isLead) then {
                // LEAD VEHICLE: Drives at base speed toward destination
                _veh forceSpeed _baseSpeed;
            } else {
                // FOLLOWING VEHICLES: Match lead speed + adjust for spacing
                private _aheadIdx = (_vehIdx - 1) max 0;
                private _aheadVeh = _vehs select _aheadIdx;
                
                if (alive _aheadVeh && canMove _aheadVeh) then {
                    private _distToAhead = _veh distance2D _aheadVeh;
                    private _aheadSpeed = (speed _aheadVeh) / 3.6;  // km/h to m/s
                    
                    // Calculate target speed based on spacing
                    private _targetSpeed = _aheadSpeed;
                    
                    if (_distToAhead > _maxSpacing) then {
                        // Way too far - go fast to catch up
                        _targetSpeed = 30;
                    } else {
                        if (_distToAhead > _convoySpacing * 1.5) then {
                            // Falling behind - speed up slightly
                            _targetSpeed = _aheadSpeed + 5;
                        } else {
                            if (_distToAhead > _convoySpacing) then {
                                // Good distance - match ahead vehicle
                                _targetSpeed = _aheadSpeed;
                            } else {
                                if (_distToAhead > 20) then {
                                    // Getting close - slow down
                                    _targetSpeed = _aheadSpeed * 0.7;
                                } else {
                                    // Too close - slow way down
                                    _targetSpeed = _aheadSpeed * 0.4;
                                };
                            };
                        };
                    };
                    
                    // Clamp speed
                    _targetSpeed = _targetSpeed max 3 min 35;
                    _veh forceSpeed _targetSpeed;
                } else {
                    // Vehicle ahead dead/disabled - become new segment lead
                    _veh forceSpeed _baseSpeed;
                };
            };
            
            // Check if stuck - more aggressive detection
            private _currentPos = getPosATL _veh;
            private _lastPos = _state get "lastPos";
            private _lastMove = _state get "lastMoveTime";
            private _movedDist = _currentPos distance2D _lastPos;
            
            // Stuck if moved less than 15m in the check interval
            if (_movedDist < 15) then {
                if (time - _lastMove > _stuckTime) then {
                    private _stuckCount = _state get "stuckCount";
                    _stuckCount = _stuckCount + 1;
                    _state set ["stuckCount", _stuckCount];
                    
                    diag_log format ["[FLO_CONVOY] Vehicle %1 slow/stuck (moved: %2m, count: %3)", _x, _movedDist, _stuckCount];
                    
                    if (_stuckCount >= 5) then {
                        _state set ["status", "STUCK"];
                    } else {
                        // Aggressive unstuck - push forward in facing direction
                        private _dir = getDir _veh;
                        private _pushForce = 5 + (_stuckCount * 2);  // Increase force with each attempt
                        _veh setVelocity [
                            (sin _dir) * _pushForce,
                            (cos _dir) * _pushForce,
                            1
                        ];
                    };
                };
            } else {
                _state set ["lastPos", _currentPos];
                _state set ["lastMoveTime", time];
                _state set ["stuckCount", 0];
            };
            
        } forEach _states;
        
        // Check completion
        if (_allDone || !_anyAlive) then {
            _ctrl set ["active", false];
            
            private _arrivedCount = { (_y get "status") == "ARRIVED" } count _states;
            if (_arrivedCount > 0) then {
                [_ctrl] call _onComp;
            } else {
                [_ctrl] call _onAbrt;
            };
        };
    };
    
    diag_log "[FLO_CONVOY] Controller finished";
};

_controller
