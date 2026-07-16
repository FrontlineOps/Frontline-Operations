/*
 * Function: FLO_fnc_campaignDirector
 * Description:
 *   Owns theater initiative and opens direct assaults against connected enemy
 *   frontline objectives as authoritative funding allows.
 */

params [
    "_resourceManager",
    "_savedState",
    "_restoreSavedState"
];

private _config = createHashMapFromArray [
    ["updateInterval", 5],
    ["scaleEvaluationInterval", 60],
    ["capacityRetrySeconds", 120],
    ["operationLogisticsMinimumSupply", 600],
    ["operationCommitmentFraction", 0.60],
    ["operationMainBudgetFraction", 0.35],
    ["operationMainBudgetMinimum", 600],
    ["operationMainBudgetMaximum", 3000],
    ["operationSupportBudgetFraction", 0.125],
    ["operationSupportBudgetMinimum", 600],
    ["operationSupportBudgetMaximum", 1500],
    ["mainAssaultPackageMinimum", 24],
    ["mainAssaultPackageMaximum", 30],
    ["mainAssaultActiveTarget", 10],
    ["mainAssaultWaveSize", 6],
    ["supportAssaultPackageMinimum", 20],
    ["supportAssaultPackageMaximum", 24],
    ["supportAssaultActiveTarget", 7],
    ["supportAssaultWaveSize", 4],
    ["assaultOpeningCommitMinimumSeconds", 30],
    ["assaultWaveCooldownSeconds", 120],
    ["assaultApproachLaneCount", 3],
    ["assaultApproachLaneSpacingMeters", 120],
    ["assaultApproachRankSpacingMeters", 90],
    ["assaultApproachEntryDepthFraction", 0.72],
    ["assaultApproachAssaultDepthFraction", 0.18],
    ["assaultLossPauseRatio", 0.35],
    ["assaultLossCulminationRatio", 0.55],
    ["assaultNoProgressSeconds", 300],
    ["assaultReorganizationSeconds", 240],
    ["opportunityExpireSeconds", 900],
    ["opportunityMinimumSamples", 3],
    ["footholdMinimumHoldSeconds", 600],
    ["phaseDurations", createHashMapFromArray [
        ["ASSAULT", 1800],
        ["SECURE", 300],
        ["CONSOLIDATE", 600],
        ["RECOVERY", 90]
    ]]
];

private _state = [
    _savedState,
    _restoreSavedState
] call FLO_fnc_campaignCreateState;

