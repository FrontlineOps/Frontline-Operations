/* World State owns graph-derived pressure and supply exposure once per decision cycle. */
params ["_commander"];
private _world = _commander get "_worldState";
private _objectives = _world get "_objectives";
private _ownSide = _commander get "_ownSide";
private _enemySide = _commander get "_enemySide";
private _picture = createHashMap;
private _network = FLO_Logistics_Networks get (_commander get "_sideKey");
private _routes = _network get "_supplyRouteInfo";
// A friendly neighbor's enemy links are reused by every objective beside it.
// Rebuild from this cycle's sensed ownership; retain multiplicity and exclude
// the scored objective exactly as the original two-hop traversal did.
private _enemyAdjacency = createHashMap;
[_commander, {
    {
        if ((_y get "owner") != _ownSide) then { continue };
        private _enemyLinks = createHashMap;
        private _total = 0;
        {
            if (((_objectives get _x) get "owner") == _enemySide) then {
                _enemyLinks set [_x, (_enemyLinks getOrDefault [_x, 0]) + 1];
                _total = _total + 1;
            };
        } forEach (_y get "linkedObjectives");
        _enemyAdjacency set [_x, [_total, _enemyLinks]];
    } forEach _objectives;
}] call FLO_fnc_gtnRunCycleStep;
// Keep the new picture private while scoring one objective per atomic step.
private _scoreObjective = {
    params ["_id", "_objective"];
    private _friendlyLinks = 0;
    private _hostileLinks = 0;
    private _exposedFlanks = 0;
    private _sources = [];
    {
        private _neighbor = _objectives get _x;
        if ((_neighbor get "owner") == _ownSide) then {
            _friendlyLinks = _friendlyLinks + 1;
            if (_neighbor get "integrated" && {_x in _routes}) then { _sources pushBack _x };
            private _adjacency = _enemyAdjacency get _x;
            _exposedFlanks = _exposedFlanks + (_adjacency select 0)
                - ((_adjacency select 1) getOrDefault [_id, 0]);
        } else { _hostileLinks = _hostileLinks + 1 };
    } forEach (_objective get "linkedObjectives");
    private _enemy = _objective get "enemyCount";
    private _friendly = _objective get "friendlyCount";
    private _supplyExposure = parseNumber (_friendlyLinks <= 1);
    _objective set ["supplied", _id in _routes];
    if ((_objective get "owner") == _ownSide && {!(_id in _routes)}) then { _supplyExposure = _supplyExposure + 1 };
    private _freshness = if (_objective get "enemyStrengthKnown") then {
        (1 - (((diag_tickTime - (_objective get "enemyIntelTime")) max 0) / 240)) max 0
    } else { 0 };
    private _pressure = ((_enemy max 0) - _friendly) max 0;
    private _value = (_objective get "priority") + (count (_objective get "linkedObjectives") * 3);
    private _threat = _hostileLinks * 4 + _pressure * 2 + (20 * parseNumber (_objective get "underAttack")) + (12 * parseNumber (_objective get "contested"));
    _picture set [_id, createHashMapFromArray [
        ["value", _value], ["threat", _threat], ["pressure", _pressure],
        ["friendlyLinks", _friendlyLinks], ["enemyLinks", _hostileLinks],
        ["exposedFlanks", _exposedFlanks], ["supplyExposure", _supplyExposure],
        ["freshness", _freshness], ["sources", _sources],
        ["defenseScore", _value + _threat + _supplyExposure * 12],
        ["attackScore", _value + _friendlyLinks * 8 + _freshness * 10 - _hostileLinks * 4 - _exposedFlanks * 4 - _supplyExposure * 10 - _pressure]
    ]];
};
{
    [_commander, _scoreObjective, [_x, _y]] call FLO_fnc_gtnRunCycleStep;
} forEach _objectives;
[_commander, {
    _world set ["_strategicPicture", _picture];
    [_world, _commander get "_config"] call FLO_fnc_gtnBuildAirThreatPicture;
}] call FLO_fnc_gtnRunCycleStep;
_picture
