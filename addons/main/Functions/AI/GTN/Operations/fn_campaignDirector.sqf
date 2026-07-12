/*
 * Function: FLO_fnc_campaignDirector
 * Description:
 *   Owns theater initiative and a bounded registry of one main effort plus
 *   up to two supporting operations above both GTN side commanders.
 */

params [
    "_resourceManager",
    ["_savedState", createHashMap, [createHashMap]]
];

private _config = createHashMapFromArray [
    ["updateInterval", 5],
    ["scaleEvaluationInterval", 60],
    ["scaleUpHoldSeconds", 600],
    ["scaleDownHoldSeconds", 180],
    ["capacityRetrySeconds", 120],
    ["operationMaximumCount", 3],
    ["operationOffensivePoolFraction", 0.60],
    ["operationMainMinimumGroups", 20],
    ["operationSupportMinimumGroups", 20],
    ["operationLogisticsMinimumSupply", 600],
    ["operationAxisSeparationMeters", 2500],
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
    ["assaultWaveCooldownSeconds", 180],
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
    ["operationIntelContactFreshSeconds", 180],
    ["phaseDurations", createHashMapFromArray [
        ["LULL", 600],
        ["PREPARE", 600],
        ["ASSAULT", 1800],
        ["SECURE", 300],
        ["CONSOLIDATE", 600],
        ["RECOVERY", 600]
    ]]
];

private _state = [_config, _savedState] call FLO_fnc_campaignCreateState;

