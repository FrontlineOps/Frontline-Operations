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
 *
 * Return Value:
 * HASHMAP - Metrics
 */

params ["_gtnCommander"];

private _metrics = createHashMapFromArray [
    ["pictureGroups", 0],
    ["pictureObjectives", 0],
    ["eligibleGroups", 0],
    ["skippedInCombat", 0],
    ["activeEngagements", 0],
    ["appliedCount", 0],
    ["retaskedCount", 0],
    ["maintainedCount", 0],
    ["restoredCount", 0],
    ["failedRestores", 0]
];

private _ws = _gtnCommander get "_worldState";
private _engagementPicture = _ws call ["_getEnemyEngagementPicture", []];
private _engagementGroups = _engagementPicture get "groups";
private _config = _gtnCommander get "_config";
private _groups = FLO_virtualGroups get "_groups";
private _ownSide = _gtnCommander get "_ownSide";

_metrics set ["pictureGroups", _engagementPicture get "groupCount"];
_metrics set ["pictureObjectives", _engagementPicture get "objectiveCount"];

{
    private _groupId = _x;
    private _groupData = _y;

    if ((_groupData get "side") != _ownSide) then { continue };

    private _groupType = _groupData get "groupType";
    if (_groupType in ["civilian", "ambient", "helicopter", "jet", "air", "artillery", "static_aa", "boat", "naval", "submarine"]) then {
        continue;
    };
    if ((_groupData get "missionLock") != "") then { continue };
    if ((_groupData get "replacementState") != "") then { continue };

    private _order = _groupData get "commanderOrder";
    if !(_order in ["ATTACK", "DEFEND", "GARRISON"]) then { continue };

    _metrics set ["eligibleGroups", (_metrics get "eligibleGroups") + 1];

    if (_groupData get "inCombat") then {
        _metrics set ["skippedInCombat", (_metrics get "skippedInCombat") + 1];
        continue;
    };

    if (_groupData get "engagementActive") then {
        _metrics set ["activeEngagements", (_metrics get "activeEngagements") + 1];

        private _targetGroupId = _groupData get "engagementTargetGroupId";
        private _targetData = _engagementGroups getOrDefault [_targetGroupId, createHashMap];
        if (count (keys _targetData) > 0) then {
            private _evaluation = [_groupData, _targetData, _config] call FLO_fnc_gtnEvaluateGroupEngagementTarget;
            if (count (keys _evaluation) > 0) then {
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
                    ["reason", _evaluation get "reason"],
                    ["leashMeters", _evaluation get "leashMeters"],
                    ["score", _evaluation get "score"]
                ];

                if ([_groupId, _groupData, _target, _config] call FLO_fnc_gtnApplyGroupEngagement) then {
                    _metrics set ["retaskedCount", (_metrics get "retaskedCount") + 1];
                    continue;
                };
            };
        };

        if ([_gtnCommander, _groupId, _groupData] call FLO_fnc_gtnRestoreStrategicGroupRoute) then {
            _metrics set ["restoredCount", (_metrics get "restoredCount") + 1];
        } else {
            _metrics set ["failedRestores", (_metrics get "failedRestores") + 1];
        };
        continue;
    };

    private _target = [_groupData, _engagementPicture, _config] call FLO_fnc_gtnSelectGroupEngagementTarget;
    if (count (keys _target) == 0) then { continue };

    if ([_groupId, _groupData, _target, _config] call FLO_fnc_gtnApplyGroupEngagement) then {
        _metrics set ["appliedCount", (_metrics get "appliedCount") + 1];
    };
} forEach _groups;

_metrics
