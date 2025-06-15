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
    FLO_AirAssetManager = createHashMapObject [
        ["missions", createHashMap],
        ["_requestAirAsset", {
            params ["_self", "_targetPos", ["_missionType", "CAS"]];

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
            _airGroups = _airGroups select {
                private _id = _x select 0;
                !((_self get "missions") in [_id]) && {true}
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
            params ["_self", "_gid"];
            if ((_self get "missions") in [_gid]) then {
                private _data = (FLO_virtualGroups get "_groups") get _gid;
                if (!isNil "_data") then { [_gid, _data] call FLO_fnc_deactivateVirtualGroup; };
                (_self get "missions") deleteAt _gid;
            };
        }]
    ];
};

FLO_AirAssetManager
