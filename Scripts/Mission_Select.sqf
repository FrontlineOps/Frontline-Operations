MissionType = _this select 0;
titleText ["Missions Initializing . . .", "BLACK IN", 9999];

// Create mission markers based on mission type
switch (MissionType) do {
    // Rescue Crashed Pilot or Missing Squad
    case 0;
    case 1: {
        private _objectLoc = nearestObjects [Centerposition, ["LocationEvacPoint_F"], 33000]; 
        private _allMarks = allMapMarkers select {
            markerType _x in ["b_installation", "o_installation", "n_installation", "o_support", "n_support", "loc_Power", "loc_Ruin"]
        };
        
        private _NOSHs = [];
        {
            private _nearHouses = nearestObjects [(getMarkerPos _x), ["HOUSE"], 100]; 
            _NOSHs append _nearHouses;
        } forEach _allMarks;
        
        {
            private _allHouses = nearestObjects [_x, ["HOUSE"], 1700] select {count (_x buildingPos -1) > 1};
            private _validHouses = _allHouses - _NOSHs;
            private _targetBuilding = _validHouses select 0;
            
            private _markerName = "InitMissionMark" + (str (getPos _targetBuilding));   
            private _marker = createMarkerLocal [_markerName, (getPos _targetBuilding)];   
            _marker setMarkerTypeLocal "Unknown";  
            _marker setMarkerShapeLocal "ELLIPSE";
            _marker setMarkerBrushLocal "SolidBorder";
            _marker setMarkerSizeLocal [-300, -300];  
            _marker setMarkerColor "colorCivilian";  
        } forEach _objectLoc;
    };
    
    // Intercept Support Convoy mission
    case 2: {
        private _allZoneMarks = allMapMarkers select {markerType _x in ["n_support", "n_installation"]};
        {
            private _markerName = "InitMissionMark" + (str (getMarkerPos _x));   
            private _marker = createMarkerLocal [_markerName, (getMarkerPos _x)];   
            _marker setMarkerTypeLocal "Unknown";  
            _marker setMarkerShapeLocal "ELLIPSE";  
            _marker setMarkerBrushLocal "SolidBorder";
            _marker setMarkerSizeLocal [-500, -500];  
            _marker setMarkerColor "colorCivilian";  
        } forEach _allZoneMarks;
    };
};

["MissionSelect", 3, format["Mission Type: %1", MissionType]] call FLO_fnc_Log;

// Open map and wait for player selection
openMap [true, true]; 
sleep 5;
titleText ["", "BLACK IN", 1];
hint "Select Mission Location"; 

