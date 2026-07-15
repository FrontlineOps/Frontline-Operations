/* Builds one side-filtered operation descriptor for Command Net. */
params [
    "_operation",
    ["_viewerSideKey", "", [""]],
    "_treasury",
    ["_isPrimary", false, [false]]
];

private _operationId = _operation get "operationId";
private _phase = _operation get "phase";
private _viewerIsAttacker = (_operation get "attackerSideKey") == _viewerSideKey;
private _viewerIntelLevel = "TARGET";
private _targetVisible = true;
private _objectiveId = _operation get "objectiveId";
private _visibleObjectiveId = _objectiveId;
private _visibleTargetName = [_objectiveId] call FLO_fnc_campaignObjectiveName;
private _visibleTargetPosition = (FLO_Objectives get _objectiveId) get "position";

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
private _role = _operation get "priorityRole";
if (!_viewerIsAttacker) then {
    _role = ["DEFEND_SUPPORTING_EFFORT", "DEFEND_MAIN_EFFORT"] select _isPrimary;
};
private _displayPhase = _phase;
private _supportPosture = switch (_phase) do {
    case "ASSAULT": { "COMMITTED" };
    case "SECURE": { "HOLDING" };
    case "CONSOLIDATE": { "CONSOLIDATING" };
    default { "RECOVERING" };
};

private _now = call FLO_fnc_operationalDateNumber;
private _remainingSeconds = round (([_now, _operation get "phaseEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) max 0);
private _resourceRemaining = 0;
private _reservationId = _operation get "resourceReservationId";
if (_viewerIsAttacker && {_reservationId != ""}) then {
    _resourceRemaining = _treasury call ["getReservationRemaining", [_reservationId]];
};
private _nextWaveRemaining = 0;
private _pauseRemaining = 0;
private _openingDelayRemaining = 0;
private _shapingObjectiveName = "";
private _exploitationObjectiveName = "";
if (_viewerIsAttacker) then {
    private _nextWaveAt = _operation get "assaultNextWaveAtDateNum";
    if (_nextWaveAt >= 0) then {
        _nextWaveRemaining = round (([_now, _nextWaveAt] call FLO_fnc_dateNumberDeltaSeconds) max 0);
    };
    private _pauseUntil = _operation get "assaultPauseUntilDateNum";
    if (_pauseUntil >= 0) then {
        _pauseRemaining = round (([_now, _pauseUntil] call FLO_fnc_dateNumberDeltaSeconds) max 0);
    };
    private _openingEligibleAt = _operation get "assaultOpeningEligibleAtDateNum";
    if (_openingEligibleAt >= 0) then {
        _openingDelayRemaining = round (([_now, _openingEligibleAt] call FLO_fnc_dateNumberDeltaSeconds) max 0);
    };
    private _shapingObjectiveId = _operation get "shapingObjectiveId";
    if (_shapingObjectiveId != "" && {_shapingObjectiveId in FLO_Objectives}) then {
        _shapingObjectiveName = [_shapingObjectiveId] call FLO_fnc_campaignObjectiveName;
    };
    private _exploitationObjectiveId = _operation get "exploitationObjectiveId";
    if (_exploitationObjectiveId != "" && {_exploitationObjectiveId in FLO_Objectives}) then {
        _exploitationObjectiveName = [_exploitationObjectiveId] call FLO_fnc_campaignObjectiveName;
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
    ["assaultOpeningDelaySeconds", _openingDelayRemaining],
    ["assaultStatus", ["CLASSIFIED", _operation get "assaultStatus"] select _viewerIsAttacker],
    ["doctrine", ["CLASSIFIED", _operation get "doctrine"] select _viewerIsAttacker],
    ["shapingStatus", ["CLASSIFIED", _operation get "shapingStatus"] select _viewerIsAttacker],
    ["shapingFormationId", ["", _operation get "shapingFormationId"] select _viewerIsAttacker],
    ["shapingObjectiveId", ["", _operation get "shapingObjectiveId"] select _viewerIsAttacker],
    ["shapingObjectiveName", _shapingObjectiveName],
    ["exploitationStatus", ["CLASSIFIED", _operation get "exploitationStatus"] select _viewerIsAttacker],
    ["exploitationFormationId", ["", _operation get "exploitationFormationId"] select _viewerIsAttacker],
    ["exploitationObjectiveId", ["", _operation get "exploitationObjectiveId"] select _viewerIsAttacker],
    ["exploitationObjectiveName", _exploitationObjectiveName],
    ["drawdownPending", _operation get "drawdownPending"]
]
