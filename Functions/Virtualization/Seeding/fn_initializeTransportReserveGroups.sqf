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

private _ownedObjectiveIds = [];
{
    if ((_y get "owner") == _side) then {
        _ownedObjectiveIds pushBack _x;
    };
} forEach FLO_Objectives;

if (_ownedObjectiveIds isEqualTo []) exitWith { [] };

private _capitalObjectives = _ownedObjectiveIds select {
    ((FLO_Objectives get _x) get "subtype") == "capital"
};

private _reserveObjectiveId = if (_capitalObjectives isNotEqualTo []) then {
    _capitalObjectives select 0
} else {
    private _selectedObjectiveId = _ownedObjectiveIds select 0;
    private _bestPriority = (FLO_Objectives get _selectedObjectiveId) get "priority";

    {
        private _priority = (FLO_Objectives get _x) get "priority";
        if (_priority > _bestPriority) then {
            _bestPriority = _priority;
            _selectedObjectiveId = _x;
        };
    } forEach _ownedObjectiveIds;

    _selectedObjectiveId
};

private _reserveObjective = FLO_Objectives get _reserveObjectiveId;
private _reservePos = _reserveObjective get "position";
private _createdGroups = [];
private _availableTransports = FLO_TransportPool get "available";

if (_groundTransportPool isNotEqualTo []) then {
    private _groundGroupId = [_reservePos, "motorized", configNull, _reserveObjectiveId, 1, _side] call FLO_fnc_createVirtualGroup;
    if (_groundGroupId != "") then {
        private _groundGroupData = (FLO_virtualGroups get "_groups") get _groundGroupId;
        [_groundGroupData, [selectRandom _groundTransportPool]] call FLO_fnc_virtualizationSetAssetComposition;
        _groundGroupData set ["transportRole", true];
        _groundGroupData set ["commanderOrder", "TRANSPORT"];
        _availableTransports set [_groundGroupId, [
            [_groundGroupData] call FLO_fnc_transportGetGroupCapacity,
            _groundGroupData get "position",
            _groundGroupData get "groupType",
            true
        ]];
        _createdGroups pushBack _groundGroupId;

        ["VIRTUALIZATION", 3, format [
            "Seeded dedicated ground transport reserve %1 for %2 at %3",
            _groundGroupId,
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
    private _airGroupId = [_reservePos, "helicopter", configNull, _reserveObjectiveId, 1, _side] call FLO_fnc_createVirtualGroup;
    if (_airGroupId != "") then {
        private _airGroupData = (FLO_virtualGroups get "_groups") get _airGroupId;
        [_airGroupData, [selectRandom _airTransportPool]] call FLO_fnc_virtualizationSetAssetComposition;
        _airGroupData set ["transportRole", true];
        _airGroupData set ["commanderOrder", "TRANSPORT"];
        _availableTransports set [_airGroupId, [
            [_airGroupData] call FLO_fnc_transportGetGroupCapacity,
            _airGroupData get "position",
            _airGroupData get "groupType",
            true
        ]];
        _createdGroups pushBack _airGroupId;

        ["VIRTUALIZATION", 3, format [
            "Seeded dedicated air transport reserve %1 for %2 at %3",
            _airGroupId,
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
