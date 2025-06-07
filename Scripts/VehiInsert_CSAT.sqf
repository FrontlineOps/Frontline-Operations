if (true) then {
    params ["_thisVehiInsertTrigger"];
    
    private _allZoneMarks = allMapMarkers select {
        private _pos = getMarkerPos _x;
        private _type = markerType _x;
        (_pos distance (getPos _thisVehiInsertTrigger) > 2000) && 
        (_type in ["n_installation", "o_installation", "o_antiair", "o_service", "o_armor", "loc_Power", "o_recon", "o_support", "n_support", "loc_Ruin"])
    };
    
    private _nearestMark = [_allZoneMarks, _thisVehiInsertTrigger] call BIS_fnc_nearestPosition;
    private _secondNearestMark = [_allZoneMarks - [_nearestMark], _nearestMark] call BIS_fnc_nearestPosition;
    
    private _spawnRoad = selectRandom ((getMarkerPos _secondNearestMark) nearRoads 1000);
    
    if (LOGDIS == 0) then {
        private ["_veh", "_vc"];
        
        if (selectRandom [true, true, false]) then {
            // Transport vehicle setup
            _veh = createVehicle [selectRandom East_Ground_Transport, getPosATL _spawnRoad, [], 2, "CAN_COLLIDE"];
            
            private _crewCount = [(typeOf _veh), true] call BIS_fnc_crewCount;
            _vc = createGroup [east, true];
            
            for "_i" from 1 to _crewCount do {
                private _unit = _vc createUnit [selectRandom East_Units, getPosATL _spawnRoad, [], 0, "NONE"];
                [_unit] joinSilent _vc;
                _unit moveInAny _veh;
            };
            
            // Intel items setup
            private _intelItems = ["FlashDisk", "FilesSecret", "SmartPhone", "MobilePhone", "DocumentsSecret"];
            private _groupUnits = units _vc;
            private _selectedUnits = ((_groupUnits call BIS_fnc_arrayShuffle) select [0, floor(count _groupUnits / 2)]);
            
            {
                _x addItem selectRandom _intelItems;
            } forEach _selectedUnits;
            
            // Add killed eventhandler for vehicle exit
            {
                _x addEventHandler ["Killed", {
                    params ["_unit"];
                    private _nearVeh = nearestObjects [_unit, ["LandVehicle"], 50] select 0;
                    {
                        [_x] orderGetIn false;
                        [_x] allowGetIn false;
                        unassignVehicle _x;
                        doGetOut _x;
                    } forEach crew _nearVeh;
                }];
            } forEach units _vc;
            
            // Add dismount trigger
            private _dismountTrigger = createTrigger ["EmptyDetector", getPos _veh, false];
            _dismountTrigger setTriggerArea [750, 750, 0, false, 100];
            _dismountTrigger setTriggerActivation ["WEST", "PRESENT", false];
            _dismountTrigger setTriggerStatements [
                "this",
                "
                private _veh = nearestObjects [thisTrigger, ['LandVehicle'], 50] select 0;
                {
                    [_x] orderGetIn false;
                    [_x] allowGetIn false;
                    unassignVehicle _x;
                    doGetOut _x;
                } forEach crew _veh;
                ",
                ""
            ];
            _dismountTrigger attachTo [_veh, [0,0,0]];
            
            // Waypoints
            private _wp1 = _vc addWaypoint [getPos _thisVehiInsertTrigger, 0];
            _wp1 setWaypointType "GETOUT";
            _wp1 setWaypointBehaviour "AWARE";
            
        } else {
            // Combat vehicle setup
            _veh = createVehicle [selectRandom East_Ground_Vehicles_Light, getPosATL _spawnRoad, [], 2, "CAN_COLLIDE"];
            private _tempGroup = createVehicleCrew _veh;
            _vc = createGroup [east, true];
            (units _tempGroup) joinSilent _vc;
            deleteGroup _tempGroup;
        };
        
        // Common vehicle settings
        (driver _veh) disableAI "LIGHTS";
        _veh setPilotLight true;
        
        // Common waypoints
        private _wp2 = _vc addWaypoint [getMarkerPos _secondNearestMark, 0];
        _wp2 setWaypointType "MOVE";
        _wp2 setWaypointBehaviour "AWARE";
        
        private _wpCycle = _vc addWaypoint [getMarkerPos _secondNearestMark, 3];
        _wpCycle setWaypointType "CYCLE";
        _wpCycle setWaypointBehaviour "AWARE";
    };
    
    // Remains collector management
    private _nonWestUnits = allUnits select {side _x != west};
    private _nonWestVehicles = vehicles select {!isNull driver _x && {side driver _x != west}};
    
    {removeFromRemainsCollector [_x]} forEach (_nonWestUnits + _nonWestVehicles);
    sleep 3;
    {addToRemainsCollector [_x]} forEach (_nonWestUnits + _nonWestVehicles);
};
