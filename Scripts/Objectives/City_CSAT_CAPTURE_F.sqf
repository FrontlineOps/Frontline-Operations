private _thisCaptureTrigger = _this select 0;
private _posit = getPos _thisCaptureTrigger;

sleep 10 ;

private _alltriggers = allMissionObjects "EmptyDetector";
private _triggers = _alltriggers select {getPos _x distance _thisCaptureTrigger < 50};
{ deleteVehicle _x; } forEach _triggers ;

private _trgA = createTrigger ["EmptyDetector", _posit];
_trgA setTriggerArea [1500, 1500, 0, false, 60];
_trgA setTriggerTimeout [7, 7, 7, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements ["this",  "[thisTrigger] execVM 'Scripts\Objectives\City_CSAT.sqf';",""]; 