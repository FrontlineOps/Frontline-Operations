/*
 * Function: FLO_fnc_virtualizationRestorePathState
 */

params ["_groupData", "_savedData"];

[_groupData] call FLO_fnc_virtualizationClearPathRequest;
if ((_savedData get "pathToken") < 0) exitWith { true };

[
    _groupData,
    _savedData get "pathToken",
    _savedData get "pathTargetPos",
    _savedData get "pathAllowTrails",
    _savedData get "pathStartedAt",
    _savedData get "pathSource",
    _savedData get "pathWaypointSettings"
] call FLO_fnc_virtualizationSetPendingPathRequest;

true
