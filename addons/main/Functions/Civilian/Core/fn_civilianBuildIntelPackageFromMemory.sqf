/*
 * Function: FLO_fnc_civilianBuildIntelPackageFromMemory
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds a civilian alert package directly from a witness or gossip memory.
 *
 * Arguments:
 * 0: Memory record <HASHMAP>
 * 1: Reporting side <SIDE>
 * 2: Civilian role <STRING>
 *
 * Return Value:
 * HASHMAP - Civilian alert package
 */

params [
    ["_memory", createHashMap, [createHashMap]],
    ["_reportingSide", west, [east]],
    ["_civilianRole", "resident", [""]]
];

private _package = createHashMap;
if ((keys _memory) isEqualTo []) exitWith { _package };

private _reportType = _memory get "reportType";
private _confidence = (_memory get "confidence") max 0.1;
private _uncertainty = 1 - (_confidence min 0.95);
private _position = _memory get "position";
private _isRumor = (_memory get "gossipDepth") > 0;
private _sourcePrefix = ["Civilian report", "Civilian rumor"] select (_isRumor);
private _summary = _memory get "summary";

private _radiusBase = switch (_reportType) do {
    case "VEHICLE_MOVEMENT": { 220 };
    case "CHECKPOINT_RUMOR": { 280 };
    case "SAFE_ROUTE_HINT": { 180 };
    default { 240 };
};

private _durationBase = switch (_reportType) do {
    case "CHECKPOINT_RUMOR": { 180 };
    case "SAFE_ROUTE_HINT": { 90 };
    default { 120 };
};

private _message = switch (_reportType) do {
    case "CHECKPOINT_RUMOR": {
        format ["%1: %2 near grid %3", _sourcePrefix, _summary, mapGridPosition _position]
    };
    case "SAFE_ROUTE_HINT": {
        format ["%1: roads near grid %2 seem quieter for now", _sourcePrefix, mapGridPosition _position]
    };
    case "VEHICLE_MOVEMENT": {
        format ["%1: military traffic was heard near grid %2", _sourcePrefix, mapGridPosition _position]
    };
    default {
        format ["%1: %2 near grid %3", _sourcePrefix, _summary, mapGridPosition _position]
    };
};

createHashMapFromArray [
    ["reportingSide", _reportingSide],
    ["position", _position],
    ["radius", _radiusBase + round (_uncertainty * 220)],
    ["duration", _durationBase + round (_confidence * 60)],
    ["message", _message],
    ["payload", [_reportType, _confidence, _civilianRole, _memory get "sourceObjectiveId"]]
]
