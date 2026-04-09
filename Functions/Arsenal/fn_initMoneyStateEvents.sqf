/*
 * Function: FLO_fnc_initMoneyStateEvents
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers the client-side publicVariable event handler that merges the
 *   lightweight money state into the local FLO_MoneyHandle.
 *
 * Arguments: None
 *
 * Return Value:
 *   BOOL
 */

if (!hasInterface) exitWith { false };
if (!isNil "FLO_MoneyStateEventsInit" && {FLO_MoneyStateEventsInit}) exitWith { true };

"FLO_MoneyState" addPublicVariableEventHandler {
    params ["_variableName", "_moneyValue"];
    [_moneyValue] call FLO_fnc_syncMoneyState;
};

[] spawn {
    waitUntil {
        sleep 0.1;
        !isNil "FLO_MissionConfig"
    };

    if (!isNil "FLO_MoneyState") then {
        [FLO_MoneyState] call FLO_fnc_syncMoneyState;
    };
};

FLO_MoneyStateEventsInit = true;

true
