/* Transfers whole formations from lower-maturity probes into an assault-ready front. */
params [
    "_director",
    "_cmdr",
    ["_recipient", createHashMap, [createHashMap]],
    ["_currentActiveCount", 0, [0]],
    ["_diagnostics", createHashMap, [createHashMap]]
];

private _metrics = createHashMapFromArray [
    ["movedFormationCount", 0],
    ["movedGroupCount", 0],
    ["donorProbeIds", []],
    ["assaultMassReady", false]
];
if ((_recipient get "formalOperationId") != "") exitWith { _metrics };
if ((_recipient get "stage") != "REINFORCE_SUCCESS") exitWith { _metrics };

private _recordDiagnostic = {
    params ["_reason"];
    private _count = if (_reason in _diagnostics) then { _diagnostics get _reason } else { 0 };
    _diagnostics set [_reason, _count + 1];
};

private _state = _director get "_state";
private _fronts = _state get "frontlineProbes";
private _formationState = _state get "formationState";
private _formations = _formationState get "formations";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _config = _director get "_config";
private _sideKey = _recipient get "sideKey";
private _ownSide = _cmdr get "_ownSide";
private _minimumMass = _config get "probeAssaultMinimumGroups";
private _maximumReinforcements = _config get "probeMaximumReinforcementFormations";
private _reinforcementSlots = _maximumReinforcements - (_recipient get "reinforcementCount");
if (_currentActiveCount >= _minimumMass || {_reinforcementSlots <= 0}) exitWith {
    _metrics set ["assaultMassReady", _currentActiveCount >= _minimumMass];
    _metrics
};

private _eligibleDonorStages = ["PROBE", "DEVELOP_CONTACT", "STALLED", "SUPPORT", "SHIFT_AXIS"];
private _candidateRows = [];
{
    private _donorProbeId = _x;
    private _donor = _y;
    if (_donorProbeId == (_recipient get "probeId")) then { continue };
    if ((_donor get "sideKey") != _sideKey) then { continue };
    if ((_donor get "formalOperationId") != "") then { ["CONCENTRATION_FORMAL_OWNER"] call _recordDiagnostic; continue };
    if !((_donor get "stage") in _eligibleDonorStages) then { ["CONCENTRATION_DONOR_MATURITY"] call _recordDiagnostic; continue };

    private _donorFormationIds = _donor get "formationIds";
    if ((count _donorFormationIds) != 1) then { ["CONCENTRATION_DONOR_WIDTH"] call _recordDiagnostic; continue };
    private _formationId = _donorFormationIds select 0;
    if !(_formationId in _formations) then {
        private _message = format ["Probe concentration donor %1 references missing formation %2", _donorProbeId, _formationId];
        ["CAMPAIGN", 1, _message] call FLO_fnc_log;
        throw _message;
    };
    private _formation = _formations get _formationId;
    if (
        (_formation get "role") != "MAIN"
        || {(_formation get "roleOperationId") != _donorProbeId}
    ) then { ["CONCENTRATION_FORMATION_ROLE"] call _recordDiagnostic; continue };

    private _memberIds = (_formation get "memberIds") select {
        _x in _groups && {((_groups get _x) get "unitCount") > 0}
    };
    if ((count _memberIds) < 3 || {(count _memberIds) > 6}) then {
        ["CONCENTRATION_MEMBER_COUNT"] call _recordDiagnostic;
        continue;
    };
    private _donorGroupIds = _donor get "committedGroupIds";
    if (
        (count _donorGroupIds) != (count _memberIds)
        || {(count (_donorGroupIds arrayIntersect _memberIds)) != (count _memberIds)}
    ) then { ["CONCENTRATION_PARTIAL_FORMATION"] call _recordDiagnostic; continue };

    private _allOwnedAndAssignable = {
        private _groupData = _groups get _x;
        (_groupData get "commanderOrder") == "ATTACK"
        && {(_groupData get "campaignOperationId") == _donorProbeId}
        && {(_groupData get "attackObjective") == (_donor get "objectiveId")}
        && {
            [
                _groupData,
                _ownSide,
                ["infantry", "motorized", "mechanized", "armor"],
                [],
                _donorProbeId,
                _diagnostics
            ] call FLO_fnc_gtnGroupIsStrategicallyAssignable
        }
    } count _memberIds == count _memberIds;
    if (!_allOwnedAndAssignable) then { ["CONCENTRATION_GROUP_ASSIGNABILITY"] call _recordDiagnostic; continue };

    _candidateRows pushBack [
        _donor get "progressSamples",
        _donor get "contactSamples",
        _donor get "createdAtDateNum",
        _donorProbeId,
        _formationId,
        _memberIds
    ];
} forEach _fronts;

