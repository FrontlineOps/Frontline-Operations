/*
    Function: FLO_fnc_gtnArtilleryManager

    Description:
    Manages artillery groups that exist in the virtualization system. The manager
    can unvirtualize a group for a fire mission, command it to fire, then move
    and revirtualize the group to simulate shoot-and-scoot tactics. This allows
    GTN Resource Manager or other systems to make use of existing virtual artillery
    assets without permanently spawning them in.

    Returns:
    HashMap object with a method to request fire missions.

    Example:
        private _mgr = call FLO_fnc_gtnArtilleryManager;
        _mgr call ["_requestFireMission", [[1000,1000,0], 6]];
*/

params [];

if (isNil "FLO_GTNArtilleryManager") then {
    FLO_GTNArtilleryManager = createHashMapObject [[
        ["missions", createHashMap],
        ["shootAndScootTime", 90],
        ["_requestFireMission", {
            params ["_targetPos", ["_rounds", 6]];

            if (isNil "FLO_virtualGroups") exitWith {false};
            private _groups = FLO_virtualGroups get "_groups";
            private _artGroups = [];
            {
                private _gData = _y;
                if (_gData getOrDefault ["groupType", ""] == "artillery") then {
                    _artGroups pushBack [_x, _gData];
                };
            } forEach _groups;

            if (count _artGroups == 0) exitWith {false};

            // Filter out groups already on mission
            private _missions = _self get "missions";
            _artGroups = _artGroups select {
                private _id = _x select 0;
                !(_id in _missions)
            };
            if (count _artGroups == 0) exitWith {false};

            // Select nearest group to target
            private _sorted = [_artGroups, [], {(_x select 1) get "position" distance2D _targetPos}, "ASCEND"] call BIS_fnc_sortBy;
            private _sel = _sorted select 0;
            private _gid = _sel select 0;
            private _gdata = _sel select 1;

            if !(_gdata getOrDefault ["isActive", false]) then {
                [_gid, _gdata] call FLO_fnc_activateVirtualGroup;
            };

            _gdata = _groups get _gid; // refresh after activation
            private _realGroup = _gdata get "realGroup";
            if (isNull _realGroup) exitWith {false};

            // Determine artillery vehicle
            private _veh = objNull;
            {
                if (vehicle _x != _x) then {
                    private _v = vehicle _x;
                    if (isNull _veh) then { _veh = _v; };
                };
            } forEach units _realGroup;
            if (isNull _veh) then { _veh = vehicle (leader _realGroup); };
            if (isNull _veh) exitWith {false};

            private _mag = [_veh] call FLO_fnc_getRandomMagazine;
            if (_mag isEqualTo "") exitWith {false};

            _veh commandArtilleryFire [_targetPos, _mag, _rounds];

            // Register mission start time
            (_self get "missions") set [_gid, diag_tickTime];

            // Start shoot-and-scoot behaviour
            [_gid, _gdata, _self] spawn {
                params ["_gid","_gdata","_mgr"];
                sleep 60; // wait for firing
                private _veh = vehicle (leader (_gdata get "realGroup"));
                private _cur = getPos _veh;
                private _dir = random 360;
                private _dist = 300 + random 300;
                private _newPos = _cur getPos [_dist, _dir];
                private _wps = [[_newPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 10]];
                [_gid, _wps, true] call FLO_fnc_updateVirtualGroupWaypoints;
                sleep (_mgr get "shootAndScootTime");
                private _data = (FLO_virtualGroups get "_groups") get _gid;
                if (!isNil "_data") then { [_gid, _data] call FLO_fnc_deactivateVirtualGroup; };
                (_mgr get "missions") deleteAt _gid;
            };
            true
        }]
    ]];
};

FLO_GTNArtilleryManager

