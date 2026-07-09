/*
 * Function: FLO_fnc_civilianConfigureActionsLocal
 * Author: Frontline Operations Development Group
 * Description:
 *   Configures civilian interaction actions locally for one client and
 *   removes any previously registered FLO civilian actions on that unit.
 *
 * Arguments:
 * 0: Civilian unit <OBJECT>
 * 1: Is protester <BOOL>
 * 2: Is detained <BOOL>
 *
 * Return Value:
 * BOOL
 */

if (!hasInterface) exitWith { false };

params [
    ["_unit", objNull, [objNull]],
    ["_isProtester", false, [true]],
    ["_isDetained", false, [true]]
];

if (isNull _unit) exitWith { false };

removeAllActions _unit;

private _actionIds = _unit getVariable ["FLO_CivilianLocalActionIds", []];
{
    _unit removeAction _x;
} forEach _actionIds;

_actionIds = [];

if (!alive _unit) exitWith {
    _unit setVariable ["FLO_CivilianLocalActionIds", _actionIds];
    false
};

if (_isDetained) then {
    _actionIds pushBack (_unit addAction [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Escort Detainee",
        {
            params ["_target", "_caller"];
            ["ESCORT", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
        },
        nil, 0, true, true, "", "alive _target && captive _target", 3, false, "", ""
    ]);

    _actionIds pushBack (_unit addAction [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Halt Detainee",
        {
            params ["_target"];
            ["HALT", [_target]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
        },
        nil, 0, true, true, "", "alive _target && captive _target", 3, false, "", ""
    ]);

    _actionIds pushBack (_unit addAction [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Load Nearby Vehicle",
        {
            params ["_target", "_caller"];
            ["LOAD", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
        },
        nil, 0, true, true, "", "alive _target && captive _target && {(nearestObjects [_target, ['Air', 'Ship', 'LandVehicle'], 15]) isNotEqualTo []}", 5, false, "", ""
    ]);

    _actionIds pushBack (_unit addAction [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Interrogate",
        {
            params ["_target", "_caller"];
            ["INTERROGATE", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
        },
        nil, 0, true, true, "", "alive _target && captive _target", 4, false, "", ""
    ]);

    _actionIds pushBack (_unit addAction [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Release",
        {
            params ["_target", "_caller"];
            ["RELEASE", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
        },
        nil, 0, true, true, "", "alive _target && captive _target", 4, false, "", ""
    ]);
} else {
    if (!_isProtester) then {
        _actionIds pushBack (_unit addAction [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Ask About Activity",
            {
                params ["_target", "_caller"];
                [_target, _caller] call FLO_fnc_civilianRequestIntel;
            },
            nil, 1.5, true, true, "", "alive _target && !captive _target", 4, false, "", ""
        ]);

        _actionIds pushBack (_unit addAction [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\defend_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Offer Help",
            {
                params ["_target", "_caller"];
                [_target, _caller] call FLO_fnc_civilianRequestMission;
            },
            nil, 1.5, true, true, "", "alive _target && !captive _target", 4, false, "", ""
        ]);
    };

    _actionIds pushBack (_unit addAction [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Detain",
        {
            params ["_target", "_caller"];
            ["DETAIN", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
        },
        nil, 0, true, true, "", "alive _target && !captive _target", 5, false, "", ""
    ]);
};

_unit setVariable ["FLO_CivilianLocalActionIds", _actionIds];

true
