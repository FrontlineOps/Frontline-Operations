/*
 * Function: FLO_fnc_virtualizationRestoreMissionState
 */

params ["_groupData", "_savedData"];

[_groupData] call FLO_fnc_virtualizationClearMissionLock;
private _missionLock = _savedData get "missionLock";
if (_missionLock != "") then {
    [_groupData, _missionLock, _savedData get "missionType"] call FLO_fnc_virtualizationSetMissionLock;
};

[_groupData] call FLO_fnc_virtualizationClearExecutionState;
private _executionState = _savedData get "executionState";
if (_executionState != "") then {
    [_groupData, _executionState] call FLO_fnc_virtualizationSetExecutionState;
};

true
