

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

				[30, "TECHNOLOGY"] call FLO_fnc_notification ;

[30] call FLO_fnc_addReward;

 
 sleep 6 ;

 
