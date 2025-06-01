// Function to hide terrain objects near specified markers
private _hideTerrainObjectsNearMarkers = {
    params ["_markers", "_types", "_radius"];

    {
        private _terrainObjects = nearestTerrainObjects [(getMarkerPos _x), _types, _radius];
        {
            _x hideObjectGlobal true;
        } forEach _terrainObjects;
    } forEach _markers;
};

// Define marker types and radius
private _markerTypes = ["b_installation"];
private _markerColor = "colorBLUFOR";
private _terrainTypes = ["FOREST", "TREE", "SMALL TREE", "BUSH", "ROCK", "ROCKS"];
private _radius = 40;

// Select markers and hide terrain objects
private _objectLocT = allMapMarkers select {markerType _x in _markerTypes && markerColor _x == _markerColor};
[_objectLocT, _terrainTypes, _radius] call _hideTerrainObjectsNearMarkers;

sleep 1;

// Create Minefields If player is in mine area (1km)
private _objectLocTMine = allMapMarkers select { markerType _x == 'loc_mine' };
{
    [_x] spawn {
        params ["_marker"];
        private _pos = getMarkerPos _marker;
        private _executed = false;

        //diag_log format ["Starting minefield check for marker: %1 at position: %2", _marker, _pos];

        scopeName "ExecMinefield";
        while {!_executed} do {
            sleep 2;
            private _units = _pos nearEntities [["Man", "LandVehicle", "Tank", "Car"], 1000];
            private _westPresent = _units findIf {side _x == west} > -1;

            if (_westPresent) then {
                [_pos] execVM "Scripts\Objectives\Minefield.sqf";
                _executed = true; // Set flag to prevent re-execution
                breakOut "ExecMinefield";
                break; // Exit the loop immediately
            };
        };

        //diag_log format ["Minefield execution completed for marker: %1", _marker];
    };
} forEach _objectLocTMine;

sleep 1;

// Create AAA sites & Set Trigger for Defenders to spawn if player is in AAA area
private _objectLocTAAA = allMapMarkers select { markerType _x == "o_antiair"};
{
    private _P1 =  [ 
        "AAA_01",  
        "AAA_02",  
        "AAA_03"    
    ]; 

    _dir = 0 + (random 360);
    if (count (nearestObjects [(getMarkerpos _x), ["House"], 200]) != 0) then {
        _dir = getDirVisual ((nearestObjects [(getMarkerpos _x), ["House"], 200]) select 0);
    };

    private _TERR = nearestTerrainObjects [(getMarkerpos _x), ['FOREST', 'House', 'TREE', 'SMALL TREE', 'BUSH', 'ROCK', 'ROCKS'], 40]; 
    {_x hideObjectGlobal true;} forEach _TERR ;

    private _compReference = [ selectRandom _P1, (getMarkerpos _x), [0,0,0], _dir, true ] call LARs_fnc_spawnComp;

    sleep 0.1;

    private _ARRAY = [ _compReference ] call LARs_fnc_getCompObjects;
    {_x setVectorUp [0,0,1];} forEach _ARRAY; 

} forEach _objectLocTAAA;

sleep 1;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_objectLocT = allMapMarkers select { markerType _x == "n_installation"};

{

_trg = createTrigger ["EmptyDetector", getMarkerpos _x, false];
_trg setTriggerArea [2000, 2000, 0, false, 300];
_trg setTriggerTimeout [1, 1, 1, true];
_trg setTriggerActivation ["WEST", "PRESENT", false];
_trg setTriggerStatements [
"this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))","

_trgA = createTrigger ['EmptyDetector', getPos thisTrigger, false];
_trgA setTriggerArea [1000, 1000, 0, false, 300];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\Capital_CSAT.sqf';

"",""""];

_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger) getPos [(300 + (random 300)),(0 + (random 350))], false];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';

"",""""];

};

", ""];

} forEach _objectLocT;


["LOADING . . . "] remoteExec ["hint", 0];
sleep 1;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_objectLocT = allMapMarkers select { markerType _x == "o_support"};

