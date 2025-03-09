


MissionType = _this select 0;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


titleText ["Missions Initializing . . .", "BLACK IN",9999];


	if ((MissionType == 0) or (MissionType == 1)) then {
		_Centerposition = [worldSize / 2, worldsize / 2, 0];
		_objectLoc = nearestobjects [_Centerposition, ["LocationEvacPoint_F"], 33000]; 
		_allMarks = allMapMarkers select {(markerType _x == "b_installation") or (markerType _x == "o_installation") or (markerType _x == "n_installation") or (markerType _x == "o_support") or (markerType _x == "n_support") or  (markerType _x == "loc_Power") or  (markerType _x == "loc_Ruin")};  
		_NOSHs = [] ;
		{
		_NOSH = nearestObjects [ (getMarkerPos _x) , ["HOUSE"], 400] ; 
		_NOSHs append _NOSH ;	
		} forEach _allMarks ;
		
		{
			_ALLSHs = nearestObjects [_x , ["HOUSE"], 1700] select {count (_x buildingPos -1) > 1};
			_SH = _ALLSHs - _NOSHs ;
			_HQB = _SH select 0 ;
							
			_markerName = "InitMissionMark" + (str (getPos _HQB));   
			_mrkr = createMarker [_markerName, (getPos _HQB)];   
			_mrkr setMarkerType "Unknown";  
			_mrkr setMarkerShape "ELLIPSE";
			_mrkr setMarkerBrush "SolidBorder" ;
			_mrkr setMarkerSize [-300, -300];  
			_mrkr setMarkerColor "colorCivilian";  
		} forEach _objectLoc ;
	};
		
	if ((MissionType == 2)) then {
			_allZoneMarks = allMapMarkers select { markerType _x == "n_support" || markerType _x == "n_installation" } ;  
		{
			_markerName = "InitMissionMark" + (str (getMarkerPos _x));   
			_mrkr = createMarker [_markerName, (getMarkerPos _x)];   
			_mrkr setMarkerType "Unknown";  
			_mrkr setMarkerShape "ELLIPSE";  
			_mrkr setMarkerBrush "SolidBorder" ;			
			_mrkr setMarkerSize [-500, -500];  
			_mrkr setMarkerColor "colorCivilian";  
		} forEach _allZoneMarks ;
	};
		
	if ((MissionType == 3)) then {
		_Centerposition = [worldSize / 2, worldsize / 2, 0];
		_objectLoc = nearestobjects [_Centerposition, ["LocationArea_F"], 33000]; 
		{
			_markerName = "InitMissionMark" + (str (getPos _x));   
			_mrkr = createMarker [_markerName, (getPos _x)];   
			_mrkr setMarkerType "Unknown";  
			_mrkr setMarkerShape "ELLIPSE";  
			_mrkr setMarkerBrush "SolidBorder" ;			
			_mrkr setMarkerSize [-500, -500];  
			_mrkr setMarkerColor "colorCivilian";  
		} forEach _objectLoc ;
	};




