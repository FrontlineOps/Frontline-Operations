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

    if (count _waypoints > 0) then { continue };

    private _pendingTarget = _groupData get "pathRequestTarget";
    private _allowTrails = _groupData get "pathRequestTrails";
    private _source = _groupData get "pathRequestSource";
    private _waypointSettings = _groupData get "tempWaypointSettings";

    private _needsResume = count _pendingTarget >= 2 && {count _waypointSettings >= 7};

    if (!_needsResume && {_groupData get "isReinforcing"}) then {
        private _reinforcementTargetPos = _groupData get "reinforcementTargetPos";
        if (count _reinforcementTargetPos >= 2) then {
            private _groupType = _groupData get "groupType";
            private _completionRadius = if (_groupType isEqualTo "static_aa") then { 80 } else { 20 };

            _pendingTarget = _reinforcementTargetPos;
            _allowTrails = _groupType in ["infantry"];
            _source = if (_groupType isEqualTo "static_aa") then { "LOGI_STATIC_AA" } else { "LOGI_REINF" };
            _waypointSettings = [_pendingTarget, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", _completionRadius];
            _needsResume = true;
        };
    };

    if (!_needsResume) then { continue };

    private _resumeWaypoint = +_waypointSettings;
    _resumeWaypoint set [0, _pendingTarget];

    // The original async callback died with the save. Reissue a fresh request.
    _groupData set ["pathRequestToken", -1];
    _groupData set ["pathRequestStartedAt", -1];
    _groupData set ["pathRequestTarget", []];
    _groupData set ["pathRequestTrails", false];

    [_groupId, [_resumeWaypoint], true, _allowTrails, _source] call FLO_fnc_updateVirtualGroupWaypoints;
    _resumed = _resumed + 1;
} forEach _groups;

if (_resumed > 0) then {
    ["VIRTUALIZATION", 2, format ["Reissued %1 saved route requests after load", _resumed]] call FLO_fnc_log;
};

_resumed