// Add the map click event handler
FLO_mapClickMS = addMissionEventHandler ["MapSingleClick", {
    params ["_control", "_pos", "_alt", "_shift"];
    
    // Debug the position and mission type
    ["MissionSelect", 3, format["Map clicked at pos: %1, MissionType: %2", _pos, MissionType]] call FLO_fnc_Log;
    
    // Remove this event handler so it only triggers once
    removeMissionEventHandler ["MapSingleClick", FLO_mapClickMS];
    
    private _allMarks = allMapMarkers select {
        markerType _x isEqualTo "Unknown" && 
        markerShape _x isEqualTo "ELLIPSE" && 
        markerBrush _x isEqualTo "SolidBorder" && 
        markerColor _x isEqualTo "colorCivilian"
    };
    
    private _nearestMarker = [_allMarks, _pos] call BIS_fnc_nearestPosition;
    
    if (_pos inArea _nearestMarker) then {  
        // Debug the mission type value
        ["MissionSelect", 3, format["Mission Type value before handling: %1 (Type: %2)", MissionType, typeName MissionType]] call FLO_fnc_Log;
        
        // Process mission based on type
        switch (MissionType) do {
            case 0: {
                private _markerName = "MissionMark" + (str (getMarkerPos _nearestMarker));
                private _marker = createMarkerLocal [_markerName, (getMarkerPos _nearestMarker)];   
                _marker setMarkerTypeLocal "mil_unknown";  
                _marker setMarkerColorLocal "colorOPFOR";  
                _marker setMarkerSize [0.8, 0.8]; 
                
                private _trigger = createTrigger ["EmptyDetector", (getMarkerPos _nearestMarker)];
                _trigger setTriggerArea [2000, 2000, 0, false, 60];
                _trigger setTriggerTimeout [1, 1, 1, true];
                _trigger setTriggerActivation ["WEST", "PRESENT", false];
                _trigger setTriggerStatements [
                    "this && (({_x isKindOf 'Man'} count thisList > 0) or ({_x isKindOf 'LandVehicle'} count thisList > 0) or ({_x isKindOf 'Tank'} count thisList > 0) or ({_x isKindOf 'Car'} count thisList > 0))",
                    "[thisTrigger] execVM 'Scripts\Mission_Pilot.sqf';",
                    ""
                ];
            };
            
            case 1: {
                private _markerName = "MissionMark" + (str (getMarkerPos _nearestMarker));   
                private _marker = createMarkerLocal [_markerName, (getMarkerPos _nearestMarker)];   
                _marker setMarkerTypeLocal "mil_warning";  
                _marker setMarkerColorLocal "colorOPFOR";  
                _marker setMarkerSize [0.8, 0.8]; 
                
                private _trigger = createTrigger ["EmptyDetector", (getMarkerPos _nearestMarker)];
                _trigger setTriggerArea [2000, 2000, 0, false, 60];
                _trigger setTriggerTimeout [1, 1, 1, true];
                _trigger setTriggerActivation ["WEST", "PRESENT", false];
                _trigger setTriggerStatements [
                    "this && (({_x isKindOf 'Man'} count thisList > 0) or ({_x isKindOf 'LandVehicle'} count thisList > 0) or ({_x isKindOf 'Tank'} count thisList > 0) or ({_x isKindOf 'Car'} count thisList > 0))",
                    "[thisTrigger] execVM 'Scripts\Mission_Squad.sqf';",
                    ""
                ];
            };
            
            case 2: {
                private _markerName = "ConvoyStrt";
                private _randomPos = (getMarkerPos _nearestMarker) getPos [(10 + (random 50)), (0 + (random 360))];
                private _marker = createMarkerLocal [_markerName, _randomPos];
                _marker setMarkerTypeLocal "mil_marker_noShadow"; 
                _marker setMarkerColorLocal "colorOPFOR";  
                _marker setMarkerTextLocal "Convoy Start";  
                _marker setMarkerSizeLocal [1.5, 1.5];
                _marker setMarkerAlpha 0.7;
                
                private _convoy = [] execVM "Scripts\Mission_Convoy_Custom.sqf";
            };
            
            default {
                ["MissionSelect", 1, format["ERROR: Invalid mission type: %1", _MissionType]] call FLO_fnc_Log;
            };
        };
        
        ["MissionSelect", 3, "After switch - mission handling complete"] call FLO_fnc_Log;
        hint "New Mission Initialized";
        openMap [true, false]; 
        openMap [false, false]; 

        private _MissionMarkers = allMapMarkers select {
            private _shape = markerShape _x;
            private _brush = markerBrush _x;
            private _color = markerColor _x;
            _shape == "ELLIPSE" && _brush == "SolidBorder" && _color == "colorCivilian"
        };
        
        [_MissionMarkers] call FLO_fnc_removeMarkers;
    } else {
        hint "No Mission Found";
        openMap [true, false]; 
        openMap [false, false]; 

        private _MissionMarkers = allMapMarkers select {
            private _shape = markerShape _x;
            private _brush = markerBrush _x;
            private _color = markerColor _x;
            _shape == "ELLIPSE" && _brush == "SolidBorder" && _color == "colorCivilian"
        };
        
        [_MissionMarkers] call FLO_fnc_removeMarkers;
    };
}];





