openMap [true, true]; 
sleep 5;
titleText ["", "BLACK IN",1];
hint "Select Mission Location"; 
onMapSingleClick {
	onMapSingleClick {}; 



_allMarks = allMapMarkers select {markerType _x == 'Unknown' && markerShape _x == 'ELLIPSE' && markerBrush _x == 'SolidBorder' && markerColor _x == 'colorCivilian'};  
_NrMrk = [_allMarks,  _pos] call BIS_fnc_nearestPosition;

if (_pos inArea _NrMrk ) then {
	
	if (MissionType == 0)  then {
		_allMarks = allMapMarkers select {markerType _x == 'Unknown' && markerShape _x == 'ELLIPSE' && markerBrush _x == 'SolidBorder' && markerColor _x == 'colorCivilian'};  
		_NrMrk = [_allMarks,  _pos] call BIS_fnc_nearestPosition;
								_markerName = "MissionMark" + (str (getMarkerPos _NrMrk));   
								_mrkr = createMarker [_markerName, (getMarkerPos _NrMrk)];   
								_mrkr setMarkerType "mil_unknown";  
								_mrkr setMarkerColor "colorOPFOR";  
								_mrkr setMarkerSize [0.8, 0.8]; 
								
								_trgA = createTrigger ["EmptyDetector", (getMarkerPos _NrMrk)];
								_trgA setTriggerArea [2000, 2000, 0, false, 60];
								_trgA setTriggerTimeout [1, 1, 1, true];
								_trgA setTriggerActivation ["WEST", "PRESENT", false];
								_trgA setTriggerStatements [
								"this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))","

								[thisTrigger] execVM 'Scripts\Mission_Pilot.sqf';


								", ""];
								};

		if (MissionType == 1)  then {
		_allMarks = allMapMarkers select {markerType _x == 'Unknown' && markerShape _x == 'ELLIPSE' && markerBrush _x == 'SolidBorder' && markerColor _x == 'colorCivilian'};  
		_NrMrk = [_allMarks,  _pos] call BIS_fnc_nearestPosition;		
								_markerName = "MissionMark" + (str (getMarkerPos _NrMrk));   
								_mrkr = createMarker [_markerName, (getMarkerPos _NrMrk)];   
								_mrkr setMarkerType "mil_warning";  
								_mrkr setMarkerColor "colorOPFOR";  
								_mrkr setMarkerSize [0.8, 0.8]; 
								
								_trgA = createTrigger ["EmptyDetector", (getMarkerPos _NrMrk)];
								_trgA setTriggerArea [2000, 2000, 0, false, 60];
								_trgA setTriggerTimeout [1, 1, 1, true];
								_trgA setTriggerActivation ["WEST", "PRESENT", false];
								_trgA setTriggerStatements [
								"this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))","

								[thisTrigger] execVM 'Scripts\Mission_Squad.sqf';


								", ""];
								};
	
		if (MissionType == 2)  then {
		_allMarks = allMapMarkers select {markerType _x == 'Unknown' && markerShape _x == 'ELLIPSE' && markerBrush _x == 'SolidBorder' && markerColor _x == 'colorCivilian'};  
		_NrMrk = [_allMarks,  _pos] call BIS_fnc_nearestPosition;								
								_markerName = "ConvoyStrt" ;  
								_mrkr = createMarker [_markerName,  (getMarkerPos _NrMrk) getPos [(10 + (random 50)), (0 + (random 360))]] ;	
								_mrkr setMarkerType "mil_marker_noShadow" ; 
								_mrkr setMarkerColor "colorOPFOR" ;  
								_mrkr setMarkerText "Convoy Start" ;  
								_mrkr setMarkerSize [1.5, 1.5] ;
								_mrkr setMarkerAlpha 0.7 ;  				
								
								_Enemy_Convoy = [] execVM "Scripts\Mission_Convoy_Custom.sqf";
								
								};
	
		if (MissionType == 3)  then {
		_allMarks = allMapMarkers select {markerType _x == 'Unknown' && markerShape _x == 'ELLIPSE' && markerBrush _x == 'SolidBorder' && markerColor _x == 'colorCivilian'};  
		_NrMrk = [_allMarks,  _pos] call BIS_fnc_nearestPosition;			
								_posship = [ _pos, 0, 2500, 3, 2, 1, 0] call BIS_fnc_findSafePos;
								_markerName = "CShipMark" + (str _posship);
								_mrkr = createMarkerLocal [_markerName,_posship];   
								_mrkr setMarkerTypeLocal "o_naval";  
								_mrkr setMarkerColorLocal "colorOPFOR";  
								_mrkr setMarkerSize [1.2, 1.2]; 
 
								_trgA = createTrigger ["EmptyDetector", _posship];
								_trgA setTriggerArea [3000, 3000, 0, false, 100];
								_trgA setTriggerTimeout [1, 1, 1, true];
								_trgA setTriggerActivation ["WEST", "PRESENT", false];
								_trgA setTriggerStatements [
								"this","

								[thisTrigger] execVM 'Scripts\Mission_Ship.sqf';

								", ""];
								};
								hint "New Mission Initialized" ;
openMap [true, false]; 
openMap [false, false]; 

								_Mrk_Rmv = [] execVM "Scripts\MrkRmv.sqf";

} else {
								hint "No Mission Found" ;
openMap [true, false]; 
openMap [false, false]; 	

								_Mrk_Rmv = [] execVM "Scripts\MrkRmv.sqf";				
};								
	


};





































