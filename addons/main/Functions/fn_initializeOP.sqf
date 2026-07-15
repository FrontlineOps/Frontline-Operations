/* Initializes one campaign COP and its shared base services. */
params [
    ["_opBuilding", objNull, [objNull]],
    ["_preserveMarker", false, [false]]
];

if (isNull _opBuilding) exitWith {
    ["COP", 1, "Null object passed to COP initialization"] call FLO_fnc_log;
    false
};

if (_opBuilding getVariable ["FLO_OP_Initialized", false]) exitWith {
    [_opBuilding] call FLO_fnc_campaignRegisterBase;
    ["COP", 3, format ["COP at %1 already initialized", getPos _opBuilding]] call FLO_fnc_log;
    true
};

_opBuilding setVariable ["FLO_OP_Initialized", true, true];
if (isNil { _opBuilding getVariable "FLO_BaseSide" }) then {
    _opBuilding setVariable ["FLO_BaseSide", FLO_ActivePlayerSide, true];
};
_opBuilding setVariable ["FLO_BaseType", "COP", true];
[_opBuilding] call FLO_fnc_campaignRegisterBase;

private _config = createHashMapFromArray [
    ["type", "COP"],
    ["actionPrefix", "OP"],
    ["markerText", "COP"],
    ["markerSize", [1.5, 1.5]],
    ["markerVariable", "opMarkerName"],
    ["initVariable", "FLO_OP_Initialized"],
    ["restoreVariable", "FLO_OP_MarkersRestored"],
    ["containerTypeVariable", "FLO_FactionCopTerminalType"],
    ["containerFallbackType", "Land_TripodScreen_01_dual_v2_sand_F"],
    ["containerSearchRadius", 10],
    ["containerMissingLog", "No COP container found nearby for actions"],
    ["resourceTriggerArea", [3, 3, 0, false, 7]],
    ["resourceSearchRadius", 3],
    ["resourceSearchRadiusLarge", 10],
    ["holdoutTime", 600],
    ["holdoutRadius", 100],
    ["cleanupRadius", 300],
    ["siegeLabel", "COP"],
    ["siegeMarkerSize", [1.2, 1.2]],
    ["cleanupObjectTypes", [FLO_FactionCopTerminalType]]
];

[_opBuilding, _config, _preserveMarker] call FLO_fnc_baseCreateMarker;
[] call FLO_fnc_refreshRespawnMarkersByTerritory;
[_opBuilding, _config] call FLO_fnc_baseConfigureMainActions;
[_opBuilding, _config] call FLO_fnc_baseConfigureContainerActions;
[_opBuilding, _config] call FLO_fnc_baseCreateTriggers;

_opBuilding addEventHandler ["Killed", {
    params ["_unit"];
    [_unit getVariable "FLO_BaseSide", "HQ"] commandChat "All Forces Fall Back. We Lost the COP...";

    {
        _x params ["_types", "_radius"];
        {
            if (_x isKindOf "Building") then { _x setDamage 1 } else { deleteVehicle _x };
        } forEach (nearestObjects [_unit, _types, _radius]);
    } forEach [
        [[FLO_FactionCopType], 1000],
        [[FLO_FactionCopTerminalType], 1000]
    ];

    private _markerName = _unit getVariable ["opMarkerName", ""];
    if (_markerName != "") then { deleteMarker _markerName };
    {
        deleteVehicle _x;
    } forEach ((allMissionObjects "EmptyDetector") select { position _x distance _unit < 20 });

    ["COP", 2, format ["COP destroyed at %1", getPos _unit]] call FLO_fnc_log;
}];

[_opBuilding, _config] spawn FLO_fnc_baseMonitorSiege;
[_opBuilding getVariable "FLO_BaseSide", "HQ"] commandChat "COP Deployed";
["COP", 3, format ["COP initialization completed at %1", getPos _opBuilding]] call FLO_fnc_log;
true