{
	
_trg = createTrigger ["EmptyDetector", getMarkerpos _x, false];
_trg setTriggerArea [2000, 2000, 0, false, 300];
_trg setTriggerTimeout [1, 1, 1, true];
_trg setTriggerActivation ["WEST", "PRESENT", false];
_trg setTriggerStatements [
"this","	
	
if ( count (nearestObjects [thisTrigger, ['Land_Cargo_Tower_V3_F', 'Land_Cargo_Tower_V2_F', 'Land_Cargo_Tower_V1_F', 'Land_Cargo_HQ_V3_F', 'Land_Cargo_HQ_V2_F', 'Land_Cargo_HQ_V1_F'], 100] ) == 0) then {

_TERR = nearestTerrainObjects [(getPos thisTrigger), ['FOREST', 'House', 'TREE', 'SMALL TREE', 'BUSH', 'ROCK', 'ROCKS'], 40]; 
{_x hideObjectGlobal true;} forEach _TERR ;

_AGGRSCORE = FLO_DifficultyHandle get ""value"";  

if (_AGGRSCORE < 6) then {
OUTC = [ 
'Outpost_01',  
'Outpost_02',  
'Outpost_03',  
'Outpost_04',  
'Outpost_05',  
'Outpost_06',  
'Outpost_07',
'Factory_1',  
'Factory_2'  
]; };

if (_AGGRSCORE > 5) then {
OUTC = [ 
'Outpost_08',  
'Outpost_09',  
'Outpost_10',  
'Outpost_11',  
'Outpost_12',  
'Outpost_13',
'Factory_3',  
'Factory_4'
]; };

if (_AGGRSCORE > 10) then {
OUTC = [ 
'Outpost_14',  
'Outpost_15',  
'Outpost_16',  
'Outpost_17',  
'Outpost_18',
'Factory_5',  
'Factory_6'
]; };


_dir = 0 + (random 360);
if (count (nearestObjects [(getPos thisTrigger), ['House'], 200]) != 0) then {
_dir = getDirVisual ((nearestObjects [(getPos thisTrigger), ['House'], 200]) select 0);
};


_compReference = [ selectRandom OUTC, (getPos thisTrigger), [0,0,0], _dir, true ] call LARs_fnc_spawnComp;

_ARRAY = [ _compReference ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1];} forEach _ARRAY; 
};

_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger), false];
_trgA setTriggerArea [1000, 1000, 0, false, 300];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\Outpost_CSAT.sqf';

"",""""];

_trgA = createTrigger ['EmptyDetector', (getPos thisTrigger) getPos [(300 + (random 300)),(0 + (random 350))], false];
_trgA setTriggerArea [500, 500, 0, false, 60];
_trgA setTriggerInterval 3;
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))"",""

[thisTrigger] execVM 'Scripts\Objectives\Recon_CSAT.sqf';

"",""""];

", ""];

} forEach _objectLocT;

["LOADING . . . "] remoteExec ["hint", 0];
sleep 1;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
_objectLocT = allMapMarkers select { markerType _x == "o_service"};

