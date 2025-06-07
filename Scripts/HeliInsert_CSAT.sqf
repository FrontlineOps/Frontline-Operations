if (true) then {
    params ["_thisHeliInsertTrigger"];
    
    // Find valid zone markers
    private _validMarkerTypes = [
        "n_installation", "o_installation", "o_antiair", 
        "o_service", "o_armor", "loc_Power", 
        "o_recon", "o_support", "n_support", "loc_Ruin"
    ];
    
    private _allZoneMarks = allMapMarkers select {
        private _pos = getMarkerPos _x;
        (_pos distance (getPos _thisHeliInsertTrigger) > 2000) && 
        (markerType _x in _validMarkerTypes)
    };
    
    private _nearestMark = [_allZoneMarks, _thisHeliInsertTrigger] call BIS_fnc_nearestPosition;
    private _targetMark = [_allZoneMarks - [_nearestMark], _nearestMark] call BIS_fnc_nearestPosition;
    private _targetPos = getMarkerPos _targetMark;
    
    if (true) then {
        if (selectRandom [true, true, false]) then {
            // Transport helicopter setup
            private _qrfPos = getPos _thisHeliInsertTrigger;
            private _randomDir = random 360;
            private _landingPos = _qrfPos getPos [1000 + (random 250), _randomDir];
            _landingPos = [_landingPos, 0, 200, 10, 0, 0.2, 0, [], [_landingPos, _landingPos]] call BIS_fnc_findSafePos;
            
            private _spawnPos = _targetPos vectorAdd [0, 0, 100];
            
            private _heli = createVehicle [
                selectRandom (FLO_configCache get "vehicles" select 5), 
                _spawnPos, [], 100, "FLY"
            ];
            
            // Create and setup helicopter crew
            private _heliCrew = createVehicleCrew _heli;
            private _pilotGroup = createGroup [east, true];
            (units _heliCrew) joinSilent _pilotGroup;
            
            // Create and setup QRF team
            private _qrfGroup = createGroup [east, true];
            private _maxCargo = [(typeOf _heli), true] call BIS_fnc_crewCount;
            private _cargoCount = _maxCargo - (count units _pilotGroup) - 1;
            
            for "_i" from 1 to _cargoCount do {
                private _unit = _qrfGroup createUnit [
                    selectRandom (FLO_configCache get "units"),
                    _spawnPos,
                    [],
                    0,
                    "NONE"
                ];
                [_unit] joinSilent _qrfGroup;
            };
            
            // Distribute intel items
            private _intelItems = [
                "FlashDisk", "FilesSecret", "SmartPhone",
                "MobilePhone", "DocumentsSecret"
            ];
            
            private _selectedUnits = (units _qrfGroup) call BIS_fnc_arrayShuffle;
            _selectedUnits resize floor(count _selectedUnits / 2);
            
            {
                _x addItem selectRandom _intelItems;
            } forEach _selectedUnits;
            
            // Setup helicopter waypoints
            private _wpDrop = _pilotGroup addWaypoint [_landingPos, 0];
            _wpDrop setWaypointType "MOVE";
            _wpDrop setWaypointBehaviour "CARELESS";
            _wpDrop setWaypointForceBehaviour true;
            _wpDrop setWaypointStatements [
                "true",
                "(vehicle this) land 'GET OUT'; GroupQRF leaveVehicle (vehicle this);"
            ];
            _wpDrop setWaypointSpeed "FULL";
            
            private _wpRTB = _pilotGroup addWaypoint [_targetPos, 0];
            _wpRTB setWaypointType "MOVE";
            _wpRTB setWaypointSpeed "FULL";
            
            // Setup QRF waypoints
            private _wpDisembark = _qrfGroup addWaypoint [_landingPos, 0];
            _wpDisembark setWaypointType "GETOUT";
            _wpDisembark setWaypointBehaviour "COMBAT";
            _wpDisembark setWaypointCompletionRadius 100;
            
            private _wpAssault = _qrfGroup addWaypoint [getPos _thisHeliInsertTrigger, 0];
            _wpAssault setWaypointType "SAD";
            _wpAssault setWaypointBehaviour "COMBAT";
            
            // Load QRF into helicopter
            {_x moveInCargo _heli} forEach units _qrfGroup;
            
            // Setup helicopter lights
            (driver _heli) disableAI "LIGHTS";
            {_heli setPilotLight true} forEach [true];
            _heli setCollisionLight true;
            
            // Create signal flare
            private _flarePos = getPos _thisHeliInsertTrigger;
            private _flare = createVehicle ["F_20mm_Red", 
                [_flarePos select 0, _flarePos select 1, 120],
                [], 0, "CAN_COLLIDE"
            ];
            _flare setVelocity [0, 0, -0.1];
            
            // Cleanup helicopter after mission
            [_heli, _pilotGroup, _qrfGroup] spawn {
                params ["_heli", "_pilotGroup", "_qrfGroup"];
                sleep 600;
                if (alive _heli) then {deleteVehicle _heli};
                {deleteVehicle _x} forEach (units _pilotGroup + units _qrfGroup);
                deleteGroup _pilotGroup;
                deleteGroup _qrfGroup;
            };
            
        } else {
            // Attack helicopter setup
            private _heli = createVehicle [
                selectRandom (FLO_configCache get "vehicles" select 0),
                _targetPos vectorAdd [0,0,100],
                [], 100, "FLY"
            ];
            
            private _tempGroup = createVehicleCrew _heli;
            private _attackGroup = createGroup [east, true];
            (units _tempGroup) joinSilent _attackGroup;
            
            // Setup attack helicopter behavior
            [_attackGroup, getPos _thisHeliInsertTrigger] call BIS_fnc_taskAttack;
            _heli addEventHandler ["Fuel", {(_this select 0) setFuel 1}];
            _heli flyInHeight 200;
            _attackGroup setSpeedMode "NORMAL";
            
            // Setup helicopter lights
            (driver _heli) disableAI "LIGHTS";
            _heli setPilotLight true;
            _heli setCollisionLight true;
        };
        
        // Manage remains collector
        private _nonWestUnits = allUnits select {side _x != west};
        private _nonWestVehicles = vehicles select {!isNull driver _x && {side driver _x != west}};
        
        {removeFromRemainsCollector [_x]} forEach (_nonWestUnits + _nonWestVehicles);
        sleep 3;
        {addToRemainsCollector [_x]} forEach (_nonWestUnits + _nonWestVehicles);
    };
};