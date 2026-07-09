/*
 * Function: FLO_fnc_syncMoneyState
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies replicated money state into the local FLO_MoneyHandle on clients.
 *
 * Arguments:
 *   0: Money value <NUMBER>
 *
 * Return Value:
 *   BOOL
 */

params [["_moneyValue", 0, [0]]];

if (isNil "FLO_MoneyHandle") then {
    private _moneyName = "";
    if (!isNil "FLO_MissionConfig" && {"moneyHandle" in FLO_MissionConfig}) then {
        _moneyName = (FLO_MissionConfig get "moneyHandle") get "name";
    };

    FLO_MoneyHandle = createHashMapFromArray [
        ["value", _moneyValue],
        ["name", _moneyName]
    ];
} else {
    FLO_MoneyHandle set ["value", _moneyValue];
};

missionNamespace setVariable ["FLO_MoneyState", _moneyValue];

true
