/*
 * Function: FLO_fnc_civilianDetainActions
 * Description:
 *   Adds detainee interaction actions that route back to the server command
 *   handler.
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit) exitWith {};

[_unit, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Escort Detainee",
    {
        params ["_target", "_caller"];
        ["ESCORT", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
    },
    nil, 0, true, true, "", "alive _target && captive _target", 3, false, "", ""
]] remoteExec ["addAction", 0, true];

[_unit, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Halt Detainee",
    {
        params ["_target"];
        ["HALT", [_target]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
    },
    nil, 0, true, true, "", "alive _target && captive _target", 3, false, "", ""
]] remoteExec ["addAction", 0, true];

[_unit, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Load Nearby Vehicle",
    {
        params ["_target", "_caller"];
        ["LOAD", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
    },
    nil, 0, true, true, "", "alive _target && captive _target && {(count (nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'], 15])) > 0}", 5, false, "", ""
]] remoteExec ["addAction", 0, true];

[_unit, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Interrogate",
    {
        params ["_target", "_caller"];
        ["INTERROGATE", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
    },
    nil, 0, true, true, "", "alive _target && captive _target", 4, false, "", ""
]] remoteExec ["addAction", 0, true];

[_unit, [
    "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Release",
    {
        params ["_target", "_caller"];
        ["RELEASE", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
    },
    nil, 0, true, true, "", "alive _target && captive _target", 4, false, "", ""
]] remoteExec ["addAction", 0, true];
