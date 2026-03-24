/*
 * Function: FLO_fnc_virtualizationProcessActiveState
 */

params ["_groupId", "_groupData", "_realGroup", "_tracksAssets", "_replacementState", "_now", "_virtStats"];

private _leader = leader _realGroup;
if (!isNull _leader && {alive _leader}) then {
    private _realPos = getPosATL _leader;
    if ([_realPos] call FLO_fnc_virtualizationIsValidPosition) then {
        [FLO_virtualGroups, _groupId, _realPos] call FLO_fnc_virtualizationUpdateGroupPosition;
        _virtStats set ["activePositionSyncsTotal", (_virtStats get "activePositionSyncsTotal") + 1];
        _virtStats set ["activePositionSyncsThisBatch", (_virtStats get "activePositionSyncsThisBatch") + 1];
    };

    if (_replacementState == "REINFORCE") then {
        private _reinforcementTargetPos = _groupData get "reinforcementTargetPos";
        if (count _reinforcementTargetPos >= 2 && {_realPos distance2D _reinforcementTargetPos <= 120}) then {
            [_groupId, _groupData] call FLO_fnc_virtualizationFinalizeReinforcement;
        };
    };

    private _realWaypoints = waypoints _realGroup;
    private _state = _groupData get "state";
    private _hasAutoPatrol = _groupData get "autoPatrol";
    if (count _realWaypoints <= 1 && {!_hasAutoPatrol} && {_state == "idle"}) then {
        if ([_groupId, _groupData, _realPos] call FLO_fnc_virtualizationAssignAutoPatrol) then {
            _virtStats set ["patrolAssignmentsTotal", (_virtStats get "patrolAssignmentsTotal") + 1];
            _virtStats set ["patrolAssignmentsThisBatch", (_virtStats get "patrolAssignmentsThisBatch") + 1];
        };
    };
};

private _lastChange = _groupData get "lastStateChangeTime";
if (_now - _lastChange > 5) then {
    private _eliminated = if (_tracksAssets) then {
        count ([_groupData, _realGroup] call FLO_fnc_virtualizationGetRealAssetVehicles) == 0
    } else {
        ({alive _x} count units _realGroup) == 0
    };

    if (_eliminated) then {
        ["VIRTUALIZATION", 3, format["Group %1 eliminated - removing", _groupId]] call FLO_fnc_log;
        [FLO_virtualGroups, _groupId] call FLO_fnc_virtualizationRemoveGroup;
        _virtStats set ["eliminatedGroupsTotal", (_virtStats get "eliminatedGroupsTotal") + 1];
        _virtStats set ["eliminatedGroupsThisBatch", (_virtStats get "eliminatedGroupsThisBatch") + 1];
    };
};

true
