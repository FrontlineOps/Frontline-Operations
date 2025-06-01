private _TheTrigg = _this select 1 ; 
private _RWRD = _this select 0;

private _allMarks = allMapMarkers select {markerColor _x == "ColorYellow" && markerType _x == "b_installation"};  
private _FOBMrk = [_allMarks,  _TheTrigg] call BIS_fnc_nearestPosition;

private _Money = FLO_MoneyHandle get "value";
private _NewMoney = _Money + _RWRD; 
FLO_MoneyHandle set ["value", _NewMoney];

sleep 1 ; 