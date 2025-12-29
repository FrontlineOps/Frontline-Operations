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

            // Clear any existing waypoints - the calling code will set new ones
            // This prevents old patrol/CYCLE waypoints from interfering with the new mission
            while {count waypoints _realGroup > 0} do {
                deleteWaypoint [_realGroup, 0];
            };
            ["Air Asset Manager", 3, format["Cleared existing waypoints for group %1", _gid]] call FLO_fnc_log;

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

            // Mark group as on mission so virtualization system won't deactivate it
            _gdata set ["onMission", true];
            ["Air Asset Manager", 3, format["Marked group %1 as onMission=true to prevent deactivation", _gid]] call FLO_fnc_log;

            [_veh, _gid]
        }],
        ["_releaseAirAsset", {
            params ["_gid"];
            private _missions = _self get "missions";
            if (_gid in _missions) then {
                private _data = (FLO_virtualGroups get "_groups") get _gid;
                if (!isNil "_data") then {
                    // Clear mission flag before deactivating
                    _data set ["onMission", false];
                    ["Air Asset Manager", 3, format["Cleared onMission flag for group %1, deactivating", _gid]] call FLO_fnc_log;
                    [_gid, _data] call FLO_fnc_deactivateVirtualGroup;
                };
                (_self get "missions") deleteAt _gid;
            };
        }],

        // Get RTB position for an aircraft (returns spawn position)
        ["_getRTBPosition", {
            params ["_groupId"];

            if (isNil "FLO_virtualGroups") exitWith { nil };
            private _gData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, nil];
            if (isNil "_gData") exitWith { nil };

            // Return the group's original spawn position
            _gData get "position"
        }],

        // Send aircraft to RTB
        ["_sendToRTB", {
            params ["_groupId"];

            private _rtbPos = _self call ["_getRTBPosition", [_groupId]];
            if (isNil "_rtbPos") exitWith { false };

            private _gData = (FLO_virtualGroups get "_groups") getOrDefault [_groupId, nil];
            if (isNil "_gData") exitWith { false };

            // Set RTB waypoints - fly to original position and loiter
            private _waypoints = [
                [_rtbPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 50],
                [_rtbPos, "LOITER", "SAFE", "LIMITED", "COLUMN", "GREEN", 500]
            ];
            [_groupId, _waypoints, true] call FLO_fnc_updateVirtualGroupWaypoints;
            _gData set ["currentOrder", "RTB"];

            ["Air Asset Manager", 3, format["Sent aircraft %1 to RTB at %2", _groupId, _rtbPos]] call FLO_fnc_log;
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
                private _gType = _gData getOrDefault ["groupType", ""];
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

FLO_AirAssetManager
