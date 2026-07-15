/* Transfers one lower-maturity probe's complete group task force to a ready front. */
params [
    "_director",
    "_cmdr",
    ["_recipient", createHashMap, [createHashMap]],
    ["_currentActiveCount", 0, [0]],
    ["_diagnostics", createHashMap, [createHashMap]]
];

private _metrics = createHashMapFromArray [
    ["movedGroupCount", 0],
    ["donorProbeIds", []],
    ["assaultMassReady", false]
];
if ((_recipient get "formalOperationId") != "" || {(_recipient get "stage") != "REINFORCE_SUCCESS"}) exitWith { _metrics };

private _recordRejection = {
    params ["_reason"];
    private _count = if (_reason in _diagnostics) then { _diagnostics get _reason } else { 0 };
    _diagnostics set [_reason, _count + 1];
};
private _state = _director get "_state";
[_state] call FLO_fnc_campaignValidateProbeOwnership;
private _fronts = _state get "frontlineProbes";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _minimumMass = (_director get "_config") get "probeAssaultMinimumGroups";
if (_currentActiveCount >= _minimumMass) exitWith {
    _metrics set ["assaultMassReady", true];
    _metrics
};

private _candidateRows = [];
{
    private _donorProbeId = _x;
    private _donor = _y;
    if (_donorProbeId == (_recipient get "probeId")) then { continue };
    if ((_donor get "sideKey") != (_recipient get "sideKey")) then { continue };
    if ((_donor get "formalOperationId") != "") then { ["CONCENTRATION_FORMAL_OWNER"] call _recordRejection; continue };
    if !((_donor get "stage") in ["PROBE", "DEVELOP_CONTACT", "STALLED", "SUPPORT", "SHIFT_AXIS"]) then {
        ["CONCENTRATION_DONOR_MATURITY"] call _recordRejection;
        continue;
    };
    private _donorGroupIds = +(_donor get "committedGroupIds");
    if (_donorGroupIds isEqualTo []) then { ["CONCENTRATION_EMPTY_DONOR"] call _recordRejection; continue };
    private _allAssignable = {
        if !(_x in _groups) exitWith { false };
        private _groupData = _groups get _x;
        (_groupData get "unitCount") > 0
        && {(_groupData get "commanderOrder") == "ATTACK"}
        && {(_groupData get "campaignOperationId") == _donorProbeId}
        && {(_groupData get "attackObjective") == (_donor get "objectiveId")}
        && {[
            _groupData,
            _cmdr get "_ownSide",
            ["infantry", "motorized", "mechanized", "armor"],
            [],
            _donorProbeId,
            _diagnostics
        ] call FLO_fnc_gtnGroupIsStrategicallyAssignable}
    } count _donorGroupIds == count _donorGroupIds;
    if (!_allAssignable) then { ["CONCENTRATION_GROUP_ASSIGNABILITY"] call _recordRejection; continue };
    _candidateRows pushBack [
        _donor get "progressSamples",
        _donor get "contactSamples",
        count _donorGroupIds,
        _donor get "createdAtDateNum",
        _donorProbeId
    ];
} forEach _fronts;

if (_candidateRows isEqualTo []) exitWith { _metrics };
_candidateRows sort true;
private _donorProbeId = (_candidateRows select 0) select 4;
private _donor = _fronts get _donorProbeId;
private _donorGroupIds = +(_donor get "committedGroupIds");
if ((_cmdr get "_strategicOrderBudgetRemaining") < count _donorGroupIds) exitWith {
    ["CONCENTRATION_ORDER_BUDGET"] call _recordRejection;
    _metrics
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
private _groupSnapshots = createHashMap;
{
    private _groupData = _groups get _x;
    private _snapshot = createHashMapFromArray [
        ["position", +(_groupData get "position")],
        ["transportAttachment", [_groupData] call FLO_fnc_virtualizationGetTransportAttachment]
    ];
    {
        _snapshot set [_x, [_groupData get _x] call FLO_fnc_virtualizationCloneValue];
    } forEach (_groupPatchMutableFields + _routeMutableFields);
    _groupSnapshots set [_x, _snapshot];
} forEach _donorGroupIds;
private _donorSnapshot = [_donor] call FLO_fnc_virtualizationCloneValue;
private _recipientSnapshot = [_recipient] call FLO_fnc_virtualizationCloneValue;
private _budgetRemaining = _cmdr get "_strategicOrderBudgetRemaining";
private _taskedGroups = +(_cmdr get "_gtnTaskedGroups");
private _assignmentCache = [_cmdr get "_objectiveAssignmentCache"] call FLO_fnc_virtualizationCloneValue;
private _eligibilityCacheDirty = _cmdr get "_availabilityCacheDirty";
private _transferSucceeded = true;
private _transferException = "";
try {
    [_director, _cmdr, _donor, "MASS_CONCENTRATED", false] call FLO_fnc_campaignReleaseProbeFront;
    {
        if !([_director, _cmdr, _recipient, _x] call FLO_fnc_campaignCommitProbeGroup) exitWith {
            _transferSucceeded = false;
        };
    } forEach _donorGroupIds;
} catch {
    _transferSucceeded = false;
    _transferException = _exception;
};

if (!_transferSucceeded) exitWith {
    {
        private _groupId = _x;
        private _snapshot = _groupSnapshots get _groupId;
        private _groupData = _groups get _groupId;
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
    } forEach _donorGroupIds;
    {
        _donor set [_x, [_y] call FLO_fnc_virtualizationCloneValue];
    } forEach _donorSnapshot;
    {
        _recipient set [_x, [_y] call FLO_fnc_virtualizationCloneValue];
    } forEach _recipientSnapshot;
    _cmdr set ["_strategicOrderBudgetRemaining", _budgetRemaining];
    _cmdr set ["_gtnTaskedGroups", _taskedGroups];
    _cmdr set ["_objectiveAssignmentCache", _assignmentCache];
    _cmdr set ["_availabilityCacheDirty", _eligibilityCacheDirty];
    [_state] call FLO_fnc_campaignValidateProbeOwnership;
    ["CAMPAIGN", 2, format [
        "Probe mass transfer rolled back recipient=%1 donor=%2 groups=%3",
        _recipient get "probeId",
        _donorProbeId,
        count _donorGroupIds
    ]] call FLO_fnc_log;
    if (_transferException != "") then {
        ["CAMPAIGN", 1, format ["Probe mass transfer failed: %1", _transferException]] call FLO_fnc_log;
        throw _transferException;
    };
    _metrics
};

[_state] call FLO_fnc_campaignValidateProbeOwnership;
private _mass = _currentActiveCount + count _donorGroupIds;
_metrics set ["movedGroupCount", count _donorGroupIds];
_metrics set ["donorProbeIds", [_donorProbeId]];
_metrics set ["assaultMassReady", _mass >= _minimumMass];
["CAMPAIGN", 3, format [
    "Probe mass concentrated recipient=%1 donor=%2 groups=%3 mass=%4/%5",
    _recipient get "probeId",
    _donorProbeId,
    count _donorGroupIds,
    _mass,
    _minimumMass
]] call FLO_fnc_log;
_metrics
