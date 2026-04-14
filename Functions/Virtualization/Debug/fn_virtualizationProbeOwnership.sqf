/*
 * Function: FLO_fnc_virtualizationProbeOwnership
 * Author: Frontline Operations Development Group
 * Description:
 *   Performs an on-demand ownership scan for live engine groups and vehicles
 *   that are no longer represented by the virtualization registry.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * HASHMAP - Ownership probe result
 */

if (!isServer) exitWith { createHashMap };

private _groups = FLO_virtualGroups get "_groups";
private _trackedRealGroups = createHashMap;
private _trackedVehicles = createHashMap;

{
    private _groupId = _x;
    private _groupData = _y;
    private _realGroup = _groupData get "realGroup";
    if (!isNull _realGroup) then {
        _trackedRealGroups set [str _realGroup, _groupId];
    };

    {
        if (!isNull _x) then {
            _trackedVehicles set [str _x, _groupId];
        };
    } forEach (_groupData get "realVehicles");
} forEach _groups;

private _orphanGroups = [];
{
    private _group = _x;
    private _units = units _group;
    if (count _units == 0) then { continue };
    if ({ isPlayer _x } count _units > 0) then { continue };

    private _trackedId = _group getVariable ["FLO_virtualGroupId", ""];
    if (_trackedId == "") then {
        _orphanGroups pushBack [
            str _group,
            "missing_virtual_id",
            side _group,
            count _units,
            typeOf leader _group
        ];
        continue;
    };

    if !(_trackedId in _groups) then {
        _orphanGroups pushBack [
            str _group,
            "missing_registry_group",
            side _group,
            count _units,
            _trackedId
        ];
        continue;
    };

    private _groupData = _groups get _trackedId;
    private _realGroup = _groupData get "realGroup";
    if !(_realGroup isEqualTo _group) then {
        _orphanGroups pushBack [
            str _group,
            "real_group_mismatch",
            side _group,
            count _units,
            _trackedId
        ];
    };
} forEach allGroups;

private _orphanVehicles = [];
{
    private _veh = _x;
    if (isNull _veh || {!alive _veh}) then { continue };
    if ((crew _veh) isEqualTo []) then { continue };

    private _vehicleKey = str _veh;
    if !(isNil { _trackedVehicles get _vehicleKey }) then { continue };

    private _crewGroup = group ((crew _veh) select 0);
    private _trackedId = _crewGroup getVariable ["FLO_virtualGroupId", ""];
    if (_trackedId == "") then {
        _orphanVehicles pushBack [
            typeOf _veh,
            "crew_group_missing_virtual_id",
            getPosATL _veh
        ];
        continue;
    };

    if !(_trackedId in _groups) then {
        _orphanVehicles pushBack [
            typeOf _veh,
            "crew_group_missing_registry_group",
            getPosATL _veh
        ];
        continue;
    };

    private _groupData = _groups get _trackedId;
    if !((_groupData get "realGroup") isEqualTo _crewGroup) then {
        _orphanVehicles pushBack [
            typeOf _veh,
            "crew_group_real_group_mismatch",
            getPosATL _veh
        ];
        continue;
    };

    _orphanVehicles pushBack [
        typeOf _veh,
        "vehicle_not_tracked_on_group",
        getPosATL _veh
    ];
} forEach vehicles;

private _result = createHashMapFromArray [
    ["trackedGroups", count (keys _groups)],
    ["orphanGroups", _orphanGroups],
    ["orphanVehicles", _orphanVehicles]
];

["VIRTUALIZATION", 2, format [
    "Ownership probe: tracked=%1 orphanGroups=%2 orphanVehicles=%3",
    _result get "trackedGroups",
    count (_result get "orphanGroups"),
    count (_result get "orphanVehicles")
]] call FLO_fnc_log;

_result
