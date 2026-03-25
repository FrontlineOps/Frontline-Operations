/*
 * Function: FLO_fnc_gtnSyncCommanderIntelMarkers
 * Author: Frontline Operations Development Group
 * Description:
 *   Client-side sync for the commander common operating picture.
 *   Maintains local intel markers for the local player's side only.
 *
 * Arguments:
 *   0: Side key <STRING>
 *   1: Group marker records <ARRAY>
 *   2: Concentration marker records <ARRAY>
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_sideKey", "", [""]],
    ["_groupMarkers", [], [[]]],
    ["_concentrationMarkers", [], [[]]]
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
    {
        deleteMarkerLocal _x;
    } forEach (keys (_staleRegistry get "groups"));
    {
        deleteMarkerLocal _x;
    } forEach (keys (_staleRegistry get "concentrations"));
    _registry deleteAt _sideKey;
    FLO_GTN_CommanderIntelMarkers = _registry;
};

if (_localSideKey != _sideKey) exitWith { false };

if !(_sideKey in _registry) then {
    _registry set [_sideKey, createHashMapFromArray [
        ["groups", createHashMap],
        ["concentrations", createHashMap]
    ]];
    FLO_GTN_CommanderIntelMarkers = _registry;
};

private _sideRegistry = _registry get _sideKey;
private _groupRegistry = _sideRegistry get "groups";
private _concentrationRegistry = _sideRegistry get "concentrations";
private _seenGroups = [];
private _seenConcentrations = [];

{
    _x params ["_markerId", "_pos", "_type", "_size", "_alpha", "_text", "_color"];

    if !(_markerId in _groupRegistry) then {
        createMarkerLocal [_markerId, _pos];
        _groupRegistry set [_markerId, true];
    };

    _markerId setMarkerPosLocal _pos;
    _markerId setMarkerShapeLocal "ICON";
    _markerId setMarkerTypeLocal _type;
    _markerId setMarkerSizeLocal _size;
    _markerId setMarkerColorLocal _color;
    _markerId setMarkerTextLocal _text;
    _markerId setMarkerAlphaLocal _alpha;
    _seenGroups pushBack _markerId;
} forEach _groupMarkers;

{
    _x params ["_markerId", "_pos", "_size", "_alpha", "_text", "_color"];

    if !(_markerId in _concentrationRegistry) then {
        createMarkerLocal [_markerId, _pos];
        _concentrationRegistry set [_markerId, true];
    };

    _markerId setMarkerPosLocal _pos;
    _markerId setMarkerShapeLocal "ELLIPSE";
    _markerId setMarkerBrushLocal "DiagGrid";
    _markerId setMarkerSizeLocal _size;
    _markerId setMarkerColorLocal _color;
    _markerId setMarkerTextLocal _text;
    _markerId setMarkerAlphaLocal _alpha;
    _seenConcentrations pushBack _markerId;
} forEach _concentrationMarkers;

{
    if !(_x in _seenGroups) then {
        deleteMarkerLocal _x;
        _groupRegistry deleteAt _x;
    };
} forEach (keys _groupRegistry);

{
    if !(_x in _seenConcentrations) then {
        deleteMarkerLocal _x;
        _concentrationRegistry deleteAt _x;
    };
} forEach (keys _concentrationRegistry);

_sideRegistry set ["groups", _groupRegistry];
_sideRegistry set ["concentrations", _concentrationRegistry];
_registry set [_sideKey, _sideRegistry];
FLO_GTN_CommanderIntelMarkers = _registry;

true
