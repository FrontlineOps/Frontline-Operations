/*
 * Function: FLO_fnc_publishMoneyState
 * Author: Frontline Operations Development Group
 * Description:
 *   Publishes the lightweight replicated money scalar while keeping the
 *   authoritative FLO_MoneyHandle structure local to the mutating machine.
 *
 * Arguments:
 *   0: Optional money value override <NUMBER>
 *
 * Return Value:
 *   BOOL
 */

private _moneyValue = if (count _this > 0) then {
    _this param [0, 0, [0]]
} else {
    FLO_MoneyHandle get "value"
};

FLO_MoneyState = _moneyValue;
publicVariable "FLO_MoneyState";

true
