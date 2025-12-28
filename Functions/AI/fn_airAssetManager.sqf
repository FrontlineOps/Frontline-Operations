/*
    Function: FLO_fnc_airAssetManager

    Description:
    Manages air groups that exist in the virtualization system. The manager
    unvirtualizes a group for a CAS or strike mission and marks it busy until
    released. This allows systems like the Air Tasking Order to leverage
    existing aircraft instead of spawning new ones.

    Returns:
    HashMap object with methods to request and release air assets.

    Example:
        private _mgr = call FLO_fnc_airAssetManager;
        private _result = _mgr call ["_requestAirAsset", [getPos player]];
        if (_result isNotEqualTo objNull) then {
            private _aircraft = _result select 0;
            // Use the aircraft for support
        };
*/

params [];

if (isNil "FLO_AirAssetManager") then {
    FLO_AirAssetManager = createHashMapObject [[
        ["missions", createHashMap],
        ["_requestAirAsset", {
            params ["_targetPos", ["_missionType", "CAS"]];

            if (isNil "FLO_virtualGroups") exitWith {objNull};
            private _groups = FLO_virtualGroups get "_groups";
            private _airGroups = [];
            {
                private _gData = _y;
                private _gType = _gData getOrDefault ["groupType", ""];
                if (_gType in ["helicopter", "jet", "air"]) then {
                    _airGroups pushBack [_x, _gData];
                };
            } forEach _groups;

            if (count _airGroups == 0) exitWith {objNull};

            // Filter out groups already on mission
            private _missions = _self get "missions";
            _airGroups = _airGroups select {
                private _id = _x select 0;
                !(_id in _missions)
            };
            if (count _airGroups == 0) exitWith {objNull};

            // Select nearest group to target
            private _sorted = [_airGroups, [], {(_x select 1) get "position" distance2D _targetPos}, "ASCEND"] call BIS_fnc_sortBy;
            private _sel = _sorted select 0;
            private _gid = _sel select 0;
            private _gdata = _sel select 1;

            if !(_gdata getOrDefault ["isActive", false]) then {
                [_gid, _gdata] call FLO_fnc_activateVirtualGroup;
            };

            _gdata = _groups get _gid; // refresh after activation
            private _realGroup = _gdata get "realGroup";
            if (isNull _realGroup) exitWith {objNull};

            // Determine aircraft vehicle
            private _veh = objNull;
            {
                if (vehicle _x != _x) then {
                    private _v = vehicle _x;
                    if (isNull _veh) then { _veh = _v; };
                };
            } forEach units _realGroup;
            if (isNull _veh) then { _veh = vehicle (leader _realGroup); };
            if (isNull _veh) exitWith {objNull};

            (_self get "missions") set [_gid, _veh];
            [_veh, _gid]
        }],
        ["_releaseAirAsset", {
            params ["_gid"];
            private _missions = _self get "missions";
            if (_gid in _missions) then {
                private _data = (FLO_virtualGroups get "_groups") get _gid;
                if (!isNil "_data") then { [_gid, _data] call FLO_fnc_deactivateVirtualGroup; };
                (_self get "missions") deleteAt _gid;
            };
        }],

        // Find nearest airport for an aircraft type
        ["_findNearestAirport", {
            params ["_pos", ["_aircraftType", "helicopter"]];

            if (isNil "FLO_Airports") then { call FLO_fnc_detectAirports; };
            if (isNil "FLO_Airports" || {count FLO_Airports == 0}) exitWith { nil };

            private _isJet = _aircraftType in ["jet", "plane", "fixed_wing"];
            private _validAirports = [];

            {
                private _airportData = _y;
                private _airportType = _airportData get "type";

                // Jets need runways, helicopters can use helipads
                if (_isJet) then {
                    if (_airportType in ["AIRFIELD", "MIXED"]) then {
                        _validAirports pushBack [_x, _airportData];
                    };
                } else {
                    // Helicopters can use any airport
                    _validAirports pushBack [_x, _airportData];
                };
            } forEach FLO_Airports;

            if (count _validAirports == 0) exitWith { nil };

            // Sort by distance
            private _sorted = [_validAirports, [], {(_x select 1) get "position" distance2D _pos}, "ASCEND"] call BIS_fnc_sortBy;
            _sorted select 0
        }],

        // Assign aircraft to an airport
        ["_assignToAirport", {
            params ["_groupId", "_airportId"];

            if (isNil "FLO_Airports") exitWith { false };
            private _airport = FLO_Airports getOrDefault [_airportId, nil];
            if (isNil "_airport") exitWith { false };

            private _assigned = _airport get "assignedAircraft";
            if !(_groupId in _assigned) then {
                _assigned pushBack _groupId;
                _airport set ["assignedAircraft", _assigned];
            };

            ["Air Asset Manager", 4, format["Assigned aircraft %1 to airport %2", _groupId, _airportId]] call FLO_fnc_log;
            true
        }],

        // Get RTB position for an aircraft
        ["_getRTBPosition", {
            params ["_groupId"];

            if (isNil "FLO_virtualGroups") exitWith { nil };
            private _gData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, nil];
            if (isNil "_gData") exitWith { nil };

            private _pos = _gData get "position";
            private _gType = _gData getOrDefault ["groupType", "helicopter"];

            // Find nearest suitable airport
            private _airport = _self call ["_findNearestAirport", [_pos, _gType]];
            if (isNil "_airport") exitWith { _pos }; // Return to current position if no airport

            private _airportData = _airport select 1;
            private _airportPos = _airportData get "position";

            // For jets, return runway position; for helicopters, return helipad if available
            if (_gType in ["jet", "plane", "fixed_wing"]) then {
                private _runways = _airportData get "runways";
                if (count _runways > 0) then {
                    (_runways select 0) select 0
                } else {
                    _airportPos
                };
            } else {
                private _helipads = _airportData get "helipads";
                if (count _helipads > 0) then {
                    (_helipads select 0) select 0
                } else {
                    _airportPos
                };
            }
        }],

        // Send aircraft to RTB
        ["_sendToRTB", {
            params ["_groupId"];

            private _rtbPos = _self call ["_getRTBPosition", [_groupId]];
            if (isNil "_rtbPos") exitWith { false };

            private _gData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, nil];
            if (isNil "_gData") exitWith { false };

            // Set RTB waypoints
            private _waypoints = [
                [_rtbPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 50],
                [_rtbPos, "LAND", "SAFE", "NORMAL", "COLUMN", "GREEN", 10]
            ];
            [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
            _gData set ["currentOrder", "RTB"];

            ["Air Asset Manager", 3, format["Sent aircraft %1 to RTB at %2", _groupId, _rtbPos]] call FLO_fnc_log;
            true
        }]
    ]];
};

FLO_AirAssetManager
