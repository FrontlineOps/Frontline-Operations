if ((typeOf player == F_Officer) || (typeOf player == "B_G_officer_F")) then {

private _Cost = 200;
private _Money = FLO_MoneyHandle get "value";
if (_Money >= _Cost) then {
private _NewMoney = _Money - _Cost; 
FLO_MoneyHandle set ["value", _NewMoney];

private _NewScore = 15; 
FLO_ReputationHandle set ["value", _NewScore];

sleep 12;

["STR_FLO_REPUTATION_TITLE", "STR_FLO_REP_AGG_INCBRIBE", "success"] call FLO_fnc_sendNotification;

}else{hint "Not enough Resources"; };
}else{  hint "You are not authorized for this Request Soldier!"; };

