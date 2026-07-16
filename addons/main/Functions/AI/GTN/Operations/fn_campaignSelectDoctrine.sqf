/* Selects an operation doctrine from maintained objective and treasury state. */
params [["_operation", createHashMap, [createHashMap]]];

private _sideKey = _operation get "attackerSideKey";
private _side = [_sideKey] call FLO_fnc_campaignSideFromKey;
private _target = FLO_Objectives get (_operation get "objectiveId");

private _threatenedSource = false;
{
    private _source = FLO_Objectives get _x;
    if ((_source get "owner") isEqualTo _side && {(_source get "underAttack") || {_source get "contested"}}) exitWith {
        _threatenedSource = true;
    };
} forEach (_operation get "sourceObjectiveIds");

private _available = (FLO_SideResources get _sideKey) call ["getAvailable", []];
private _doctrine = "ECONOMY_OF_FORCE";
if (_threatenedSource) then {
    _doctrine = "COUNTERATTACK";
} else {
    if (_available >= 1000 && {(_target get "priority") >= 40}) then {
        _doctrine = "BREAKTHROUGH";
    };
};

["CAMPAIGN", 4, format [
    "Operation %1 selected doctrine=%2 threatenedSource=%3 available=%4 targetPriority=%5",
    _operation get "operationId",
    _doctrine,
    _threatenedSource,
    round _available,
    _target get "priority"
]] call FLO_fnc_log;
_doctrine
