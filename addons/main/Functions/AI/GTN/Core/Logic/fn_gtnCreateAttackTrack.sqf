/* Creates one fully initialized runtime attack track for an exact operation. */
params [
    ["_cmdr", nil],
    ["_operationId", "", [""]]
];

if (isNil "_cmdr" || {_operationId == ""}) then {
    throw "Attack-track creation requires commander and operation ID";
};
private _director = _cmdr get "_campaignDirector";
if (isNil "_director") then {
    throw format ["Attack track %1 has no campaign director", _operationId];
};
private _operations = (_director call ["_getState", []]) get "operations";
if !(_operationId in _operations) then {
    throw format ["Cannot create attack track for missing operation %1", _operationId];
};
private _operation = _operations get _operationId;
if ((_operation get "attackerSideKey") != (_cmdr get "_sideKey")) then {
    throw format ["Operation %1 belongs to %2, not commander %3", _operationId, _operation get "attackerSideKey", _cmdr get "_sideKey"];
};

private _phase = switch (_operation get "phase") do {
    case "ASSAULT": { "assault" };
    default { "spent" };
};
createHashMapFromArray [
    ["id", format ["ATK_%1", _operationId]],
    ["goal", "capture_priority_objective"],
    ["resourceShare", 0],
    ["planner", [(_cmdr get "_goalLibrary"), (_cmdr get "_worldState")] call FLO_fnc_gtnPlanner],
    ["status", "IDLE"],
    ["groupPool", []],
    ["frontSectorObjectives", []],
    ["frontSectorAnchorPos", []],
    ["phase", _phase],
    ["phaseChangedAt", diag_tickTime],
    ["phaseUntil", 0],
    ["phaseOperationId", _operationId],
    ["phaseObjectiveId", _operation get "objectiveId"],
    ["phaseRole", _operation get "priorityRole"]
]
