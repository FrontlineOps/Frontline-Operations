/*
 * Function: FLO_fnc_sideMissionSabotage
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts a mission to sabotage enemy technology or supplies.
 */

params [];

private _GNRT = "YES";
private _DVRT = "NO";
[_DVRT, _GNRT] spawn {
    params ["_DVRT", "_GNRT"];
    private _result = [
        "Intel reports a valuable enemy device in the area. Destroy it (Optional Mission: Sabotage Tech)",
        "", _DVRT, _GNRT, nil, false, false
    ] call BIS_fnc_guiMessage;

    if (_result) then {
        [player] call FLO_fnc_revealRandomEnemyGroup;
    } else {
        private _pos = player getPos [300 + random 300, random 360];
        private _obj = createVehicle ["Land_CargoBox_V1_F", _pos, [], 0, "NONE"];
        [_obj] spawn {
            params ["_CRVEH"];
        };


_CRVEH = _this select 0;

titleText ["Planting Explosives Charges . . .", "BLACK IN",9999];
sleep 2 ;
titleText ["Planting Explosives Charges . . .", "BLACK IN",1];


["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 10</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;
["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 9</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;
["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 8</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;
["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 7</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;
["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 6</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;
["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 5</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;
["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 4</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;
["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 3</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;
["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in 2</t>",-1,-1,1,0.1,0,789] spawn BIS_fnc_dynamicText;
sleep 1 ;

[_CRVEH, "Sh_82mm_AMOS", 0, 1, 1] spawn BIS_fnc_fireSupportVirtual;
sleep 1.5 ;
_CRVEH setdamage 1;

				[30, "STR_FLO_TECH"] call FLO_fnc_sendRewardNotification ;

[30] call FLO_fnc_addReward;

 
 sleep 6 ;

 
    };
};
