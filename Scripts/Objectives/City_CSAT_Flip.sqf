
_thisCityTrigger = _this select 0;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_mrkrs = allMapMarkers select {markerColor _x == "Color6_FD_F"};
_mrkr = _mrkrs select 0;
_AGGRSCORE = parseNumber (markerText _mrkr) ;  
//////Resources////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


[_thisCityTrigger, 'Sh_82mm_AMOS', 250, 15, 7, {!alive MortarRoad}, 5] spawn BIS_fnc_fireSupportVirtual;

			_allZoneMarks = allMapMarkers select {markerType _x == "loc_Power" || markerType _x == "o_support" || markerType _x == "n_support" || markerType _x == "loc_Ruin" || markerType _x == "n_installation" || markerType _x == "o_installation"} ;  
			_AssStartMrk = [_allZoneMarks,  getPos _thisCityTrigger] call BIS_fnc_nearestPosition ;

			_azimuth = (getMarkerPos _AssStartMrk) getDir (getPos _thisCityTrigger);
			_CNTR = (nearestObjects [(getPos _thisCityTrigger), ["Land_Cargo_HQ_V3_F", "Land_Cargo_HQ_V1_F", "Land_Cargo_House_V1_F", "Land_Cargo_House_V3_F", "House"], 300]) select 0 ;

			 _QRF = selectRandom [ "Scripts\HeliInsert_CSAT.sqf", "Scripts\VehiInsert_CSAT.sqf"]; 
			[_CNTR] execVM _QRF ;
			
		_PRL = [_thisCityTrigger getPos [(200 + (random 200)), (_azimuth + (random 20))] , East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
		_WP_1 = _PRL addWaypoint [(getPos _thisCityTrigger), 0]; 
		_WP_1 SetWaypointType "MOVE"; 
		
		_PRL = [_thisCityTrigger getPos [(200 + (random 200)), (_azimuth - (random 20))] , East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
		_WP_1 = _PRL addWaypoint [(getPos _thisCityTrigger), 0]; 
		_WP_1 SetWaypointType "MOVE"; 
		

		
		if (_AGGRSCORE > 10) then {		
			 _QRF = selectRandom [ "Scripts\HeliInsert_CSAT.sqf", "Scripts\VehiInsert_CSAT.sqf"]; 
			[_CNTR] execVM _QRF ;
		_PRL = [_thisCityTrigger getPos [(200 + (random 200)), (_azimuth - (random 20))] , East, [selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units, selectRandom East_Units]] call BIS_fnc_spawnGroup;
		_WP_1 = _PRL addWaypoint [(getPos _thisCityTrigger), 0]; 
		_WP_1 SetWaypointType "MOVE"; 	
		};		
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


// {

// _nvg = hmd _x;
//  _x unassignItem _nvg;
//  _x removeItem _nvg;
// 	  _x addPrimaryWeaponItem "acc_flashlight";
// 	  _x assignItem "acc_flashlight";
// 	  _x enableGunLights "ForceOn";
//   } foreach (allUnits select {side _x == east}); 


sleep 10;




_trg = createTrigger ["EmptyDetector", getPos _thisCityTrigger, false];  
_trg setTriggerArea [220, 220, 0, false, 200];  
_trg setTriggerTimeout [10, 10, 10, true];
_trg setTriggerActivation ["WEST SEIZED", "PRESENT", true];  
_trg setTriggerStatements [  
"this",  "  

[parseText '<t color=""#1AA3FF"" font=""PuristaBold"" align = ""right"" shadow = ""1"" size=""2"">SITREP</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Friendly Forces Dominating the Battle,</t><br /><t color=""#959393"" align = ""right"" shadow = ""1"" size=""0.8"">Keep Up the Fight, We will Capture and Secure the Outpost,</t>', [0, 0.5, 1, 1], nil, 5, 1.7, 0] remoteExec ['BIS_fnc_textTiles', 0];
_allMarks = allMapMarkers select {markerType _x == 'o_installation'};  
_FOBMrk = [_allMarks,  thisTrigger] call BIS_fnc_nearestPosition;
						_FOBMrk setMarkerColor 'ColorGrey' ;	
									_attackingAtGrid = mapGridPosition getMarkerPos _FOBMrk;
								[[west,'HQ'], 'Friendly Forces Dominating the Battle at grid ' + _attackingAtGrid] remoteExec ['sideChat', 0];

[thisTrigger] execVM 'Scripts\Objectives\City_CSAT_CAPTURE_West.sqf';

", "

_allMarks = allMapMarkers select {markerType _x == 'o_installation'};  
_FOBMrk = [_allMarks,  thisTrigger] call BIS_fnc_nearestPosition;
						_FOBMrk setMarkerColor 'colorOPFOR' ;	

"]; 





{ if !((side _x) == west) then {
            ZEUS removeCuratorEditableObjects [[_x],true];
}; } foreach allUnits;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

[_thisCityTrigger, 300] execVM "Scripts\INTLitems.sqf";



sleep 2 ;

