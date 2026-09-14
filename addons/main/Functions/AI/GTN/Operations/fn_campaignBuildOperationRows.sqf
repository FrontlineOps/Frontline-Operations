/* Publish own intent progress. Enemy plans and unsensed registry counts are private. */
params ["_commander"];
private _ranked = [];
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _world = _commander get "_worldState";
private _objectives = _world get "_objectives";
{
    private _intent = _y;
    private _phase = _intent get "phase";
    if (_phase == "COMPLETE") then { continue };
    private _kind = _intent get "kind";
    private _objectiveId = _intent get "objectiveId";
    private _objective = _objectives get _objectiveId;
    private _ids = _intent get "groupIds";
    private _atStage = 0;
    private _inTransit = 0;
    private _inCombat = 0;
    {
        private _group = _groups get _x;
        if ((_group get "attachedTo") != "" || {(_group get "mountedIn") != ""}) then {
            _inTransit = _inTransit + 1;
        } else {
            if ((_group get "position") distance2D (_intent get "stagePos") <= 180) then { _atStage = _atStage + 1 };
        };
        if (_group get "inCombat") then { _inCombat = _inCombat + 1 };
    } forEach _ids;
    private _role = _phase;
    private _status = switch (_phase) do {
        case "MUSTER": { "Assigning movement orders to the task force" };
        case "ASSEMBLE": { format ["%1 of %2 groups at the assembly area", _atStage, count _ids] };
        case "SCOUT": { "Reconnaissance is checking resistance before the assault" };
        case "ASSAULT": { "Preparing coordinated assault orders" };
        case "SECURE": {
            if ((_objective get "owner") == (_commander get "_ownSide")) then {
                _role = "HOLDING";
                "Holding captured territory until integration completes"
            } else {
                _role = "ATTACKING";
                "Task force advancing on and fighting for the objective"
            }
        };
        case "DISPATCH": { "Assigning the defending force" };
        case "ARRIVE": { "Defenders moving into position" };
        case "REQUEST": { "Coordinating support availability and authorization" };
        default { throw format ["CAMPAIGN unknown intent phase %1 for %2", _phase, _x] };
    };
    _ranked pushBack [
        parseNumber (_kind != "CAPTURE"), -(_intent get "score"), _x,
        createHashMapFromArray [
            ["id", _x], ["kind", _kind], ["phase", _phase], ["role", _role],
            ["status", _status], ["phaseSeconds", (diag_tickTime - (_intent get "phaseStartedAt")) max 0],
            ["isPrimary", false], ["targetVisible", true], ["targetId", _objectiveId],
            ["targetName", [_objectiveId] call FLO_fnc_campaignObjectiveName],
            ["stageId", _intent get "stageObjective"],
            ["stageName", [_intent get "stageObjective"] call FLO_fnc_campaignObjectiveName],
            ["attackerCount", count _ids], ["readyGroups", _atStage],
            ["transportedGroups", _inTransit], ["engagedGroups", _inCombat]
        ]
    ];
} forEach (_commander get "_intents");
_ranked sort true;
_ranked apply { _x select 3 }
