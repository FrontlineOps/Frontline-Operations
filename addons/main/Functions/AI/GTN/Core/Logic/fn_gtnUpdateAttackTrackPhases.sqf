/*
 * Function: FLO_fnc_gtnUpdateAttackTrackPhases
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Maintains a simple phase state machine for attack tracks so offensives
 *   happen in bursts instead of every commander cycle. Tracks cycle through
 *   quiet, staging, assault, and spent.
 *
 * Arguments:
 *   0: GTN Commander <HASHMAP>
 *
 * Return Value:
 *   Metrics <HASHMAP>
 */

params [["_cmdr", nil]];

private _metrics = createHashMapFromArray [
    ["trackCount", 0],
    ["quietCount", 0],
    ["stagingCount", 0],
    ["assaultCount", 0],
    ["spentCount", 0],
    ["transitionCount", 0],
    ["selectedObjectiveCount", 0],
    ["currentTotalGroups", 0],
    ["baselineTotalGroups", 0],
    ["theaterStrengthRatio", 1],
    ["posture", "normal"]
];

if (isNil "_cmdr") exitWith { _metrics };

private _tracks = (_cmdr get "_tracks") select { (_x get "goal") == "capture_priority_objective" };
_metrics set ["trackCount", count _tracks];
if (_tracks isEqualTo []) exitWith { _metrics };

private _ws = _cmdr get "_worldState";
private _frontlineEnemyObjectives = _cmdr call ["_getAttackFrontlineEnemyObjectives", []];
private _now = diag_tickTime;
private _config = _cmdr get "_config";
private _minStageGroups = _config get "attackLaneStagingMinGroups";
private _stageGoalFraction = _config get "attackLaneStagingGoalFraction";
private _cautiousStrengthRatio = _config get "attackLaneCautiousStrengthRatio";
private _exhaustedStrengthRatio = _config get "attackLaneExhaustedStrengthRatio";
private _cautiousGoalMultiplier = _config get "attackLaneCautiousGoalMultiplier";
private _timeoutAssaultFraction = _config get "attackLaneTimeoutAssaultFraction";
private _maxStageSeconds = _config get "attackLaneMaxStagingSeconds";
private _assaultSeconds = _config get "attackLaneAssaultDurationSeconds";
private _spentBaseSeconds = _config get "attackLaneSpentDurationSeconds";
private _forces = _ws call ["_getForces", []];
private _currentTotalGroups = _forces get "totalGroups";
private _baselineTotalGroups = _cmdr get "_forceBaselineTotalGroups";

if (_baselineTotalGroups <= 0 && _currentTotalGroups > 0) then {
    _baselineTotalGroups = _currentTotalGroups;
    _cmdr set ["_forceBaselineTotalGroups", _baselineTotalGroups];
};

private _theaterStrengthRatio = if (_baselineTotalGroups > 0) then {
    _currentTotalGroups / _baselineTotalGroups
} else {
    1
};

private _posture = "normal";
if (_theaterStrengthRatio < _exhaustedStrengthRatio) then {
    _posture = "exhausted";
} else {
    if (_theaterStrengthRatio < _cautiousStrengthRatio) then {
        _posture = "cautious";
    };
};

_metrics set ["currentTotalGroups", _currentTotalGroups];
_metrics set ["baselineTotalGroups", _baselineTotalGroups];
_metrics set ["theaterStrengthRatio", _theaterStrengthRatio];
_metrics set ["posture", _posture];

private _setPhase = {
    params ["_track", "_phase", "_phaseUntil", "_phaseObjectiveId", "_phaseStagingGoal"];

    _track set ["phase", _phase];
    _track set ["phaseChangedAt", _now];
    _track set ["phaseUntil", _phaseUntil];
    _track set ["phaseObjectiveId", _phaseObjectiveId];
    _track set ["phaseStagingGoal", _phaseStagingGoal];
    _metrics set ["transitionCount", (_metrics get "transitionCount") + 1];
};

