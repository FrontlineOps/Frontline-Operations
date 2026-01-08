/*
    Function: FLO_fnc_gtnAirAssetManager

    Description:
    Manages air groups that exist in the virtualization system. The manager
    unvirtualizes a group for a CAS or strike mission and marks it busy until
    released. This allows systems like the Air Tasking Order to leverage
    existing aircraft instead of spawning new ones.

    Returns:
    HashMap object with methods to request and release air assets.

    Example:
        private _mgr = call FLO_fnc_gtnAirAssetManager;
        private _result = _mgr call ["_requestAirAsset", [getPos player]];
        if (_result isNotEqualTo objNull) then {
            private _aircraft = _result select 0;
            // Use the aircraft for support
        };
*/

params [];

if (isNil "FLO_GTNAirAssetManager") then {
    FLO_GTNAirAssetManager = createHashMapObject [[
        ["missions", createHashMap],
        ["_requestAirAsset", {
            params ["_targetPos", ["_missionType", "CAS"]];

            if (isNil "FLO_virtualGroups") exitWith {objNull};
            private _groups = FLO_virtualGroups get "_groups";
            private _airGroups = [];
            {
                private _gData = _y;
                private _gType = _gData get "groupType";
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

            if !(_gdata get "isActive") then {
                [_gid, _gdata] call FLO_fnc_activateVirtualGroup;
            };

            _gdata = _groups get _gid; // refresh after activation
            
            // Mark group as on mission to prevent deactivation
            _gdata set ["onMission", true];
            ["GTN Air Asset Manager", 3, format["Marked group %1 as onMission=true to prevent deactivation", _gid]] call FLO_fnc_log;
            
            private _realGroup = _gdata get "realGroup";
            if (isNull _realGroup) exitWith {objNull};

            // Clear any existing waypoints
            [_realGroup] call CBA_fnc_clearWaypoints;
            ["GTN Air Asset Manager", 3, format["Cleared existing waypoints for group %1", _gid]] call FLO_fnc_log;

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
                _data set ["onMission", false];
                _self call ["_sendToRTB", [_gid]];
                (_self get "missions") deleteAt _gid;
                ["GTN Air Asset Manager", 3, format["Released air asset %1 - RTB ordered", _gid]] call FLO_fnc_log;
            };
        }],

        // Get RTB position for an aircraft (returns original spawn position)
        ["_getRTBPosition", {
            params ["_groupId"];
            private _gData = (FLO_virtualGroups get "_groups") get _groupId;
            _gData get "spawnPosition"
        }],

        // Send aircraft to RTB - works for both active (real) and virtual groups
        ["_sendToRTB", {
            params ["_groupId"];

            private _rtbPos = _self call ["_getRTBPosition", [_groupId]];
            private _gData = (FLO_virtualGroups get "_groups") get _groupId;
            private _isActive = _gData get "isActive";
            private _realGroup = _gData get "realGroup";

            if (_isActive && !isNull _realGroup) then {
                // Active group - set real waypoints
                [_realGroup] call CBA_fnc_clearWaypoints;

                _realGroup setBehaviour "SAFE";
                _realGroup setCombatMode "GREEN";
                _realGroup setSpeedMode "NORMAL";

                private _wp = _realGroup addWaypoint [_rtbPos, 50];
                _wp setWaypointType "MOVE";
                _wp setWaypointBehaviour "SAFE";
                _wp setWaypointCombatMode "GREEN";
                _wp setWaypointSpeed "NORMAL";

                private _loiterWp = _realGroup addWaypoint [_rtbPos, 500];
                _loiterWp setWaypointType "LOITER";
                _loiterWp setWaypointLoiterType "CIRCLE";
                _loiterWp setWaypointLoiterRadius 500;

                _realGroup setCurrentWaypoint [_realGroup, 1];

                ["GTN Air Asset Manager", 3, format["RTB waypoints set for %1 to %2", _groupId, _rtbPos]] call FLO_fnc_log;
            } else {
                // Virtual group - use virtual waypoint system
                private _waypoints = [
                    [_rtbPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 50],
                    [_rtbPos, "LOITER", "SAFE", "LIMITED", "COLUMN", "GREEN", 500]
                ];
                [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;

                ["GTN Air Asset Manager", 3, format["Virtual RTB waypoints for %1 to %2", _groupId, _rtbPos]] call FLO_fnc_log;
            };

            _gData set ["currentOrder", "RTB"];
            true
        }],

        // Get available aircraft for missions
        ["_getAvailableAircraft", {
            if (isNil "FLO_virtualGroups") exitWith { [] };
            private _groups = FLO_virtualGroups get "_groups";
            private _missions = _self get "missions";
            private _available = [];

            {
                private _gData = _y;
                private _gType = _gData get "groupType";
                if (_gType in ["helicopter", "jet", "air"]) then {
                    if !(_x in _missions) then {
                        _available pushBack _x;
                    };
                };
            } forEach _groups;

            _available
        }]
    ]];
};

FLO_GTNAirAssetManager

