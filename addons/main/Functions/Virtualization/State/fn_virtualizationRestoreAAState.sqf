/*
 * Function: FLO_fnc_virtualizationRestoreAAState
 */

params ["_groupData", "_savedData"];

[_groupData] call FLO_fnc_virtualizationClearAADeployState;
private _aaDeployState = _savedData get "aaDeployState";
if (_aaDeployState == "") exitWith { true };

[
    _groupData,
    _aaDeployState,
    _savedData get "aaDeployTargetPos",
    _savedData get "aaDeployTargetObjective",
    _savedData get "isStrategicAA"
] call FLO_fnc_virtualizationSetAADeployState;

true
