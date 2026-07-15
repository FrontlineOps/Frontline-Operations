/* Evaluates and advances one persistent probe front from maintained evidence. */
params [
    "_director",
    "_cmdr",
    ["_front", createHashMap, [createHashMap]],
    ["_support", createHashMap, [createHashMap]],
    ["_commitAllowed", false, [true]],
    ["_selectionDiagnostics", createHashMap, [createHashMap]]
];

private _metrics = createHashMapFromArray [
    ["changed", false],
    ["committed", false],
    ["selectionAttempted", false],
    ["activeGroups", 0],
    ["activeUnits", 0],
    ["combatEffectiveness", 0],
    ["madeProgress", false],
    ["usefulContact", false],
    ["stage", _front get "stage"]
];
private _config = _director get "_config";
private _now = call FLO_fnc_operationalDateNumber;
private _stage = _front get "stage";
private _actionDue = ([_now, _front get "nextActionAtDateNum"] call FLO_fnc_dateNumberDeltaSeconds) <= 0;

if (_stage == "ASSAULT" && {(_front get "formalOperationId") != ""}) exitWith { _metrics };

if (_stage == "REGROUP") exitWith {
    if (_commitAllowed && {_actionDue}) then {
        _metrics set ["selectionAttempted", true];
        private _selection = [_director, _cmdr, _front, _selectionDiagnostics] call FLO_fnc_campaignSelectProbeFormation;
        if ((keys _selection) isNotEqualTo []) then {
            if ([_director, _cmdr, _front, _selection, false] call FLO_fnc_campaignCommitProbeFormation) then {
                _front set ["contactSamples", 0];
                _front set ["progressSamples", 0];
                _front set ["stalledSamples", 0];
                _front set ["reinforcementProgressCheckpoint", 0];
                _front set ["supportProgressCheckpoint", 0];
                [_front, "PROBE", "FORMATIONS_RECONSTITUTED"] call FLO_fnc_campaignSetProbeStage;
                _metrics set ["changed", true];
                _metrics set ["committed", true];
                _metrics set ["stage", "PROBE"];
            };
        };
    };
    _metrics
};

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _objectiveId = _front get "objectiveId";
private _objective = ((_cmdr get "_worldState") call ["_getObjectives", []]) get _objectiveId;
private _targetPos = _objective get "position";
private _targetRadius = _objective get "radius";
private _assignmentId = _front get "formalOperationId";
if (_assignmentId == "") then { _assignmentId = _front get "probeId"; };
private _activeGroupIds = [];
private _activeUnits = 0;
private _nearestDistance = 1e12;
private _arrivedCount = 0;

{
    private _groupId = _x;
    if !(_groupId in _groups) then { continue };
    private _groupData = _groups get _groupId;
    if ((_groupData get "unitCount") <= 0) then { continue };
    if ((_groupData get "commanderOrder") != "ATTACK") then { continue };
    if ((_groupData get "campaignOperationId") != _assignmentId) then { continue };
    if ((_groupData get "attackObjective") != _objectiveId) then { continue };
    _activeGroupIds pushBack _groupId;
    _activeUnits = _activeUnits + (_groupData get "unitCount");
    private _distance = (_groupData get "position") distance2D _targetPos;
    _nearestDistance = _nearestDistance min _distance;
    if (_distance <= _targetRadius) then { _arrivedCount = _arrivedCount + 1; };
} forEach (_front get "committedGroupIds");

private _activeCount = count _activeGroupIds;
_metrics set ["activeGroups", _activeCount];
_metrics set ["activeUnits", _activeUnits];

if ((_front get "committedGroupIds") isEqualTo []) exitWith {
    if (_stage != "PROBE") then {
        [_director, _cmdr, _front, "PROBE_FORCE_RELEASED"] call FLO_fnc_campaignReleaseProbeFront;
        _metrics set ["changed", true];
        _metrics set ["stage", "REGROUP"];
    } else {
        if (_commitAllowed && {_actionDue}) then {
            _metrics set ["selectionAttempted", true];
            private _selection = [_director, _cmdr, _front, _selectionDiagnostics] call FLO_fnc_campaignSelectProbeFormation;
            if ([_director, _cmdr, _front, _selection, false] call FLO_fnc_campaignCommitProbeFormation) then {
                _metrics set ["changed", true];
                _metrics set ["committed", true];
            };
        };
    };
    _metrics
};

if (_activeCount == 0) exitWith {
    [_director, _cmdr, _front, "PROBE_FORCE_DESTROYED"] call FLO_fnc_campaignReleaseProbeFront;
    _metrics set ["changed", true];
    _metrics set ["stage", "REGROUP"];
    _metrics
};

private _baseline = _front get "committedUnitBaseline";
if (_baseline <= 0) then {
    throw format ["Probe front %1 has active groups without a unit baseline", _front get "probeId"];
};
private _combatEffectiveness = _activeUnits / _baseline;
_metrics set ["combatEffectiveness", _combatEffectiveness];

