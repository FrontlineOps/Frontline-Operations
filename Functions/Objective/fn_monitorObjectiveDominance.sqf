/*
 * Function: FLO_fnc_monitorObjectiveDominance
 * Author: Frontline Operations Development Group
 * Description:
 *   Continuously checks unit presence at objectives and flips ownership
 *   when one side holds dominance for a period of time.
 *   Updates FLO_Objectives which is publicVariable'd for client UI sync.
 *   Fires CBA target events to clients when they enter/leave objectives.
 *
 * Arguments: None
 *
 * Returns: Nothing (runs indefinitely)
 *
 * Example:
 *   [] spawn FLO_fnc_monitorObjectiveDominance;
 */

if (!isServer) exitWith {};

["OBJECTIVEMONITOR", 2, "MonitorObjectiveDominance started"] call FLO_fnc_log;

// Wait for objectives to be initialized
waitUntil { !isNil "FLO_Objectives" };
["OBJECTIVEMONITOR", 3, "FLO_Objectives initialized"] call FLO_fnc_log;

// Get config values
private _captureTime = ["get", "captureTime"] call FLO_fnc_objectiveConfig;

// 0.5s is reasonable for capture logic; clients poll faster for UI
private _updateInterval = 0.5;

// Track time for progress calculation
private _lastTickTime = diag_tickTime;

// Track which objective each player is in (for CBA event firing)
FLO_PlayerObjectiveStates = createHashMap;

// Initialize inactive update index
private _inactiveMonitorIndex = 0;
private _objKeys = keys FLO_Objectives;

