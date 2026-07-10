/*
 * Function: FLO_fnc_gtnUpdateAttackTrackPhases
 * Author: Frontline Operations Development Group
 *
 * Description:
 *   Projects the theater director's active operation onto commander attack
 *   tracks. The director is the only owner of attack phase and target state.
 *
 * Arguments:
 *   0: GTN Commander <HASHMAP>
 *
 * Return Value:
 *   Metrics <HASHMAP>
 */

params ["_cmdr"];

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

private _director = _cmdr get "_campaignDirector";
if (isNil "_director") then {
    throw "FLO_fnc_gtnUpdateAttackTrackPhases: commander has no campaign director";
};

private _tracks = (_cmdr get "_tracks") select { (_x get "goal") == "capture_priority_objective" };
_metrics set ["trackCount", count _tracks];
if (_tracks isEqualTo []) exitWith { _metrics };

private _state = _director call ["_getState", []];
private _campaignPhase = _state get "phase";
private _operationId = _state get "operationId";
private _objectiveId = _state get "objectiveId";
private _isAttacker = (_state get "attackerSideKey") == (_cmdr get "_sideKey");
private _desiredPhase = "quiet";
private _desiredObjectiveId = "";

if (_isAttacker && {_operationId != ""} && {_objectiveId != ""}) then {
    switch (_campaignPhase) do {
        case "PREPARE": {
            _desiredPhase = "staging";
            _desiredObjectiveId = _objectiveId;
        };
        case "ASSAULT": {
            _desiredPhase = "assault";
            _desiredObjectiveId = _objectiveId;
        };
        case "SECURE";
        case "CONSOLIDATE";
        case "RECOVERY": {
            _desiredPhase = "spent";
            _desiredObjectiveId = _objectiveId;
        };
    };
};

{
    private _track = _x;
    private _oldPhase = _track get "phase";
    private _oldObjectiveId = _track get "phaseObjectiveId";

    if (_oldPhase != _desiredPhase || {_oldObjectiveId != _desiredObjectiveId}) then {
        _track set ["phase", _desiredPhase];
        _track set ["phaseChangedAt", diag_tickTime];
        _track set ["phaseUntil", 0];
        _track set ["phaseObjectiveId", _desiredObjectiveId];
        _track set ["phaseStagingGoal", 0];
        _metrics set ["transitionCount", (_metrics get "transitionCount") + 1];
    };

    private _countKey = format ["%1Count", _desiredPhase];
    _metrics set [_countKey, (_metrics get _countKey) + 1];
    if (_desiredObjectiveId != "") then {
        _metrics set ["selectedObjectiveCount", (_metrics get "selectedObjectiveCount") + 1];
    };
} forEach _tracks;

_metrics
