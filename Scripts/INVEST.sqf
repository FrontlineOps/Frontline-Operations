_mrkrs = allMapMarkers select {markerColor _x == "Color4_FD_F"};
_mrkr = _mrkrs select 0;
_REPSCORE = parseNumber (markerText _mrkr);  
_Civl = _this select 0;

_ChanceN = selectRandom [1, 2, 3]; 

if ((_Civl getUnitTrait "engineer" == true) && (_ChanceN > 1)) then {	
    _complMessage = selectRandom ["DEATH TO OUTSIDERS, DEATH TO OUTSIDERS !!!", "Walk Away Bastards. . .You Just Bring Chaos and Destruction !!!","You will Pay for what you have done to our Country, I dont tell you shit !!!","May GOD Save us from Your Wicked chains you Devils, May GOD Dawn you all !!!","Your Men Caused my Innocent brothers and sisters Suffer and Die, FUCK YOU ALL !!!"];
    ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
} else {
    if (_REPSCORE > 10) then {
        _Chance = selectRandom [3, 4, 5]; 
        if (_Chance > 3) then {
            _Cost = 5;
            _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
            _mrkr = _mrkrs select 0;
            _Money = parseNumber (markerText _mrkr);  
            if (_Money >= _Cost) then {
                _NewMoney = _Money - _Cost; 
                _mrkr setMarkerText str _NewMoney;
                execVM "Scripts\INTL_Civ.sqf";
                _complMessage = selectRandom ["Sure, Let me Show you the way!","We appericiate your Efforts for our Homeland, let me Help you!","Yes, Come, I know Some !"];
                ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
            } else {
                hint "Not enough Resources";
            };
        } else {
            _complMessage = selectRandom ["We Dont talk to Strangers!","I don't know much about this Region!","Sorry but I dont Trust you Outsiders!","Maybe that Man there can Help you, He has been with the Army years ago !"];
            ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
        };
    } else {
        _Chance = selectRandom [1, 2, 3]; 
        if (_Chance > 2) then {
            _Cost = 5;
            _mrkrs = allMapMarkers select {markerColor _x == "Color2_FD_F"};
            _mrkr = _mrkrs select 0;
            _Money = parseNumber (markerText _mrkr);  
            if (_Money >= _Cost) then {
                _NewMoney = _Money - _Cost; 
                _mrkr setMarkerText str _NewMoney;
                execVM "Scripts\INTL_Civ.sqf";
                _complMessage = selectRandom ["Sure, Let me Show you the way!","We appericiate your Efforts for our Homeland, let me Help you!","Yes, Come, I know Some !"];
                ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
            } else {
                hint "Not enough Resources";
            };
        } else {
            _complMessage = selectRandom ["We Dont talk to Strangers!","I don't know much about this Region!","Sorry but I dont Trust you Outsiders!","Maybe that Man there can Help you, He has been with the Army years ago !"];
            ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
        };
    };
};