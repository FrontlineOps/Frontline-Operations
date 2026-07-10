/*
 * Function: FLO_fnc_campaignDirector
 * Description:
 *   Owns theater initiative and the single active territorial operation above
 *   both GTN side commanders.
 */

params [
    "_resourceManager",
    ["_savedState", createHashMap, [createHashMap]]
];

private _config = createHashMapFromArray [
    ["updateInterval", 5],
    ["opportunityExpireSeconds", 900],
    ["opportunityMinimumSamples", 3],
    ["footholdMinimumHoldSeconds", 600],
    ["operationIntelContactFreshSeconds", 180],
    ["operationBudgetFraction", 0.35],
    ["operationBudgetMinimum", 600],
    ["operationBudgetMaximum", 3000],
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
    ["_intelContactAfter", diag_tickTime],

    ["_getState", {
        _self get "_state"
    }],

    ["_getConfig", {
        _self get "_config"
    }],

    ["_serialize", {
        private _current = _self get "_state";
        createHashMapFromArray [
            ["schemaVersion", _current get "schemaVersion"],
            ["sequence", _current get "sequence"],
            ["revision", _current get "revision"],
            ["operationId", _current get "operationId"],
            ["phase", _current get "phase"],
            ["phaseStartedAtDateNum", _current get "phaseStartedAtDateNum"],
            ["phaseEndsAtDateNum", _current get "phaseEndsAtDateNum"],
            ["initiativeSideKey", _current get "initiativeSideKey"],
            ["attackerSideKey", _current get "attackerSideKey"],
            ["defenderSideKey", _current get "defenderSideKey"],
            ["objectiveId", _current get "objectiveId"],
            ["sourceObjectiveIds", +(_current get "sourceObjectiveIds")],
            ["supportObjectiveIds", +(_current get "supportObjectiveIds")],
            ["result", _current get "result"],
            ["transitionReason", _current get "transitionReason"],
            ["lastCompletedOperationId", _current get "lastCompletedOperationId"],
            ["lastCompletedResult", _current get "lastCompletedResult"],
            ["defenderIntelLevel", _current get "defenderIntelLevel"],
            ["defenderIntelReason", _current get "defenderIntelReason"],
            ["resourceReservationId", _current get "resourceReservationId"],
            ["resourceBudget", _current get "resourceBudget"],
            ["resourceSpent", _current get "resourceSpent"],
            ["resourceReleased", _current get "resourceReleased"],
            ["opportunities", +(_current get "opportunities")]
        ]
    }],

    ["_beginOperation", {
        private _current = _self get "_state";
        private _attackerSideKey = _current get "initiativeSideKey";
        private _defenderSideKey = ["WEST", "EAST"] select (_attackerSideKey isEqualTo "WEST");
        private _attackerSide = [_attackerSideKey] call FLO_fnc_campaignSideFromKey;
        private _selection = [_self, _attackerSide] call FLO_fnc_campaignSelectTarget;
        private _objectiveId = _selection get "objectiveId";

        if (_objectiveId == "") exitWith {
            _current set ["result", "NO_TARGET"];
            _current set ["lastCompletedResult", "NO_TARGET"];
            _current set ["initiativeSideKey", _defenderSideKey];
            _current set ["attackerSideKey", _defenderSideKey];
            _current set ["defenderSideKey", _attackerSideKey];
            [_self, "LULL", [_self, "LULL"] call FLO_fnc_campaignGetPhaseDuration, "NO_REACHABLE_TARGET"] call FLO_fnc_campaignTransition;
        };

        private _sequence = (_current get "sequence") + 1;
        private _operationId = format ["OP_%1_%2", _attackerSideKey, _sequence];

        _current set ["sequence", _sequence];
        _current set ["operationId", _operationId];
        _current set ["attackerSideKey", _attackerSideKey];
        _current set ["defenderSideKey", _defenderSideKey];
        _current set ["objectiveId", _objectiveId];
        _current set ["sourceObjectiveIds", _selection get "sourceObjectiveIds"];
        _current set ["supportObjectiveIds", _selection get "supportObjectiveIds"];
        _current set ["result", ""];
        _current set ["resourceReservationId", ""];
        _current set ["resourceBudget", 0];
        _current set ["resourceSpent", 0];
        _current set ["resourceReleased", 0];
        _current set ["defenderIntelLevel", "SECTOR"];
        _current set ["defenderIntelReason", "OPERATION_ASSESSMENT"];
        _self set ["_intelContactAfter", diag_tickTime];
        [_self, _objectiveId] call FLO_fnc_campaignClearObjectiveOpportunities;
        [_self] call FLO_fnc_campaignReserveOperationBudget;

        private _reason = ["COMMANDER_SELECTION", "PLAYER_OPPORTUNITY"] select (_selection get "fromOpportunity");
        [_self, "PREPARE", [_self, "PREPARE"] call FLO_fnc_campaignGetPhaseDuration, _reason] call FLO_fnc_campaignTransition;

        ["CAMPAIGN", 2, format [
            "Operation %1 started: %2 attacks %3",
            _operationId,
            _attackerSideKey,
            _objectiveId
        ]] call FLO_fnc_log;
    }],

    ["_completeOperation", {
        params [
            ["_result", "", [""]],
            ["_reason", "", [""]]
        ];

        private _current = _self get "_state";
        _current set ["result", _result];
        _current set ["lastCompletedOperationId", _current get "operationId"];
        _current set ["lastCompletedResult", _result];
        [_self, format ["Operation %1: %2", _current get "operationId", _reason]] call FLO_fnc_campaignReleaseOperationBudget;

        [_self, "RECOVERY", [_self, "RECOVERY"] call FLO_fnc_campaignGetPhaseDuration, _reason] call FLO_fnc_campaignTransition;
    }],

    ["_enterLull", {
        private _current = _self get "_state";
        private _nextInitiativeSideKey = _current get "defenderSideKey";
        private _nextDefenderSideKey = _current get "attackerSideKey";

        _current set ["initiativeSideKey", _nextInitiativeSideKey];
        _current set ["attackerSideKey", _nextInitiativeSideKey];
        _current set ["defenderSideKey", _nextDefenderSideKey];
        _current set ["operationId", ""];
        _current set ["objectiveId", ""];
        _current set ["sourceObjectiveIds", []];
        _current set ["supportObjectiveIds", []];
        _current set ["result", ""];
        _current set ["resourceReservationId", ""];
        _current set ["resourceBudget", 0];
        _current set ["resourceSpent", 0];
        _current set ["resourceReleased", 0];
        _current set ["defenderIntelLevel", "NONE"];
        _current set ["defenderIntelReason", "NO_ACTIVE_OPERATION"];

        [_self, "LULL", [_self, "LULL"] call FLO_fnc_campaignGetPhaseDuration, "INITIATIVE_TRANSFER"] call FLO_fnc_campaignTransition;
    }],

    ["_onObjectiveFlipped", {
        params ["_objectiveId", "_previousOwner", "_newOwner"];

        private _current = _self get "_state";
        if ((_current get "objectiveId") != _objectiveId) exitWith {};

        private _phase = _current get "phase";
        private _attackerSide = [_current get "attackerSideKey"] call FLO_fnc_campaignSideFromKey;

        if (_newOwner isEqualTo _attackerSide && {_phase in ["PREPARE", "ASSAULT"]}) exitWith {
            [_self, "SECURE", [_self, "SECURE"] call FLO_fnc_campaignGetPhaseDuration, "TARGET_CAPTURED"] call FLO_fnc_campaignTransition;
        };

        if (_newOwner isNotEqualTo _attackerSide && {_phase in ["SECURE", "CONSOLIDATE"]}) then {
            _self call ["_completeOperation", ["ATTACKER_FAILED", "TARGET_LOST"]];
        };
    }],

    ["_update", {
        if (!FLO_MissionReady) exitWith {};

        _self set ["_lastUpdateAt", diag_tickTime];
        [_self] call FLO_fnc_campaignCollectOpportunities;
        [_self] call FLO_fnc_campaignProcessIntegrations;
        [_self] call FLO_fnc_campaignUpdateDefenderIntel;

        private _current = _self get "_state";
        private _phase = _current get "phase";
        private _now = dateToNumber date;
        private _deadlineReached = ([_now, _current get "phaseEndsAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0;

        if (_phase == "LULL") exitWith {
            if (_deadlineReached) then { _self call ["_beginOperation", []]; };
        };

        if (_phase == "RECOVERY") exitWith {
            if (_deadlineReached) then { _self call ["_enterLull", []]; };
        };

        private _objectiveId = _current get "objectiveId";
        if !(_objectiveId in FLO_Objectives) exitWith {
            _self call ["_completeOperation", ["NO_TARGET", "TARGET_MISSING"]];
        };

        private _objective = FLO_Objectives get _objectiveId;
        private _attackerSide = [_current get "attackerSideKey"] call FLO_fnc_campaignSideFromKey;
        private _attackerOwnsTarget = (_objective get "owner") isEqualTo _attackerSide;

        switch (_phase) do {
            case "PREPARE": {
                if (_attackerOwnsTarget) then {
                    [_self, "SECURE", [_self, "SECURE"] call FLO_fnc_campaignGetPhaseDuration, "TARGET_CAPTURED_DURING_PREPARE"] call FLO_fnc_campaignTransition;
                } else {
                    if (_deadlineReached) then {
                        [_self, "ASSAULT", [_self, "ASSAULT"] call FLO_fnc_campaignGetPhaseDuration, "PREPARATION_COMPLETE"] call FLO_fnc_campaignTransition;
                    };
                };
            };
            case "ASSAULT": {
                if (_attackerOwnsTarget) then {
                    [_self, "SECURE", [_self, "SECURE"] call FLO_fnc_campaignGetPhaseDuration, "TARGET_CAPTURED"] call FLO_fnc_campaignTransition;
                } else {
                    if (_deadlineReached) then {
                        _self call ["_completeOperation", ["ATTACKER_FAILED", "ASSAULT_TIMEOUT"]];
                    };
                };
            };
            case "SECURE": {
                if (!_attackerOwnsTarget) then {
                    _self call ["_completeOperation", ["ATTACKER_FAILED", "TARGET_LOST_DURING_SECURE"]];
                } else {
                    if (_deadlineReached) then {
                        [_self, "CONSOLIDATE", [_self, "CONSOLIDATE"] call FLO_fnc_campaignGetPhaseDuration, "SECURE_COMPLETE"] call FLO_fnc_campaignTransition;
                    };
                };
            };
            case "CONSOLIDATE": {
                if (!_attackerOwnsTarget) then {
                    _self call ["_completeOperation", ["ATTACKER_FAILED", "TARGET_LOST_DURING_CONSOLIDATION"]];
                } else {
                    if (_deadlineReached) then {
                        [_self, _objectiveId, "OPERATION_COMPLETE"] call FLO_fnc_campaignIntegrateObjective;
                        _self call ["_completeOperation", ["ATTACKER_SUCCESS", "CONSOLIDATION_COMPLETE"]];
                    };
                };
            };
            default {
                throw format ["Campaign director reached unsupported phase '%1'", _phase];
            };
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
        ["CAMPAIGN", 2, format ["Campaign director started (%1s)", _interval]] call FLO_fnc_log;
        true
    }]
]];

if ((keys _savedState) isNotEqualTo [] && {(_savedState get "schemaVersion") < 4}) then {
    private _restoredState = _director get "_state";
    if ((_restoredState get "operationId") != "" && {(_restoredState get "phase") in ["PREPARE", "ASSAULT", "SECURE", "CONSOLIDATE"]}) then {
        [_director] call FLO_fnc_campaignReserveOperationBudget;
    };
};

[_director] call FLO_fnc_campaignValidateOperationBudget;

_director
