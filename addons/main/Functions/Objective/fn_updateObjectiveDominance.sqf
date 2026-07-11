/*
 * Function: FLO_fnc_updateObjectiveDominance
 * Author: Frontline Operations Development Group
 * Description:
 *   Updates unit dominance, capture state, ownership, and runtime dirty state
 *   for one objective.
 *
 * Arguments:
 *   0: Objective id <STRING>
 *   1: Current diag_tickTime <NUMBER>
 *   2: Current date number <NUMBER>
 *   3: Capture time <NUMBER>
 *   4: Capture secure time <NUMBER>
 *   5: Live objective ids <ARRAY>
 *   6: Current players <ARRAY>
 *   7: Virtual objective counts <HASHMAP>
 *   8: Last objective update times <HASHMAP>
 *   9: Dirty runtime objective ids <HASHMAP>
 *
 * Return Value:
 *   Force runtime sync needed <BOOL>
 */

params [
    "_id",
    "_currentTime",
    "_currentDateNum",
    "_captureTime",
    "_captureSecureTime",
    "_liveObjectives",
    "_allPlayers",
    "_virtualObjectiveCounts",
    "_objectiveLastUpdateTimes",
    "_dirtyRuntimeObjectiveIds"
];

private _forceRuntimeSync = false;
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

private _virtualCounts = _virtualObjectiveCounts get _id;
_bluforCount = _bluforCount + (_virtualCounts select 0);
_opforCount = _opforCount + (_virtualCounts select 1);

private _minUnitsToCapture = [3, 1] select (_id in _liveObjectives);

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

if (_requestedOwner isNotEqualTo sideUnknown) then {
    [_id, _requestedOwner] call FLO_fnc_flipObjective;

    _objRecord = FLO_Objectives get _id;

    if (_activeSide isEqualTo _requestedOwner) then {
        [0.20, "increase"] call FLO_fnc_adjustAggression;
    } else {
        [-0.10, "decrease"] call FLO_fnc_adjustAggression;
    };
};

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
_objRecord set ["captureTime", _captureTime];
_objRecord set ["captureSecureTime", _captureSecureTime];

if (
    (abs (_previousProgress - (_objRecord get "captureProgress"))) > 0.01
    || {_previousState != (_objRecord get "captureState")}
    || {_previousCaptureSide isNotEqualTo (_objRecord get "captureSide")}
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

_forceRuntimeSync
