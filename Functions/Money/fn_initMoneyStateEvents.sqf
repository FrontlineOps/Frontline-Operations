/*
 * Function: FLO_fnc_initMoneyStateEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies the initial lightweight money state locally.
 *   Subsequent server changes are pushed directly by FLO_fnc_publishMoneyState.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };
if (!isNil "FLO_MoneyStateEventsInit" && {FLO_MoneyStateEventsInit}) exitWith { true };

[] spawn {
    waitUntil {
        sleep 0.1;
        !isNil "FLO_MissionConfig"
        && {!isNil "FLO_MoneyState"}
    };

    [FLO_MoneyState] call FLO_fnc_syncMoneyState;
};

FLO_MoneyStateEventsInit = true;

true
