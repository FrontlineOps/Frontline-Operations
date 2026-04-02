/*
 * Function: FLO_fnc_gtnRefreshCommanderSupplyToggleAction
 * Author: Frontline Operations Development Group
 * Description:
 *   Refreshes the local player action used to hide or show commander COP
 *   logistics supply-node markers.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface || {isNull player}) exitWith { false };
if !(side group player in [east, west]) exitWith { false };

if (FLO_GTN_CommanderSupplyToggleActionId >= 0) then {
    player removeAction FLO_GTN_CommanderSupplyToggleActionId;
};

private _actionText = if (FLO_GTN_ShowSupplyMarkers) then {
    "<t color='#7CC2FF'>Hide Commander Supply Nodes</t>"
} else {
    "<t color='#7CC2FF'>Show Commander Supply Nodes</t>"
};

FLO_GTN_CommanderSupplyToggleActionId = player addAction [
    _actionText,
    {
        ["toggle"] call FLO_fnc_gtnCommanderSupplyMarkersToggle;
        [] call FLO_fnc_gtnRefreshCommanderSupplyToggleAction;
    },
    [],
    1.2,
    false,
    true,
    "",
    "(side group player) in [east, west]"
];

true
