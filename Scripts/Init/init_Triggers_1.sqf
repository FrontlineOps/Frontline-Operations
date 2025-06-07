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