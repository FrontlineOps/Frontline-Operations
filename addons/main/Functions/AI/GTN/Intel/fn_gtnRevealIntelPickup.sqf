/*
 * Function: FLO_fnc_gtnRevealIntelPickup
 * Author: Frontline Operations Development Group
 * Description:
 *   Resolves one actionable strategic intel reveal from a recovered intel
 *   item and publishes it to the recovering side as a temporary GTN alert.
 *
 * Arguments:
 *   0: Recovering side <SIDE>
 *   1: Intel item classname <STRING>
 *   2: Recovering grid position <STRING>
 *
 * Return Value:
 *   HASHMAP - Selected reveal, or empty map when nothing actionable exists
 */

params [
    ["_playerSide", sideUnknown, [sideUnknown]],
    ["_itemClass", "", [""]],
    ["_gridPos", "", [""]]
];

private _result = createHashMap;
if !(_playerSide in [east, west]) exitWith { _result };

private _sideKey = ([_playerSide] call FLO_fnc_gtnSideContext) get "sideKey";
private _candidates = [_playerSide] call FLO_fnc_gtnCollectIntelPickupRevealCandidates;
if (_candidates isEqualTo []) exitWith {
    [format ["Recovered enemy intel at %1, but no actionable strategic lead was extracted.", _gridPos], "info", false, _playerSide] call FLO_fnc_sendNotification;
    ["INTEL", 2, format ["Intel pickup at %1 for %2 produced no actionable reveal", _gridPos, _sideKey]] call FLO_fnc_log;
    _result
};

private _revealState = FLO_GTN_IntelPickupRevealState;
private _sideState = _revealState get _sideKey;

private _now = diag_tickTime;
{
    if ((_sideState get _x) <= _now) then {
        _sideState deleteAt _x;
    };
} forEach +(keys _sideState);

private _preferredCategories = switch (_itemClass) do {
    case "SmartPhone";
    case "MobilePhone": {
        ["commander_target", "supply_node", "hq"]
    };
    case "FilesSecret";
    case "DocumentsSecret": {
        ["supply_node", "hq", "commander_target"]
    };
    case "FlashDisk": {
        ["hq", "commander_target", "supply_node"]
    };
    default {
        ["commander_target", "supply_node", "hq"]
    };
};

private _freshCandidates = _candidates select {
    !((_x get "revealKey") in _sideState)
};
private _selectionPool = [_candidates, _freshCandidates] select (_freshCandidates isNotEqualTo []);

private _selectedPool = [_selectionPool, [], {
    private _category = _x get "category";
    private _preferredIndex = _preferredCategories find _category;
    if (_preferredIndex < 0) then {
        _preferredIndex = 99;
    };

    [
        _preferredIndex,
        -(_x get "priority"),
        _x get "revealKey"
    ]
}, "ASCEND"] call BIS_fnc_sortBy;

if (_selectedPool isEqualTo []) exitWith { _result };

private _selected = _selectedPool select 0;
private _message = _selected get "message";

[_message, "intel", false, _playerSide] call FLO_fnc_sendNotification;
[
    _playerSide,
    _selected get "alertType",
    _selected get "position",
    _selected get "radius",
    _selected get "duration",
    "",
    _selected get "payload"
] call FLO_fnc_gtnPublishAlert;

private _cooldown = (_selected get "duration") max 180;
_sideState set [(_selected get "revealKey"), _now + _cooldown];
FLO_GTN_IntelPickupRevealState = _revealState;

private _category = _selected get "category";
if (_category in ["hq", "supply_node"]) then {
    private _intelBySide = FLO_GTN_StrategicIntelBySide;
    private _strategicRecords = _intelBySide get _sideKey;
    private _duration = _selected get "duration";
    private _position = +(_selected get "position");
    _strategicRecords set [_selected get "revealKey", createHashMapFromArray [
        ["category", _category],
        ["nodeType", _selected get "nodeType"],
        ["position", _position],
        ["objectiveName", _selected get "objectiveName"],
        ["grid", mapGridPosition _position],
        ["radius", _selected get "radius"],
        ["reportedAt", _now],
        ["expiresAt", _now + _duration]
    ]];
    _intelBySide set [_sideKey, _strategicRecords];
    FLO_GTN_StrategicIntelBySide = _intelBySide;
};

["INTEL", 2, format [
    "Intel pickup %1 at %2 for %3 revealed %4 %5",
    _itemClass,
    _gridPos,
    _sideKey,
    _category,
    _selected get "revealKey"
]] call FLO_fnc_log;

_selected
