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

private _reserveData = [_side] call FLO_fnc_transportResolveReserveObjective;
_reserveData params ["_reserveObjectiveId", "_reservePos"];
if (_reserveObjectiveId isEqualTo "") exitWith { [] };

private _createdGroups = [];

if (_groundTransportPool isNotEqualTo []) then {
    for "_i" from 1 to _groundReserveCount do {
        private _groundGroupId = [_side, "ground", _reserveObjectiveId, _reservePos] call FLO_fnc_transportCreateReserveCarrier;
        if (_groundGroupId == "") then { continue };
        _createdGroups pushBack _groundGroupId;

        ["VIRTUALIZATION", 2, format [
            "Seeded dedicated ground transport reserve %1 (%2/%3) for %4 at %5",
            _groundGroupId,
            _i,
            _groundReserveCount,
            _sideKey,
            _reserveObjectiveId
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
    for "_i" from 1 to _airReserveCount do {
        private _airGroupId = [_side, "air", _reserveObjectiveId, _reservePos] call FLO_fnc_transportCreateReserveCarrier;
        if (_airGroupId == "") then { continue };
        _createdGroups pushBack _airGroupId;

        ["VIRTUALIZATION", 2, format [
            "Seeded dedicated air transport reserve %1 (%2/%3) for %4 at %5",
            _airGroupId,
            _i,
            _airReserveCount,
            _sideKey,
            _reserveObjectiveId
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
