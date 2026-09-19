/* Monitor and execute one intent atomically, including its full bounded track cycle. */
params ["_commander", "_id"];
private _intents = _commander get "_intents";
// A group-removal callback may retire a captured ID between commander steps.
if !(_id in _intents) exitWith { [0, 0, 0, 0, 0] };
private _intent = _intents get _id;
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _world = _commander get "_worldState";
private _reason = "";
private _remaining = [];
private _units = 0;
{
    if !(_x in _groups) then { continue };
    private _group = _groups get _x;
    if ((_group get "commanderIntent") != _id) then { _reason = "FORCE_REASSIGNED"; continue };
    if ((_group get "unitCount") <= 0) then { _group set ["commanderIntent", ""]; continue };
    _remaining pushBack _x;
    _units = _units + (_group get "unitCount");
} forEach (_intent get "groupIds");
_intent set ["groupIds", _remaining];
_intent set ["issued", (_intent get "issued") arrayIntersect _remaining];
if ((_intent get "initialUnits") > 0 && {_units < ((_intent get "initialUnits") * (1 - ((_commander get "_config") get "intentWithdrawalLossFraction")))}) then { _reason = "FORCE_LOSSES" };
// This read-only ownership check needs no detached prediction or force-readiness scan.
private _state = createHashMapFromArray [
    ["intent", _intent], ["objectives", _world get "_objectives"], ["ownSide", _world get "_ownSide"]
];
if !([_state, [_id]] call FLO_fnc_gtnIntentGoalValid) then { _reason = "OBJECTIVE_OR_SUPPLY_LOST" };
private _phaseLimit = [1800, 3600] select ((_intent get "phase") == "SECURE");
if (diag_tickTime - (_intent get "phaseStartedAt") > _phaseLimit) then { _reason = "PHASE_TIMEOUT" };
if (_reason != "") exitWith {
    [_commander, _intent, false, _reason] call FLO_fnc_gtnRetireIntent;
    [0, 0, 1, 0, 0]
};
private _tracks = _commander get "_tracks";
private _track = _tracks select (_tracks findIf { (_x get "id") == _id });
private _objective = (_world get "_objectives") get (_intent get "objectiveId");
if ((_intent get "kind") == "CAPTURE" && {(_objective get "owner") == (_commander get "_ownSide")}
    && {!((_intent get "phase") in ["SECURE", "COMPLETE"])}) then {
    (_track get "planner") call ["_cancel", [_commander get "_executor", "OBJECTIVE_CAPTURED"]];
    _intent set ["issued", []];
    [_commander, _intent, "SECURE"] call FLO_fnc_gtnSetIntentPhase;
    _track set ["status", "IDLE"];
    _track set ["retryAt", -1];
};
private _metrics = [_commander, _track] call FLO_fnc_gtnExecuteTrackCycle;
private _planMs = _metrics get "planMs";
private _executeMs = (_metrics get "primitiveExecMs") + (_metrics get "checkMs");
private _completed = 0;
private _failed = 0;
if ((_metrics get "plansFailed") > 0) then {
    [_commander, _intent, false, (_track get "planner") get "_failureReason"] call FLO_fnc_gtnRetireIntent;
    _failed = 1;
} else {
    if ((_track get "status") == "COMPLETE") then {
        [_commander, _intent, true, "GOAL_SATISFIED"] call FLO_fnc_gtnRetireIntent;
        _completed = 1;
    };
};
[1, _completed, _failed, _planMs, _executeMs]