_candidateRows sort true;
private _mass = _currentActiveCount;
private _donorProbeIds = [];
private _movedFormationCount = 0;
private _movedGroupCount = 0;
private _recoverySeconds = _config get "probeConcentrationDonorRecoverySeconds";

{
    if (_mass >= _minimumMass || {_reinforcementSlots <= 0}) exitWith {};
    private _donorProbeId = _x select 3;
    private _formationId = _x select 4;
    private _memberIds = _x select 5;
    if ((_cmdr get "_strategicOrderBudgetRemaining") < count _memberIds) then {
        ["CONCENTRATION_ORDER_BUDGET"] call _recordDiagnostic;
        continue;
    };

    [_state] call FLO_fnc_campaignValidateProbeOwnership;
    private _donor = _fronts get _donorProbeId;
    private _formation = _formations get _formationId;
    private _donorSnapshot = createHashMapFromArray [
        ["formationIds", +(_donor get "formationIds")],
        ["committedGroupIds", +(_donor get "committedGroupIds")],
        ["committedUnitBaseline", _donor get "committedUnitBaseline"]
    ];
    private _formationSnapshot = createHashMapFromArray [
        ["role", _formation get "role"],
        ["roleMemberIds", +(_formation get "roleMemberIds")],
        ["roleObjectiveId", _formation get "roleObjectiveId"],
        ["roleOperationId", _formation get "roleOperationId"],
        ["roleStartedAtDateNum", _formation get "roleStartedAtDateNum"],
        ["roleEndsAtDateNum", _formation get "roleEndsAtDateNum"],
        ["returnObjectiveId", _formation get "returnObjectiveId"]
    ];

    _donor set ["formationIds", []];
    _donor set ["committedGroupIds", []];
    _donor set ["committedUnitBaseline", 0];
    _formation set ["role", "RESERVE"];
    _formation set ["roleMemberIds", []];
    _formation set ["roleObjectiveId", ""];
    _formation set ["roleOperationId", ""];
    _formation set ["roleStartedAtDateNum", -1];
    _formation set ["roleEndsAtDateNum", -1];
    _formation set ["returnObjectiveId", ""];

    private _selection = createHashMapFromArray [
        ["formationId", _formationId],
        ["memberIds", _memberIds]
    ];
    private _commitSucceeded = false;
    private _commitException = "";
    try {
        _commitSucceeded = [_director, _cmdr, _recipient, _selection, true]
            call FLO_fnc_campaignCommitProbeFormation;
    } catch {
        _commitException = _exception;
    };

    if (!_commitSucceeded) then {
        {
            _donor set [_x, _y];
        } forEach _donorSnapshot;
        {
            _formation set [_x, _y];
        } forEach _formationSnapshot;
        if (_commitException != "") then { throw _commitException };
        ["CONCENTRATION_COMMIT_FAILED"] call _recordDiagnostic;
        continue;
    };

    [_director, _cmdr, _donor, "MASS_CONCENTRATED", _recoverySeconds]
        call FLO_fnc_campaignReleaseProbeFront;
    _donorProbeIds pushBack _donorProbeId;
    _movedFormationCount = _movedFormationCount + 1;
    _movedGroupCount = _movedGroupCount + count _memberIds;
    _mass = _mass + count _memberIds;
    _reinforcementSlots = _reinforcementSlots - 1;
} forEach _candidateRows;

_metrics set ["movedFormationCount", _movedFormationCount];
_metrics set ["movedGroupCount", _movedGroupCount];
_metrics set ["donorProbeIds", _donorProbeIds];
_metrics set ["assaultMassReady", _mass >= _minimumMass];

if (_movedFormationCount > 0) then {
    ["CAMPAIGN", 3, format [
        "Probe mass concentrated recipient=%1 donors=%2 formations=%3 groups=%4 mass=%5/%6",
        _recipient get "probeId",
        _donorProbeIds,
        _movedFormationCount,
        _movedGroupCount,
        _mass,
        _minimumMass
    ]] call FLO_fnc_log;
};

_metrics
