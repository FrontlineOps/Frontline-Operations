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

["OBJECTIVEMONITOR", 3, "MonitorObjectiveDominance started"] call FLO_fnc_log;

// Wait for objectives to be initialized
waitUntil { !isNil "FLO_Objectives" };
["OBJECTIVEMONITOR", 3, "FLO_Objectives initialized"] call FLO_fnc_log;

// Get config values
private _captureTime = ["get", "captureTime"] call FLO_fnc_objectiveConfig;
private _captureSecureTime = ["get", "captureSecureTime"] call FLO_fnc_objectiveConfig;

// Capture state updates at tactical cadence; clients receive owner-targeted events.
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
    private _currentDateNum = call FLO_fnc_operationalDateNumber;

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
    private _allPlayers = [] call FLO_fnc_getConnectedHumanPlayers;
    
    // === IDENTIFY ACTIVE OBJECTIVES (Near Players) ===
    {
        private _pPos = getPosATL _x;
        {
            private _oId = _x;
            private _objData = FLO_Objectives get _oId;
            private _radius = _objData get "radius";
            // Keep large objective areas active across their full capture radius.
            private _dist = (_objData get "position") distance2D _pPos;
            if (_dist < (1000 max _radius)) then {
                _activeObjectives pushBackUnique _oId;
            };
            if (_dist < _radius) then {
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

    if (_objectivesToUpdate isNotEqualTo [] && {!isNil "FLO_VirtualForceRegistry"}) then {
        private _groups = call FLO_fnc_virtualizationGetGroupMap;
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

            FLO_ObjectiveRuntimeState set [
                _objectiveId,
                [_objective] call FLO_fnc_buildObjectiveRuntimeRecord
            ];
        } forEach (keys _dirtyRuntimeObjectiveIds);

        [] call FLO_fnc_publishObjectiveRuntimeState;
        _lastRuntimeSyncAt = _currentTime;
        ["objectiveRuntimeSyncs", 1] call FLO_fnc_netDebugRecord;
        ["objectiveRuntimeObjectives", count (keys _dirtyRuntimeObjectiveIds)] call FLO_fnc_netDebugRecord;
        _dirtyRuntimeObjectiveIds = createHashMap;
        _forceRuntimeSync = false;
    };

    // Publish viewer-relative Capture UI state from the maintained objective data.
    {
        private _player = _x;
        if (isNull _player) then { continue };
        if (!alive _player) then {
            [_player, [], false] call FLO_fnc_captureUIPublishPlayerState;
            continue;
        };
        if !((side group _player) in [west, east]) then { continue };

        private _match = [_player, _activeObjectives] call FLO_fnc_captureUIResolvePlayerObjective;
        [_player, _match, false] call FLO_fnc_captureUIPublishPlayerState;
    } forEach _allPlayers;

    sleep _updateInterval;
};