{
    private _track = _x;
    private _trackId = _track get "id";
    private _phase = _track get "phase";
    private _phaseUntil = _track get "phaseUntil";
    private _phaseObjectiveId = _track get "phaseObjectiveId";
    private _poolCount = count (_track get "groupPool");

    if (_phase == "spent") then {
        if (_now >= _phaseUntil) then {
            [_track, "quiet", 0, "", 0] call _setPhase;
            _phase = "quiet";
            _phaseObjectiveId = "";
        };

        private _phaseCountKey = format ["%1Count", _phase];
        _metrics set [_phaseCountKey, (_metrics get _phaseCountKey) + 1];

        ["GTN", 3, format [
            "Track %1 phase=%2 objective=%3 pool=%4 staged=%5 posture=%6 strength=%7",
            _trackId,
            _phase,
            _phaseObjectiveId,
            _poolCount,
            _track get "phaseStagingGoal",
            _posture,
            _theaterStrengthRatio toFixed 2
        ]] call FLO_fnc_log;

        continue;
    };

    if (_phaseObjectiveId != "" && !(_phaseObjectiveId in _frontlineEnemyObjectives)) then {
        _phaseObjectiveId = "";
        _track set ["phaseObjectiveId", ""];
        _track set ["phaseStagingGoal", 0];
    };

    if (_phaseObjectiveId == "" && _phase != "spent") then {
        _phaseObjectiveId = _cmdr call ["_selectPriorityObjective", [_trackId]];
        _track set ["phaseObjectiveId", _phaseObjectiveId];
        if (_phaseObjectiveId != "") then {
            _metrics set ["selectedObjectiveCount", (_metrics get "selectedObjectiveCount") + 1];
        };
    };

    if (_phaseObjectiveId == "") then {
        if (_phase != "quiet") then {
            [_track, "quiet", 0, "", 0] call _setPhase;
        };

        _metrics set ["quietCount", (_metrics get "quietCount") + 1];
        continue;
    };

    private _attackCap = _cmdr call ["_getAttackCapForObjective", [_phaseObjectiveId]];
    private _pressureProfile = [_cmdr, _phaseObjectiveId] call FLO_fnc_gtnGetAttackPressureProfile;
    private _activeAttackers = _cmdr call ["_countObjectiveAttackers", [_phaseObjectiveId]];
    private _slotsRemaining = (_attackCap - _activeAttackers) max 0;
    private _maxRelevantSlots = _slotsRemaining max 1;
    private _scaledStagingGoal = ceil(_maxRelevantSlots * _stageGoalFraction);
    private _stagingGoal = (_scaledStagingGoal max _minStageGroups) min _maxRelevantSlots;
    if (_posture == "cautious") then {
        _stagingGoal = ((ceil(_stagingGoal * _cautiousGoalMultiplier)) max 1) min _maxRelevantSlots;
    };
    _stagingGoal = ((ceil(_stagingGoal * (_pressureProfile get "stagingGoalMultiplier"))) max 1) min _maxRelevantSlots;
    private _timeoutAssaultAllowed = _posture == "normal";
    private _timeoutAssaultGoal = if (_timeoutAssaultAllowed) then {
        ((ceil(_stagingGoal * _timeoutAssaultFraction)) max 1) min _stagingGoal
    } else {
        -1
    };
    private _spentSeconds = _spentBaseSeconds + (_pressureProfile get "spentSecondsBonus");
    _track set ["phaseStagingGoal", _stagingGoal];

    switch (_phase) do {
        case "quiet": {
            if (_posture != "exhausted" && {_slotsRemaining > 0} && {_poolCount > 0}) then {
                [_track, "staging", _now + _maxStageSeconds, _phaseObjectiveId, _stagingGoal] call _setPhase;
                _phase = "staging";
            };
        };
        case "staging": {
            if (_slotsRemaining <= 0) then {
                [_track, "quiet", 0, "", 0] call _setPhase;
                _phase = "quiet";
                _phaseObjectiveId = "";
            } else {
                if (_posture == "exhausted") then {
                    [_track, "quiet", 0, "", 0] call _setPhase;
                    _phase = "quiet";
                    _phaseObjectiveId = "";
                } else {
                    if (_poolCount >= _stagingGoal) then {
                        [_track, "assault", _now + _assaultSeconds, _phaseObjectiveId, _stagingGoal] call _setPhase;
                        _phase = "assault";
                    } else {
                        if (_timeoutAssaultAllowed && {_now >= _phaseUntil && _poolCount >= _timeoutAssaultGoal}) then {
                            [_track, "assault", _now + _assaultSeconds, _phaseObjectiveId, _stagingGoal] call _setPhase;
                            _phase = "assault";
                        } else {
                            if (_now >= _phaseUntil) then {
                                [_track, "quiet", 0, "", 0] call _setPhase;
                                _phase = "quiet";
                                _phaseObjectiveId = "";
                            };
                        };
                    };
                };
            };
        };
        case "assault": {
            if (_now >= _phaseUntil || {_slotsRemaining <= 0 && _poolCount == 0}) then {
                [_track, "spent", _now + _spentSeconds, _phaseObjectiveId, _stagingGoal] call _setPhase;
                _phase = "spent";
            };
        };
        default {
            [_track, "quiet", 0, "", 0] call _setPhase;
            _phase = "quiet";
            _phaseObjectiveId = "";
        };
    };

    private _phaseCountKey = format ["%1Count", _phase];
    _metrics set [_phaseCountKey, (_metrics get _phaseCountKey) + 1];

    ["GTN", 3, format [
        "Track %1 phase=%2 objective=%3 pool=%4 staged=%5 timeoutGoal=%6 active=%7 cap=%8 posture=%9 strength=%10 streak=%11 overext=%12",
        _trackId,
        _phase,
        _phaseObjectiveId,
        _poolCount,
        _track get "phaseStagingGoal",
        _timeoutAssaultGoal,
        _activeAttackers,
        _attackCap,
        _posture,
        _theaterStrengthRatio toFixed 2,
        _pressureProfile get "captureStreakSteps",
        _pressureProfile get "overextensionSteps"
    ]] call FLO_fnc_log;
} forEach _tracks;

_metrics
