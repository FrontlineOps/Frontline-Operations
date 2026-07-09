/*
 * Function: FLO_fnc_virtualizationResumeSavedRoutes
 * Author: Frontline Operations Development Group
 * Description:
 *   Reissues saved virtual-group routes whose pending pathfinding callbacks
 *   were lost across save/load. This primarily restores logistics
 *   reinforcements that were saved in a planning state.
 *
 * Arguments: None
 *
 * Return Value:
 * NUMBER - Count of groups whose routes were reissued
 */

if (isNil "FLO_virtualGroups") exitWith { 0 };

private _groups = FLO_virtualGroups get "_groups";
private _resumed = 0;

{
    private _groupId = _x;
    private _groupData = _y;
    private _waypoints = _groupData get "waypoints";

    if (_waypoints isNotEqualTo []) then { continue };

    private _pendingTarget = _groupData get "pathTargetPos";
    private _allowTrails = _groupData get "pathAllowTrails";
    private _source = _groupData get "pathSource";
    private _waypointSettings = _groupData get "pathWaypointSettings";
    private _replacementState = _groupData get "replacementState";

    private _needsResume = count _pendingTarget >= 2 && {count _waypointSettings >= 7};

    if (!_needsResume && {_replacementState != ""}) then {
        private _reinforcementTargetPos = _groupData get "reinforcementTargetPos";
        if (count _reinforcementTargetPos >= 2) then {
            private _groupType = _groupData get "groupType";
            private _completionRadius = [20, 80] select (_replacementState == "AA_DEPLOY");

            _pendingTarget = _reinforcementTargetPos;
            _allowTrails = _groupType in ["infantry"];
            _source = ["LOGI_REINF", "LOGI_STATIC_AA"] select (_replacementState == "AA_DEPLOY");
            _waypointSettings = [_pendingTarget, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", _completionRadius];
            _needsResume = true;
        };
    };

    if (!_needsResume) then { continue };

    private _resumeWaypoint = +_waypointSettings;
    _resumeWaypoint set [0, _pendingTarget];

    [_groupData] call FLO_fnc_virtualizationClearPathRequest;

    [_groupId, [_resumeWaypoint], true, _allowTrails, _source] call FLO_fnc_updateVirtualGroupWaypoints;
    _resumed = _resumed + 1;
} forEach _groups;

if (_resumed > 0) then {
    ["VIRTUALIZATION", 2, format ["Reissued %1 saved route requests after load", _resumed]] call FLO_fnc_log;
};

_resumed
