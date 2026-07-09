/*
 * Function: FLO_fnc_transportCreateReserveCarrier
 * Description:
 *   Creates a dedicated reserve transport carrier for a side and registers it
 *   into the shared transport pool as an available carrier.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Reserve type <STRING> - "ground" or "air"
 *   2: Reserve objective ID <STRING> - Default resolved automatically
 *   3: Spawn position <ARRAY> - Default reserve objective position
 *
 * Return Value:
 *   STRING - New virtual group ID or empty string
 */

params [
    ["_side", east, [east]],
    ["_reserveType", "ground", [""]],
    ["_reserveObjectiveId", "", [""]],
    ["_spawnPos", [], [[]]]
];

if (!isServer) exitWith { "" };
if !(_side in [east, west]) exitWith { "" };
if !(_reserveType in ["ground", "air"]) exitWith { "" };

if (_reserveObjectiveId isEqualTo "" || {_spawnPos isEqualTo []}) then {
    private _reserveData = [_side] call FLO_fnc_transportResolveReserveObjective;
    _reserveData params ["_resolvedObjectiveId", "_resolvedPos"];
    if (_reserveObjectiveId isEqualTo "") then {
        _reserveObjectiveId = _resolvedObjectiveId;
    };
    if (_spawnPos isEqualTo []) then {
        _spawnPos = _resolvedPos;
    };
};

if (_reserveObjectiveId isEqualTo "" || {_spawnPos isEqualTo []}) exitWith { "" };

private _sideContext = [_side] call FLO_fnc_gtnSideContext;
private _sideKey = _sideContext get "sideKey";
private _catalog = FLO_FactionCatalog get _sideKey;

private _groupType = "motorized";
private _assetPool = [];

switch (_reserveType) do {
    case "ground": {
        _assetPool = (_catalog get "groundTransport") select {
            ([_x] call FLO_fnc_transportGetCapacity) > 0
        };
    };
    case "air": {
        _groupType = "helicopter";
        _assetPool = (_catalog get "airTransport") select {
            (_x isKindOf "Helicopter") && {([_x] call FLO_fnc_transportGetCapacity) > 0}
        };
    };
};

if (_assetPool isEqualTo []) exitWith { "" };

private _groupId = [_spawnPos, _groupType, configNull, _reserveObjectiveId, 1, _side] call FLO_fnc_createVirtualGroup;
if (_groupId isEqualTo "") exitWith { "" };

private _groupData = (FLO_virtualGroups get "_groups") get _groupId;
[_groupData, [selectRandom _assetPool]] call FLO_fnc_virtualizationSetAssetComposition;
_groupData set ["transportRole", true];
_groupData set ["commanderOrder", "TRANSPORT"];
_groupData set ["homeObjective", _reserveObjectiveId];

private _availableTransports = FLO_TransportPool get "available";
_availableTransports set [_groupId, [
    [_groupData] call FLO_fnc_transportGetGroupCapacity,
    _groupData get "position",
    _groupData get "groupType",
    true,
    _side
]];

_groupId
