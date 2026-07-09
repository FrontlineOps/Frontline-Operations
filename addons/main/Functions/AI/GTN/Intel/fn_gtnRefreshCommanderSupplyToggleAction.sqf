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
    private _actionOwner = FLO_GTN_CommanderSupplyToggleActionOwner;
    if (isNull _actionOwner) then {
        _actionOwner = player;
    };
    _actionOwner removeAction FLO_GTN_CommanderSupplyToggleActionId;
};

private _actionText = ["<t color='#7CC2FF'>Show Commander Supply Nodes</t>", "<t color='#7CC2FF'>Hide Commander Supply Nodes</t>"] select (FLO_GTN_ShowSupplyMarkers);

FLO_GTN_CommanderSupplyToggleActionId = player addAction [
    _actionText,
    {
        ["toggle"] call FLO_fnc_gtnCommanderSupplyMarkersToggle;
        [] call FLO_fnc_gtnRefreshCommanderSupplyToggleAction;
    },
    [],
    1.2,
    true,
    true,
    "",
    "(side group player) in [east, west]"
];

FLO_GTN_CommanderSupplyToggleActionOwner = player;

true
