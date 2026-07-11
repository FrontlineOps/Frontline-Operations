/* Maintains the side-filtered client commander picture using delta updates. */
if (!hasInterface) exitWith { false };

params [
    ["_sideKey", "", [""]],
    ["_enemyGroupMarkers", [], [[]]],
    ["_enemyConcentrationMarkers", [], [[]]],
    ["_friendlyGroupMarkers", [], [[]]],
    ["_supportMarkers", [], [[]]]
];

if (isNull player) exitWith { false };
private _startedAt = diag_tickTime;
private _localSide = side group player;
if !(_localSide in [east, west]) exitWith { false };

private _localSideKey = ["WEST", "EAST"] select (_localSide isEqualTo east);
private _registry = FLO_GTN_CommanderIntelMarkers;
if (_localSideKey != _sideKey && {_sideKey in _registry}) then {
    private _staleRegistry = _registry get _sideKey;
    private _emptySeen = createHashMap;
    {
        [_staleRegistry get _x, _emptySeen] call FLO_fnc_gtnRemoveStaleIntelMarkers;
    } forEach ["enemyGroups", "enemyConcentrations", "friendlyGroups", "support"];
    _registry deleteAt _sideKey;
};
if (_localSideKey != _sideKey) exitWith { false };

if !(_sideKey in _registry) then {
    _registry set [_sideKey, createHashMapFromArray [
        ["enemyGroups", createHashMap],
        ["enemyConcentrations", createHashMap],
        ["friendlyGroups", createHashMap],
        ["support", createHashMap]
    ]];
};

private _sideRegistry = _registry get _sideKey;
private _enemyGroupRegistry = _sideRegistry get "enemyGroups";
private _enemyConcentrationRegistry = _sideRegistry get "enemyConcentrations";
private _friendlyGroupRegistry = _sideRegistry get "friendlyGroups";
private _supportRegistry = _sideRegistry get "support";

private _enemyGroupResult = [_enemyGroupRegistry, _enemyGroupMarkers] call FLO_fnc_gtnSyncIntelIconMarkers;
private _enemyConcentrationResult = [_enemyConcentrationRegistry, _enemyConcentrationMarkers] call FLO_fnc_gtnSyncIntelConcentrationMarkers;
private _friendlyGroupResult = [_friendlyGroupRegistry, _friendlyGroupMarkers] call FLO_fnc_gtnSyncIntelIconMarkers;
private _supportResult = [_supportRegistry, _supportMarkers] call FLO_fnc_gtnSyncIntelSupportMarkers;

private _removed = 0;
_removed = _removed + ([_enemyGroupRegistry, _enemyGroupResult select 0] call FLO_fnc_gtnRemoveStaleIntelMarkers);
_removed = _removed + ([_enemyConcentrationRegistry, _enemyConcentrationResult select 0] call FLO_fnc_gtnRemoveStaleIntelMarkers);
_removed = _removed + ([_friendlyGroupRegistry, _friendlyGroupResult select 0] call FLO_fnc_gtnRemoveStaleIntelMarkers);
_removed = _removed + ([_supportRegistry, _supportResult select 0] call FLO_fnc_gtnRemoveStaleIntelMarkers);

_sideRegistry set ["enemyGroups", _enemyGroupRegistry];
_sideRegistry set ["enemyConcentrations", _enemyConcentrationRegistry];
_sideRegistry set ["friendlyGroups", _friendlyGroupRegistry];
_sideRegistry set ["support", _supportRegistry];
_registry set [_sideKey, _sideRegistry];
FLO_GTN_CommanderIntelMarkers = _registry;

private _elapsed = diag_tickTime - _startedAt;
if (_elapsed > 0.01) then {
    private _results = [_enemyGroupResult, _enemyConcentrationResult, _friendlyGroupResult, _supportResult];
    private _created = 0;
    private _changed = 0;
    private _commands = 0;
    {
        _created = _created + (_x select 1);
        _changed = _changed + (_x select 2);
        _commands = _commands + (_x select 3);
    } forEach _results;
    diag_log format [
        "[FLO][PERF] Commander intel marker sync side=%1 time=%2ms records=%3 created=%4 changed=%5 removed=%6 commands=%7",
        _sideKey,
        round (_elapsed * 100000) / 100,
        count _enemyGroupMarkers + count _enemyConcentrationMarkers + count _friendlyGroupMarkers + count _supportMarkers,
        _created,
        _changed,
        _removed,
        _commands
    ];
};

true
