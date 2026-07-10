/*
 * Function: FLO_fnc_campaignCreateState
 * Description:
 *   Creates or restores the canonical multi-operation campaign state.
 */

params ["_config", ["_savedState", createHashMap, [createHashMap]]];

private _validOperationPhases = ["PREPARE", "ASSAULT", "SECURE", "CONSOLIDATE", "RECOVERY"];
private _validIntelLevels = ["NONE", "SECTOR", "TARGET"];
private _now = dateToNumber date;
private _emptyScaleMetrics = createHashMapFromArray [
    ["availableGroups", 0],
    ["activeAttackGroups", 0],
    ["offensiveGroups", 0],
    ["forceSlots", 0],
    ["logisticsSlots", 0],
    ["treasurySlots", 0],
    ["axisSlots", 0],
    ["pressureCap", 3],
    ["threatenedObjectives", 0],
    ["forceDeficit", 0]
];

if ((keys _savedState) isNotEqualTo []) exitWith {
    private _schemaVersion = _savedState get "schemaVersion";
    if !(_schemaVersion in [1, 2, 3, 4, 5]) then {
        throw format ["Unsupported campaign operation schema version: %1", _schemaVersion];
    };

    if (_schemaVersion == 5) exitWith {
        private _initiativeSideKey = toUpper (_savedState get "initiativeSideKey");
        private _defenderSideKey = toUpper (_savedState get "defenderSideKey");
        {
            if !(_x in ["WEST", "EAST"]) then {
                throw format ["Invalid saved campaign side key: %1", _x];
            };
        } forEach [_initiativeSideKey, _defenderSideKey];
        if (_initiativeSideKey == _defenderSideKey) then {
            throw format ["Saved campaign uses one side as attacker and defender: %1", _initiativeSideKey];
        };

        private _savedOperations = _savedState get "operations";
        private _operations = createHashMap;
        {
            private _operationId = _x;
            private _savedOperation = _y;
            if ((_savedOperation get "operationId") != _operationId) then {
                throw format ["Saved campaign operation key/id mismatch: %1", _operationId];
            };

            private _phase = toUpper (_savedOperation get "phase");
            private _intelLevel = toUpper (_savedOperation get "defenderIntelLevel");
            private _priorityRole = toUpper (_savedOperation get "priorityRole");
            if !(_phase in _validOperationPhases) then {
                throw format ["Invalid saved operation phase %1 for %2", _phase, _operationId];
            };
            if !(_intelLevel in _validIntelLevels) then {
                throw format ["Invalid saved operation intelligence %1 for %2", _intelLevel, _operationId];
            };
            if !(_priorityRole in ["MAIN_EFFORT", "SUPPORTING_EFFORT"]) then {
                throw format ["Invalid saved operation role %1 for %2", _priorityRole, _operationId];
            };

            private _attackerSideKey = toUpper (_savedOperation get "attackerSideKey");
            private _operationDefenderSideKey = toUpper (_savedOperation get "defenderSideKey");
            if (_attackerSideKey != _initiativeSideKey || {_operationDefenderSideKey != _defenderSideKey}) then {
                throw format ["Saved operation %1 does not match campaign initiative sides", _operationId];
            };

            private _resourceBudget = _savedOperation get "resourceBudget";
            private _resourceSpent = _savedOperation get "resourceSpent";
            private _resourceReleased = _savedOperation get "resourceReleased";
            if (
                _resourceBudget < 0
                || {_resourceSpent < 0}
                || {_resourceReleased < 0}
                || {_resourceSpent + _resourceReleased > _resourceBudget + 0.001}
            ) then {
                throw format ["Invalid saved operation resource state for %1", _operationId];
            };

            _operations set [_operationId, createHashMapFromArray [
                ["operationId", _operationId],
                ["priorityRole", _priorityRole],
                ["attackerSideKey", _attackerSideKey],
                ["defenderSideKey", _operationDefenderSideKey],
                ["objectiveId", _savedOperation get "objectiveId"],
                ["sourceObjectiveIds", +(_savedOperation get "sourceObjectiveIds")],
                ["supportObjectiveIds", +(_savedOperation get "supportObjectiveIds")],
                ["supplySourceObjectiveId", _savedOperation get "supplySourceObjectiveId"],
                ["phase", _phase],
                ["phaseStartedAtDateNum", _savedOperation get "phaseStartedAtDateNum"],
                ["phaseEndsAtDateNum", _savedOperation get "phaseEndsAtDateNum"],
                ["result", _savedOperation get "result"],
                ["transitionReason", _savedOperation get "transitionReason"],
                ["defenderIntelLevel", _intelLevel],
                ["defenderIntelReason", _savedOperation get "defenderIntelReason"],
                ["intelContactAfter", diag_tickTime],
                ["resourceReservationId", _savedOperation get "resourceReservationId"],
                ["resourceBudget", _resourceBudget],
                ["resourceSpent", _resourceSpent],
                ["resourceReleased", _resourceReleased],
                ["drawdownPending", _savedOperation get "drawdownPending"]
            ]];
        } forEach _savedOperations;

        private _savedOrder = +(_savedState get "operationOrder");
        private _savedPrimaryOperationId = _savedState get "primaryOperationId";
        if (_savedOrder isEqualTo []) then {
            if (_savedPrimaryOperationId != "") then {
                throw format ["Empty saved campaign registry retained primary %1", _savedPrimaryOperationId];
            };
        } else {
            if (_savedPrimaryOperationId != (_savedOrder select 0)) then {
                throw format ["Saved primary operation %1 does not match order %2", _savedPrimaryOperationId, _savedOrder];
            };
        };

        private _mainEffortCount = 0;
        private _targetIds = [];
        private _supplySourceIds = [];
        {
            if !(_x in _operations) then {
                throw format ["Saved campaign order references missing operation %1", _x];
            };
            private _operation = _operations get _x;
            if ((_operation get "priorityRole") == "MAIN_EFFORT") then {
                _mainEffortCount = _mainEffortCount + 1;
            };
            private _objectiveId = _operation get "objectiveId";
            private _supplySourceObjectiveId = _operation get "supplySourceObjectiveId";
            if (_objectiveId == "" || {_objectiveId in _targetIds}) then {
                throw format ["Saved campaign operation has invalid or duplicate target %1", _objectiveId];
            };
            if (_supplySourceObjectiveId == "" || {_supplySourceObjectiveId in _supplySourceIds}) then {
                throw format ["Saved campaign operation has invalid or duplicate supply axis %1", _supplySourceObjectiveId];
            };
            _targetIds pushBack _objectiveId;
            _supplySourceIds pushBack _supplySourceObjectiveId;
        } forEach _savedOrder;
        if (_mainEffortCount != parseNumber (_savedOrder isNotEqualTo [])) then {
            throw format ["Saved campaign registry has %1 main efforts", _mainEffortCount];
        };
        if (_savedOrder isNotEqualTo [] && {((_operations get (_savedOrder select 0)) get "priorityRole") != "MAIN_EFFORT"}) then {
            throw format ["Saved campaign order does not begin with its main effort: %1", _savedOrder];
        };

        private _state = createHashMapFromArray [
            ["schemaVersion", 5],
            ["sequence", _savedState get "sequence"],
            ["revision", _savedState get "revision"],
            ["initiativeSideKey", _initiativeSideKey],
            ["defenderSideKey", _defenderSideKey],
            ["operations", _operations],
            ["operationOrder", _savedOrder],
            ["primaryOperationId", _savedPrimaryOperationId],
            ["desiredOperationCount", _savedState get "desiredOperationCount"],
            ["lastScaleEvaluationAtDateNum", _savedState get "lastScaleEvaluationAtDateNum"],
            ["scaleUpCandidateSinceDateNum", _savedState get "scaleUpCandidateSinceDateNum"],
            ["scaleDownCandidateSinceDateNum", _savedState get "scaleDownCandidateSinceDateNum"],
            ["scaleReason", _savedState get "scaleReason"],
            ["scaleMetrics", +(_savedState get "scaleMetrics")],
            ["lastCompletedOperationId", _savedState get "lastCompletedOperationId"],
            ["lastCompletedResult", _savedState get "lastCompletedResult"],
            ["opportunities", +(_savedState get "opportunities")],
            ["phase", toUpper (_savedState get "phase")],
            ["phaseStartedAtDateNum", _savedState get "phaseStartedAtDateNum"],
            ["phaseEndsAtDateNum", _savedState get "phaseEndsAtDateNum"],
            ["transitionReason", _savedState get "transitionReason"],
            ["operationId", ""],
            ["attackerSideKey", _initiativeSideKey],
            ["objectiveId", ""],
            ["sourceObjectiveIds", []],
            ["supportObjectiveIds", []],
            ["result", ""],
            ["defenderIntelLevel", "NONE"],
            ["defenderIntelReason", "NO_ACTIVE_OPERATION"],
            ["resourceReservationId", ""],
            ["resourceBudget", 0],
            ["resourceSpent", 0],
            ["resourceReleased", 0]
        ];

        if ((_state get "operationOrder") isEqualTo [] && {(_state get "phase") != "LULL"}) then {
            throw format ["Saved empty campaign registry has phase %1", _state get "phase"];
        };
        [_state] call FLO_fnc_campaignSyncPrimaryProjection
    };

    private _phase = toUpper (_savedState get "phase");
    if !(_phase in (["LULL"] + _validOperationPhases)) then {
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
    if (_operationId == "" && {_phase != "LULL"}) then {
        throw format ["Saved campaign phase %1 has no operation", _phase];
    };
    if (_operationId != "" && {_phase == "LULL"}) then {
        throw format ["Saved LULL campaign retained operation %1", _operationId];
    };

    private _defenderIntelLevel = "NONE";
    private _defenderIntelReason = "SAVE_MIGRATION";
    if (_schemaVersion >= 3) then {
        _defenderIntelLevel = toUpper (_savedState get "defenderIntelLevel");
        _defenderIntelReason = _savedState get "defenderIntelReason";
    } else {
        if (_operationId != "") then {
            _defenderIntelLevel = ["TARGET", "SECTOR"] select (_phase == "PREPARE");
        };
    };
    if !(_defenderIntelLevel in _validIntelLevels) then {
        throw format ["Invalid saved defender intelligence level: %1", _defenderIntelLevel];
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
        if (
            _resourceBudget < 0
            || {_resourceSpent < 0}
            || {_resourceReleased < 0}
            || {_resourceSpent + _resourceReleased > _resourceBudget + 0.001}
        ) then {
            throw format ["Invalid saved operation resource state for %1", _operationId];
        };
        if ((_resourceBudget - _resourceSpent - _resourceReleased) <= 0.001) then {
            _resourceReservationId = "";
        };
    };

    private _operations = createHashMap;
    private _operationOrder = [];
    if (_operationId != "") then {
        _operations set [_operationId, createHashMapFromArray [
            ["operationId", _operationId],
            ["priorityRole", "MAIN_EFFORT"],
            ["attackerSideKey", _attackerSideKey],
            ["defenderSideKey", _defenderSideKey],
            ["objectiveId", _savedState get "objectiveId"],
            ["sourceObjectiveIds", +(_savedState get "sourceObjectiveIds")],
            ["supportObjectiveIds", +(_savedState get "supportObjectiveIds")],
            ["supplySourceObjectiveId", ""],
            ["phase", _phase],
            ["phaseStartedAtDateNum", _phaseStartedAtDateNum],
            ["phaseEndsAtDateNum", _phaseEndsAtDateNum],
            ["result", _savedState get "result"],
            ["transitionReason", _savedState get "transitionReason"],
            ["defenderIntelLevel", _defenderIntelLevel],
            ["defenderIntelReason", _defenderIntelReason],
            ["intelContactAfter", diag_tickTime],
            ["resourceReservationId", _resourceReservationId],
            ["resourceBudget", _resourceBudget],
            ["resourceSpent", _resourceSpent],
            ["resourceReleased", _resourceReleased],
            ["drawdownPending", false]
        ]];
        _operationOrder pushBack _operationId;
    };

    private _state = createHashMapFromArray [
        ["schemaVersion", 5],
        ["sequence", _savedState get "sequence"],
        ["revision", _savedState get "revision"],
        ["initiativeSideKey", _initiativeSideKey],
        ["defenderSideKey", _defenderSideKey],
        ["operations", _operations],
        ["operationOrder", _operationOrder],
        ["primaryOperationId", _operationId],
        ["desiredOperationCount", count _operationOrder],
        ["lastScaleEvaluationAtDateNum", -1],
        ["scaleUpCandidateSinceDateNum", -1],
        ["scaleDownCandidateSinceDateNum", -1],
        ["scaleReason", "SAVE_MIGRATION"],
        ["scaleMetrics", _emptyScaleMetrics],
        ["lastCompletedOperationId", _savedState get "lastCompletedOperationId"],
        ["lastCompletedResult", _savedState get "lastCompletedResult"],
        ["opportunities", +(_savedState get "opportunities")],
        ["phase", _phase],
        ["phaseStartedAtDateNum", _phaseStartedAtDateNum],
        ["phaseEndsAtDateNum", _phaseEndsAtDateNum],
        ["transitionReason", _savedState get "transitionReason"],
        ["operationId", ""],
        ["attackerSideKey", _initiativeSideKey],
        ["objectiveId", ""],
        ["sourceObjectiveIds", []],
        ["supportObjectiveIds", []],
        ["result", ""],
        ["defenderIntelLevel", "NONE"],
        ["defenderIntelReason", "NO_ACTIVE_OPERATION"],
        ["resourceReservationId", ""],
        ["resourceBudget", 0],
        ["resourceSpent", 0],
        ["resourceReleased", 0]
    ];
    [_state] call FLO_fnc_campaignSyncPrimaryProjection
};

private _activeSide = FLO_ActivePlayerSide;
private _initiativeSideKey = "EAST";
if (_activeSide isEqualTo east) then { _initiativeSideKey = "WEST"; };
if (_activeSide isEqualTo west) then { _initiativeSideKey = "EAST"; };
private _defenderSideKey = ["WEST", "EAST"] select (_initiativeSideKey == "WEST");
private _lullDuration = (_config get "phaseDurations") get "LULL";

createHashMapFromArray [
    ["schemaVersion", 5],
    ["sequence", 0],
    ["revision", 1],
    ["initiativeSideKey", _initiativeSideKey],
    ["defenderSideKey", _defenderSideKey],
    ["operations", createHashMap],
    ["operationOrder", []],
    ["primaryOperationId", ""],
    ["desiredOperationCount", 0],
    ["lastScaleEvaluationAtDateNum", -1],
    ["scaleUpCandidateSinceDateNum", -1],
    ["scaleDownCandidateSinceDateNum", -1],
    ["scaleReason", "INITIAL_LULL"],
    ["scaleMetrics", _emptyScaleMetrics],
    ["lastCompletedOperationId", ""],
    ["lastCompletedResult", ""],
    ["opportunities", createHashMap],
    ["operationId", ""],
    ["phase", "LULL"],
    ["phaseStartedAtDateNum", _now],
    ["phaseEndsAtDateNum", [_now, _lullDuration] call FLO_fnc_dateNumberAddSeconds],
    ["attackerSideKey", _initiativeSideKey],
    ["objectiveId", ""],
    ["sourceObjectiveIds", []],
    ["supportObjectiveIds", []],
    ["result", ""],
    ["transitionReason", "INITIAL_LULL"],
    ["defenderIntelLevel", "NONE"],
    ["defenderIntelReason", "NO_ACTIVE_OPERATION"],
    ["resourceReservationId", ""],
    ["resourceBudget", 0],
    ["resourceSpent", 0],
    ["resourceReleased", 0]
]
