/*
 * Function: FLO_fnc_civilianInvestigate
 * Author: Frontline Operations Development Group
 * Description:
 * Handles civilian investigation interaction logic (dialogue, reputation, resource cost, etc).
 * Arguments:
 *   0: Civilian unit <OBJECT>
 * Returns: Nothing
 * Usage: [unit] call FLO_fnc_civilianInvestigate;
 */

params ["_civl"];

private _mrkrs = allMapMarkers select {markerColor _x == "Color4_FD_F"};
private _mrkr = _mrkrs select 0;
private _REPSCORE = parseNumber (markerText _mrkr);

private _ChanceN = selectRandom [1, 2, 3];

if ((_civl getUnitTrait "engineer" == true) && (_ChanceN > 1)) then {
    private _complMessage = selectRandom [
        "DEATH TO OUTSIDERS, DEATH TO OUTSIDERS !!!",
        "Walk Away Bastards. . .You Just Bring Chaos and Destruction !!!",
        "You will Pay for what you have done to our Country, I dont tell you shit !!!",
        "May GOD Save us from Your Wicked chains you Devils, May GOD Dawn you all !!!",
        "Your Men Caused my Innocent brothers and sisters Suffer and Die, FUCK YOU ALL !!!"
    ];
    ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
} else {
    if (_REPSCORE > 10) then {
        private _Chance = selectRandom [3, 4, 5];
        if (_Chance > 3) then {
            private _Cost = 5;
            private _Money = FLO_MoneyHandle get "value";
            if (_Money >= _Cost) then {
                private _NewMoney = _Money - _Cost;
                FLO_MoneyHandle set ["value", _NewMoney];
                [] call FLO_fnc_civilianIntel;
                private _complMessage = selectRandom [
                    "Sure, Let me Show you the way!",
                    "We appericiate your Efforts for our Homeland, let me Help you!",
                    "Yes, Come, I know Some !"
                ];
                ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
            } else {
                hint "Not enough Resources";
            };
        } else {
            private _complMessage = selectRandom [
                "We Dont talk to Strangers!",
                "I don't know much about this Region!",
                "Sorry but I dont Trust you Outsiders!",
                "Maybe that Man there can Help you, He has been with the Army years ago !"
            ];
            ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
        };
    } else {
        private _Chance = selectRandom [1, 2, 3];
        if (_Chance > 2) then {
            private _Cost = 5;
            private _Money = FLO_MoneyHandle get "value";
            if (_Money >= _Cost) then {
                private _NewMoney = _Money - _Cost;
                FLO_MoneyHandle set ["value", _NewMoney];
                [] call FLO_fnc_civilianIntel;
                private _complMessage = selectRandom [
                    "Sure, Let me Show you the way!",
                    "We appericiate your Efforts for our Homeland, let me Help you!",
                    "Yes, Come, I know Some !"
                ];
                ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
            } else {
                hint "Not enough Resources";
            };
        } else {
            private _complMessage = selectRandom [
                "We Dont talk to Strangers!",
                "I don't know much about this Region!",
                "Sorry but I dont Trust you Outsiders!",
                "Maybe that Man there can Help you, He has been with the Army years ago !"
            ];
            ["Civilian", _complMessage] remoteExec ["BIS_fnc_showSubtitle"];
        };
    };
} 