private _director = createHashMapObject [[
    ["_resourceManager", _resourceManager],
    ["_config", _config],
    ["_state", _state],
    ["_pfhId", -1],
    ["_lastUpdateAt", -1],
    ["_pendingOperationAdmissions", []],

    ["_getState", {
        _self get "_state"
    }],

    ["_getConfig", {
        _self get "_config"
    }],

    ["_serialize", {
        private _current = _self get "_state";
        private _serializedOperations = createHashMap;
        {
            private _operationId = _x;
            private _operation = _y;
            _serializedOperations set [_operationId, createHashMapFromArray [
                ["operationId", _operationId],
                ["priorityRole", _operation get "priorityRole"],
                ["attackerSideKey", _operation get "attackerSideKey"],
                ["defenderSideKey", _operation get "defenderSideKey"],
                ["objectiveId", _operation get "objectiveId"],
                ["sourceObjectiveIds", +(_operation get "sourceObjectiveIds")],
                ["supportObjectiveIds", +(_operation get "supportObjectiveIds")],
                ["supplySourceObjectiveId", _operation get "supplySourceObjectiveId"],
                ["phase", _operation get "phase"],
                ["phaseStartedAtDateNum", _operation get "phaseStartedAtDateNum"],
                ["phaseEndsAtDateNum", _operation get "phaseEndsAtDateNum"],
                ["result", _operation get "result"],
                ["transitionReason", _operation get "transitionReason"],
                ["defenderIntelLevel", _operation get "defenderIntelLevel"],
                ["defenderIntelReason", _operation get "defenderIntelReason"],
                ["resourceReservationId", _operation get "resourceReservationId"],
                ["resourceBudget", _operation get "resourceBudget"],
                ["resourceSpent", _operation get "resourceSpent"],
                ["resourceReleased", _operation get "resourceReleased"],
                ["drawdownPending", _operation get "drawdownPending"],
                ["assaultPackageTarget", _operation get "assaultPackageTarget"],
                ["assaultActiveTarget", _operation get "assaultActiveTarget"],
                ["assaultWaveSize", _operation get "assaultWaveSize"],
                ["assaultCommittedTotal", _operation get "assaultCommittedTotal"],
                ["assaultLosses", _operation get "assaultLosses"],
                ["assaultWaveSequence", _operation get "assaultWaveSequence"],
                ["assaultNextWaveAtDateNum", _operation get "assaultNextWaveAtDateNum"],
                ["assaultPauseUntilDateNum", _operation get "assaultPauseUntilDateNum"],
                ["assaultLastProgressAtDateNum", _operation get "assaultLastProgressAtDateNum"],
                ["assaultBestDistance", _operation get "assaultBestDistance"],
                ["assaultLastEnemyCount", _operation get "assaultLastEnemyCount"],
                ["assaultLastArrivedCount", _operation get "assaultLastArrivedCount"],
                ["assaultPauseCount", _operation get "assaultPauseCount"],
                ["assaultLastContested", _operation get "assaultLastContested"],
                ["assaultStatus", _operation get "assaultStatus"],
                ["doctrine", _operation get "doctrine"],
                ["assaultOpeningEligibleAtDateNum", _operation get "assaultOpeningEligibleAtDateNum"]
            ]];
        } forEach (_current get "operations");

        createHashMapFromArray [
            ["sequence", _current get "sequence"],
            ["revision", _current get "revision"],
            ["initiativeSideKey", _current get "initiativeSideKey"],
            ["defenderSideKey", _current get "defenderSideKey"],
            ["operations", _serializedOperations],
            ["operationOrder", +(_current get "operationOrder")],
            ["primaryOperationId", _current get "primaryOperationId"],
            ["desiredOperationCount", _current get "desiredOperationCount"],
            ["lastScaleEvaluationAtDateNum", _current get "lastScaleEvaluationAtDateNum"],
            ["scaleReason", _current get "scaleReason"],
            ["scaleMetrics", +(_current get "scaleMetrics")],
            ["lastCompletedOperationId", _current get "lastCompletedOperationId"],
            ["lastCompletedResult", _current get "lastCompletedResult"],
            ["opportunities", +(_current get "opportunities")],
            ["phase", _current get "phase"],
            ["phaseStartedAtDateNum", _current get "phaseStartedAtDateNum"],
            ["phaseEndsAtDateNum", _current get "phaseEndsAtDateNum"],
            ["transitionReason", _current get "transitionReason"]
        ]
    }],

    ["_extendIdle", {
        params [
            ["_durationSeconds", 120, [0]],
            ["_reason", "INSUFFICIENT_CAPACITY", [""]]
        ];
        private _current = _self get "_state";
        if ((_current get "operationOrder") isNotEqualTo []) then {
            throw "Cannot extend idle campaign planning while operations exist";
        };
        _self set ["_pendingOperationAdmissions", []];
        private _now = call FLO_fnc_operationalDateNumber;
        _current set ["phase", "IDLE"];
        _current set ["phaseStartedAtDateNum", _now];
        _current set ["phaseEndsAtDateNum", [_now, _durationSeconds] call FLO_fnc_dateNumberAddSeconds];
        _current set ["transitionReason", _reason];
        _current set ["revision", (_current get "revision") + 1];
        [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        ["CAMPAIGN", 3, format ["Direct frontline planning deferred %1s (%2)", _durationSeconds, _reason]] call FLO_fnc_log;
    }],

    ["_enterIdle", {
        params [
            ["_reason", "INITIATIVE_TRANSFER", [""]],
            ["_durationSeconds", 0, [0]]
        ];
        private _current = _self get "_state";
        if ((_current get "operationOrder") isNotEqualTo []) then {
            throw format ["Cannot enter idle campaign planning with active operations: %1", _current get "operationOrder"];
        };
        _self set ["_pendingOperationAdmissions", []];

        private _nextInitiativeSideKey = _current get "defenderSideKey";
        private _nextDefenderSideKey = _current get "initiativeSideKey";
        private _now = call FLO_fnc_operationalDateNumber;
        _current set ["initiativeSideKey", _nextInitiativeSideKey];
        _current set ["defenderSideKey", _nextDefenderSideKey];
        _current set ["phase", "IDLE"];
        _current set ["phaseStartedAtDateNum", _now];
        _current set ["phaseEndsAtDateNum", [_now, _durationSeconds] call FLO_fnc_dateNumberAddSeconds];
        _current set ["transitionReason", _reason];
        _current set ["desiredOperationCount", 0];
        _current set ["revision", (_current get "revision") + 1];
        [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        ["FLO_Campaign_OperationChanged", [_current get "revision", "", "IDLE"]] call CBA_fnc_localEvent;
        ["CAMPAIGN", 3, format ["Initiative transferred to %1 (%2)", _nextInitiativeSideKey, _reason]] call FLO_fnc_log;
    }],

    ["_beginOperation", {
        params [
            ["_selection", createHashMap, [createHashMap]],
            ["_priorityRole", "SUPPORTING_EFFORT", [""]]
        ];
        private _current = _self get "_state";
        private _operations = _current get "operations";
        private _order = _current get "operationOrder";
        if !(_priorityRole in ["MAIN_EFFORT", "SUPPORTING_EFFORT"]) then {
            throw format ["Invalid new operation role %1", _priorityRole];
        };
        if (_order isEqualTo [] && {_priorityRole != "MAIN_EFFORT"}) then {
            throw "The first operation in a cycle must be the main effort";
        };
        if (_order isNotEqualTo [] && {_priorityRole == "MAIN_EFFORT"}) then {
            throw "A campaign cycle cannot create a second main effort";
        };

        private _attackerSideKey = _current get "initiativeSideKey";
        private _attackerSide = [_attackerSideKey] call FLO_fnc_campaignSideFromKey;
        private _objectiveId = _selection get "objectiveId";
        if (_objectiveId == "") then {
            throw "Cannot create an operation without a target";
        };

        private _existingTargetIds = _order apply {
            (_operations get _x) get "objectiveId"
        };
        private _currentSelections = [
            _self,
            _attackerSide,
            _existingTargetIds
        ] call FLO_fnc_campaignSelectTarget;
        private _currentSelectionIndex = _currentSelections findIf {
            (_x get "objectiveId") == _objectiveId
        };
        if (_currentSelectionIndex < 0) exitWith {
            ["CAMPAIGN", 4, format [
                "Skipped stale direct assault for %1/%2 because its frontline link, land anchor, or logistics axis changed",
                _attackerSideKey,
                _objectiveId
            ]] call FLO_fnc_log;
            ""
        };
        _selection = _currentSelections select _currentSelectionIndex;
        private _supplySourceObjectiveId = _selection get "supplySourceObjectiveId";

        private _budget = [
            _self,
            _attackerSideKey,
            _priorityRole
        ] call FLO_fnc_campaignCalculateOperationBudget;
        if (_budget <= 0) exitWith {
            ["CAMPAIGN", 4, format [
                "Skipped direct assault for %1/%2 because its %3 budget is no longer reservable",
                _attackerSideKey,
                _objectiveId,
                _priorityRole
            ]] call FLO_fnc_log;
            ""
        };

        private _defenderSideKey = _current get "defenderSideKey";
        private _sequence = (_current get "sequence") + 1;
        private _operationId = format ["OP_%1_%2", _attackerSideKey, _sequence];
        if (_operationId in _operations) then {
            throw format ["Campaign operation sequence collision for %1", _operationId];
        };
        private _now = call FLO_fnc_operationalDateNumber;
        private _reason = if (_priorityRole == "MAIN_EFFORT") then {
            ["COMMANDER_SELECTION", "PLAYER_OPPORTUNITY"] select (_selection get "fromOpportunity")
        } else {
            ["CAPACITY_SCALE_UP", "OPPORTUNITY_SCALE_UP"] select (_selection get "fromOpportunity")
        };
        private _operation = createHashMapFromArray [
            ["operationId", _operationId],
            ["priorityRole", _priorityRole],
            ["attackerSideKey", _attackerSideKey],
            ["defenderSideKey", _defenderSideKey],
            ["objectiveId", _objectiveId],
            ["sourceObjectiveIds", +(_selection get "sourceObjectiveIds")],
            ["supportObjectiveIds", +(_selection get "supportObjectiveIds")],
            ["supplySourceObjectiveId", _supplySourceObjectiveId],
            ["phase", "ASSAULT"],
            ["phaseStartedAtDateNum", _now],
            ["phaseEndsAtDateNum", [
                _now,
                [_self, "ASSAULT"] call FLO_fnc_campaignGetPhaseDuration
            ] call FLO_fnc_dateNumberAddSeconds],
            ["result", ""],
            ["transitionReason", "DIRECT_FRONTLINE_ASSAULT"],
            ["defenderIntelLevel", "TARGET"],
            ["defenderIntelReason", "PHASE_COMMITMENT"],
            ["intelContactAfter", diag_tickTime],
            ["resourceReservationId", ""],
            ["resourceBudget", 0],
            ["resourceSpent", 0],
            ["resourceReleased", 0],
            ["drawdownPending", false]
        ];
        {
            _operation set [_x, _y];
        } forEach (call FLO_fnc_campaignAssaultStateDefaults);
        {
            _operation set [_x, _y];
        } forEach (call FLO_fnc_campaignOperationalStateDefaults);
        _operation set ["doctrine", [_operation] call FLO_fnc_campaignSelectDoctrine];
        private _coverage = ([_attackerSide, "attackCoverage"] call FLO_fnc_gtnGetSideCommanderHandle) get "value";
        private _coverageScale = (((_coverage - 0.5) / 0.75) max 0) min 1;
        [_operation, _self get "_config", _coverageScale] call FLO_fnc_campaignConfigureOffensiveState;
        [_operation] call FLO_fnc_campaignValidateOperationalState;

        private _reservationId = format ["OPERATION:%1", _operationId];
        private _treasury = FLO_SideResources get _attackerSideKey;
        if !(_treasury call ["reserve", [
            _reservationId,
            _budget,
            "OPERATION",
            format ["Campaign operation %1", _operationId],
            "COMMANDER",
            _objectiveId
        ]]) exitWith {
            ["CAMPAIGN", 4, format [
                "Skipped direct assault for %1 because reservation %2 changed before commit",
                _objectiveId,
                _reservationId
            ]] call FLO_fnc_log;
            ""
        };
        _operation set ["resourceReservationId", _reservationId];
        _operation set ["resourceBudget", _budget];

        private _previousRevision = _current get "revision";
        private _previousOrder = +_order;
        try {
            _operations set [_operationId, _operation];
            _order pushBack _operationId;
            _current set ["sequence", _sequence];
            _current set ["operationOrder", _order];
            _current set ["revision", _previousRevision + 1];
            [_current] call FLO_fnc_campaignSyncPrimaryProjection;
            [_self] call FLO_fnc_campaignValidateOperationBudget;
        } catch {
            _treasury call ["releaseReservation", [_reservationId, "Direct assault admission rolled back"]];
            if (_operationId in _operations) then { _operations deleteAt _operationId; };
            _current set ["sequence", _sequence - 1];
            _current set ["operationOrder", _previousOrder];
            _current set ["revision", _previousRevision];
            [_current] call FLO_fnc_campaignSyncPrimaryProjection;
            ["CAMPAIGN", 1, format [
                "Operation %1 direct assault admission rolled back: %2",
                _operationId,
                _exception
            ]] call FLO_fnc_log;
            throw _exception;
        };

        [_self, _objectiveId] call FLO_fnc_campaignClearObjectiveOpportunities;
        ["FLO_Campaign_OperationChanged", [_current get "revision", _operationId, "ASSAULT"]] call CBA_fnc_localEvent;

        ["CAMPAIGN", 3, format [
            "Operation %1 opened as %2 direct assault: %3 attacks %4 from logistics axis %5 (%6)",
            _operationId,
            _priorityRole,
            _attackerSideKey,
            _objectiveId,
            _supplySourceObjectiveId,
            _reason
        ]] call FLO_fnc_log;
        _operationId
    }],

    ["_completeOperation", {
        params [
            ["_operationId", "", [""]],
            ["_result", "", [""]],
            ["_reason", "", [""]]
        ];
        private _current = _self get "_state";
        private _operation = [_self, _operationId] call FLO_fnc_campaignGetOperation;
        private _reservationId = _operation get "resourceReservationId";
        if (_reservationId == "") then {
            private _expectedRemaining = (_operation get "resourceBudget")
                - (_operation get "resourceSpent")
                - (_operation get "resourceReleased");
            if (_expectedRemaining > 0.001) then {
                throw format ["Operation %1 lost its reservation with %2 resources remaining", _operationId, _expectedRemaining];
            };
        } else {
            private _treasury = FLO_SideResources get (_operation get "attackerSideKey");
            if !(_reservationId in (_treasury get "_reservations")) then {
                throw format ["Operation %1 treasury reservation %2 is missing before completion", _operationId, _reservationId];
            };
        };

        [_self, _operationId, "RECOVERY", [_self, "RECOVERY"] call FLO_fnc_campaignGetPhaseDuration, _reason] call FLO_fnc_campaignTransition;
        [_self, _operationId, format ["Operation %1: %2", _operationId, _reason]] call FLO_fnc_campaignReleaseOperationBudget;
        _operation set ["result", _result];
        _current set ["lastCompletedOperationId", _operationId];
        _current set ["lastCompletedResult", _result];
        _current set ["revision", (_current get "revision") + 1];
        [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        ["FLO_Campaign_OperationChanged", [_current get "revision", _operationId, "RECOVERY"]] call CBA_fnc_localEvent;

        private _order = _current get "operationOrder";
        if ((_order select 0) == _operationId) then {
            private _activeSupports = _order select {
                _x != _operationId
                && {(((_current get "operations") get _x) get "phase") != "RECOVERY"}
            };
            if (_activeSupports isNotEqualTo []) then {
                _order deleteAt 0;
                _order pushBack _operationId;
                _current set ["operationOrder", _order];
                _current set ["revision", (_current get "revision") + 1];
                [_current] call FLO_fnc_campaignSyncPrimaryProjection;
                ["CAMPAIGN", 3, format ["Promoted operation %1 to main effort", _order select 0]] call FLO_fnc_log;
            };
        };
    }],

    ["_removeRecoveredOperation", {
        params [["_operationId", "", [""]]];
        private _current = _self get "_state";
        private _operations = _current get "operations";
        private _operation = [_self, _operationId] call FLO_fnc_campaignGetOperation;
        if ((_operation get "phase") != "RECOVERY") then {
            throw format ["Cannot remove non-recovery operation %1", _operationId];
        };
        _operations deleteAt _operationId;
        private _order = _current get "operationOrder";
        _order deleteAt (_order find _operationId);
        _current set ["operationOrder", _order];
        _current set ["revision", (_current get "revision") + 1];

        if (_order isEqualTo []) then {
            _self call ["_enterIdle", ["OPERATIONS_RECOVERED", 0]];
        } else {
            [_current] call FLO_fnc_campaignSyncPrimaryProjection;
            ["FLO_Campaign_OperationChanged", [_current get "revision", _current get "primaryOperationId", _current get "phase"]] call CBA_fnc_localEvent;
        };
    }],

    ["_drainPendingAdmission", {
        private _pending = _self get "_pendingOperationAdmissions";
        if (_pending isEqualTo []) exitWith { "" };

        private _current = _self get "_state";
        private _operations = _current get "operations";
        private _activeOperationIds = (_current get "operationOrder") select {
            ((_operations get _x) get "phase") != "RECOVERY"
        };
        if ((keys _operations) isNotEqualTo [] && {_activeOperationIds isEqualTo []}) exitWith { "" };

        private _selection = _pending deleteAt 0;
        _self set ["_pendingOperationAdmissions", _pending];
        private _priorityRole = ["SUPPORTING_EFFORT", "MAIN_EFFORT"] select (_activeOperationIds isEqualTo []);
        _self call ["_beginOperation", [_selection, _priorityRole]]
    }],

    ["_evaluateScaling", {
        private _current = _self get "_state";
        private _evaluation = [_self] call FLO_fnc_campaignEvaluateScale;
        private _now = call FLO_fnc_operationalDateNumber;
        private _currentCount = _evaluation get "currentCount";
        private _desiredCount = _evaluation get "desiredCount";
        _current set ["desiredOperationCount", _desiredCount];
        _current set ["lastScaleEvaluationAtDateNum", _now];
        _current set ["scaleReason", _evaluation get "reason"];
        _current set ["scaleMetrics", _evaluation get "metrics"];

        _self set ["_pendingOperationAdmissions", +(_evaluation get "plannedSelections")];

        _current set ["revision", (_current get "revision") + 1];
        [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        private _metrics = _evaluation get "metrics";
        ["CAMPAIGN", 4, format [
            "Direct frontline admission %1 current=%2 desired=%3 rankable=%4 treasurySlots=%5 sources=%6",
            _evaluation get "reason",
            _currentCount,
            _desiredCount,
            _metrics get "rankableTargetCount",
            _metrics get "treasurySlots",
            _metrics get "qualifyingSupplySourceCount"
        ]] call FLO_fnc_log;
        _evaluation
    }],

    ["_startCycle", {
        private _current = _self get "_state";
        private _evaluation = [_self] call FLO_fnc_campaignEvaluateScale;
        _current set ["desiredOperationCount", _evaluation get "desiredCount"];
        _current set ["lastScaleEvaluationAtDateNum", call FLO_fnc_operationalDateNumber];
        _current set ["scaleReason", _evaluation get "reason"];
        _current set ["scaleMetrics", _evaluation get "metrics"];

        if ((_evaluation get "desiredCount") <= 0) exitWith {
            _self call ["_extendIdle", [(_self get "_config") get "capacityRetrySeconds", _evaluation get "reason"]];
        };

        private _plannedSelections = _evaluation get "plannedSelections";
        if (_plannedSelections isEqualTo []) then {
            throw "Campaign scale evaluation returned positive capacity without a target selection";
        };
        _self set ["_pendingOperationAdmissions", +_plannedSelections];
        private _mainOperationId = _self call ["_drainPendingAdmission", []];
        if (_mainOperationId == "") exitWith {
            if ((_self get "_pendingOperationAdmissions") isEqualTo []) then {
                _self call ["_extendIdle", [(_self get "_config") get "capacityRetrySeconds", "ADMISSION_REVALIDATION_FAILED"]];
            };
        };
    }],

    ["_onObjectiveFlipped", {
        params ["_objectiveId", "_previousOwner", "_newOwner"];
        private _current = _self get "_state";
        private _matchedOperationId = "";
        {
            if ((_y get "objectiveId") == _objectiveId) exitWith {
                _matchedOperationId = _x;
            };
        } forEach (_current get "operations");
        if (_matchedOperationId == "") exitWith {};

        private _operation = ((_current get "operations") get _matchedOperationId);
        private _phase = _operation get "phase";
        private _attackerSide = [_operation get "attackerSideKey"] call FLO_fnc_campaignSideFromKey;
        if (_newOwner isEqualTo _attackerSide && {_phase == "ASSAULT"}) exitWith {
            [_self, _matchedOperationId, "SECURE", [_self, "SECURE"] call FLO_fnc_campaignGetPhaseDuration, "TARGET_CAPTURED"] call FLO_fnc_campaignTransition;
        };
        if (_newOwner isNotEqualTo _attackerSide && {_phase in ["SECURE", "CONSOLIDATE"]}) then {
            _self call ["_completeOperation", [_matchedOperationId, "ATTACKER_FAILED", "TARGET_LOST"]];
        };
    }],

    ["_updateOperation", {
        params [["_operationId", "", [""]]];
        private _operation = [_self, _operationId] call FLO_fnc_campaignGetOperation;
        private _phase = _operation get "phase";
        private _now = call FLO_fnc_operationalDateNumber;
        private _deadlineReached = ([_now, _operation get "phaseEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0;

        if (_phase == "RECOVERY") exitWith {
            if (_deadlineReached) then {
                _self call ["_removeRecoveredOperation", [_operationId]];
            };
        };

        private _objectiveId = _operation get "objectiveId";
        if !(_objectiveId in FLO_Objectives) exitWith {
            _self call ["_completeOperation", [_operationId, "NO_TARGET", "TARGET_MISSING"]];
        };

        private _objective = FLO_Objectives get _objectiveId;
        private _attackerSide = [_operation get "attackerSideKey"] call FLO_fnc_campaignSideFromKey;
        private _attackerOwnsTarget = (_objective get "owner") isEqualTo _attackerSide;
        if (
            _phase == "ASSAULT"
            && {([_objectiveId, _objective] call FLO_fnc_campaignResolveAssaultLandAnchor) isEqualTo []}
        ) exitWith {
            ["CAMPAIGN", 2, format [
                "Operation %1 withdrawing: objective %2 has no ground-assault anchor",
                _operationId,
                _objectiveId
            ]] call FLO_fnc_log;
            _self call ["_completeOperation", [_operationId, "NO_TARGET", "NO_LAND_ASSAULT_ANCHOR"]];
        };
        switch (_phase) do {
            case "ASSAULT": {
                if (_attackerOwnsTarget) then {
                    [_self, _operationId, "SECURE", [_self, "SECURE"] call FLO_fnc_campaignGetPhaseDuration, "TARGET_CAPTURED"] call FLO_fnc_campaignTransition;
                } else {
                    if (_deadlineReached) then {
                        _self call ["_completeOperation", [_operationId, "ATTACKER_FAILED", "ASSAULT_TIMEOUT"]];
                    };
                };
            };
            case "SECURE": {
                if (!_attackerOwnsTarget) then {
                    _self call ["_completeOperation", [_operationId, "ATTACKER_FAILED", "TARGET_LOST_DURING_SECURE"]];
                } else {
                    if (_deadlineReached) then {
                        [_self, _operationId, "CONSOLIDATE", [_self, "CONSOLIDATE"] call FLO_fnc_campaignGetPhaseDuration, "SECURE_COMPLETE"] call FLO_fnc_campaignTransition;
                    };
                };
            };
            case "CONSOLIDATE": {
                if (!_attackerOwnsTarget) then {
                    _self call ["_completeOperation", [_operationId, "ATTACKER_FAILED", "TARGET_LOST_DURING_CONSOLIDATION"]];
                } else {
                    if (_deadlineReached) then {
                        [_self, _objectiveId, "OPERATION_COMPLETE", _operationId] call FLO_fnc_campaignIntegrateObjective;
                        _self call ["_completeOperation", [_operationId, "ATTACKER_SUCCESS", "CONSOLIDATION_COMPLETE"]];
                    };
                };
            };
            default {
                throw format ["Campaign operation %1 reached unsupported phase %2", _operationId, _phase];
            };
        };
    }],

    ["_update", {
        if (!FLO_MissionReady) exitWith {};
        _self set ["_lastUpdateAt", diag_tickTime];
        [_self] call FLO_fnc_campaignCollectOpportunities;
        [_self] call FLO_fnc_campaignProcessIntegrations;
        private _current = _self get "_state";
        private _order = _current get "operationOrder";
        private _now = call FLO_fnc_operationalDateNumber;
        if (_order isEqualTo []) exitWith {
            if ((_current get "phase") != "IDLE") then {
                throw format ["Empty campaign registry has phase %1", _current get "phase"];
            };
            private _deadlineReached = ([_now, _current get "phaseEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0;
            if (_deadlineReached) then {
                if ((_self get "_pendingOperationAdmissions") isEqualTo []) then {
                    _self call ["_startCycle", []];
                } else {
                    _self call ["_drainPendingAdmission", []];
                };
            };
        };

        {
            if (_x in ((_self get "_state") get "operations")) then {
                _self call ["_updateOperation", [_x]];
            };
        } forEach (+_order);

        if ((_self get "_pendingOperationAdmissions") isNotEqualTo []) then {
            _self call ["_drainPendingAdmission", []];
        };

        _current = _self get "_state";
        if ((_current get "operationOrder") isEqualTo []) exitWith {};
        private _lastEvaluation = _current get "lastScaleEvaluationAtDateNum";
        if (
            _lastEvaluation < 0
            || {([_lastEvaluation, _now] call FLO_fnc_dateNumberDeltaSeconds) >= ((_self get "_config") get "scaleEvaluationInterval")}
        ) then {
            _self call ["_evaluateScaling", []];
        };
    }],

    ["_start", {
        if ((_self get "_pfhId") >= 0) exitWith { true };
        FLO_CampaignDirector = _self;
        private _interval = (_self get "_config") get "updateInterval";
        private _pfhId = [{
            params ["_args"];
            _args params ["_directorRef"];
            _directorRef call ["_update", []];
        }, _interval, [_self]] call CBA_fnc_addPerFrameHandler;
        _self set ["_pfhId", _pfhId];
        ["CAMPAIGN", 3, format ["Campaign director started (%1s, direct connected-frontline assaults)", _interval]] call FLO_fnc_log;
        true
    }]
]];

private _restoredState = _director get "_state";
[_restoredState] call FLO_fnc_campaignSyncPrimaryProjection;
[_director] call FLO_fnc_campaignValidateOperationBudget;
_director
