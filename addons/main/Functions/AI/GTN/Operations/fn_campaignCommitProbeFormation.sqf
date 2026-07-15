/* Atomically commits one whole formation through compact probe approach lanes. */
params [
    "_director",
    "_cmdr",
    ["_front", createHashMap, [createHashMap]],
    ["_selection", createHashMap, [createHashMap]],
    ["_isReinforcement", false, [true]]
];

if ((keys _selection) isEqualTo []) exitWith { false };
private _formationId = _selection get "formationId";
private _memberIds = +(_selection get "memberIds");
private _state = _director get "_state";
private _fronts = _state get "frontlineProbes";
private _formationState = _state get "formationState";
private _formations = _formationState get "formations";
private _formation = _formations get _formationId;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
if ((_formation get "role") != "RESERVE" || {(_formation get "roleOperationId") != ""}) then {
    private _message = format [
        "Probe formation %1 is not an unowned reserve (%2/%3)",
        _formationId,
        _formation get "role",
        _formation get "roleOperationId"
    ];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};
private _livingFormationMembers = (_formation get "memberIds") select {
    _x in _groups && {((_groups get _x) get "unitCount") > 0}
};
if (_memberIds isNotEqualTo _livingFormationMembers) then {
    private _message = format ["Probe formation %1 selection no longer matches its living members", _formationId];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};
{
    if (_formationId in (_y get "formationIds")) then {
        private _message = format ["Probe formation %1 is already owned by front %2", _formationId, _x];
        ["CAMPAIGN", 1, _message] call FLO_fnc_log;
        throw _message;
    };
    private _conflictingGroupIds = (_y get "committedGroupIds") arrayIntersect _memberIds;
    if (_conflictingGroupIds isNotEqualTo []) then {
        private _message = format [
            "Probe formation %1 members %2 are already owned by front %3",
            _formationId,
            _conflictingGroupIds,
            _x
        ];
        ["CAMPAIGN", 1, _message] call FLO_fnc_log;
        throw _message;
    };
} forEach _fronts;
if ((count _memberIds) < 3 || {(count _memberIds) > 6}) then {
    throw format ["Probe formation %1 has invalid commitment size %2", _formationId, count _memberIds];
};
if ((_cmdr get "_strategicOrderBudgetRemaining") < count _memberIds) exitWith { false };

private _objectiveId = _front get "objectiveId";
private _sourceObjectiveId = _front get "primarySourceObjectiveId";
private _objective = FLO_Objectives get _objectiveId;
private _source = FLO_Objectives get _sourceObjectiveId;
private _assignmentId = _front get "formalOperationId";
if (_assignmentId == "") then { _assignmentId = _front get "probeId"; };
private _routes = [
    _director,
    _objectiveId,
    _objective,
    _source get "position",
    _memberIds,
    _groups
] call FLO_fnc_campaignBuildAssaultApproachLanes;
if ((count (keys _routes)) != count _memberIds) then {
    throw format ["Probe formation %1 route count %2 does not match members %3", _formationId, count (keys _routes), count _memberIds];
};

private _routePreflightFailed = false;
{
    private _approachRoute = _routes get _x;
    private _semanticWaypoints = _approachRoute apply {
        [_x, "MOVE", "AWARE", "FULL", "STAG COLUMN", "YELLOW", 25]
    };
    private _preflight = [
        (_groups get _x) get "position",
        _semanticWaypoints,
        true,
        "PROBE_PREFLIGHT",
        false
    ] call FLO_fnc_virtualizationResolveLandWaypoints;
    if !(_preflight select 0) then {
        _routePreflightFailed = true;
    };
} forEach _memberIds;
if (_routePreflightFailed) exitWith {
    ["CAMPAIGN", 2, format ["Probe formation %1 held because one or more members have no land route", _formationId]] call FLO_fnc_log;
    false
};

