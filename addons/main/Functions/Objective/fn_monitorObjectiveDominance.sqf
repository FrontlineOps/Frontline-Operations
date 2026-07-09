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

    if (_objectivesToUpdate isNotEqualTo [] && {!isNil "FLO_virtualGroups"}) then {
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

    // === EXECUTE UPDATES ===
    {
        private _objectiveForceRuntimeSync = [
            _x,
            _currentTime,
            _currentDateNum,
            _captureTime,
            _captureSecureTime,
            _liveObjectives,
            _allPlayers,
            _virtualObjectiveCounts,
            _objectiveLastUpdateTimes,
            _dirtyRuntimeObjectiveIds
        ] call FLO_fnc_updateObjectiveDominance;

        if (_objectiveForceRuntimeSync) then {
            _forceRuntimeSync = true;
        };
    } forEach _objectivesToUpdate;

    // === LIGHTWEIGHT CLIENT RUNTIME SYNC ===
    if ((keys _dirtyRuntimeObjectiveIds) isNotEqualTo [] && {_forceRuntimeSync || {(_currentTime - _lastRuntimeSyncAt) >= _runtimeSyncInterval}}) then {
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

        [] call FLO_fnc_publishObjectiveRuntimeState;
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
                private _friendlyCount = [_bluforCount, _opforCount] select (_playerSide isEqualTo east);
                private _enemyCount = [_opforCount, _bluforCount] select (_playerSide isEqualTo east);
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
