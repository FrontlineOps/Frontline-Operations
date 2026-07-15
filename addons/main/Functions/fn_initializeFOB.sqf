/* Initializes one campaign FOB and its shared base services. */
params [
    ["_fobBuilding", objNull, [objNull]],
    ["_preserveMarker", false, [false]]
];

if (isNull _fobBuilding) exitWith {
    ["FOB", 1, "Null object passed to FOB initialization"] call FLO_fnc_log;
    false
};

if (_fobBuilding getVariable ["FLO_FOB_Initialized", false]) exitWith {
    [_fobBuilding] call FLO_fnc_campaignRegisterBase;
    ["FOB", 3, format ["FOB at %1 already initialized", getPos _fobBuilding]] call FLO_fnc_log;
    true
};

_fobBuilding setVariable ["FLO_FOB_Initialized", true, true];
if (isNil { _fobBuilding getVariable "FLO_BaseSide" }) then {
    _fobBuilding setVariable ["FLO_BaseSide", FLO_ActivePlayerSide, true];
};
_fobBuilding setVariable ["FLO_BaseType", "FOB", true];
[_fobBuilding] call FLO_fnc_campaignRegisterBase;

private _config = createHashMapFromArray [
    ["type", "FOB"],
    ["actionPrefix", "FOB"],
    ["markerText", "FOB"],
    ["markerSize", [1.5, 1.5]],
    ["markerVariable", "fobMarkerName"],
    ["initVariable", "FLO_FOB_Initialized"],
    ["restoreVariable", "FLO_FOB_MarkersRestored"],
    ["containerTypeVariable", "FLO_FactionFobTerminalType"],
    ["containerFallbackType", "Land_Cargo20_military_green_F"],
    ["containerSearchRadius", 25],
    ["containerMissingLog", "No FOB container found nearby for commander actions"],
    ["resourceTriggerArea", [5, 5, 0, false, 7]],
    ["resourceSearchRadius", 4],
    ["resourceSearchRadiusLarge", 10],
    ["holdoutTime", 900],
    ["holdoutRadius", 150],
    ["cleanupRadius", 500],
    ["siegeLabel", "FOB"],
    ["siegeMarkerSize", [1.5, 1.5]],
    ["cleanupObjectTypes", [FLO_FactionFobTerminalType]]
];

[_fobBuilding, _config, _preserveMarker] call FLO_fnc_baseCreateMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;
[_fobBuilding, _config] call FLO_fnc_baseConfigureMainActions;
[_fobBuilding, _config] call FLO_fnc_baseConfigureContainerActions;
[_fobBuilding, _config] call FLO_fnc_baseCreateTriggers;

_fobBuilding addEventHandler ["Killed", {
    params ["_unit"];
    [_unit getVariable "FLO_BaseSide", "HQ"] commandChat "All Forces Fall Back. We Lost the FOB...";

    {
        _x params ["_types", "_radius"];
        {
            if (_x isKindOf "Building") then { _x setDamage 1 } else { deleteVehicle _x };
        } forEach (nearestObjects [_unit, _types, _radius]);
    } forEach [
        [[FLO_FactionFobType], 1000],
        [[FLO_FactionFobTerminalType], 1000]
    ];

    private _markerName = _unit getVariable ["fobMarkerName", ""];
    if (_markerName != "") then { deleteMarker _markerName };
    {
        deleteVehicle _x;
    } forEach ((allMissionObjects "EmptyDetector") select { position _x distance _unit < 20 });

    ["FOB", 2, format ["FOB destroyed at %1", getPos _unit]] call FLO_fnc_log;
}];

[_fobBuilding, _config] spawn FLO_fnc_baseMonitorSiege;
[_fobBuilding getVariable "FLO_BaseSide", "HQ"] commandChat "FOB Deployed";
["FOB", 3, format ["FOB initialization completed at %1", getPos _fobBuilding]] call FLO_fnc_log;
true
