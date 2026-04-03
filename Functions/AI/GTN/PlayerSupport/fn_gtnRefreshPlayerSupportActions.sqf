/*
 * Function: FLO_fnc_gtnRefreshPlayerSupportActions
 * Author: Frontline Operations Development Group
 * Description:
 *   Refreshes the local player commander support request actions.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };
if (isNull player) exitWith { false };

{
    player removeAction _x;
} forEach FLO_GTN_PlayerSupportActionIds;

FLO_GTN_PlayerSupportActionIds = [];

if !((side group player) in [east, west]) exitWith { false };

private _condition = "alive _target && {!visibleMap} && {!isNil 'FLO_MissionReady'} && {FLO_MissionReady}";

FLO_GTN_PlayerSupportActionIds pushBack (
    player addAction [
        "Request Commander Artillery",
        { ["ARTY"] call FLO_fnc_gtnOpenPlayerSupportRequestMap; },
        nil,
        1.4,
        false,
        true,
        "",
        _condition
    ]
);

FLO_GTN_PlayerSupportActionIds pushBack (
    player addAction [
        "Request Commander CAS",
        { ["CAS"] call FLO_fnc_gtnOpenPlayerSupportRequestMap; },
        nil,
        1.3,
        false,
        true,
        "",
        _condition
    ]
);

FLO_GTN_PlayerSupportActionIds pushBack (
    player addAction [
        "Request Commander CAP",
        { ["CAP"] call FLO_fnc_gtnOpenPlayerSupportRequestMap; },
        nil,
        1.2,
        false,
        true,
        "",
        _condition
    ]
);

true
