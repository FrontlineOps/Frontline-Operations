/*
 * Function: FLO_fnc_initializeTransportReserveGroups
 * Author: Frontline Operations Development Group
 * Description:
 *   Seeds dedicated reserve carriers from faction transport pools so long-haul
 *   infantry reassignment can draw from non-combat transport assets.
 *
 * Arguments:
 *   0: Side <SIDE>
 *
 * Return Value:
 *   ARRAY - Created virtual group IDs
 */

params [["_side", east]];

if (!isServer) exitWith { [] };
if !(_side in [east, west]) exitWith { [] };

private _sideCtx = [_side] call FLO_fnc_gtnSideContext;
private _sideKey = _sideCtx get "sideKey";
private _net = FLO_Logistics_Networks get _sideKey;
private _catalog = FLO_FactionCatalog get _sideKey;
private _rawGroundTransportPool = _catalog get "groundTransport";
private _rawAirTransportPool = _catalog get "airTransport";
private _groundReserveCount = _catalog get "transportReserveGroundCount";
private _airReserveCount = _catalog get "transportReserveAirCount";

private _groundTransportPool = _rawGroundTransportPool select {
    ([_x] call FLO_fnc_transportGetCapacity) > 0
};
private _airTransportPool = _rawAirTransportPool select {
    (_x isKindOf "Helicopter") && {([_x] call FLO_fnc_transportGetCapacity) > 0}
};

if (_groundTransportPool isEqualTo [] && {_airTransportPool isEqualTo []}) exitWith {
    if (_rawGroundTransportPool isNotEqualTo []) then {
        ["VIRTUALIZATION", 2, format [
            "No cargo-capable ground transport pool entries available for %1 transport reserve seeding",
            _sideKey
        ]] call FLO_fnc_log;
    };
    if (_rawAirTransportPool isNotEqualTo []) then {
        ["VIRTUALIZATION", 2, format [
            "No cargo-capable transport helicopters available for %1 air transport reserve seeding",
            _sideKey
        ]] call FLO_fnc_log;
    };
    []
};

private _spawnContext = [_side, _net] call FLO_fnc_transportResolveReserveSpawnContext;
_spawnContext params ["_spawnObjectiveIds", "_reserveObjectiveId", "_reservePos"];
if (_reserveObjectiveId isEqualTo "") exitWith { [] };

private _createdGroups = [];
private _groups = FLO_virtualGroups get "_groups";
private _activeSupplyNodes = _net get "_activeSupplyNodes";
private _currentGround = 0;
private _currentAir = 0;
private _groundByObjective = createHashMap;
private _airByObjective = createHashMap;

{
    private _groupData = _y;
    if ((_groupData get "side") isNotEqualTo _side) then { continue };
    if !(_groupData get "transportRole") then { continue };

    private _groupType = _groupData get "groupType";
    private _homeObjective = _groupData get "homeObjective";

    if (_groupType isEqualTo "helicopter") then {
        _currentAir = _currentAir + 1;
        if (_homeObjective != "") then {
            private _airCount = if (_homeObjective in _airByObjective) then {
                _airByObjective get _homeObjective
            } else {
                0
            };
            _airByObjective set [_homeObjective, _airCount + 1];
        };
        continue;
    };

    if (_groupType in ["motorized", "mechanized"]) then {
        _currentGround = _currentGround + 1;
        if (_homeObjective != "") then {
            private _groundCount = if (_homeObjective in _groundByObjective) then {
                _groundByObjective get _homeObjective
            } else {
                0
            };
            _groundByObjective set [_homeObjective, _groundCount + 1];
        };
    };
} forEach _groups;

private _groundToCreate = (_groundReserveCount - _currentGround) max 0;
private _airToCreate = (_airReserveCount - _currentAir) max 0;

if (_groundTransportPool isNotEqualTo []) then {
    for "_i" from 1 to _groundToCreate do {
        private _spawnObjectiveId = [_spawnObjectiveIds, _groundByObjective, _activeSupplyNodes, _reserveObjectiveId] call FLO_fnc_transportPickReserveSpawnObjective;
        private _objectiveReserveCount = if (_spawnObjectiveId in _groundByObjective) then {
            _groundByObjective get _spawnObjectiveId
        } else {
            0
        };
        private _spawnPos = [_net, _spawnObjectiveId, _objectiveReserveCount, "ground", _reservePos] call FLO_fnc_transportResolveReserveSpawnPosition;
        private _groundGroupId = [_side, "ground", _spawnObjectiveId, _spawnPos] call FLO_fnc_transportCreateReserveCarrier;
        if (_groundGroupId == "") then { continue };
        _createdGroups pushBack _groundGroupId;
        _groundByObjective set [_spawnObjectiveId, _objectiveReserveCount + 1];

        ["VIRTUALIZATION", 2, format [
            "Seeded dedicated ground transport reserve %1 (%2/%3) for %4 at %5",
            _groundGroupId,
            _i,
            _groundToCreate,
            _sideKey,
            _spawnObjectiveId
        ]] call FLO_fnc_log;
    };
} else {
    if (_rawGroundTransportPool isNotEqualTo []) then {
        ["VIRTUALIZATION", 2, format [
            "No cargo-capable ground transport pool entries available for %1 transport reserve seeding",
            _sideKey
        ]] call FLO_fnc_log;
    };
};

if (_airTransportPool isNotEqualTo []) then {
    for "_i" from 1 to _airToCreate do {
        private _spawnObjectiveId = [_spawnObjectiveIds, _airByObjective, _activeSupplyNodes, _reserveObjectiveId] call FLO_fnc_transportPickReserveSpawnObjective;
        private _objectiveReserveCount = if (_spawnObjectiveId in _airByObjective) then {
            _airByObjective get _spawnObjectiveId
        } else {
            0
        };
        private _spawnPos = [_net, _spawnObjectiveId, _objectiveReserveCount, "air", _reservePos] call FLO_fnc_transportResolveReserveSpawnPosition;
        private _airGroupId = [_side, "air", _spawnObjectiveId, _spawnPos] call FLO_fnc_transportCreateReserveCarrier;
        if (_airGroupId == "") then { continue };
        _createdGroups pushBack _airGroupId;
        _airByObjective set [_spawnObjectiveId, _objectiveReserveCount + 1];

        ["VIRTUALIZATION", 2, format [
            "Seeded dedicated air transport reserve %1 (%2/%3) for %4 at %5",
            _airGroupId,
            _i,
            _airToCreate,
            _sideKey,
            _spawnObjectiveId
        ]] call FLO_fnc_log;
    };
} else {
    if (_rawAirTransportPool isNotEqualTo []) then {
        ["VIRTUALIZATION", 2, format [
            "No cargo-capable transport helicopters available for %1 air transport reserve seeding",
            _sideKey
        ]] call FLO_fnc_log;
    };
};

_createdGroups
