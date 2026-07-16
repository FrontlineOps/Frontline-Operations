/* Creates or restores the current canonical multi-operation campaign state. */
params ["_savedState", "_restoreSavedState"];

if !(_savedState isEqualType createHashMap) then {
    throw format ["Campaign state input has invalid type %1", typeName _savedState];
};
if !(_restoreSavedState isEqualType false) then {
    throw format ["Campaign restore intent has invalid type %1", typeName _restoreSavedState];
};

private _now = call FLO_fnc_operationalDateNumber;
private _emptyScaleMetrics = createHashMapFromArray [
    ["availableGroups", 0],
    ["activeAttackGroups", 0],
    ["offensiveGroups", 0],
    ["forceSlots", 0],
    ["logisticsSlots", 0],
    ["treasurySlots", 0],
    ["axisSlots", 0],
    ["pressureCap", 0],
    ["threatenedObjectives", 0],
    ["forceDeficit", 0],
    ["qualifyingSupplySourceCount", 0],
    ["rankableTargetCount", 0],
    ["plannedCommitment", 0]
];

if (_restoreSavedState) exitWith {
    private _requiredStateFields = [
        "sequence", "revision", "initiativeSideKey", "defenderSideKey", "operations",
        "operationOrder", "primaryOperationId", "desiredOperationCount",
        "lastScaleEvaluationAtDateNum", "scaleReason", "scaleMetrics",
        "lastCompletedOperationId", "lastCompletedResult", "opportunities",
        "phase", "phaseStartedAtDateNum", "phaseEndsAtDateNum", "transitionReason"
    ];
    private _missingStateFields = _requiredStateFields select { !(_x in _savedState) };
    private _unexpectedStateFields = (keys _savedState) select { !(_x in _requiredStateFields) };
    if (_missingStateFields isNotEqualTo [] || {_unexpectedStateFields isNotEqualTo []}) then {
        ["CAMPAIGN", 1, format [
            "Current campaign save is missing fields %1 and was not loaded; unexpected fields %2",
            _missingStateFields,
            _unexpectedStateFields
        ]] call FLO_fnc_log;
        throw format [
            "Current campaign save shape is invalid; missing=%1 unexpected=%2",
            _missingStateFields,
            _unexpectedStateFields
        ];
    };

    private _initiativeSideKey = toUpper (_savedState get "initiativeSideKey");
    private _defenderSideKey = toUpper (_savedState get "defenderSideKey");
    if !(_initiativeSideKey in ["WEST", "EAST"] && {_defenderSideKey in ["WEST", "EAST"]}) then {
        throw format ["Saved campaign has invalid sides %1/%2", _initiativeSideKey, _defenderSideKey];
    };
    if (_initiativeSideKey == _defenderSideKey) then {
        throw format ["Saved campaign uses one side as attacker and defender: %1", _initiativeSideKey];
    };

    private _savedScaleMetrics = _savedState get "scaleMetrics";
    if !(_savedScaleMetrics isEqualType createHashMap) then {
        throw format ["Saved campaign scale metrics have invalid type %1", typeName _savedScaleMetrics];
    };
    private _requiredScaleMetricFields = keys _emptyScaleMetrics;
    private _missingScaleMetricFields = _requiredScaleMetricFields select {
        !(_x in _savedScaleMetrics)
    };
    private _unexpectedScaleMetricFields = (keys _savedScaleMetrics) select {
        !(_x in _requiredScaleMetricFields)
    };
    if (
        _missingScaleMetricFields isNotEqualTo []
        || {_unexpectedScaleMetricFields isNotEqualTo []}
    ) then {
        throw format [
            "Saved campaign scale metrics have invalid shape; missing=%1 unexpected=%2",
            _missingScaleMetricFields,
            _unexpectedScaleMetricFields
        ];
    };
    {
        private _value = _savedScaleMetrics get _x;
        if !(_value isEqualType 0) then {
            throw format ["Saved campaign scale metric %1 has invalid type %2", _x, typeName _value];
        };
    } forEach _requiredScaleMetricFields;

    private _savedOpportunities = _savedState get "opportunities";
    if !(_savedOpportunities isEqualType createHashMap) then {
        throw format ["Saved campaign opportunities have invalid type %1", typeName _savedOpportunities];
    };
    private _requiredOpportunityTypes = [
        ["sideKey", ""],
        ["objectiveId", ""],
        ["status", ""],
        ["firstSeenAtDateNum", 0],
        ["lastSeenAtDateNum", 0],
        ["sampleCount", 0]
    ];
    private _requiredOpportunityFields = _requiredOpportunityTypes apply { _x select 0 };
    private _opportunities = createHashMap;
    {
        private _opportunityKey = _x;
        private _record = _y;
        if !(_record isEqualType createHashMap) then {
            throw format ["Saved campaign opportunity %1 has invalid record type %2", _opportunityKey, typeName _record];
        };
        private _missingOpportunityFields = _requiredOpportunityFields select { !(_x in _record) };
        private _unexpectedOpportunityFields = (keys _record) select { !(_x in _requiredOpportunityFields) };
        if (
            _missingOpportunityFields isNotEqualTo []
            || {_unexpectedOpportunityFields isNotEqualTo []}
        ) then {
            throw format [
                "Saved campaign opportunity %1 has invalid shape; missing=%2 unexpected=%3",
                _opportunityKey,
                _missingOpportunityFields,
                _unexpectedOpportunityFields
            ];
        };
        {
            _x params ["_field", "_prototype"];
            private _value = _record get _field;
            if !(_value isEqualType _prototype) then {
                throw format [
                    "Saved campaign opportunity %1 field %2 has invalid type %3",
                    _opportunityKey,
                    _field,
                    typeName _value
                ];
            };
        } forEach _requiredOpportunityTypes;
        private _sideKey = _record get "sideKey";
        private _objectiveId = _record get "objectiveId";
        private _status = _record get "status";
        private _sampleCount = _record get "sampleCount";
        if !(_sideKey in ["WEST", "EAST"]) then {
            throw format ["Saved campaign opportunity %1 has invalid side %2", _opportunityKey, _sideKey];
        };
        if (_objectiveId == "" || {!(_objectiveId in FLO_Objectives)}) then {
            throw format ["Saved campaign opportunity %1 has invalid objective %2", _opportunityKey, _objectiveId];
        };
        if !(_status in ["FOOTHOLD", "LOCAL_DEFENSE", "CONTACT", "ASSAULT"]) then {
            throw format ["Saved campaign opportunity %1 has invalid status %2", _opportunityKey, _status];
        };
        if (_sampleCount < 1 || {_sampleCount != floor _sampleCount}) then {
            throw format ["Saved campaign opportunity %1 has invalid sample count %2", _opportunityKey, _sampleCount];
        };
        if (_opportunityKey != (_sideKey + "|" + _objectiveId)) then {
            throw format ["Saved campaign opportunity key %1 does not match its record", _opportunityKey];
        };
        _opportunities set [
            _opportunityKey,
            createHashMapFromArray [
                ["sideKey", _sideKey],
                ["objectiveId", _objectiveId],
                ["status", _status],
                ["firstSeenAtDateNum", _record get "firstSeenAtDateNum"],
                ["lastSeenAtDateNum", _record get "lastSeenAtDateNum"],
                ["sampleCount", _sampleCount]
            ]
        ];
    } forEach _savedOpportunities;

    private _validOperationPhases = ["ASSAULT", "SECURE", "CONSOLIDATE", "RECOVERY"];
    private _validIntelLevels = ["TARGET"];
    private _assaultDefaults = call FLO_fnc_campaignAssaultStateDefaults;
    private _operationalDefaults = call FLO_fnc_campaignOperationalStateDefaults;
    private _requiredOperationFields = [
        "operationId", "priorityRole", "attackerSideKey", "defenderSideKey", "objectiveId",
        "sourceObjectiveIds", "supportObjectiveIds", "supplySourceObjectiveId", "phase",
        "phaseStartedAtDateNum", "phaseEndsAtDateNum", "result", "transitionReason",
        "defenderIntelLevel", "defenderIntelReason", "resourceReservationId", "resourceBudget",
        "resourceSpent", "resourceReleased", "drawdownPending"
    ] + (keys _assaultDefaults) + (keys _operationalDefaults);
    private _savedOperations = _savedState get "operations";
    private _operations = createHashMap;
    {
        private _operationId = _x;
        private _savedOperation = _y;
        if !(_savedOperation isEqualType createHashMap) then {
            throw format [
                "Saved campaign operation %1 has invalid record type %2",
                _operationId,
                typeName _savedOperation
            ];
        };
        private _missingOperationFields = _requiredOperationFields select {
            !(_x in _savedOperation)
        };
        private _unexpectedOperationFields = (keys _savedOperation) select {
            !(_x in _requiredOperationFields)
        };
        if (
            _missingOperationFields isNotEqualTo []
            || {_unexpectedOperationFields isNotEqualTo []}
        ) then {
            throw format [
                "Saved campaign operation %1 has invalid shape; missing=%2 unexpected=%3",
                _operationId,
                _missingOperationFields,
                _unexpectedOperationFields
            ];
        };
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

        private _operation = createHashMapFromArray [
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
        ];
        {
            _operation set [_x, _savedOperation get _x];
        } forEach (keys _assaultDefaults);
        {
            _operation set [_x, _savedOperation get _x];
        } forEach (keys _operationalDefaults);
        [_operation] call FLO_fnc_campaignValidateAssaultState;
        [_operation] call FLO_fnc_campaignValidateOperationalState;
        _operations set [_operationId, _operation];
    } forEach _savedOperations;

    private _operationOrder = +(_savedState get "operationOrder");
    private _primaryOperationId = _savedState get "primaryOperationId";
    if ((count (_operationOrder arrayIntersect _operationOrder)) != count _operationOrder) then {
        throw format ["Saved campaign operation order contains duplicates: %1", _operationOrder];
    };
    if ((count (keys _operations)) != count _operationOrder) then {
        throw "Saved campaign operation registry/order count mismatch";
    };
    private _targetIds = [];
    private _mainEffortCount = 0;
    private _recoverySeen = false;
    {
        if !(_x in _operations) then {
            throw format ["Saved campaign order references missing operation %1", _x];
        };
        private _operation = _operations get _x;
        if ((_operation get "phase") == "RECOVERY") then {
            _recoverySeen = true;
        } else {
            if (_recoverySeen) then {
                throw "Saved campaign orders an active operation after recovery entries";
            };
        };
        if ((_operation get "priorityRole") == "MAIN_EFFORT") then {
            _mainEffortCount = _mainEffortCount + 1;
        };
        private _objectiveId = _operation get "objectiveId";
        if (_objectiveId == "" || {_objectiveId in _targetIds}) then {
            throw format ["Saved campaign operation has invalid or duplicate target %1", _objectiveId];
        };
        if ((_operation get "supplySourceObjectiveId") == "") then {
            throw format ["Saved campaign operation %1 has no supply axis", _x];
        };
        _targetIds pushBack _objectiveId;
    } forEach _operationOrder;

    if (_operationOrder isEqualTo []) then {
        if (_primaryOperationId != "" || {(toUpper (_savedState get "phase")) != "IDLE"}) then {
            throw "Saved empty campaign has an invalid primary operation or phase";
        };
    } else {
        if (_primaryOperationId != (_operationOrder select 0)) then {
            throw format ["Saved primary operation %1 does not match ordered main effort", _primaryOperationId];
        };
        if (_mainEffortCount != 1 || {((_operations get _primaryOperationId) get "priorityRole") != "MAIN_EFFORT"}) then {
            throw format ["Saved campaign registry has %1 main efforts", _mainEffortCount];
        };
        if ((toUpper (_savedState get "phase")) != ((_operations get _primaryOperationId) get "phase")) then {
            throw "Saved campaign phase does not match its primary operation";
        };
    };
    private _state = createHashMapFromArray [
        ["sequence", _savedState get "sequence"],
        ["revision", _savedState get "revision"],
        ["initiativeSideKey", _initiativeSideKey],
        ["defenderSideKey", _defenderSideKey],
        ["operations", _operations],
        ["operationOrder", _operationOrder],
        ["primaryOperationId", _primaryOperationId],
        ["desiredOperationCount", _savedState get "desiredOperationCount"],
        ["lastScaleEvaluationAtDateNum", _savedState get "lastScaleEvaluationAtDateNum"],
        ["scaleReason", _savedState get "scaleReason"],
        ["scaleMetrics", +_savedScaleMetrics],
        ["lastCompletedOperationId", _savedState get "lastCompletedOperationId"],
        ["lastCompletedResult", _savedState get "lastCompletedResult"],
        ["opportunities", _opportunities],
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
    [_state] call FLO_fnc_campaignSyncPrimaryProjection
};

if ((keys _savedState) isNotEqualTo []) then {
    throw format [
        "Fresh campaign construction received persisted fields %1",
        keys _savedState
    ];
};

private _activeSide = FLO_ActivePlayerSide;
private _initiativeSideKey = "EAST";
if (_activeSide isEqualTo east) then { _initiativeSideKey = "WEST"; };
if (_activeSide isEqualTo west) then { _initiativeSideKey = "EAST"; };
private _defenderSideKey = ["WEST", "EAST"] select (_initiativeSideKey == "WEST");
createHashMapFromArray [
    ["sequence", 0],
    ["revision", 1],
    ["initiativeSideKey", _initiativeSideKey],
    ["defenderSideKey", _defenderSideKey],
    ["operations", createHashMap],
    ["operationOrder", []],
    ["primaryOperationId", ""],
    ["desiredOperationCount", 0],
    ["lastScaleEvaluationAtDateNum", -1],
    ["scaleReason", "INITIAL_DIRECT_FRONTLINE_PLANNING"],
    ["scaleMetrics", _emptyScaleMetrics],
    ["lastCompletedOperationId", ""],
    ["lastCompletedResult", ""],
    ["opportunities", createHashMap],
    ["operationId", ""],
    ["phase", "IDLE"],
    ["phaseStartedAtDateNum", _now],
    ["phaseEndsAtDateNum", _now],
    ["attackerSideKey", _initiativeSideKey],
    ["objectiveId", ""],
    ["sourceObjectiveIds", []],
    ["supportObjectiveIds", []],
    ["result", ""],
    ["transitionReason", "INITIAL_DIRECT_FRONTLINE_PLANNING"],
    ["defenderIntelLevel", "NONE"],
    ["defenderIntelReason", "NO_ACTIVE_OPERATION"],
    ["resourceReservationId", ""],
    ["resourceBudget", 0],
    ["resourceSpent", 0],
    ["resourceReleased", 0]
]
