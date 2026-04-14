/*
 * Function: FLO_fnc_gtnManageOpportunisticEngagements
 * Author: Frontline Operations Development Group
 * Description:
 *   Maintains short-lived tactical engagement overlays for GTN attack,
 *   defense, and garrison groups based on commander-confirmed enemy intel.
 *   Strategic commander orders remain unchanged; only the temporary route is
 *   replaced while the opportunity exists.
 *
 * Arguments:
 * 0: GTN commander <HASHMAP>
 * 1: BOOL - true to allow fresh target acquisition, false to only maintain
 *    active engagement overlays
 *
 * Return Value:
 * HASHMAP - Metrics
 */

params [
    "_gtnCommander",
    ["_fullSweep", true, [true]]
];

private _metrics = createHashMapFromArray [
    ["fullSweep", _fullSweep],
    ["pictureGroups", 0],
    ["pictureObjectives", 0],
    ["eligibleGroups", 0],
    ["skippedInCombat", 0],
    ["inactiveSweepSkipped", 0],
    ["activeEngagements", 0],
    ["appliedCount", 0],
    ["retaskedCount", 0],
    ["maintainedCount", 0],
    ["restoredCount", 0],
    ["failedRestores", 0],
    ["activeAfterCount", 0]
];

private _ws = _gtnCommander get "_worldState";
private _engagementPicture = _ws call ["_getEnemyEngagementPicture", []];
private _engagementGroups = _engagementPicture get "groups";
private _attackCandidateIds = keys _engagementGroups;
private _config = _gtnCommander get "_config";
private _groups = FLO_virtualGroups get "_groups";
private _ownSide = _gtnCommander get "_ownSide";
private _taskedGroupIds = +(_gtnCommander get "_gtnTaskedGroups");
private _assignmentState = createHashMap;
private _assignmentCapCache = createHashMap;
private _commanderGroups = [];
private _activeCommanderGroups = [];

_metrics set ["pictureGroups", _engagementPicture get "groupCount"];
_metrics set ["pictureObjectives", _engagementPicture get "objectiveCount"];

{
    private _groupId = _x;
    if !(_groupId in _groups) then { continue };

    private _groupData = _groups get _groupId;
    if ((_groupData get "side") != _ownSide) then { continue };
    _commanderGroups pushBack [_groupId, _groupData];

    if !(_groupData get "engagementActive") then { continue };
    _activeCommanderGroups pushBack [_groupId, _groupData];
    private _targetGroupId = _groupData get "engagementTargetGroupId";
    if (_targetGroupId == "") then { continue };
    private _targetData = _engagementGroups get _targetGroupId;
    if (isNil "_targetData") then { continue };

    private _groupLoad = [_groupData, false] call FLO_fnc_virtualizationGetGroupUnitLoad;
    [_assignmentState, _targetGroupId, 1, _groupLoad] call FLO_fnc_gtnAdjustEngagementTargetAssignment;
} forEach _taskedGroupIds;

if (!_fullSweep) then {
    _metrics set ["inactiveSweepSkipped", (count _commanderGroups) - (count _activeCommanderGroups)];
};

{
    _x params ["_groupId", "_groupData"];

    private _groupType = _groupData get "groupType";
    if (_groupType in ["civilian", "ambient", "helicopter", "jet", "air", "artillery", "static_aa", "boat", "naval", "submarine"]) then {
        continue;
    };
    if ((_groupData get "missionLock") != "") then { continue };
    if ((_groupData get "replacementState") != "") then { continue };

    private _order = _groupData get "commanderOrder";
    if !(_order in ["ATTACK", "DEFEND", "GARRISON"]) then { continue };
    private _groupLoad = [_groupData, false] call FLO_fnc_virtualizationGetGroupUnitLoad;

    _metrics set ["eligibleGroups", (_metrics get "eligibleGroups") + 1];

    if (_groupData get "inCombat") then {
        _metrics set ["skippedInCombat", (_metrics get "skippedInCombat") + 1];
        continue;
    };

    private _groupContext = [_groupData, _config] call FLO_fnc_gtnBuildGroupEngagementContext;

    if (_groupData get "engagementActive") then {
        _metrics set ["activeEngagements", (_metrics get "activeEngagements") + 1];

        private _targetGroupId = _groupData get "engagementTargetGroupId";
        private _targetData = _engagementGroups get _targetGroupId;
        if !(isNil "_targetData") then {
            private _evaluation = [_groupData, _targetData, _config, _groupContext] call FLO_fnc_gtnEvaluateGroupEngagementTarget;
            if (count _evaluation > 0) then {
                _groupData set ["engagementExpiresAt", diag_tickTime + (_config get "engagementDurationSeconds")];

                private _targetPos = _targetData get "position";
                private _storedTargetPos = _groupData get "engagementTargetPos";
                if (count _storedTargetPos >= 2 && {_storedTargetPos distance2D _targetPos <= (_config get "engagementRetaskMoveMeters")}) then {
                    _metrics set ["maintainedCount", (_metrics get "maintainedCount") + 1];
                    continue;
                };

                private _target = createHashMapFromArray [
                    ["targetGroupId", _targetGroupId],
                    ["targetPos", _targetPos],
                    ["targetObjective", if (_order == "DEFEND") then { _groupData get "defendObjective" } else { if (_order == "GARRISON") then { _groupData get "garrisonObjective" } else { _groupData get "attackObjective" } }],
                    ["reason", _evaluation select 1],
                    ["leashMeters", _evaluation select 2],
                    ["score", _evaluation select 0]
                ];

                if ([_groupId, _groupData, _target, _config] call FLO_fnc_gtnApplyGroupEngagement) then {
                    _metrics set ["retaskedCount", (_metrics get "retaskedCount") + 1];
                    continue;
                };
            };
        };

        [_assignmentState, _targetGroupId, -1, -_groupLoad] call FLO_fnc_gtnAdjustEngagementTargetAssignment;
        if ([_gtnCommander, _groupId, _groupData] call FLO_fnc_gtnRestoreStrategicGroupRoute) then {
            _metrics set ["restoredCount", (_metrics get "restoredCount") + 1];
        } else {
            _metrics set ["failedRestores", (_metrics get "failedRestores") + 1];
        };
        continue;
    };

    if (!_fullSweep) then { continue };

    private _target = [
        _groupData,
        _engagementPicture,
        _config,
        _assignmentState,
        _groupContext,
        _attackCandidateIds,
        _assignmentCapCache
    ] call FLO_fnc_gtnSelectGroupEngagementTarget;
    private _targetGroupId = _target get "targetGroupId";
    if (isNil "_targetGroupId" || {_targetGroupId == ""}) then { continue };

    if ([_groupId, _groupData, _target, _config] call FLO_fnc_gtnApplyGroupEngagement) then {
        [_assignmentState, _target get "targetGroupId", 1, _groupLoad] call FLO_fnc_gtnAdjustEngagementTargetAssignment;
        _metrics set ["appliedCount", (_metrics get "appliedCount") + 1];
    };
} forEach (if (_fullSweep) then { _commanderGroups } else { _activeCommanderGroups });

_metrics set [
    "activeAfterCount",
    ((_metrics get "activeEngagements") + (_metrics get "appliedCount")) - (_metrics get "restoredCount") - (_metrics get "failedRestores")
];

_metrics
