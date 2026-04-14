/*
 * Function: FLO_fnc_gtnSyncCommanderIntelMarkers
 * Author: Frontline Operations Development Group
 * Description:
 *   Client-side sync for the commander common operating picture.
 *   Maintains local intel markers for the local player's side only.
 *
 * Arguments:
 *   0: Side key <STRING>
 *   1: Enemy group marker records <ARRAY>
 *   2: Enemy concentration marker records <ARRAY>
 *   3: Friendly group marker records <ARRAY>
 *   4: Support marker records <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_sideKey", "", [""]],
    ["_enemyGroupMarkers", [], [[]]],
    ["_enemyConcentrationMarkers", [], [[]]],
    ["_friendlyGroupMarkers", [], [[]]],
    ["_supportMarkers", [], [[]]]
];

if (isNull player) exitWith { false };

private _localSide = side group player;
if !(_localSide in [east, west]) exitWith { false };

private _localSideKey = if (_localSide isEqualTo east) then { "EAST" } else { "WEST" };
if (isNil "FLO_GTN_CommanderIntelMarkers") then {
    FLO_GTN_CommanderIntelMarkers = createHashMap;
};

private _registry = FLO_GTN_CommanderIntelMarkers;
if (_localSideKey != _sideKey && {_sideKey in _registry}) then {
    private _staleRegistry = _registry get _sideKey;
    private _staleEnemyGroups = if ("enemyGroups" in _staleRegistry) then { _staleRegistry get "enemyGroups" } else { _staleRegistry get "groups" };
    private _staleEnemyConcentrations = if ("enemyConcentrations" in _staleRegistry) then { _staleRegistry get "enemyConcentrations" } else { _staleRegistry get "concentrations" };
    {
        deleteMarkerLocal _x;
    } forEach (keys _staleEnemyGroups);
    {
        deleteMarkerLocal _x;
    } forEach (keys _staleEnemyConcentrations);
    if ("friendlyGroups" in _staleRegistry) then {
        {
            deleteMarkerLocal _x;
        } forEach (keys (_staleRegistry get "friendlyGroups"));
    };
    if ("support" in _staleRegistry) then {
        {
            deleteMarkerLocal _x;
        } forEach (keys (_staleRegistry get "support"));
    };
    _registry deleteAt _sideKey;
    FLO_GTN_CommanderIntelMarkers = _registry;
};

if (_localSideKey != _sideKey) exitWith { false };

FLO_GTN_LastCommanderIntelSyncArgs = [
    _sideKey,
    +_enemyGroupMarkers,
    +_enemyConcentrationMarkers,
    +_friendlyGroupMarkers,
    +_supportMarkers
];

if (!FLO_GTN_ShowSupplyMarkers) then {
    private _supplyPrefix = format ["FLO_GTN_INTEL_%1_SUP_LOG_", _sideKey];
    _supportMarkers = _supportMarkers select { ((_x select 0) find _supplyPrefix) != 0 };
};

if !(_sideKey in _registry) then {
    _registry set [_sideKey, createHashMapFromArray [
        ["enemyGroups", createHashMap],
        ["enemyConcentrations", createHashMap],
        ["friendlyGroups", createHashMap],
        ["support", createHashMap]
    ]];
    FLO_GTN_CommanderIntelMarkers = _registry;
};

private _sideRegistry = _registry get _sideKey;
if !("enemyGroups" in _sideRegistry) then {
    private _legacyGroups = _sideRegistry get "groups";
    if (!isNil "_legacyGroups") then {
        {
            deleteMarkerLocal _x;
        } forEach (keys _legacyGroups);
    };
    private _legacyConcentrations = _sideRegistry get "concentrations";
    if (!isNil "_legacyConcentrations") then {
        {
            deleteMarkerLocal _x;
        } forEach (keys _legacyConcentrations);
    };

    _sideRegistry = createHashMapFromArray [
        ["enemyGroups", createHashMap],
        ["enemyConcentrations", createHashMap],
        ["friendlyGroups", createHashMap],
        ["support", createHashMap]
    ];
};

private _enemyGroupRegistry = _sideRegistry get "enemyGroups";
private _enemyConcentrationRegistry = _sideRegistry get "enemyConcentrations";
private _friendlyGroupRegistry = _sideRegistry get "friendlyGroups";
private _supportRegistry = _sideRegistry get "support";
private _seenEnemyGroups = [];
private _seenEnemyConcentrations = [];
private _seenFriendlyGroups = [];
private _seenSupport = [];

{
    _x params ["_markerId", "_pos", "_type", "_size", "_alpha", "_text", "_color"];

    if !(_markerId in _enemyGroupRegistry) then {
        createMarkerLocal [_markerId, _pos];
        _enemyGroupRegistry set [_markerId, true];
    };

    _markerId setMarkerPosLocal _pos;
    _markerId setMarkerShapeLocal "ICON";
    _markerId setMarkerTypeLocal _type;
    _markerId setMarkerSizeLocal _size;
    _markerId setMarkerColorLocal _color;
    _markerId setMarkerTextLocal _text;
    _markerId setMarkerAlphaLocal _alpha;
    _seenEnemyGroups pushBack _markerId;
} forEach _enemyGroupMarkers;

{
    _x params ["_markerId", "_pos", "_size", "_alpha", "_text", "_color"];

    if !(_markerId in _enemyConcentrationRegistry) then {
        createMarkerLocal [_markerId, _pos];
        _enemyConcentrationRegistry set [_markerId, true];
    };

    _markerId setMarkerPosLocal _pos;
    _markerId setMarkerShapeLocal "ELLIPSE";
    _markerId setMarkerBrushLocal "DiagGrid";
    _markerId setMarkerSizeLocal _size;
    _markerId setMarkerColorLocal _color;
    _markerId setMarkerTextLocal _text;
    _markerId setMarkerAlphaLocal _alpha;
    _seenEnemyConcentrations pushBack _markerId;
} forEach _enemyConcentrationMarkers;

{
    _x params ["_markerId", "_pos", "_type", "_size", "_alpha", "_text", "_color"];

    if !(_markerId in _friendlyGroupRegistry) then {
        createMarkerLocal [_markerId, _pos];
        _friendlyGroupRegistry set [_markerId, true];
    };

    _markerId setMarkerPosLocal _pos;
    _markerId setMarkerShapeLocal "ICON";
    _markerId setMarkerTypeLocal _type;
    _markerId setMarkerSizeLocal _size;
    _markerId setMarkerColorLocal _color;
    _markerId setMarkerTextLocal _text;
    _markerId setMarkerAlphaLocal _alpha;
    _seenFriendlyGroups pushBack _markerId;
} forEach _friendlyGroupMarkers;

{
    _x params ["_markerId", "_shape", "_pos", "_type", "_size", "_alpha", "_text", "_color", "_brush"];

    if !(_markerId in _supportRegistry) then {
        createMarkerLocal [_markerId, _pos];
        _supportRegistry set [_markerId, true];
    };

    _markerId setMarkerPosLocal _pos;
    _markerId setMarkerShapeLocal _shape;
    if (_shape == "ICON") then {
        _markerId setMarkerTypeLocal _type;
    } else {
        _markerId setMarkerBrushLocal _brush;
    };
    _markerId setMarkerSizeLocal _size;
    _markerId setMarkerColorLocal _color;
    _markerId setMarkerTextLocal _text;
    _markerId setMarkerAlphaLocal _alpha;
    _seenSupport pushBack _markerId;
} forEach _supportMarkers;

{
    if !(_x in _seenEnemyGroups) then {
        deleteMarkerLocal _x;
        _enemyGroupRegistry deleteAt _x;
    };
} forEach (keys _enemyGroupRegistry);

{
    if !(_x in _seenEnemyConcentrations) then {
        deleteMarkerLocal _x;
        _enemyConcentrationRegistry deleteAt _x;
    };
} forEach (keys _enemyConcentrationRegistry);

{
    if !(_x in _seenFriendlyGroups) then {
        deleteMarkerLocal _x;
        _friendlyGroupRegistry deleteAt _x;
    };
} forEach (keys _friendlyGroupRegistry);

{
    if !(_x in _seenSupport) then {
        deleteMarkerLocal _x;
        _supportRegistry deleteAt _x;
    };
} forEach (keys _supportRegistry);

_sideRegistry set ["enemyGroups", _enemyGroupRegistry];
_sideRegistry set ["enemyConcentrations", _enemyConcentrationRegistry];
_sideRegistry set ["friendlyGroups", _friendlyGroupRegistry];
_sideRegistry set ["support", _supportRegistry];
_registry set [_sideKey, _sideRegistry];
FLO_GTN_CommanderIntelMarkers = _registry;

true
