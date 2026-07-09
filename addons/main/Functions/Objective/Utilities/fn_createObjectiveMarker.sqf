/*
 * Function: FLO_fnc_createObjectiveMarker
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates or updates a marker for an objective.
 *   Centralizes marker creation logic for consistency.
 *
 * Arguments:
 *   0: Objective ID (STRING)
 *   1: Objective data (HASHMAP) - Optional, will fetch from FLO_Objectives if not provided
 *   2: Options (HASHMAP) - Optional overrides:
 *      - "prefix": Marker name prefix (default: "obj_")
 *      - "alpha": Marker alpha (default: from config)
 *      - "local": Create local marker only (default: false)
 *
 * Returns:
 *   STRING - Marker name, or "" on failure
 *
 * Examples:
 *   ["virtual_1"] call FLO_fnc_createObjectiveMarker;
 *   ["virtual_1", _objData, createHashMapFromArray [["local", true]]] call FLO_fnc_createObjectiveMarker;
 */

params [
    ["_objId", ""],
    ["_objData", nil],
    ["_options", createHashMap]
];

if (_objId == "") exitWith { "" };

// Get objective data if not provided
if (isNil "_objData") then {
    if (isNil "FLO_Objectives") exitWith { _objData = nil };
    _objData = FLO_Objectives get _objId;
};

if (isNil "_objData") exitWith { "" };

// Get options
private _prefix = _options getOrDefault ["prefix", "obj_"];
private _alphaOverride = _options getOrDefault ["alpha", nil];
private _isLocal = _options getOrDefault ["local", false];

// Get objective properties
private _pos = _objData get "position";
private _radius = _objData getOrDefault ["radius", 50];
private _owner = _objData getOrDefault ["owner", east];

// Get config values
private _configAlpha = ["get", "markerAlpha"] call FLO_fnc_objectiveConfig;
private _markerColors = ["get", "markerColors"] call FLO_fnc_objectiveConfig;

private _alpha = if (!isNil "_alphaOverride") then { _alphaOverride } else { _configAlpha };
private _color = _markerColors getOrDefault [_owner, _markerColors get "default"];

// Generate marker name
private _markerName = format ["%1%2", _prefix, _objId];

// Delete existing marker if present
if (getMarkerColor _markerName != "") then {
    deleteMarker _markerName;
};

// Create marker
if (_isLocal) then {
    createMarkerLocal [_markerName, _pos];
    _markerName setMarkerShapeLocal "ELLIPSE";
    _markerName setMarkerSizeLocal [_radius, _radius];
    _markerName setMarkerColorLocal _color;
    _markerName setMarkerAlphaLocal _alpha;
} else {
    createMarker [_markerName, _pos];
    _markerName setMarkerShapeLocal "ELLIPSE";
    _markerName setMarkerSizeLocal [_radius, _radius];
    _markerName setMarkerColorLocal _color;
    _markerName setMarkerAlpha _alpha;
};

// Store marker reference in objective data
private _markers = _objData getOrDefault ["markerIds", []];
_markers pushBackUnique _markerName;
_objData set ["markerIds", _markers];

_markerName

