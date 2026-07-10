/*
 * Function: FLO_fnc_campaignCreateState
 * Description:
 *   Creates or restores the canonical theater operation state.
 */

params ["_config", ["_savedState", createHashMap, [createHashMap]]];

private _validPhases = ["LULL", "PREPARE", "ASSAULT", "SECURE", "CONSOLIDATE", "RECOVERY"];
private _validIntelLevels = ["NONE", "SECTOR", "TARGET"];
private _hasSavedState = (keys _savedState) isNotEqualTo [];
private _now = dateToNumber date;

if (_hasSavedState) exitWith {
    private _schemaVersion = _savedState get "schemaVersion";
    if !(_schemaVersion in [1, 2, 3, 4]) then {
        throw format ["Unsupported campaign operation schema version: %1", _savedState get "schemaVersion"];
    };

    private _phase = toUpper (_savedState get "phase");
    if !(_phase in _validPhases) then {
        throw format ["Invalid saved campaign phase: %1", _phase];
    };

    private _initiativeSideKey = toUpper (_savedState get "initiativeSideKey");
    private _attackerSideKey = toUpper (_savedState get "attackerSideKey");
    private _defenderSideKey = toUpper (_savedState get "defenderSideKey");
    {
        if !(_x in ["WEST", "EAST"]) then {
            throw format ["Invalid saved campaign side key: %1", _x];
        };
    } forEach [_initiativeSideKey, _attackerSideKey, _defenderSideKey];

    private _phaseStartedAtDateNum = _savedState get "phaseStartedAtDateNum";
    private _phaseEndsAtDateNum = _savedState get "phaseEndsAtDateNum";
    if (_schemaVersion == 1) then {
        private _phaseDuration = (_config get "phaseDurations") get _phase;
        _phaseStartedAtDateNum = _now;
        _phaseEndsAtDateNum = [_now, _phaseDuration] call FLO_fnc_dateNumberAddSeconds;
    };

    private _operationId = _savedState get "operationId";
    private _defenderIntelLevel = "NONE";
    private _defenderIntelReason = "SAVE_MIGRATION";
    if (_schemaVersion >= 3) then {
        _defenderIntelLevel = _savedState get "defenderIntelLevel";
        _defenderIntelReason = _savedState get "defenderIntelReason";
    } else {
        if (_operationId != "") then {
            _defenderIntelLevel = ["TARGET", "SECTOR"] select (_phase == "PREPARE");
        };
    };
    if !(_defenderIntelLevel in _validIntelLevels) then {
        throw format ["Invalid saved defender intelligence level: %1", _defenderIntelLevel];
    };
    if (_operationId == "" && {_defenderIntelLevel != "NONE"}) then {
        throw format ["Saved campaign without an operation has defender intelligence '%1'", _defenderIntelLevel];
    };
    if (_operationId != "" && {_phase == "PREPARE"} && {!(_defenderIntelLevel in ["SECTOR", "TARGET"])}) then {
        throw format ["Saved PREPARE operation has defender intelligence '%1'", _defenderIntelLevel];
    };
    if (_operationId != "" && {_phase != "PREPARE"} && {_defenderIntelLevel != "TARGET"}) then {
        throw format ["Saved %1 operation has defender intelligence '%2'", _phase, _defenderIntelLevel];
    };

    private _resourceReservationId = "";
    private _resourceBudget = 0;
    private _resourceSpent = 0;
    private _resourceReleased = 0;
    if (_schemaVersion == 4) then {
        _resourceReservationId = _savedState get "resourceReservationId";
        _resourceBudget = _savedState get "resourceBudget";
        _resourceSpent = _savedState get "resourceSpent";
        _resourceReleased = _savedState get "resourceReleased";
        if !(
            _resourceReservationId isEqualType ""
            && {_resourceBudget isEqualType 0}
            && {_resourceSpent isEqualType 0}
            && {_resourceReleased isEqualType 0}
            && {_resourceBudget >= 0}
            && {_resourceSpent >= 0}
            && {_resourceReleased >= 0}
            && {_resourceSpent + _resourceReleased <= _resourceBudget}
        ) then {
            throw format ["Invalid saved operation resource state for %1", _operationId];
        };
    };

    createHashMapFromArray [
        ["schemaVersion", 4],
        ["sequence", _savedState get "sequence"],
        ["revision", _savedState get "revision"],
        ["operationId", _operationId],
        ["phase", _phase],
        ["phaseStartedAtDateNum", _phaseStartedAtDateNum],
        ["phaseEndsAtDateNum", _phaseEndsAtDateNum],
        ["initiativeSideKey", _initiativeSideKey],
        ["attackerSideKey", _attackerSideKey],
        ["defenderSideKey", _defenderSideKey],
        ["objectiveId", _savedState get "objectiveId"],
        ["sourceObjectiveIds", +(_savedState get "sourceObjectiveIds")],
        ["supportObjectiveIds", +(_savedState get "supportObjectiveIds")],
        ["result", _savedState get "result"],
        ["transitionReason", _savedState get "transitionReason"],
        ["lastCompletedOperationId", _savedState get "lastCompletedOperationId"],
        ["lastCompletedResult", _savedState get "lastCompletedResult"],
        ["defenderIntelLevel", _defenderIntelLevel],
        ["defenderIntelReason", _defenderIntelReason],
        ["resourceReservationId", _resourceReservationId],
        ["resourceBudget", _resourceBudget],
        ["resourceSpent", _resourceSpent],
        ["resourceReleased", _resourceReleased],
        ["opportunities", _savedState get "opportunities"]
    ]
};

private _activeSide = FLO_ActivePlayerSide;
private _initiativeSideKey = "EAST";
if (_activeSide isEqualTo east) then { _initiativeSideKey = "WEST"; };
if (_activeSide isEqualTo west) then { _initiativeSideKey = "EAST"; };
private _defenderSideKey = ["WEST", "EAST"] select (_initiativeSideKey isEqualTo "WEST");
private _lullDuration = (_config get "phaseDurations") get "LULL";

createHashMapFromArray [
    ["schemaVersion", 4],
    ["sequence", 0],
    ["revision", 1],
    ["operationId", ""],
    ["phase", "LULL"],
    ["phaseStartedAtDateNum", _now],
    ["phaseEndsAtDateNum", [_now, _lullDuration] call FLO_fnc_dateNumberAddSeconds],
    ["initiativeSideKey", _initiativeSideKey],
    ["attackerSideKey", _initiativeSideKey],
    ["defenderSideKey", _defenderSideKey],
    ["objectiveId", ""],
    ["sourceObjectiveIds", []],
    ["supportObjectiveIds", []],
    ["result", ""],
    ["transitionReason", "INITIAL_LULL"],
    ["lastCompletedOperationId", ""],
    ["lastCompletedResult", ""],
    ["defenderIntelLevel", "NONE"],
    ["defenderIntelReason", "NO_ACTIVE_OPERATION"],
    ["resourceReservationId", ""],
    ["resourceBudget", 0],
    ["resourceSpent", 0],
    ["resourceReleased", 0],
    ["opportunities", createHashMap]
]
