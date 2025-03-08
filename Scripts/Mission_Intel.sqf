
/////////////////////Gather Intel////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_thisIntelTrigger = _this select 0;

_Chance = selectRandom [1, 2, 3]; 

_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

sleep 15 ; 

_Mount = (nearestLocations [getPos _thisIntelTrigger, ["Mount"], 500]) select 0 ;
_poss = locationPosition _Mount ; 
[ "Recon_OPF_1", _poss, [0, 0, 0], 0, true ] call LARs_fnc_spawnComp;
sleep 5 ; 
{_x setUnitLoadout selectRandom East_Units;} forEach nearestObjects [_poss,["Man"],40];


MapBooard = nearestObjects [_poss,["MapBoard_altis_F"],40] select 0 ;
publicVariable "MapBooard";

			removeAllActions MapBooard;

[MapBooard,[
				"<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Investigate Enemy Plans",
				{
					[(_this select 0)] execVM "Scripts\INTL.sqf";
					(_this select 0) removeAction (_this select 2) ;		

				_MMarks = allMapMarkers select { markerType _x == "o_recon"};
				_M = [_MMarks,  (_this select 0)] call BIS_fnc_nearestPosition;

				deleteMarker _M ; 

				[(_this select 0), 1000] call FLO_fnc_requestQRF;

								[30, "RECON SITE"] call FLO_fnc_notification ;

				[30] call FLO_fnc_addReward;
				[] execVM "Scripts\DangerMinus.sqf";					
				[] execVM "Scripts\DangerMinus.sqf";					
				},
				nil,
				1.5,
				true,
				true,
				"",
				"alive _target", // _target, _this, _originalTarget
				4,
				false,
				"",
				""
]] remoteExec ["addAction",0,true];


PRL = [_poss getPos [(20 + (random 30)),(0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, _poss, 70] call BIS_fnc_taskPatrol;
			PRL deleteGroupWhenEmpty true;


if (_AGGRSCORE > 5) then {
_Mount = selectRandom nearestLocations [getPos _thisIntelTrigger, ["Mount"], 500];
_poss = locationPosition _Mount ; 
[ "Recon_OPF_2", _poss, [0, 0, 0],0, true ] call LARs_fnc_spawnComp;
{_x setUnitLoadout selectRandom East_Units;} forEach nearestObjects [_poss,["Man"],40];



PRL = [_poss getPos [(20 + (random 30)),(0 + (random 360))], East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, _poss, 70] call BIS_fnc_taskPatrol;
			PRL deleteGroupWhenEmpty true;

};

if (_AGGRSCORE > 10) then {
_Mount = selectRandom nearestLocations [getPos _thisIntelTrigger, ["Mount"], 500];
_poss = locationPosition _Mount ; 
[ "Recon_OPF_3", _poss, [0, 0, 0],0, true ] call LARs_fnc_spawnComp;
{_x setUnitLoadout selectRandom East_Units;} forEach nearestObjects [_poss,["Man"],40];


PRL = [_poss getPos [(20 + (random 30)),(0 + (random 360))] , East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
[PRL, _poss, 70] call BIS_fnc_taskPatrol;
			PRL deleteGroupWhenEmpty true;

};



//////Trigger/////////////////////////////////////////////////////////////////////////////////////////

{ if !((side _x) == west) then {
            ZEUS removeCuratorEditableObjects [[_x],true];
}; } foreach allUnits;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
[_thisIntelTrigger, 300] execVM "Scripts\INTLitems.sqf";

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

