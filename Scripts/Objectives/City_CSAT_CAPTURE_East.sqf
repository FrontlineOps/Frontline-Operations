private _thisCaptureEastTrigger = _this select 0;
private _posit = getPos _thisCaptureEastTrigger;

sleep 180 ;

if !(isNull _thisCaptureEastTrigger) then {

private _AGGRSCORE = FLO_DifficultyHandle get "value";

if (triggerActivated _thisCaptureEastTrigger) then {
		[playerSide, 'HQ'] commandChat 'all Forces Fall Back. We Lost the OUTPOST,...';

		private _allMarks = allMapMarkers select {markerType _x == 'b_installation'};  
		private _FOBMrk = [_allMarks,  _thisCaptureEastTrigger] call BIS_fnc_nearestPosition;
		deleteMarker _FOBMrk ; 

		private _markerName = 'City' + (str (getPos _thisCaptureEastTrigger));  
		private _mrkr = createMarkerLocal [_markerName, (getPos _thisCaptureEastTrigger)] ;
		_mrkr setMarkerTypeLocal 'o_installation'; 
		_mrkr setMarkerColorLocal 'colorOPFOR';
		_mrkr setMarkerSize [1.2, 1.2]; 

		private _alltriggers = allMissionObjects "EmptyDetector";
		private _triggers = _alltriggers select {getPos _x distance _thisCaptureEastTrigger < 10};
		{ deleteVehicle _x; } forEach _triggers ;
				

		private _trgA = createTrigger ["EmptyDetector", _posit];
		_trgA setTriggerArea [1000, 1000, 0, false, 200];
		_trgA setTriggerTimeout [7,7, 7, true];
		_trgA setTriggerActivation ["WEST", "PRESENT", false];
		_trgA setTriggerStatements ["this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))",  "[thisTrigger] execVM 'Scripts\Objectives\City_CSAT_Flip.sqf';",""]; 
	};		
};