private _defenderCount = _objective get "enemyCount";
private _contested = _objective get "contested";
private _madeProgress = false;
if (_nearestDistance <= ((_front get "bestDistance") - (_config get "probeProgressDistanceMeters"))) then {
    _madeProgress = true;
};
if (_arrivedCount > (_front get "lastArrivedCount")) then { _madeProgress = true; };
if ((_front get "lastEnemyCount") >= 0 && {_defenderCount < (_front get "lastEnemyCount")}) then {
    _madeProgress = true;
};
if (_contested && {!(_front get "lastContested")}) then { _madeProgress = true; };

private _usefulContact = (_support get "reportCount") > 0
    && {(_support get "confidence") >= (_config get "probeMinimumContactConfidence")};
private _contactAt = _support get "newestContactTime";
private _newUsefulContact = _usefulContact && {_contactAt > (_front get "lastContactAt")};
if (_newUsefulContact) then {
    _front set ["contactSamples", (_front get "contactSamples") + 1];
    _front set ["lastContactAt", _contactAt];
};
if (_madeProgress) then {
    _front set ["progressSamples", (_front get "progressSamples") + 1];
    _front set ["stalledSamples", 0];
} else {
    _front set ["stalledSamples", (_front get "stalledSamples") + 1];
};
_front set ["bestDistance", (_front get "bestDistance") min _nearestDistance];
_front set ["lastEnemyCount", _defenderCount];
_front set ["lastActiveGroupCount", _activeCount];
_front set ["lastUnitCount", _activeUnits];
_front set ["lastArrivedCount", _arrivedCount];
_front set ["lastContested", _contested];
_front set ["lastContactCount", _support get "reportCount"];
_front set ["lastEvaluatedAtDateNum", _now];
_metrics set ["madeProgress", _madeProgress];
_metrics set ["usefulContact", _usefulContact];
_metrics set ["changed", true];

if (_combatEffectiveness < (_config get "probeMinimumCombatEffectiveness")) exitWith {
    [_director, _cmdr, _front, "COMBAT_INEFFECTIVE"] call FLO_fnc_campaignReleaseProbeFront;
    _metrics set ["stage", "REGROUP"];
    _metrics
};

