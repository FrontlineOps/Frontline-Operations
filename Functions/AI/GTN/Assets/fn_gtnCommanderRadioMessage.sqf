/*
 * Function: FLO_fnc_gtnCommanderRadioMessage
 * Author: Frontline Operations Development Group
 * Description:
 *   Plays a side-filtered local side-chat message for GTN support traffic.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Sender label <STRING>
 *   2: Text <STRING>
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_side", sideUnknown],
    ["_sender", "HQ", [""]],
    ["_text", "", [""]]
];

if !(_side in [east, west]) exitWith { false };
if (isNull player) exitWith { false };
if ((side group player) != _side) exitWith { false };

private _identity = switch (toUpper _sender) do {
    case "ARTY": { "Base" };
    case "HQ": { "HQ" };
    default { "HQ" };
};

[_side, _identity] sideChat _text;

true
