/* Atomically commits one eligible group to a probe through its approach lane. */
params [
    "_director",
    "_cmdr",
    ["_front", createHashMap, [createHashMap]],
    ["_groupId", "", [""]]
];

private _fail = {
    params ["_message"];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};
if (_groupId == "") exitWith { false };
private _state = _director get "_state";
[_state] call FLO_fnc_campaignValidateProbeOwnership;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
if !(_groupId in _groups) then {
    [format ["Probe front %1 selected missing group %2", _front get "probeId", _groupId]] call _fail;
};
{
    if (_groupId in (_y get "committedGroupIds")) then {
        [format ["Probe group %1 is already owned by front %2", _groupId, _x]] call _fail;
    };
} forEach (_state get "frontlineProbes");

private _groupData = _groups get _groupId;
if !([
    _groupData,
    _cmdr get "_ownSide",
    ["infantry", "motorized", "mechanized", "armor"],
    ["PATROL", "DEFEND"],
    ""
] call FLO_fnc_gtnGroupIsStrategicallyAssignable) then {
    [format ["Probe group %1 is no longer strategically assignable", _groupId]] call _fail;
};
if ((_groupData get "unitCount") <= 0) then {
    [format ["Probe group %1 has no living units", _groupId]] call _fail;
};
if ((_cmdr get "_strategicOrderBudgetRemaining") < 1) exitWith { false };

private _objectiveId = _front get "objectiveId";
private _objective = FLO_Objectives get _objectiveId;
private _source = FLO_Objectives get (_front get "primarySourceObjectiveId");
private _routes = [
    _director,
    _objectiveId,
    _objective,
    _source get "position",
    [_groupId],
    _groups
] call FLO_fnc_campaignBuildAssaultApproachLanes;
if !(_groupId in _routes) then {
    [format ["Probe group %1 has no generated approach route", _groupId]] call _fail;
};
private _approachRoute = _routes get _groupId;
private _semanticWaypoints = _approachRoute apply {
    [_x, "MOVE", "AWARE", "FULL", "STAG COLUMN", "YELLOW", 25]
};
private _preflight = [
    _groupData get "position",
    _semanticWaypoints,
    true,
    "PROBE_PREFLIGHT",
    false
] call FLO_fnc_virtualizationResolveLandWaypoints;
if !(_preflight select 0) exitWith {
    ["CAMPAIGN", 2, format [
        "Probe front %1 held group %2 because it has no land route",
        _front get "probeId",
        _groupId
    ]] call FLO_fnc_log;
    false
};

private _routeMutableFields = [
    "waypoints", "currentWaypointIndex", "autoPatrol", "patrolConfig", "virtualSpeed",
    "lastMoveTime", "virtualMoveCarryMeters", "loiterStartTime", "pathToken", "pathTargetPos",
    "pathAllowTrails", "pathStartedAt", "pathSource", "pathWaypointSettings"
];
private _groupPatchMutableFields = [
    "state", "lastStateChangeTime", "noWaypoints", "idleHelicopterParked", "missionLock", "missionType",
    "executionState", "commanderOrder", "orderTargetPos", "orderMode", "attackObjective",
    "campaignOperationId", "defendObjective", "defendLeaseIssuedAt", "defendLeaseUntil",
    "garrisonPosition", "garrisonObjective", "postDismountWaypoint"
];
private _snapshot = createHashMapFromArray [
    ["position", +(_groupData get "position")],
    ["transportAttachment", [_groupData] call FLO_fnc_virtualizationGetTransportAttachment]
];
{
    _snapshot set [_x, [_groupData get _x] call FLO_fnc_virtualizationCloneValue];
} forEach (_groupPatchMutableFields + _routeMutableFields);
private _frontSnapshot = createHashMapFromArray [
    ["committedGroupIds", +(_front get "committedGroupIds")],
    ["committedUnitBaseline", _front get "committedUnitBaseline"],
    ["nextActionAtDateNum", _front get "nextActionAtDateNum"]
];
private _budgetRemaining = _cmdr get "_strategicOrderBudgetRemaining";
private _taskedGroups = +(_cmdr get "_gtnTaskedGroups");
private _assignmentCache = [_cmdr get "_objectiveAssignmentCache"] call FLO_fnc_virtualizationCloneValue;
private _eligibilityCacheDirty = _cmdr get "_availabilityCacheDirty";
private _assignmentId = _front get "formalOperationId";
if (_assignmentId == "") then { _assignmentId = _front get "probeId"; };
private _commitSucceeded = false;
private _commitException = "";
try {
    _commitSucceeded = _cmdr call ["_orderGroupAttack", [
        _groupId,
        _approachRoute,
        _objectiveId,
        true,
        _assignmentId
    ]];
    if (_commitSucceeded) then {
        private _committedIds = +(_front get "committedGroupIds");
        _committedIds pushBack _groupId;
        _front set ["committedGroupIds", _committedIds];
        _front set ["committedUnitBaseline", (_front get "committedUnitBaseline") + (_groupData get "unitCount")];
        private _now = call FLO_fnc_operationalDateNumber;
        _front set ["nextActionAtDateNum", [
            _now,
            (_director get "_config") get "probeCommitmentPaceSeconds"
        ] call FLO_fnc_dateNumberAddSeconds];
        [_front get "probeId", _front] call FLO_fnc_campaignValidateProbeFrontState;
        [_state] call FLO_fnc_campaignValidateProbeOwnership;
    };
} catch {
    _commitException = _exception;
};

if (!_commitSucceeded) exitWith {
    private _previousAttachment = _snapshot get "transportAttachment";
    private _currentAttachment = [_groupData] call FLO_fnc_virtualizationGetTransportAttachment;
    if (_previousAttachment == "" && {_currentAttachment != ""}) then {
        [_groupId, 0] call FLO_fnc_transportDetach;
        [_currentAttachment] call FLO_fnc_transportPoolRelease;
    };
    private _changes = createHashMap;
    {
        _changes set [_x, _snapshot get _x];
    } forEach _groupPatchMutableFields;
    [_groupId, _changes] call FLO_fnc_virtualizationPatchGroup;
    [_groupId, _snapshot get "position"] call FLO_fnc_virtualizationUpdateGroupPosition;
    [_groupId, _snapshot] call FLO_fnc_virtualizationRestoreRouteState;
    {
        _front set [_x, _y];
    } forEach _frontSnapshot;
    _cmdr set ["_strategicOrderBudgetRemaining", _budgetRemaining];
    _cmdr set ["_gtnTaskedGroups", _taskedGroups];
    _cmdr set ["_objectiveAssignmentCache", _assignmentCache];
    _cmdr set ["_availabilityCacheDirty", _eligibilityCacheDirty];
    ["CAMPAIGN", 2, format ["Probe front %1 rolled back group %2 commitment", _front get "probeId", _groupId]] call FLO_fnc_log;
    if (_commitException != "") then {
        [format ["Probe front %1 group %2 commitment failed: %3", _front get "probeId", _groupId, _commitException]] call _fail;
    };
    false
};

true