private _committedIds = [];
private _attemptedIds = [];
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
private _groupMutableFields = _groupPatchMutableFields + _routeMutableFields;
private _groupSnapshots = createHashMap;
{
    private _groupData = _groups get _x;
    private _snapshot = createHashMapFromArray [
        ["position", +(_groupData get "position")],
        ["transportAttachment", [_groupData] call FLO_fnc_virtualizationGetTransportAttachment]
    ];
    {
        _snapshot set [_x, [_groupData get _x] call FLO_fnc_virtualizationCloneValue];
    } forEach _groupMutableFields;
    _groupSnapshots set [_x, _snapshot];
} forEach _memberIds;
private _formationRoleSnapshot = createHashMapFromArray [
    ["role", _formation get "role"],
    ["roleMemberIds", +(_formation get "roleMemberIds")],
    ["roleObjectiveId", _formation get "roleObjectiveId"],
    ["roleOperationId", _formation get "roleOperationId"],
    ["roleStartedAtDateNum", _formation get "roleStartedAtDateNum"],
    ["roleEndsAtDateNum", _formation get "roleEndsAtDateNum"],
    ["returnObjectiveId", _formation get "returnObjectiveId"]
];
private _formationRevisionBeforeCommit = _formationState get "revision";
private _frontSnapshot = createHashMapFromArray [
    ["formationIds", +(_front get "formationIds")],
    ["committedGroupIds", +(_front get "committedGroupIds")],
    ["committedUnitBaseline", _front get "committedUnitBaseline"],
    ["reinforcementCount", _front get "reinforcementCount"],
    ["nextActionAtDateNum", _front get "nextActionAtDateNum"]
];
private _budgetRemainingBeforeCommit = _cmdr get "_strategicOrderBudgetRemaining";
private _taskedGroupsBeforeCommit = +(_cmdr get "_gtnTaskedGroups");
private _assignmentCacheBeforeCommit = [
    _cmdr get "_objectiveAssignmentCache"
] call FLO_fnc_virtualizationCloneValue;
private _availabilityCacheDirtyBeforeCommit = _cmdr get "_availabilityCacheDirty";
private _commitException = "";
private _commitSucceeded = false;
try {
    {
        private _groupId = _x;
        _attemptedIds pushBack _groupId;
        if !(_cmdr call ["_orderGroupAttack", [_groupId, _routes get _groupId, _objectiveId, true, _assignmentId]]) exitWith {};
        _committedIds pushBack _groupId;
    } forEach _memberIds;

    if ((count _committedIds) == count _memberIds) then {
        private _now = call FLO_fnc_operationalDateNumber;
        _formation set ["role", "MAIN"];
        _formation set ["roleMemberIds", _memberIds];
        _formation set ["roleObjectiveId", _objectiveId];
        _formation set ["roleOperationId", _assignmentId];
        _formation set ["roleStartedAtDateNum", _now];
        _formation set ["roleEndsAtDateNum", -1];
        _formation set ["returnObjectiveId", _sourceObjectiveId];
        _formationState set ["revision", _formationRevisionBeforeCommit + 1];

        private _formationIds = +(_front get "formationIds");
        _formationIds pushBackUnique _formationId;
        _front set ["formationIds", _formationIds];
        private _probeGroupIds = +(_front get "committedGroupIds");
        private _unitBaseline = _front get "committedUnitBaseline";
        {
            _probeGroupIds pushBackUnique _x;
            _unitBaseline = _unitBaseline + ((_groups get _x) get "unitCount");
        } forEach _memberIds;
        _front set ["committedGroupIds", _probeGroupIds];
        _front set ["committedUnitBaseline", _unitBaseline];
        if (_isReinforcement) then {
            _front set ["reinforcementCount", (_front get "reinforcementCount") + 1];
        };
        _front set [
            "nextActionAtDateNum",
            [_now, (_director get "_config") get "probeCommitmentPaceSeconds"] call FLO_fnc_dateNumberAddSeconds
        ];
        [_front get "probeId", _front] call FLO_fnc_campaignValidateProbeFrontState;
        [_state] call FLO_fnc_campaignValidateProbeOwnership;
        _commitSucceeded = true;
    };
} catch {
    _commitException = _exception;
};

if (!_commitSucceeded) exitWith {
    {
        private _snapshot = _groupSnapshots get _x;
        private _groupData = _groups get _x;
        private _previousAttachment = _snapshot get "transportAttachment";
        private _currentAttachment = [_groupData] call FLO_fnc_virtualizationGetTransportAttachment;
        if (_previousAttachment == "" && {_currentAttachment != ""}) then {
            [_x, 0] call FLO_fnc_transportDetach;
            [_currentAttachment] call FLO_fnc_transportPoolRelease;
        };
        private _changes = createHashMap;
        {
            _changes set [_x, _snapshot get _x];
        } forEach _groupPatchMutableFields;
        [_x, _changes] call FLO_fnc_virtualizationPatchGroup;
        [_x, _snapshot get "position"] call FLO_fnc_virtualizationUpdateGroupPosition;
        [_x, _snapshot] call FLO_fnc_virtualizationRestoreRouteState;
    } forEach _attemptedIds;
    _cmdr set ["_strategicOrderBudgetRemaining", _budgetRemainingBeforeCommit];
    _cmdr set ["_gtnTaskedGroups", _taskedGroupsBeforeCommit];
    _cmdr set ["_objectiveAssignmentCache", _assignmentCacheBeforeCommit];
    _cmdr set ["_availabilityCacheDirty", _availabilityCacheDirtyBeforeCommit];
    {
        _formation set [_x, _y];
    } forEach _formationRoleSnapshot;
    _formationState set ["revision", _formationRevisionBeforeCommit];
    {
        _front set [_x, _y];
    } forEach _frontSnapshot;
    ["CAMPAIGN", 2, format [
        "Probe formation %1 commitment rolled back after %2/%3 groups",
        _formationId,
        count _committedIds,
        count _memberIds
    ]] call FLO_fnc_log;
    if (_commitException != "") then {
        throw _commitException;
    };
    false
};

["CAMPAIGN", 3, format [
    "Probe front %1 committed formation %2 groups=%3 reinforcement=%4",
    _front get "probeId",
    _formation get "name",
    count _memberIds,
    _isReinforcement
]] call FLO_fnc_log;
true
