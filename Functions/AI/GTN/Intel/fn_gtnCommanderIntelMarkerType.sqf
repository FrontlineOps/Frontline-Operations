/*
 * Function: FLO_fnc_gtnCommanderIntelMarkerType
 * Author: Frontline Operations Development Group
 * Description:
 *   Maps a GTN group type to a player-facing commander intel marker type.
 *
 * Arguments:
 *   0: Group type <STRING>
 *   1: Marker side <SIDE>
 *
 * Return Value:
 *   Marker type <STRING>
 */

params [
    ["_groupType", "", [""]],
    ["_markerSide", east]
];

private _prefix = if (_markerSide isEqualTo east) then { "o" } else { "b" };

switch (_groupType) do {
    case "armor": { format ["%1_armor", _prefix] };
    case "mechanized": { format ["%1_mech_inf", _prefix] };
    case "motorized": { format ["%1_motor_inf", _prefix] };
    case "mobile_aa";
    case "static_aa": { format ["%1_antiair", _prefix] };
    case "artillery": { format ["%1_art", _prefix] };
    case "infantry": { format ["%1_inf", _prefix] };
    default { format ["%1_unknown", _prefix] };
}
