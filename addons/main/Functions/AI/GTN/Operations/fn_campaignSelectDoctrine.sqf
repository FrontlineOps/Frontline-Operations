/* Selects an operation doctrine from maintained task-force and objective state. */
params [
    ["_operation", createHashMap, [createHashMap]],
    ["_front", createHashMap, [createHashMap]]
];

private _sideKey = _operation get "attackerSideKey";
private _side = [_sideKey] call FLO_fnc_campaignSideFromKey;
private _target = FLO_Objectives get (_operation get "objectiveId");
private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _committedCount = 0;
private _experienceTotal = 0;
{
    if !(_x in _groups) then { continue };
    private _groupData = _groups get _x;
    if ((_groupData get "unitCount") <= 0) then { continue };
    _committedCount = _committedCount + 1;
    _experienceTotal = _experienceTotal + (_groupData get "combatExperience");
} forEach (_front get "committedGroupIds");
if (_committedCount <= 0) then {
    private _message = format ["Cannot select doctrine for operation %1 without a task force", _operation get "operationId"];
    ["CAMPAIGN", 1, _message] call FLO_fnc_log;
    throw _message;
};

private _threatenedSource = false;
{
    private _source = FLO_Objectives get _x;
    if ((_source get "owner") isEqualTo _side && {(_source get "underAttack") || {_source get "contested"}}) exitWith {
        _threatenedSource = true;
    };
} forEach (_operation get "sourceObjectiveIds");

private _available = (FLO_SideResources get _sideKey) call ["getAvailable", []];
private _averageExperience = _experienceTotal / _committedCount;
private _doctrine = "ECONOMY_OF_FORCE";
if (_threatenedSource) then {
    _doctrine = "COUNTERATTACK";
} else {
    if (
        _available >= 1000
        && {_committedCount >= 8}
        && {_averageExperience >= 20}
        && {(_target get "priority") >= 40}
    ) then {
        _doctrine = "BREAKTHROUGH";
    };
};

["CAMPAIGN", 4, format [
    "Operation %1 selected doctrine=%2 groups=%3 averageExperience=%4 threatenedSource=%5 available=%6",
    _operation get "operationId",
    _doctrine,
    _committedCount,
    round _averageExperience,
    _threatenedSource,
    round _available
]] call FLO_fnc_log;
_doctrine
