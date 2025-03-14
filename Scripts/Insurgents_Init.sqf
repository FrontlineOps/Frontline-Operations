

_thisCenterTrigger = _this select 0;


_mrkrs = allMapMarkers select {markerColor _x == "Color4_FD_F"};
_mrkr = _mrkrs select 0;
_REPSCORE = parseNumber (markerText _mrkr) ;  

allInsurPositions = [] ;


_chance = selectRandom [1, 2] ;
if (_Chance == 1) then {
		_Road= selectRandom (_thisCenterTrigger nearRoads 1500)  ; 
				_markerName = "InsurMark" + (str getPos _Road) ;  
				_mrkr = createMarker [_markerName, (getPos _Road)] ;   
				_mrkr setMarkerType "o_unknown";  
				_mrkr setMarkerColor "colorOPFOR";  
				_mrkr setMarkerSize [0.6, 0.6]; 
				_mrkr setMarkerAlpha 0;				
				
				_trgA = createTrigger ["EmptyDetector", (getPos _Road)];
				_trgA setTriggerArea [500, 500, 0, false, 200];
				_trgA setTriggerTimeout [1, 1, 1, true];
				_trgA setTriggerActivation ["WEST", "PRESENT", false];
				_trgA setTriggerStatements [
				"this","

				[thisTrigger] execVM 'Scripts\Insurgents.sqf';

				", ""];
				
		}else{
		_House = selectRandom (nearestObjects [_thisCenterTrigger, ["HOUSE"], 1500]select {count (_x buildingPos -1) > 3});  
				_markerName = "InsurMark" + (str getPos _House) ;  
				_mrkr = createMarker [_markerName, (getPos _House)] ;   
				_mrkr setMarkerType "o_unknown";  
				_mrkr setMarkerColor "colorOPFOR";  
				_mrkr setMarkerSize [0.6, 0.6];   
				_mrkr setMarkerAlpha 0;				
				
				_trgA = createTrigger ["EmptyDetector", (getPos _House)];
				_trgA setTriggerArea [1000, 1000, 0, false, 200];
				_trgA setTriggerTimeout [1, 1, 1, true];
				_trgA setTriggerActivation ["WEST", "PRESENT", false];
				_trgA setTriggerStatements [
				"this","

				[thisTrigger] execVM 'Scripts\G_CSAT.sqf';

				", ""];				
		};
		
_chance = selectRandom [1, 2] ;
if (count (allMapMarkers select {markerType _x == "o_inf" && (getMarkerPos _x distance getpos _thisCenterTrigger < 1500)}) > 0) then {



_InsVillMrks = allMapMarkers select {markerType _x == "o_inf" && (getMarkerPos _x distance getpos _thisCenterTrigger < 1500)}  ; 
_InsVillMrk = selectRandom _InsVillMrks ;

_alltriggers = allMissionObjects "EmptyDetector";
_triggers = _alltriggers select {(getMarkerPos _InsVillMrk) distance (getPos _x) < 10};

		if (count _triggers == 0) then {

				_markerName = "InsurVillVillMark" + (str getMarkerPos _InsVillMrk) ;  
				_mrkr = createMarker [_markerName, (getMarkerPos _InsVillMrk)] ;   
				_mrkr setMarkerType "o_unknown";  
				_mrkr setMarkerColor "colorOPFOR";  
				_mrkr setMarkerSize [0.6, 0.6];  
				_mrkr setMarkerAlpha 0;				

				_trgA = createTrigger ["EmptyDetector", (getMarkerPos _InsVillMrk)];
				_trgA setTriggerArea [1000, 1000, 0, false, 200];
				_trgA setTriggerTimeout [1, 1, 1, true];
				_trgA setTriggerActivation ["WEST", "PRESENT", false];
				_trgA setTriggerStatements [
				"this","

				[thisTrigger] execVM 'Scripts\Objectives\Town_CSAT.sqf';

				", ""];				
			};
			
		}else{
			
		_Mount = selectRandom (nearestLocations [ _thisCenterTrigger, ["Mount"], 1500]);  
				_markerName = "InsurMark" + (str locationPosition _Mount) ;  
				_mrkr = createMarker [_markerName, (locationPosition _Mount)] ;   
				_mrkr setMarkerType "o_unknown";  
				_mrkr setMarkerColor "colorOPFOR";  
				_mrkr setMarkerSize [0.6, 0.6];   
				_mrkr setMarkerAlpha 0;				
				
				_trgA = createTrigger ["EmptyDetector", (locationPosition _Mount)];
				_trgA setTriggerArea [1000, 1000, 0, false, 200];
				_trgA setTriggerTimeout [1, 1, 1, true];
				_trgA setTriggerActivation ["WEST", "PRESENT", false];
				_trgA setTriggerStatements [
				"this","

				[thisTrigger] execVM 'Scripts\Insurgents.sqf';

				", ""];								
		};

if (_REPSCORE < 7) then {		
_chance = selectRandom [1, 2] ;
if (_Chance == 1) then {
		_Road= selectRandom (_thisCenterTrigger nearRoads 1500)  ; 
				_markerName = "InsurMark" + (str getPos _Road) ;  
				_mrkr = createMarker [_markerName, (getPos _Road)] ;   
				_mrkr setMarkerType "o_unknown";  
				_mrkr setMarkerColor "colorOPFOR";  
				_mrkr setMarkerSize [0.6, 0.6];   
				_mrkr setMarkerAlpha 0;				
				
				_trgA = createTrigger ["EmptyDetector", (getPos _Road)];
				_trgA setTriggerArea [1000, 1000, 0, false, 200];
				_trgA setTriggerTimeout [1, 1, 1, true];
				_trgA setTriggerActivation ["WEST", "PRESENT", false];
				_trgA setTriggerStatements [
				"this","

				[thisTrigger] execVM 'Scripts\Insurgents.sqf';

				", ""];
				
		}else{
		_House = selectRandom (nearestObjects [_thisCenterTrigger, ["HOUSE"], 1500]select {count (_x buildingPos -1) > 3});  
				_markerName = "InsurMark" + (str getPos _House) ;  
				_mrkr = createMarker [_markerName, (getPos _House)] ;   
				_mrkr setMarkerType "o_unknown";  
				_mrkr setMarkerColor "colorOPFOR";  
				_mrkr setMarkerSize [0.6, 0.6];   
				_mrkr setMarkerAlpha 0;				
				
				_trgA = createTrigger ["EmptyDetector", (getPos _House)];
				_trgA setTriggerArea [1000, 1000, 0, false, 200];
				_trgA setTriggerTimeout [1, 1, 1, true];
				_trgA setTriggerActivation ["WEST", "PRESENT", false];
				_trgA setTriggerStatements [
				"this","

				[thisTrigger] execVM 'Scripts\G_CSAT.sqf';

				", ""];				
		};
};


if (_REPSCORE < 5) then {

if (count (allMapMarkers select {markerType _x == "o_inf" && (getMarkerPos _x distance _thisCenterTrigger < 1500)}) > 0) then {

_InsVillMrks = allMapMarkers select {markerType _x == "o_inf" && (getMarkerPos _x distance _thisCenterTrigger < 1500)}  ; 
_InsVillMrk = selectRandom _InsVillMrks ;

				_markerName = "InsurVillVillMark" + (str getMarkerPos _InsVillMrk) ;  
				_mrkr = createMarker [_markerName, (getMarkerPos _InsVillMrk)] ;   
				_mrkr setMarkerType "o_unknown";  
				_mrkr setMarkerColor "colorOPFOR";  
				_mrkr setMarkerSize [0.6, 0.6];  
				_mrkr setMarkerAlpha 0;				

				_trgA = createTrigger ["EmptyDetector", (getMarkerPos _InsVillMrk)];
				_trgA setTriggerArea [1000, 1000, 0, false, 200];
				_trgA setTriggerTimeout [1, 1, 1, true];
				_trgA setTriggerActivation ["WEST", "PRESENT", false];
				_trgA setTriggerStatements [
				"this","

				[thisTrigger] execVM 'Scripts\Objectives\Town_CSAT.sqf';
				
				", ""];				
		}else{
		_Mount = selectRandom (nearestLocations [ _thisCenterTrigger, ["Mount"], 1500]);  
				_markerName = "InsurMark" + (str locationPosition _Mount) ;  
				_mrkr = createMarker [_markerName, (locationPosition _Mount)] ;   
				_mrkr setMarkerType "o_unknown";  
				_mrkr setMarkerColor "colorOPFOR";  
				_mrkr setMarkerSize [0.6, 0.6];   
				_mrkr setMarkerAlpha 0;				
				
				_trgA = createTrigger ["EmptyDetector", (locationPosition _Mount)];
				_trgA setTriggerArea [1000, 1000, 0, false, 200];
				_trgA setTriggerTimeout [1, 1, 1, true];
				_trgA setTriggerActivation ["WEST", "PRESENT", false];
				_trgA setTriggerStatements [
				"this","

				[thisTrigger] execVM 'Scripts\Insurgents.sqf';

				", ""];				
		};
};