{


_trg = createTrigger ["EmptyDetector", getMarkerpos _x, false];
_trg setTriggerArea [2000, 2000, 0, false, 300];
_trg setTriggerTimeout [1, 1, 1, true];

_trg setTriggerTimeout [1, 1, 1, true];
_trg setTriggerActivation ["WEST", "PRESENT", false];
_trg setTriggerStatements [
"this","	

_TERR = nearestTerrainObjects [(getPos thisTrigger), ['FOREST', 'House', 'TREE', 'SMALL TREE', 'BUSH', 'ROCK', 'ROCKS'], 40]; 
{_x hideObjectGlobal true;} forEach _TERR ;

_AGGRSCORE = FLO_DifficultyHandle get ""value"";  

if (_AGGRSCORE < 6) then {
RDPC = [ 
'Road_Post_CSAT_01',  
'Road_Post_CSAT_02',
'Road_Post_CSAT_01',  
'Road_Post_CSAT_02',
'Road_Post_CSAT_01',  
'Road_Post_CSAT_02',
'Road_Post_CSAT_01',  
'Road_Post_CSAT_02',
'Watchpost_2', 
'Watchpost_3', 
'Watchpost_4', 
'Watchpost_5', 
'Watchpost_6',
'Watchpost_7',
'Watchpost_8',
'Watchpost_9',
'Watchpost_10'
]; };

if (_AGGRSCORE > 5) then {
RDPC =  [ 
'Road_Post_CSAT_03',  
'Road_Post_CSAT_04',
'Road_Post_CSAT_03',  
'Road_Post_CSAT_04',
'Road_Post_CSAT_03',  
'Road_Post_CSAT_04',
'Road_Post_CSAT_03',  
'Road_Post_CSAT_04',
'Road_Post_CSAT_03',  
'Road_Post_CSAT_04',
'Road_Post_CSAT_03',  
'Road_Post_CSAT_04',
'Road_Post_CSAT_03',  
'Road_Post_CSAT_04',
'Road_Post_CSAT_03',  
'Road_Post_CSAT_04',
'Watchpost_2', 
'Watchpost_3', 
'Watchpost_4', 
'Watchpost_5', 
'Watchpost_6',
'Watchpost_7',
'Watchpost_8',
'Watchpost_9',
'Watchpost_10'
]; };

if (_AGGRSCORE > 10) then {
RDPC =  [ 
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Road_Post_CSAT_05',  
'Road_Post_CSAT_06',
'Watchpost_2', 
'Watchpost_3', 
'Watchpost_4', 
'Watchpost_5', 
'Watchpost_6',
'Watchpost_7',
'Watchpost_8',
'Watchpost_9',
'Watchpost_10'
]; };

       _nearRoad = ( (getPos thisTrigger) nearRoads 10 ) select 0;
		_nextRoad = ( roadsConnectedTo _nearRoad ) select 0;
		_dir = _nearRoad getDir _nextRoad;
		
		
_COM = [ selectRandom RDPC, getPosATL _nearRoad, [0,0,0], _dir, true ] call LARs_fnc_spawnComp;	
_ARRAY = [ _COM ] call LARs_fnc_getCompObjects;
{_x setVectorUp [0,0,1]} forEach _ARRAY;


_trgA = createTrigger ['EmptyDetector', (getPosATL _nearRoad), false];
_trgA setTriggerArea [1000, 1000, 0, false, 300];
_trgA setTriggerTimeout [1, 1, 1, true];

_trgA setTriggerActivation ['WEST', 'PRESENT', false];
_trgA setTriggerStatements [
""this"",""

[thisTrigger] execVM 'Scripts\Objectives\RoadBlock_CSAT.sqf';

"",""""];

", ""];

} forEach _objectLocT;

sleep 1;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

private _objectLocT = allMapMarkers select { markerType _x == "o_recon" };

{

private _trgA = createTrigger ["EmptyDetector", getMarkerpos _x, false];
_trgA setTriggerArea [1000, 1000, 0, false, 300];
_trgA setTriggerTimeout [1, 1, 1, true];
_trgA setTriggerActivation ["WEST", "PRESENT", false];
_trgA setTriggerStatements [
"this && (({_x isKindOf 'Man'} count thisList >0) or ({_x isKindOf 'LandVehicle'} count thisList >0) or ({_x isKindOf 'Tank'} count thisList >0) or ({_x isKindOf 'Car'} count thisList >0))","

[thisTrigger] execVM 'Scripts\Mission_Intel.sqf';

", ""];

sleep 0.2;

} forEach _objectLocT;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sleep 4;


private _aaTypes = ["O_Radar_System_02_F", "O_SAM_System_04_F"];
private _samType = ["O_SAM_System_04_F"];

// Create crew for all AA systems
{
    private _crew = createVehicleCrew _x;
    private _group = createGroup [east, true];
    {[_x] joinSilent _group} forEach units _crew;
} forEach (nearestObjects [position player, _aaTypes, 40000]);

// Setup SAM kill handlers
{
    _x removeAllEventHandlers "Killed";
    _x addEventHandler ["Killed", {
        params ["_killed"];
        
        // Find and delete associated marker
        private _markers = allMapMarkers select {markerType _x == "o_antiair"};
        private _nearestMarker = [_markers, _killed] call BIS_fnc_nearestPosition;
        deleteMarker _nearestMarker;
        
        // Send reward notification and add reward
        [40, "STR_FLO_AASITE"] call FLO_fnc_sendRewardNotification;
        [40] call FLO_fnc_addReward;
        
        // Create new assault marker
        private _markerName = format ["AssaultMark%1", random 1000];
        private _marker = createMarker [_markerName, [random 1000, random 1000, 0]];
        _marker setMarkerType "loc_Bunker";
        _marker setMarkerAlpha 0.003;
        
        // Increase danger level
        [0.35, 'increase'] call FLO_fnc_adjustAggression;
    }];
} forEach (nearestObjects [position player, _samType, 40000]);

TRG1LOCC = 1;
publicVariable "TRG1LOCC";