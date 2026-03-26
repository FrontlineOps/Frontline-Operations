/*
 * Function: FLO_fnc_gtnCommanderRadioMessage
 * Author: Frontline Operations Development Group
 * Description:
 *   Plays a side-filtered local command-chat message for GTN support traffic.
 *
 * Arguments:
 *   0: Side <SIDE>
 *   1: Sender label <STRING>
 *   2: Text <STRING>
 *   3: Delay seconds <NUMBER>
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_side", sideUnknown],
    ["_sender", "HQ", [""]],
    ["_text", "", [""]],
    ["_delay", 0, [0]]
];

if !(_side in [east, west]) exitWith { false };
if (isNull player) exitWith { false };
if ((side group player) != _side) exitWith { false };

[_side, _sender, _text, _delay] spawn {
    params ["_side", "_sender", "_text", "_delay"];
    if (_delay > 0) then {
        sleep _delay;
    };
    [_side, _sender] commandChat _text;
};

true