private _stallThreshold = _config get "probeStalledSampleThreshold";
switch (_stage) do {
    case "PROBE": {
        if (_usefulContact) then {
            [_front, "DEVELOP_CONTACT", "USEFUL_CONTACT_ESTABLISHED"] call FLO_fnc_campaignSetProbeStage;
        } else {
            if ((_front get "stalledSamples") >= _stallThreshold) then {
                [_front, "STALLED", "PROBE_AXIS_NOT_ADVANCING"] call FLO_fnc_campaignSetProbeStage;
            };
        };
    };

    case "DEVELOP_CONTACT": {
        if (
            (_front get "contactSamples") >= (_config get "probeContactSamplesForReinforcement")
            && {(_front get "progressSamples") > 0}
        ) then {
            [_front, "REINFORCE_SUCCESS", "CONTACT_DEVELOPED"] call FLO_fnc_campaignSetProbeStage;
        } else {
            if ((_front get "stalledSamples") >= _stallThreshold) then {
                [_front, "STALLED", "CONTACT_NOT_DEVELOPING"] call FLO_fnc_campaignSetProbeStage;
            };
        };
    };

    case "REINFORCE_SUCCESS": {
        private _assaultMassReady = _activeCount >= (_config get "probeAssaultMinimumGroups");
        private _reinforcementAvailable =
            (_front get "reinforcementCount") < (_config get "probeMaximumReinforcementFormations");

        if (_assaultMassReady) then {
            _front set ["supportProgressCheckpoint", _front get "progressSamples"];
            _front set ["evaluatedSupportMissionCount", _front get "supportMissionCount"];
            [_front, "COMMIT_SUPPORT", "ASSAULT_MASS_ESTABLISHED"] call FLO_fnc_campaignSetProbeStage;
        } else {
            if (!_reinforcementAvailable) then {
                [_director, _cmdr, _front, "REINFORCEMENT_CAP_BELOW_ASSAULT_MASS"] call FLO_fnc_campaignReleaseProbeFront;
            } else {
                if (_commitAllowed && {_actionDue}) then {
                    _metrics set ["selectionAttempted", true];
                    private _selection = [_director, _cmdr, _front, _selectionDiagnostics] call FLO_fnc_campaignSelectProbeFormation;
                    private _selectionFailed = !([_director, _cmdr, _front, _selection, true] call FLO_fnc_campaignCommitProbeFormation);
                    if (_selectionFailed) then {
                        private _concentration = createHashMapFromArray [
                            ["movedFormationCount", 0],
                            ["movedGroupCount", 0],
                            ["donorProbeIds", []],
                            ["assaultMassReady", false]
                        ];
                        if ((keys _selection) isEqualTo []) then {
                            _concentration = [
                                _director,
                                _cmdr,
                                _front,
                                _activeCount,
                                _selectionDiagnostics
                            ] call FLO_fnc_campaignConcentrateProbeMass;
                        };
                        if ((_concentration get "movedFormationCount") > 0) then {
                            _front set ["reinforcementProgressCheckpoint", _front get "progressSamples"];
                            _metrics set ["changed", true];
                            _metrics set ["committed", true];
                            if (_concentration get "assaultMassReady") then {
                                _front set ["supportProgressCheckpoint", _front get "progressSamples"];
                                _front set ["evaluatedSupportMissionCount", _front get "supportMissionCount"];
                                [_front, "COMMIT_SUPPORT", "ASSAULT_MASS_CONCENTRATED"] call FLO_fnc_campaignSetProbeStage;
                            };
                        } else {
                            [_front, "STALLED", "REINFORCEMENT_UNAVAILABLE"] call FLO_fnc_campaignSetProbeStage;
                        };
                    } else {
                        _front set ["reinforcementProgressCheckpoint", _front get "progressSamples"];
                        _metrics set ["committed", true];
                    };
                };
            };
        };
    };

    case "COMMIT_SUPPORT": {
        private _newSupport = (_front get "supportMissionCount") > (_front get "evaluatedSupportMissionCount");
        if (
            _newSupport
            && {_usefulContact}
            && {_front get "progressSamples" > (_front get "supportProgressCheckpoint")}
            && {_activeCount >= (_config get "probeAssaultMinimumGroups")}
        ) then {
            _front set ["evaluatedSupportMissionCount", _front get "supportMissionCount"];
            [_front, "ASSAULT", "SUPPORTED_ADVANCE_CONFIRMED"] call FLO_fnc_campaignSetProbeStage;
        } else {
            if ((_front get "stalledSamples") >= _stallThreshold) then {
                if (_newSupport) then {
                    _front set ["evaluatedSupportMissionCount", _front get "supportMissionCount"];
                };
                [_front, "STALLED", "SUPPORT_COMMITMENT_NOT_EXPLOITED"] call FLO_fnc_campaignSetProbeStage;
            };
        };
    };

    case "STALLED": {
        if (_usefulContact) then {
            _front set ["supportProgressCheckpoint", _front get "progressSamples"];
            _front set ["evaluatedSupportMissionCount", _front get "supportMissionCount"];
            [_front, "SUPPORT", "STALLED_WITH_TARGETABLE_CONTACT"] call FLO_fnc_campaignSetProbeStage;
        } else {
            [_front, "SHIFT_AXIS", "STALLED_WITHOUT_TARGETABLE_CONTACT"] call FLO_fnc_campaignSetProbeStage;
        };
    };

    case "SUPPORT": {
        private _newSupport = (_front get "supportMissionCount") > (_front get "evaluatedSupportMissionCount");
        if (_newSupport && {_front get "progressSamples" > (_front get "supportProgressCheckpoint")}) then {
            _front set ["evaluatedSupportMissionCount", _front get "supportMissionCount"];
            [_front, "DEVELOP_CONTACT", "SUPPORT_RESTORED_MOMENTUM"] call FLO_fnc_campaignSetProbeStage;
        } else {
            if ((_front get "stalledSamples") >= (_config get "probeSupportFailureSampleThreshold")) then {
                if (_newSupport) then {
                    _front set ["evaluatedSupportMissionCount", _front get "supportMissionCount"];
                };
                [_front, "SHIFT_AXIS", "SUPPORT_FAILED_TO_RESTORE_MOMENTUM"] call FLO_fnc_campaignSetProbeStage;
            };
        };
    };

    case "SHIFT_AXIS": {
        private _sources = +(_front get "sourceObjectiveIds");
        _sources sort true;
        private _currentIndex = _sources find (_front get "primarySourceObjectiveId");
        private _nextSource = "";
        if ((count _sources) > 1) then {
            _nextSource = _sources select ((_currentIndex + 1) mod (count _sources));
        };
        if (_nextSource != "" && {[_director, _cmdr, _front, _nextSource] call FLO_fnc_campaignRerouteProbeFront}) then {
            _front set ["contactSamples", 0];
            [_front, "PROBE", "ALTERNATE_AXIS_ESTABLISHED"] call FLO_fnc_campaignSetProbeStage;
        } else {
            [_director, _cmdr, _front, "NO_ALTERNATE_AXIS"] call FLO_fnc_campaignReleaseProbeFront;
        };
    };

    case "ASSAULT": {
        if (_activeCount < (_config get "probeAssaultMinimumGroups")) then {
            [_front, "STALLED", "ASSAULT_MASS_ERODED_BEFORE_ADOPTION"] call FLO_fnc_campaignSetProbeStage;
        };
    };
    default {
        throw format ["Probe front %1 reached unsupported evaluation stage %2", _front get "probeId", _stage];
    };
};

[_front get "probeId", _front] call FLO_fnc_campaignValidateProbeFrontState;
_metrics set ["stage", _front get "stage"];
_metrics
