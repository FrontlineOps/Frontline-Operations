/* Builds one side-filtered operation descriptor for Command Net. */
params [
    "_director",
    "_operation",
    ["_viewerSideKey", "", [""]],
    "_treasury",
    ["_isPrimary", false, [false]]
];

private _operationId = _operation get "operationId";
private _phase = _operation get "phase";
private _viewerIsAttacker = (_operation get "attackerSideKey") == _viewerSideKey;
private _viewerIntelLevel = [
    _operation get "defenderIntelLevel",
    "TARGET"
] select _viewerIsAttacker;
private _targetVisible = _viewerIntelLevel == "TARGET";
private _objectiveId = _operation get "objectiveId";
private _visibleObjectiveId = ["", _objectiveId] select _targetVisible;
private _visibleTargetName = "Undisclosed";
private _visibleTargetPosition = [];
if (_visibleObjectiveId != "") then {
    _visibleTargetName = [_visibleObjectiveId] call FLO_fnc_campaignObjectiveName;
    _visibleTargetPosition = (FLO_Objectives get _visibleObjectiveId) get "position";
};

private _threatSector = createHashMapFromArray [
    ["operationId", _operationId],
    ["visible", false],
    ["position", []],
    ["longAxis", 0],
    ["shortAxis", 0],
    ["direction", 0],
    ["grid", ""],
    ["label", ""]
];
if (!_viewerIsAttacker && {_phase == "PREPARE"} && {_viewerIntelLevel == "SECTOR"}) then {
    _threatSector = [_director, _operationId] call FLO_fnc_campaignBuildThreatSector;
};

private _role = _operation get "priorityRole";
if (!_viewerIsAttacker) then {
    _role = if (_targetVisible) then {
        ["DEFEND_SUPPORTING_EFFORT", "DEFEND_MAIN_EFFORT"] select _isPrimary
    } else {
        "SCREEN"
    };
};
private _displayPhase = [_phase, "SCREEN"] select (!_viewerIsAttacker && {!_targetVisible && {_phase == "PREPARE"}});
private _supportPosture = switch (_phase) do {
    case "PREPARE": { ["SCREENING", "STAGING"] select _viewerIsAttacker };
    case "ASSAULT": { "COMMITTED" };
    case "SECURE": { "HOLDING" };
    case "CONSOLIDATE": { "CONSOLIDATING" };
    default { "RECOVERING" };
};

private _now = dateToNumber date;
private _remainingSeconds = round ([_now, _operation get "phaseEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds);
_remainingSeconds = _remainingSeconds max 0;
private _resourceRemaining = 0;
private _reservationId = _operation get "resourceReservationId";
if (_viewerIsAttacker && {_reservationId != ""}) then {
    _resourceRemaining = _treasury call ["getReservationRemaining", [_reservationId]];
};
private _nextWaveRemaining = 0;
private _pauseRemaining = 0;
if (_viewerIsAttacker) then {
    private _nextWaveAt = _operation get "assaultNextWaveAtDateNum";
    if (_nextWaveAt >= 0) then {
        _nextWaveRemaining = round (([_now, _nextWaveAt] call FLO_fnc_dateNumberDeltaSeconds) max 0);
    };
    private _pauseUntil = _operation get "assaultPauseUntilDateNum";
    if (_pauseUntil >= 0) then {
        _pauseRemaining = round (([_now, _pauseUntil] call FLO_fnc_dateNumberDeltaSeconds) max 0);
    };
};

createHashMapFromArray [
    ["id", _operationId],
    ["isPrimary", _isPrimary],
    ["role", _role],
    ["phase", _displayPhase],
    ["actualPhase", _phase],
    ["targetVisible", _targetVisible],
    ["targetId", _visibleObjectiveId],
    ["targetName", _visibleTargetName],
    ["targetPosition", _visibleTargetPosition],
    ["intelLevel", _viewerIntelLevel],
    ["intelReason", [(_operation get "defenderIntelReason"), "COMMANDER_INTENT"] select _viewerIsAttacker],
    ["threatSector", _threatSector],
    ["sourceObjectiveIds", [[], +(_operation get "sourceObjectiveIds")] select _viewerIsAttacker],
    ["supportObjectiveIds", [[], +(_operation get "supportObjectiveIds")] select _viewerIsAttacker],
    ["supplySourceObjectiveId", ["", _operation get "supplySourceObjectiveId"] select _viewerIsAttacker],
    ["supportPosture", _supportPosture],
    ["remainingSeconds", _remainingSeconds],
    ["result", _operation get "result"],
    ["transitionReason", _operation get "transitionReason"],
    ["resourceBudget", [0, _operation get "resourceBudget"] select _viewerIsAttacker],
    ["resourceSpent", [0, _operation get "resourceSpent"] select _viewerIsAttacker],
    ["resourceRemaining", _resourceRemaining],
    ["resourceReleased", [0, _operation get "resourceReleased"] select _viewerIsAttacker],
    ["assaultPackageTarget", [0, _operation get "assaultPackageTarget"] select _viewerIsAttacker],
    ["assaultActiveTarget", [0, _operation get "assaultActiveTarget"] select _viewerIsAttacker],
    ["assaultWaveSize", [0, _operation get "assaultWaveSize"] select _viewerIsAttacker],
    ["assaultCommittedTotal", [0, _operation get "assaultCommittedTotal"] select _viewerIsAttacker],
    ["assaultLosses", [0, _operation get "assaultLosses"] select _viewerIsAttacker],
    ["assaultWaveSequence", [0, _operation get "assaultWaveSequence"] select _viewerIsAttacker],
    ["assaultNextWaveSeconds", _nextWaveRemaining],
    ["assaultPauseSeconds", _pauseRemaining],
    ["assaultStatus", ["CLASSIFIED", _operation get "assaultStatus"] select _viewerIsAttacker],
    ["drawdownPending", _operation get "drawdownPending"]
]
