/*
 * Function: FLO_fnc_gtnCommanderSupplyMarkersToggle
 * Author: Frontline Operations Development Group
 * Description:
 *   Toggles the local player's commander COP logistics supply-node markers
 *   without affecting other players.
 *
 * Arguments:
 *   0: Mode <STRING> - "toggle", "enable", or "disable"
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface || {isNull player}) exitWith { false };

params [["_mode", "toggle", [""]]];

switch (toLower _mode) do {
    case "enable": {
        FLO_GTN_ShowSupplyMarkers = true;
    };
    case "disable": {
        FLO_GTN_ShowSupplyMarkers = false;
    };
    default {
        FLO_GTN_ShowSupplyMarkers = !FLO_GTN_ShowSupplyMarkers;
    };
};

if (FLO_GTN_LastCommanderIntelSyncArgs isNotEqualTo []) then {
    FLO_GTN_LastCommanderIntelSyncArgs call FLO_fnc_gtnSyncCommanderIntelMarkers;
};

systemChat format [
    "Commander supply nodes %1",
    ["hidden", "enabled"] select (FLO_GTN_ShowSupplyMarkers)
];

true
