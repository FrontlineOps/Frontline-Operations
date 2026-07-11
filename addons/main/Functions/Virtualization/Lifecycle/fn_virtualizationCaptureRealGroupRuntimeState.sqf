/*
 * Function: FLO_fnc_virtualizationCaptureRealGroupRuntimeState
 */

params ["_groupData", "_realGroup"];

private _leader = leader _realGroup;
private _state = "idle";
private _leaderBehavior = behaviour _leader;
private _leaderCommand = currentCommand _leader;

if (_leaderBehavior isEqualTo "COMBAT") then {
    _state = "holding";
} else {
    if (_leaderCommand isEqualTo "MOVE") then {
        _state = "moving";
    };
};

[_groupData, _state] call FLO_fnc_virtualizationSetRuntimeState;

_state
