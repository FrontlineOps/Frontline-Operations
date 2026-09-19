/* Rank reserves by source pressure, graph connection and role before transit cost. */
params ["_commander", "_kind", "_objectiveId", "_stageId"];
private _world = _commander get "_worldState";
private _facts = _world get "_ownGroupFacts";
private _picture = _world get "_strategicPicture";
private _objectives = _world get "_objectives";
private _target = (_objectives get _stageId) get "position";
private _groups = call FLO_fnc_virtualizationGetGroupMap;
// For single-group holds, an eligible home force is always in the best band.
// Do not walk the rest of the graph or rank remote forces once band zero exists.
private _preferLocal = _kind != "CAPTURE" && {((_objectives get _stageId) get "owner") == (_commander get "_ownSide")};
private _localOnly = false;
private _ranked = [];
{
    private _fact = _y;
    if !(_fact get "assignable") then { continue };
    private _group = _groups get _x;
    if ((_group get "commanderIntent") != "") then { continue };
    if ((_group get "groupType") == "infantry" && {(_group get "unitCount") < 3}) then { continue };
    private _home = _group get "homeObjective";
    if (_localOnly && {_home != _stageId}) then { continue };
    if (_preferLocal && {_home == _stageId} && {!_localOnly}) then {
        _localOnly = true;
        _ranked = [];
    };
    private _pressure = if (_home in _picture) then { (_picture get _home) get "threat" } else { 0 };
    if (_kind == "CAPTURE" && {_pressure >= 20}) then { continue };
    private _role = parseNumber ((_group get "groupType") != "infantry");
    _ranked pushBack [_home, _pressure, _role, (_fact get "position") distance2D _target, _x];
} forEach _facts;
if (_ranked isEqualTo []) exitWith { [] };
if (_localOnly) then {
    { _x set [0, 0] } forEach _ranked;
} else {
    private _bands = [_commander, [_stageId], 3] call FLO_fnc_gtnGetCachedReserveBands;
    { _x set [0, _bands getOrDefault [_x select 0, 4]] } forEach _ranked;
};
_ranked sort true;
if (_kind != "CAPTURE") exitWith { [(_ranked select 0) select 4] };
private _reserve = ceil ((count _ranked) * ((_commander get "_config") get "operationalReserveShare"));
private _cap = ([(_commander get "_config") get "attackCoverageMultiplier", (_commander get "_config") get "attackObjectiveGroupCap"] call FLO_fnc_gtnResolveAttackCoverageCap) min ((count _ranked) - _reserve);
private _selected = [];
private _power = 0;
private _infantry = 0;
private _antiArmor = false;
private _requirement = [_commander, _objectiveId] call FLO_fnc_gtnGetAssaultRequirement;
private _required = _requirement get "power";
private _needsAntiArmor = _requirement get "antiArmor";
private _combined = [];
private _profiles = createHashMap;
// Include an infantry element, then favor useful combat power on the connected axis.
{
    _x params ["_band", "_pressure", "_role", "_distance", "_id"];
    private _profile = [_commander get "_capabilityAnalyzer", _groups get _id] call FLO_fnc_gtnAnalyzeManeuverGroup;
    _profiles set [_id, _profile];
    private _utility = ((_profile get "power") min _required) * 2 + 15 * parseNumber (_needsAntiArmor && {_profile get "antiArmor"});
    _combined pushBack [_band * 20 + _pressure * 2 + _distance / 1000 * 3 - _utility, _id];
} forEach _ranked;
_combined sort true;
private _infantryIndex = _ranked findIf {((_groups get (_x select 4)) get "groupType") == "infantry"};
if (_infantryIndex < 0) exitWith {[]};
private _firstId = (_ranked select _infantryIndex) select 4;
_combined = [[-1e12, _firstId]] + (_combined select {(_x select 1) != _firstId});
{
    if (count _selected >= _cap) exitWith {};
    private _id = _x select 1;
    private _group = _groups get _id;
    private _profile = _profiles get _id;
    _selected pushBack _id;
    _power = _power + (_profile get "power");
    _antiArmor = _antiArmor || {_profile get "antiArmor"};
    if ((_group get "groupType") == "infantry") then { _infantry = _infantry + (_group get "unitCount") };
    if (count _selected >= 2 && {_power >= _required} && {_infantry >= 3} && {!_needsAntiArmor || {_antiArmor}}) exitWith {};
} forEach _combined;
if (count _selected < 2 || {_power < _required} || {_infantry < 3} || {_needsAntiArmor && {!_antiArmor}}) exitWith { [] };
_selected