while {true} do {
    private _currentTime = diag_tickTime;
    private _deltaTime = _currentTime - _lastTickTime;
    _lastTickTime = _currentTime;

    if (isNil "FLO_Objectives") then {
        waitUntil { !isNil "FLO_Objectives" };
        _objKeys = keys FLO_Objectives; // Refresh keys
    };

    private _dataChanged = false;
    private _activeObjectives = [];
    private _allPlayers = allPlayers;
    
    // === IDENTIFY ACTIVE OBJECTIVES (Near Players) ===
    {
        private _pPos = getPosATL _x;
        {
            private _oId = _x;
            private _objData = FLO_Objectives get _oId;
            // Active if player is within 1000m (allows for seeing capture status from distance)
            if ((_objData get "position") distance2D _pPos < 1000) then {
                _activeObjectives pushBackUnique _oId;
            };
        } forEach _objKeys;
    } forEach _allPlayers;

    // === UPDATE LOGIC FUNCTION ===
    private _fnc_updateObjective = {
        params ["_id"];
        private _objRecord = FLO_Objectives get _id;

        if (isNil {_objRecord get "owner"}) then { _objRecord set ["owner", east]; };
        if (isNil {_objRecord get "captureProgress"}) then { _objRecord set ["captureProgress", 0]; };
        if (isNil {_objRecord get "bluforCount"}) then { _objRecord set ["bluforCount", 0]; };
        if (isNil {_objRecord get "opforCount"}) then { _objRecord set ["opforCount", 0]; };
        
        private _pos = _objRecord get "position";
        private _radius = _objRecord get "radius";
        private _owner = _objRecord get "owner";
        private _progress = _objRecord get "captureProgress";
        private _units = _pos nearEntities [["Man", "LandVehicle"], _radius];
        
        private _bluforCount = 0;
        private _opforCount = 0;
        
        {
            if (alive _x) then {
                // Verify strictly inside (if irregular shape) or simple radius check
                // Assuming radius check is sufficient
                switch (side _x) do {
                    case west: { _bluforCount = _bluforCount + 1 };
                    case east: { _opforCount = _opforCount + 1 };
                };
            };
        } forEach _units;

        // Count virtual groups for both EAST and WEST (inactive only)
        if (!isNil "FLO_virtualGroups") then {
            private _groups = FLO_virtualGroups get "_groups";
            {
                private _groupId = _x;
                private _gData = _groups get _groupId;
                if (_gData get "isActive") then { continue };
                if ((_gData get "position") distance2D _pos >= _radius) then { continue };

                private _gSide = _gData get "side";
                private _vCount = _gData get "unitCount";
                if (_gSide isEqualTo east) then { _opforCount = _opforCount + _vCount };
                if (_gSide isEqualTo west) then { _bluforCount = _bluforCount + _vCount };
            } forEach (keys _groups);
        };
        
        // Calculate progress (Dynamic Rate based on force difference)
        // More units = Faster capture
        private _diff = abs (_bluforCount - _opforCount);
        private _dynamicRate = 1.0 + (_diff * 0.5); // Base 1.0 + 0.5 per unit advantage
        if (_dynamicRate > 5.0) then { _dynamicRate = 5.0 }; // Cap at 5x speed
        
        // Minimum unit requirement to complete capture
        private _minUnitsToCapture = 3;
        
        if (_bluforCount > _opforCount && {_bluforCount >= _minUnitsToCapture}) then {
            _progress = (_progress + (_deltaTime * _dynamicRate)) min _captureTime;
        } else {
            if (_opforCount > _bluforCount && {_opforCount >= _minUnitsToCapture}) then {
                _progress = (_progress - (_deltaTime * _dynamicRate)) max (-_captureTime);
            } else {
                // Decay (slower than capture)
                if (_progress > 0) then { _progress = (_progress - (_deltaTime * 0.5)) max 0 };
                if (_progress < 0) then { _progress = (_progress + (_deltaTime * 0.5)) min 0 };
            };
        };
        
        // Checks
        private _activeSide = FLO_ActivePlayerSide;

        if (_progress >= _captureTime && {_owner != west}) then {
            [_id, west] call FLO_fnc_flipObjective;
            _progress = 0;
            if (_activeSide isEqualTo west) then {
                [0.20, "increase"] call FLO_fnc_adjustAggression;
            } else {
                [-0.10, "decrease"] call FLO_fnc_adjustAggression;
            };
        } else {
            if (_progress <= -_captureTime && {_owner != east} && {_opforCount >= _minUnitsToCapture}) then {
                [_id, east] call FLO_fnc_flipObjective;
                _progress = 0;
                if (_activeSide isEqualTo east) then {
                    [0.20, "increase"] call FLO_fnc_adjustAggression;
                } else {
                    [-0.10, "decrease"] call FLO_fnc_adjustAggression;
                };
            };
        };
        
        // Store
        _objRecord set ["captureProgress", _progress];
        _objRecord set ["bluforCount", _bluforCount];
        _objRecord set ["opforCount", _opforCount];
        _objRecord set ["captureTime", _captureTime]; // Ensure fresh config
        _dataChanged = true;
    };

    // === EXECUTE UPDATES ===
    
    // Always update Active Objectives
    { [_x] call _fnc_updateObjective; } forEach _activeObjectives;
    
    // Round-Robin update Inactive Objectives (2 per tick)
    // This ensures distant objectives are updated eventually without clogging CPU
    private _processCount = 0;
    while {_processCount < 2} do {
        if (_inactiveMonitorIndex >= count _objKeys) then { _inactiveMonitorIndex = 0 };
        private _currKey = _objKeys select _inactiveMonitorIndex;
        
        if !(_currKey in _activeObjectives) then {
            [_currKey] call _fnc_updateObjective;
            _processCount = _processCount + 1;
        };
        _inactiveMonitorIndex = _inactiveMonitorIndex + 1;
        if (_processCount >= 2 && _inactiveMonitorIndex >= count _objKeys) exitWith {}; // Break if cycled fully
    };

    // === SYNC & UI ===
    if (_dataChanged) then {
        publicVariable "FLO_Objectives";
    };

    // UI Event Logic (Optimized to only check Active Objectives close to players)
    {
        if (alive _x && !isNull _x) then {
            private _player = _x;
            private _uid = getPlayerUID _player;
            if (_uid == "") then { continue };
            
            private _pPos = getPosATL _player;
            private _currentObjId = "";
            private _closestDist = 9999;
            private _currentObjData = createHashMap;

            // Only check active objectives for UI presence
            {
                private _oId = _x;
                private _oData = FLO_Objectives get _oId;
                private _dist = (_oData get "position") distance2D _pPos;
                if (_dist < (_oData get "radius")) then {
                    // Check strict shape if needed, but radius implies check passed
                    if (_dist < _closestDist) then {
                        _closestDist = _dist;
                        _currentObjId = _oId;
                        _currentObjData = _oData;
                    };
                };
            } forEach _activeObjectives; // only check active list

            // Detect state change
            private _previousObjId = FLO_PlayerObjectiveStates get _uid;
            if (isNil "_previousObjId") then { _previousObjId = ""; };

            if (_currentObjId != _previousObjId) then {
                private _ownerId = owner _player;
                if (_currentObjId != "") then {
                    private _objName = _currentObjData get "name";
                    ["FLO_CaptureUI_Show", [_objName, _currentObjId], _ownerId] call CBA_fnc_ownerEvent;
                } else {
                    ["FLO_CaptureUI_Hide", [], _ownerId] call CBA_fnc_ownerEvent;
                };
                FLO_PlayerObjectiveStates set [_uid, _currentObjId];
            };

            // Send Realtime Update
            if (_currentObjId != "") then {
                private _bluforCount = _currentObjData get "bluforCount";
                private _opforCount = _currentObjData get "opforCount";
                private _owner = _currentObjData get "owner";
                
                private _playerSide = side group _player;
                private _friendlyCount = if (_playerSide isEqualTo east) then { _opforCount } else { _bluforCount };
                private _enemyCount = if (_playerSide isEqualTo east) then { _bluforCount } else { _opforCount };
                private _totalCount = _friendlyCount + _enemyCount;
                private _ratio = if (_totalCount > 0) then { _friendlyCount / _totalCount } else { 0.5 };
                
                ["FLO_CaptureUI_Update", [_ratio, _friendlyCount, _enemyCount, str _owner], owner _player] call CBA_fnc_ownerEvent;
            };
        };
    } forEach _allPlayers;

    sleep _updateInterval;
};