private _director = createHashMapObject [[
    ["_resourceManager", _resourceManager],
    ["_config", _config],
    ["_state", _state],
    ["_pfhId", -1],
    ["_lastUpdateAt", -1],

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
                ["assaultStatus", _operation get "assaultStatus"]
            ]];
        } forEach (_current get "operations");

        createHashMapFromArray [
            ["schemaVersion", 6],
            ["sequence", _current get "sequence"],
            ["revision", _current get "revision"],
            ["initiativeSideKey", _current get "initiativeSideKey"],
            ["defenderSideKey", _current get "defenderSideKey"],
            ["operations", _serializedOperations],
            ["operationOrder", +(_current get "operationOrder")],
            ["primaryOperationId", _current get "primaryOperationId"],
            ["desiredOperationCount", _current get "desiredOperationCount"],
            ["lastScaleEvaluationAtDateNum", _current get "lastScaleEvaluationAtDateNum"],
            ["scaleUpCandidateSinceDateNum", _current get "scaleUpCandidateSinceDateNum"],
            ["scaleDownCandidateSinceDateNum", _current get "scaleDownCandidateSinceDateNum"],
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

    ["_extendLull", {
        params [
            ["_durationSeconds", 120, [0]],
            ["_reason", "INSUFFICIENT_CAPACITY", [""]]
        ];
        private _current = _self get "_state";
        if ((_current get "operationOrder") isNotEqualTo []) then {
            throw "Cannot extend campaign LULL while operations exist";
        };
        private _now = dateToNumber date;
        _current set ["phase", "LULL"];
        _current set ["phaseStartedAtDateNum", _now];
        _current set ["phaseEndsAtDateNum", [_now, _durationSeconds] call FLO_fnc_dateNumberAddSeconds];
        _current set ["transitionReason", _reason];
        _current set ["revision", (_current get "revision") + 1];
        [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        ["CAMPAIGN", 2, format ["Campaign LULL extended %1s (%2)", _durationSeconds, _reason]] call FLO_fnc_log;
    }],

    ["_enterLull", {
        params [["_reason", "INITIATIVE_TRANSFER", [""]]];
        private _current = _self get "_state";
        if ((_current get "operationOrder") isNotEqualTo []) then {
            throw format ["Cannot enter LULL with active operations: %1", _current get "operationOrder"];
        };

        private _nextInitiativeSideKey = _current get "defenderSideKey";
        private _nextDefenderSideKey = _current get "initiativeSideKey";
        private _now = dateToNumber date;
        private _duration = [_self, "LULL"] call FLO_fnc_campaignGetPhaseDuration;
        _current set ["initiativeSideKey", _nextInitiativeSideKey];
        _current set ["defenderSideKey", _nextDefenderSideKey];
        _current set ["phase", "LULL"];
        _current set ["phaseStartedAtDateNum", _now];
        _current set ["phaseEndsAtDateNum", [_now, _duration] call FLO_fnc_dateNumberAddSeconds];
        _current set ["transitionReason", _reason];
        _current set ["desiredOperationCount", 0];
        _current set ["scaleUpCandidateSinceDateNum", -1];
        _current set ["scaleDownCandidateSinceDateNum", -1];
        _current set ["revision", (_current get "revision") + 1];
        [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        ["FLO_Campaign_OperationChanged", [_current get "revision", "", "LULL"]] call CBA_fnc_localEvent;
        ["CAMPAIGN", 2, format ["Initiative transferred to %1 (%2)", _nextInitiativeSideKey, _reason]] call FLO_fnc_log;
    }],

    ["_beginOperation", {
        params [
            ["_selection", createHashMap, [createHashMap]],
            ["_priorityRole", "SUPPORTING_EFFORT", [""]]
        ];
        private _current = _self get "_state";
        private _operations = _current get "operations";
        private _order = _current get "operationOrder";
        if ((count _order) >= ((_self get "_config") get "operationMaximumCount")) then {
            throw format ["Cannot add operation beyond registry limit: %1", _order];
        };
        if !(_priorityRole in ["MAIN_EFFORT", "SUPPORTING_EFFORT"]) then {
            throw format ["Invalid new operation role %1", _priorityRole];
        };
        if (_order isEqualTo [] && {_priorityRole != "MAIN_EFFORT"}) then {
            throw "The first operation in a cycle must be the main effort";
        };
        if (_order isNotEqualTo [] && {_priorityRole == "MAIN_EFFORT"}) then {
            throw "A campaign cycle cannot create a second main effort";
        };

        private _objectiveId = _selection get "objectiveId";
        private _supplySourceObjectiveId = _selection get "supplySourceObjectiveId";
        if (_objectiveId == "" || {_supplySourceObjectiveId == ""}) then {
            throw "Cannot create an operation without target and logistics axis";
        };
        {
            private _existing = _operations get _x;
            if ((_existing get "objectiveId") == _objectiveId) then {
                throw format ["Operation target %1 is already active", _objectiveId];
            };
            if ((_existing get "supplySourceObjectiveId") == _supplySourceObjectiveId) then {
                throw format ["Logistics axis %1 is already assigned", _supplySourceObjectiveId];
            };
        } forEach _order;

        private _attackerSideKey = _current get "initiativeSideKey";
        private _defenderSideKey = _current get "defenderSideKey";
        private _sequence = (_current get "sequence") + 1;
        private _operationId = format ["OP_%1_%2", _attackerSideKey, _sequence];
        private _now = dateToNumber date;
        private _operation = createHashMapFromArray [
            ["operationId", _operationId],
            ["priorityRole", _priorityRole],
            ["attackerSideKey", _attackerSideKey],
            ["defenderSideKey", _defenderSideKey],
            ["objectiveId", _objectiveId],
            ["sourceObjectiveIds", +(_selection get "sourceObjectiveIds")],
            ["supportObjectiveIds", +(_selection get "supportObjectiveIds")],
            ["supplySourceObjectiveId", _supplySourceObjectiveId],
            ["phase", "PREPARE"],
            ["phaseStartedAtDateNum", _now],
            ["phaseEndsAtDateNum", _now],
            ["result", ""],
            ["transitionReason", "OPERATION_CREATED"],
            ["defenderIntelLevel", "SECTOR"],
            ["defenderIntelReason", "OPERATION_ASSESSMENT"],
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

        _operations set [_operationId, _operation];
        _order pushBack _operationId;
        _current set ["sequence", _sequence];
        _current set ["operationOrder", _order];
        [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        [_self, _objectiveId] call FLO_fnc_campaignClearObjectiveOpportunities;
        [_self, _operationId] call FLO_fnc_campaignReserveOperationBudget;

        private _reason = if (_priorityRole == "MAIN_EFFORT") then {
            ["COMMANDER_SELECTION", "PLAYER_OPPORTUNITY"] select (_selection get "fromOpportunity")
        } else {
            ["CAPACITY_SCALE_UP", "OPPORTUNITY_SCALE_UP"] select (_selection get "fromOpportunity")
        };
        [_self, _operationId, "PREPARE", [_self, "PREPARE"] call FLO_fnc_campaignGetPhaseDuration, _reason] call FLO_fnc_campaignTransition;

        ["CAMPAIGN", 2, format [
            "Operation %1 started as %2: %3 attacks %4 from logistics axis %5",
            _operationId,
            _priorityRole,
            _attackerSideKey,
            _objectiveId,
            _supplySourceObjectiveId
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
        _operation set ["result", _result];
        _current set ["lastCompletedOperationId", _operationId];
        _current set ["lastCompletedResult", _result];
        [_self, _operationId, format ["Operation %1: %2", _operationId, _reason]] call FLO_fnc_campaignReleaseOperationBudget;
        [_self, _operationId, "RECOVERY", [_self, "RECOVERY"] call FLO_fnc_campaignGetPhaseDuration, _reason] call FLO_fnc_campaignTransition;

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
                ["CAMPAIGN", 2, format ["Promoted operation %1 to main effort", _order select 0]] call FLO_fnc_log;
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
            _self call ["_enterLull", ["OPERATIONS_RECOVERED"]];
        } else {
            [_current] call FLO_fnc_campaignSyncPrimaryProjection;
            ["FLO_Campaign_OperationChanged", [_current get "revision", _current get "primaryOperationId", _current get "phase"]] call CBA_fnc_localEvent;
        };
    }],

    ["_withdrawSupportingOperation", {
        private _current = _self get "_state";
        private _operations = _current get "operations";
        private _reversedOrder = +(_current get "operationOrder");
        reverse _reversedOrder;
        private _withdrawOperationId = "";
        {
            private _operation = _operations get _x;
            if ((_operation get "priorityRole") != "SUPPORTING_EFFORT") then { continue };
            if ((_operation get "phase") in ["PREPARE", "ASSAULT"]) exitWith {
                _withdrawOperationId = _x;
            };
        } forEach _reversedOrder;

        if (_withdrawOperationId != "") exitWith {
            _self call ["_completeOperation", [_withdrawOperationId, "COMMAND_DRAWDOWN", "CAPACITY_SCALE_DOWN"]];
            true
        };

        private _marked = false;
        {
            private _operation = _operations get _x;
            if ((_operation get "priorityRole") != "SUPPORTING_EFFORT") then { continue };
            if !((_operation get "phase") in ["SECURE", "CONSOLIDATE"]) then { continue };
            if !(_operation get "drawdownPending") then {
                _operation set ["drawdownPending", true];
                _marked = true;
            };
        } forEach _reversedOrder;
        if (_marked) then {
            _current set ["revision", (_current get "revision") + 1];
            [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        };
        _marked
    }],

    ["_evaluateScaling", {
        private _current = _self get "_state";
        private _evaluation = [_self] call FLO_fnc_campaignEvaluateScale;
        private _now = dateToNumber date;
        private _currentCount = _evaluation get "currentCount";
        private _desiredCount = _evaluation get "desiredCount";
        _current set ["desiredOperationCount", _desiredCount];
        _current set ["lastScaleEvaluationAtDateNum", _now];
        _current set ["scaleReason", _evaluation get "reason"];
        _current set ["scaleMetrics", _evaluation get "metrics"];

        if (_desiredCount > _currentCount) then {
            _current set ["scaleDownCandidateSinceDateNum", -1];
            private _since = _current get "scaleUpCandidateSinceDateNum";
            if (_since < 0) then {
                _current set ["scaleUpCandidateSinceDateNum", _now];
            } else {
                if (([_since, _now] call FLO_fnc_dateNumberDeltaSeconds) >= ((_self get "_config") get "scaleUpHoldSeconds")) then {
                    private _plannedSelections = _evaluation get "plannedSelections";
                    if (_plannedSelections isNotEqualTo []) then {
                        _self call ["_beginOperation", [_plannedSelections select 0, "SUPPORTING_EFFORT"]];
                    };
                    _current set ["scaleUpCandidateSinceDateNum", -1];
                };
            };
        } else {
            if (_desiredCount < _currentCount) then {
                _current set ["scaleUpCandidateSinceDateNum", -1];
                private _since = _current get "scaleDownCandidateSinceDateNum";
                if (_since < 0) then {
                    _current set ["scaleDownCandidateSinceDateNum", _now];
                } else {
                    if (([_since, _now] call FLO_fnc_dateNumberDeltaSeconds) >= ((_self get "_config") get "scaleDownHoldSeconds")) then {
                        _self call ["_withdrawSupportingOperation", []];
                        _current set ["scaleDownCandidateSinceDateNum", -1];
                    };
                };
            } else {
                _current set ["scaleUpCandidateSinceDateNum", -1];
                _current set ["scaleDownCandidateSinceDateNum", -1];
            };
        };

        _current set ["revision", (_current get "revision") + 1];
        [_current] call FLO_fnc_campaignSyncPrimaryProjection;
        private _metrics = _evaluation get "metrics";
        ["CAMPAIGN", 3, format [
            "Scale %1 current=%2 desired=%3 slots force=%4 logistics=%5 treasury=%6 axes=%7 pressure=%8",
            _evaluation get "reason",
            _currentCount,
            _desiredCount,
            _metrics get "forceSlots",
            _metrics get "logisticsSlots",
            _metrics get "treasurySlots",
            _metrics get "axisSlots",
            _metrics get "pressureCap"
        ]] call FLO_fnc_log;
        _evaluation
    }],

    ["_startCycle", {
        private _current = _self get "_state";
        private _evaluation = [_self] call FLO_fnc_campaignEvaluateScale;
        _current set ["desiredOperationCount", _evaluation get "desiredCount"];
        _current set ["lastScaleEvaluationAtDateNum", dateToNumber date];
        _current set ["scaleReason", _evaluation get "reason"];
        _current set ["scaleMetrics", _evaluation get "metrics"];

        if ((_evaluation get "desiredCount") <= 0) exitWith {
            private _metrics = _evaluation get "metrics";
            private _strategicCapacity = (_metrics get "forceSlots")
                min (_metrics get "logisticsSlots")
                min (_metrics get "treasurySlots")
                min (_metrics get "pressureCap");
            if (_strategicCapacity > 0 && {(_metrics get "axisSlots") == 0}) then {
                _current set ["lastCompletedResult", "NO_TARGET"];
                _self call ["_enterLull", ["NO_REACHABLE_TARGET"]];
            } else {
                _self call ["_extendLull", [(_self get "_config") get "capacityRetrySeconds", _evaluation get "reason"]];
            };
        };

        private _plannedSelections = _evaluation get "plannedSelections";
        if (_plannedSelections isEqualTo []) then {
            throw "Campaign scale evaluation returned positive capacity without a target selection";
        };
        _self call ["_beginOperation", [_plannedSelections select 0, "MAIN_EFFORT"]];
        _current set ["scaleUpCandidateSinceDateNum", -1];
        _current set ["scaleDownCandidateSinceDateNum", -1];
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
        if (_newOwner isEqualTo _attackerSide && {_phase in ["PREPARE", "ASSAULT"]}) exitWith {
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
        private _now = dateToNumber date;
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
        switch (_phase) do {
            case "PREPARE": {
                if (_attackerOwnsTarget) then {
                    [_self, _operationId, "SECURE", [_self, "SECURE"] call FLO_fnc_campaignGetPhaseDuration, "TARGET_CAPTURED_DURING_PREPARE"] call FLO_fnc_campaignTransition;
                } else {
                    if (_deadlineReached) then {
                        [_self, _operationId, "ASSAULT", [_self, "ASSAULT"] call FLO_fnc_campaignGetPhaseDuration, "PREPARATION_COMPLETE"] call FLO_fnc_campaignTransition;
                    };
                };
            };
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
        [_self] call FLO_fnc_campaignUpdateDefenderIntel;

        private _current = _self get "_state";
        private _order = _current get "operationOrder";
        private _now = dateToNumber date;
        if (_order isEqualTo []) exitWith {
            if ((_current get "phase") != "LULL") then {
                throw format ["Empty campaign registry has phase %1", _current get "phase"];
            };
            private _deadlineReached = ([_now, _current get "phaseEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0;
            if (_deadlineReached) then {
                _self call ["_startCycle", []];
            };
        };

        {
            if (_x in ((_self get "_state") get "operations")) then {
                _self call ["_updateOperation", [_x]];
            };
        } forEach (+_order);

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
        ["CAMPAIGN", 2, format ["Campaign director started (%1s, max %2 operations)", _interval, (_self get "_config") get "operationMaximumCount"]] call FLO_fnc_log;
        true
    }]
]];

private _restoredState = _director get "_state";
private _restoredOperations = _restoredState get "operations";
if ((keys _savedState) isNotEqualTo [] && {(_savedState get "schemaVersion") < 5}) then {
    private _sideKey = _restoredState get "initiativeSideKey";
    private _network = FLO_Logistics_Networks get _sideKey;
    {
        private _operation = _restoredOperations get _x;
        if ((_operation get "supplySourceObjectiveId") == "") then {
            {
                private _sourceObjectiveId = [_network, _x, [], 0] call FLO_fnc_logisticsNetworkFindSupplySourceObjective;
                if (_sourceObjectiveId != "") exitWith {
                    _operation set ["supplySourceObjectiveId", _sourceObjectiveId];
                };
            } forEach (_operation get "sourceObjectiveIds");
        };
    } forEach (_restoredState get "operationOrder");
};

if ((keys _savedState) isNotEqualTo [] && {(_savedState get "schemaVersion") < 4}) then {
    {
        private _operation = _restoredOperations get _x;
        if ((_operation get "phase") in ["PREPARE", "ASSAULT", "SECURE", "CONSOLIDATE"]) then {
            [_director, _x] call FLO_fnc_campaignReserveOperationBudget;
        };
    } forEach (_restoredState get "operationOrder");
};

[_restoredState] call FLO_fnc_campaignSyncPrimaryProjection;
[_director] call FLO_fnc_campaignValidateOperationBudget;
_director
