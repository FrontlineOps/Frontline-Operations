/*
 * Function: FLO_fnc_virtualizationRequestPathRouteUpdate
 */

params ["_groupId", "_groupData", "_currentPos", "_sanitizedWaypoints", "_allowTrails", "_sourceTag", "_isNavalGroup", "_groupType"];

private _firstWaypoint = _sanitizedWaypoints select 0;
private _endPos = _firstWaypoint select 0;
private _pathStart = +_currentPos;
private _pathEnd = +_endPos;

if (count _pathStart > 2) then { _pathStart resize 2; };
if (count _pathEnd > 2) then { _pathEnd resize 2; };

private _existingToken = _groupData get "pathToken";
private _existingTarget = _groupData get "pathTargetPos";
private _existingTrails = _groupData get "pathAllowTrails";
private _sameRoutePending = _existingToken >= 0 && {count _existingTarget >= 2} && {_existingTarget distance2D _pathEnd < 25} && {_existingTrails isEqualTo _allowTrails};
if (_sameRoutePending) exitWith {
    ["VIRTUALIZATION", 4, format ["Path request already pending for group %1 to %2", _groupId, _pathEnd]] call FLO_fnc_log;
    true
};

[_groupData] call FLO_fnc_virtualizationClearPathRequest;
private _directBootstrapAllowed = _isNavalGroup || {_groupType in ["helicopter", "air", "jet"]};

private _wpType = _firstWaypoint select 1;
private _wpBehavior = _firstWaypoint select 2;
private _wpSpeed = _firstWaypoint select 3;
private _wpFormation = _firstWaypoint select 4;
private _wpMode = _firstWaypoint select 5;
private _wpCompletionRadius = _firstWaypoint select 6;

[_groupData, if (_directBootstrapAllowed) then { [_firstWaypoint] } else { [] }, _sourceTag, if (_directBootstrapAllowed) then { "moving" } else { "planning" }, if (_directBootstrapAllowed) then { 1 } else { 0 }] call FLO_fnc_virtualizationSetRouteState;
_groupData set ["pathWaypointSettings", _firstWaypoint];

if (_groupData get "isActive") then {
    private _bootstrapPos = if (_directBootstrapAllowed) then { _endPos } else { _currentPos };
    private _bootstrapType = if (_directBootstrapAllowed) then { _wpType } else { "HOLD" };
    [_groupData, _bootstrapPos, _bootstrapType, _wpBehavior, _wpSpeed, _wpFormation, _wpMode, _wpCompletionRadius] call FLO_fnc_virtualizationApplyBootstrapWaypoint;
};

private _requestToken = floor (diag_tickTime * 1000) + floor random 100000;
private _requestTime = diag_tickTime;
[_groupData, _requestToken, _pathEnd, _allowTrails, _requestTime, _sourceTag, _firstWaypoint] call FLO_fnc_virtualizationSetPendingPathRequest;

if (!_directBootstrapAllowed) then {
    ["VIRTUALIZATION", 3, format ["Starting route resolution for group %1 from %2 to %3 (holding: waiting for resolved path)", _groupId, _pathStart, _pathEnd]] call FLO_fnc_log;
} else {
    ["VIRTUALIZATION", 3, format ["Starting route resolution for group %1 from %2 to %3 (direct movement active)", _groupId, _pathStart, _pathEnd]] call FLO_fnc_log;
};

private _callbackArgs = [_groupId, _firstWaypoint, _requestToken];
[_pathStart, _pathEnd, FLO_fnc_virtualizationHandlePathResolved, _callbackArgs, _allowTrails, _sourceTag] call FLO_fnc_findRoadPath;

true
