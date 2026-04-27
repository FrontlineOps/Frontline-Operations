/*
 * Function: FLO_fnc_monitorObjectiveDominance
 * Author: Frontline Operations Development Group
 * Description:
 *   Continuously checks unit presence at objectives and flips ownership
 *   when one side holds dominance for a period of time.
 *   Updates authoritative objective runtime state on the server.
 *   Fires CBA owner events for capture UI and publishes a lightweight runtime
 *   state map to clients instead of rebroadcasting full FLO_Objectives.
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
private _captureSecureTime = ["get", "captureSecureTime"] call FLO_fnc_objectiveConfig;

// 0.5s is reasonable for capture logic; clients poll faster for UI
private _updateInterval = 0.5;
private _targetInactiveRefresh = 2;
private _runtimeSyncInterval = 2;

// Track which objective each player is in (for CBA event firing)
FLO_PlayerObjectiveStates = createHashMap;
private _objectiveLastUpdateTimes = createHashMap;
private _lastRuntimeSyncAt = diag_tickTime - _runtimeSyncInterval;
private _dirtyRuntimeObjectiveIds = createHashMap;
private _forceRuntimeSync = false;

// Initialize inactive update index
private _inactiveMonitorIndex = 0;
private _objKeys = keys FLO_Objectives;

while {true} do {
    private _currentTime = diag_tickTime;
    private _currentDateNum = dateToNumber date;

    if (isNil "FLO_Objectives") then {
        waitUntil { !isNil "FLO_Objectives" };
        _objKeys = keys FLO_Objectives; // Refresh keys
    };
    private _currentObjectiveCount = count (keys FLO_Objectives);
    if ((count _objKeys) != _currentObjectiveCount) then {
        _objKeys = keys FLO_Objectives;
        if (_inactiveMonitorIndex >= count _objKeys) then {
            _inactiveMonitorIndex = 0;
        };
    };

    private _activeObjectives = [];
    private _liveObjectives = [];
    private _allPlayers = allPlayers;
    
    // === IDENTIFY ACTIVE OBJECTIVES (Near Players) ===
    {
        private _pPos = getPosATL _x;
        {
            private _oId = _x;
            private _objData = FLO_Objectives get _oId;
            // Active if player is within 1000m (allows for seeing capture status from distance)
            private _dist = (_objData get "position") distance2D _pPos;
            if (_dist < 1000) then {
                _activeObjectives pushBackUnique _oId;
            };
            if (_dist < (_objData get "radius")) then {
                _liveObjectives pushBackUnique _oId;
            };
        } forEach _objKeys;
    } forEach _allPlayers;

    // Build objective update set for this tick:
    // all active objectives + a bounded round-robin slice of inactive objectives.
    private _objectivesToUpdate = +_activeObjectives;
    private _inactiveObjectiveCount = ((count _objKeys) - (count _activeObjectives)) max 0;
    private _inactiveBatchSize = 0;
    if (_inactiveObjectiveCount > 0) then {
        _inactiveBatchSize = ceil ((_inactiveObjectiveCount * _updateInterval) / _targetInactiveRefresh);
        if (_inactiveBatchSize < 2) then { _inactiveBatchSize = 2; };
        if (_inactiveBatchSize > _inactiveObjectiveCount) then { _inactiveBatchSize = _inactiveObjectiveCount; };
    };
    private _processCount = 0;
    private _scanAttempts = 0;
    private _maxAttempts = count _objKeys;
    while {_processCount < _inactiveBatchSize && _scanAttempts < _maxAttempts} do {
        if (_inactiveMonitorIndex >= count _objKeys) then { _inactiveMonitorIndex = 0 };
        private _currKey = _objKeys select _inactiveMonitorIndex;

        if !(_currKey in _activeObjectives) then {
            _objectivesToUpdate pushBack _currKey;
            _processCount = _processCount + 1;
        };
        _inactiveMonitorIndex = _inactiveMonitorIndex + 1;
        _scanAttempts = _scanAttempts + 1;
    };

    // Pre-compute virtual contribution only for objectives updated this tick.
    // A virtual group contributes to the nearest objective whose area contains it.
    private _virtualObjectiveCounts = createHashMap;
    {
        _virtualObjectiveCounts set [_x, [0, 0]]; // [westCount, eastCount]
    } forEach _objectivesToUpdate;

    if (count _objectivesToUpdate > 0 && {!isNil "FLO_virtualGroups"}) then {
        private _groups = FLO_virtualGroups get "_groups";
        {
            private _gData = _x;
            if (_gData get "isActive") then { continue };
            if ((_gData get "unitCount") <= 0) then { continue };
            if (([_gData] call FLO_fnc_virtualizationGetTransportAttachment) != "") then { continue };
            if !([_gData get "groupType"] call FLO_fnc_gtnCombatIsDirectCombatGroup) then { continue };

            private _gPos = _gData get "position";
            private _bestObjId = "";
            private _bestDist = 1000000000;

            {
                private _oId = _x;
                private _oData = FLO_Objectives get _oId;
                private _dist = _gPos distance2D (_oData get "position");
                if (_dist < (_oData get "radius") && {_dist < _bestDist}) then {
                    _bestDist = _dist;
                    _bestObjId = _oId;
                };
            } forEach _objectivesToUpdate;

            if (_bestObjId == "") then { continue };
            if (_bestObjId in _liveObjectives) then { continue };

            private _entry = _virtualObjectiveCounts get _bestObjId;
            private _vCount = _gData get "unitCount";
            private _gSide = _gData get "side";

            if (_gSide isEqualTo west) then {
                _entry set [0, (_entry select 0) + _vCount];
            };
            if (_gSide isEqualTo east) then {
                _entry set [1, (_entry select 1) + _vCount];
            };
            _virtualObjectiveCounts set [_bestObjId, _entry];
        } forEach (values _groups);
    };

    // === UPDATE LOGIC FUNCTION ===
    private _fnc_updateObjective = {
        params ["_id", "_currentTime"];
        private _objRecord = FLO_Objectives get _id;

        if (isNil {_objRecord get "owner"}) then { _objRecord set ["owner", east]; };
        if (isNil {_objRecord get "captureProgress"}) then { _objRecord set ["captureProgress", 0]; };
        if (isNil {_objRecord get "captureState"}) then { _objRecord set ["captureState", "held"]; };
        if (isNil {_objRecord get "captureSide"}) then { _objRecord set ["captureSide", sideUnknown]; };
        if (isNil {_objRecord get "captureSecureStartedAt"}) then { _objRecord set ["captureSecureStartedAt", -1]; };
        if (isNil {_objRecord get "captureSecureProgress"}) then { _objRecord set ["captureSecureProgress", 0]; };
        if (isNil {_objRecord get "captureSecureTime"}) then { _objRecord set ["captureSecureTime", _captureSecureTime]; };
        if (isNil {_objRecord get "captureStatusChangedAt"}) then { _objRecord set ["captureStatusChangedAt", _currentTime]; };
        if (isNil {_objRecord get "captureIntegratedAtDateNum"}) then { _objRecord set ["captureIntegratedAtDateNum", -1]; };
        if (isNil {_objRecord get "bluforCount"}) then { _objRecord set ["bluforCount", 0]; };
        if (isNil {_objRecord get "opforCount"}) then { _objRecord set ["opforCount", 0]; };
        if (isNil {_objRecord get "contested"}) then { _objRecord set ["contested", false]; };
        if (isNil {_objRecord get "underAttack"}) then { _objRecord set ["underAttack", false]; };
        
        private _pos = _objRecord get "position";
        private _radius = _objRecord get "radius";
        private _owner = _objRecord get "owner";
        private _previousProgress = _objRecord get "captureProgress";
        private _previousState = _objRecord get "captureState";
        private _previousCaptureSide = _objRecord get "captureSide";
        private _previousSecureProgress = _objRecord get "captureSecureProgress";
        private _previousBluforCount = _objRecord get "bluforCount";
        private _previousOpforCount = _objRecord get "opforCount";
        private _previousContested = _objRecord get "contested";
        private _previousUnderAttack = _objRecord get "underAttack";
        private _bluforCount = 0;
        private _opforCount = 0;
        private _useLiveCounting = _id in _liveObjectives;
        private _lastObjectiveUpdate = _objectiveLastUpdateTimes getOrDefault [_id, _currentTime];
        private _objectiveDeltaTime = _currentTime - _lastObjectiveUpdate;
        _objectiveLastUpdateTimes set [_id, _currentTime];

        if (_objectiveDeltaTime < 0) then {
            _objectiveDeltaTime = 0;
        };

        if (_useLiveCounting) then {
            // In live objectives (players inside), count from allUnits to avoid
            // dedicated nearEntities misses and ensure vehicle crews are included.
            private _liveUnits = allUnits select { alive _x && { (_x distance2D _pos) <= _radius } };
            _bluforCount = { (side group _x) isEqualTo west } count _liveUnits;
            _opforCount = { (side group _x) isEqualTo east } count _liveUnits;
        } else {
            private _units = _pos nearEntities ["Man", _radius];

            {
                if (!alive _x) then { continue };
                if ((_x distance2D _pos) > _radius) then { continue };

                private _uSide = side group _x;
                if (_uSide isEqualTo west) then { _bluforCount = _bluforCount + 1 };
                if (_uSide isEqualTo east) then { _opforCount = _opforCount + 1 };
            } forEach _units;

            // Dedicated can occasionally miss remote players in nearEntities.
            {
                if (!alive _x) then { continue };
                if ((_x distance2D _pos) > _radius) then { continue };
                if (_x in _units) then { continue };

                private _pSide = side group _x;
                if (_pSide isEqualTo west) then { _bluforCount = _bluforCount + 1 };
                if (_pSide isEqualTo east) then { _opforCount = _opforCount + 1 };
            } forEach _allPlayers;
        };

        // Add precomputed virtual presence for this objective.
        private _virtualCounts = _virtualObjectiveCounts get _id;
        _bluforCount = _bluforCount + (_virtualCounts select 0);
        _opforCount = _opforCount + (_virtualCounts select 1);

        // Minimum unit requirement to complete capture
        private _minUnitsToCapture = if (_id in _liveObjectives) then { 1 } else { 3 };

        private _captureResult = [
            _id,
            _objRecord,
            _bluforCount,
            _opforCount,
            _objectiveDeltaTime,
            _currentTime,
            _captureTime,
            _captureSecureTime,
            _minUnitsToCapture,
            _currentDateNum
        ] call FLO_fnc_updateObjectiveCaptureState;

        private _activeSide = FLO_ActivePlayerSide;
        private _requestedOwner = _captureResult get "requestedOwner";

        if !(_requestedOwner isEqualTo sideUnknown) then {
            [_id, _requestedOwner] call FLO_fnc_flipObjective;

            _objRecord = FLO_Objectives get _id;

            if (_activeSide isEqualTo _requestedOwner) then {
                [0.20, "increase"] call FLO_fnc_adjustAggression;
            } else {
                [-0.10, "decrease"] call FLO_fnc_adjustAggression;
            };
        };

        // Store
        _owner = _objRecord get "owner";
        private _contested = (_bluforCount > 0) && { _opforCount > 0 };
        private _underAttack = if (_owner isEqualTo west) then {
            _opforCount > 0
        } else {
            if (_owner isEqualTo east) then {
                _bluforCount > 0
            } else {
                false
            }
        };

        _objRecord set ["bluforCount", _bluforCount];
        _objRecord set ["opforCount", _opforCount];
        _objRecord set ["contested", _contested];
        _objRecord set ["underAttack", _underAttack];
        _objRecord set ["captureTime", _captureTime]; // Ensure fresh config
        _objRecord set ["captureSecureTime", _captureSecureTime];

        if (
            (abs (_previousProgress - (_objRecord get "captureProgress"))) > 0.01
            || {_previousState != (_objRecord get "captureState")}
            || {!(_previousCaptureSide isEqualTo (_objRecord get "captureSide"))}
            || {(abs (_previousSecureProgress - (_objRecord get "captureSecureProgress"))) > 0.01}
            || {_previousBluforCount != _bluforCount}
            || {_previousOpforCount != _opforCount}
            || {_previousContested != _contested}
            || {_previousUnderAttack != _underAttack}
        ) then {
            _dirtyRuntimeObjectiveIds set [_id, true];
            if (_previousState != (_objRecord get "captureState")) then {
                _forceRuntimeSync = true;
            };
        };
    };

    // === EXECUTE UPDATES ===
    { [_x, _currentTime] call _fnc_updateObjective; } forEach _objectivesToUpdate;

    // === LIGHTWEIGHT CLIENT RUNTIME SYNC ===
    if ((count (keys _dirtyRuntimeObjectiveIds)) > 0 && {_forceRuntimeSync || {(_currentTime - _lastRuntimeSyncAt) >= _runtimeSyncInterval}}) then {
        {
            private _objectiveId = _x;
            private _objective = FLO_Objectives get _objectiveId;

            FLO_ObjectiveRuntimeState set [_objectiveId, createHashMapFromArray [
                ["captureProgress", _objective get "captureProgress"],
                ["captureState", _objective get "captureState"],
                ["captureSide", _objective get "captureSide"],
                ["captureSecureProgress", _objective get "captureSecureProgress"],
                ["captureSecureStartedAt", _objective get "captureSecureStartedAt"],
                ["captureStatusChangedAt", _objective get "captureStatusChangedAt"],
                ["captureIntegratedAtDateNum", _objective get "captureIntegratedAtDateNum"],
                ["bluforCount", _objective get "bluforCount"],
                ["opforCount", _objective get "opforCount"],
                ["contested", _objective get "contested"],
                ["underAttack", _objective get "underAttack"]
            ]];
        } forEach (keys _dirtyRuntimeObjectiveIds);

        publicVariable "FLO_ObjectiveRuntimeState";
        _lastRuntimeSyncAt = _currentTime;
        ["objectiveRuntimeSyncs", 1] call FLO_fnc_netDebugRecord;
        ["objectiveRuntimeObjectives", count (keys _dirtyRuntimeObjectiveIds)] call FLO_fnc_netDebugRecord;
        _dirtyRuntimeObjectiveIds = createHashMap;
        _forceRuntimeSync = false;
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
                private _captureState = _currentObjData get "captureState";
                private _secureProgress = _currentObjData get "captureSecureProgress";
                private _captureProgress = _currentObjData get "captureProgress";
                
                ["FLO_CaptureUI_Update", [
                    _ratio,
                    _friendlyCount,
                    _enemyCount,
                    str _owner,
                    _captureState,
                    _secureProgress,
                    _captureProgress
                ], owner _player] call CBA_fnc_ownerEvent;
            };
        };
    } forEach _allPlayers;

    sleep _updateInterval;
};
