/*
    Function: FLO_fnc_gtnArtilleryManager

    Description:
    Manages artillery groups that exist in the virtualization system. The manager
    unvirtualizes a group for a fire mission, commands it to fire using LAMBS-style
    beaten zone pattern (one round at a time with waitUntil), then executes
    shoot-and-scoot tactics before revirtualizing.

    Firing pattern inspired by LAMBS Danger fnc_doArtillery:
    - Beaten zone cone pattern spreading towards the target
    - MLRS detection with salvo fire
    - Round-by-round firing with waitUntil unitReady
    - Heavier artillery fires more rounds, more accurately

    Returns:
    HashMap object with methods to request fire missions.

    Example:
        private _mgr = call FLO_fnc_gtnArtilleryManager;
        _mgr call ["_requestFireMission", [[1000,1000,0], 6, 100]];
*/

params [];

if (isNil "FLO_GTNArtilleryManager") then {
    FLO_GTNArtilleryManager = createHashMapObject [[
        ["missions", createHashMap],
        ["shootAndScootTime", 90],
        ["defaultRounds", 6],
        ["defaultAccuracy", 100],  // Dispersion in meters

        // =========================================================================
        // REQUEST FIRE MISSION
        // Main entry point for artillery fire missions
        // =========================================================================
        ["_requestFireMission", {
            params ["_targetPos", ["_rounds", -1], ["_accuracy", -1]];

            if (_rounds < 0) then { _rounds = _self get "defaultRounds"; };
            if (_accuracy < 0) then { _accuracy = _self get "defaultAccuracy"; };

            private _groups = FLO_virtualGroups get "_groups";
            private _artGroups = [];
            {
                private _gid = _x;
                private _gData = _groups get _gid;
                if (_gData get "groupType" == "artillery") then {
                    _artGroups pushBack [_gid, _gData];
                };
            } forEach (keys _groups);

            ["GTN Artillery", 3, format["Found %1 artillery groups", count _artGroups]] call FLO_fnc_log;

            if (count _artGroups == 0) exitWith { false };

            // Filter out groups already on mission
            private _missions = _self get "missions";
            _artGroups = _artGroups select {
                private _id = _x select 0;
                !(_id in _missions)
            };

            ["GTN Artillery", 3, format["Available (not on mission): %1. Missions map: %2", count _artGroups, _missions]] call FLO_fnc_log;

            if (count _artGroups == 0) exitWith { false };

            // Select nearest group to target
            private _sorted = [_artGroups, [], {(_x select 1) get "position" distance2D _targetPos}, "ASCEND"] call BIS_fnc_sortBy;
            private _sel = _sorted select 0;
            private _gid = _sel select 0;
            private _gdata = _sel select 1;

            ["GTN Artillery", 3, format["Selected group %1, isActive: %2", _gid, _gdata get "isActive"]] call FLO_fnc_log;

            if !(_gdata get "isActive") then {
                [_gid, _gdata] call FLO_fnc_activateVirtualGroup;
            };

            _gdata = _groups get _gid;
            private _realGroup = _gdata get "realGroup";

            // Mark as on mission to prevent virtualization
            _gdata set ["onMission", true];

            // Register mission
            (_self get "missions") set [_gid, diag_tickTime];

            // Spawn the fire mission process
            [_gid, _gdata, _realGroup, _targetPos, _rounds, _accuracy, _self] spawn FLO_fnc_gtnArtilleryFireMission;

            true
        }],

        // =========================================================================
        // CLEANUP MISSION
        // Called when a mission completes (success or failure)
        // =========================================================================
        ["_cleanupMission", {
            params ["_gid", "_veh"];

            private _groups = FLO_virtualGroups get "_groups";
            private _gdata = _groups get _gid;

            if (isNil "_gdata") exitWith {
                (_self get "missions") deleteAt _gid;
            };

            private _realGroup = _gdata get "realGroup";

            // Shoot and scoot - move to new position
            if (!isNull _realGroup && {count units _realGroup > 0}) then {
                private _cur = if (!isNull _veh && alive _veh) then { getPos _veh } else { getPos leader _realGroup };
                private _dir = random 360;
                private _dist = 300 + random 300;
                private _newPos = _cur getPos [_dist, _dir];
                private _wps = [[_newPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 10]];
                [_gid, _wps, false] call FLO_fnc_updateVirtualGroupWaypoints;

                ["GTN Artillery", 3, format["Artillery %1 shoot-and-scoot to %2", _gid, _newPos]] call FLO_fnc_log;
            };

            // Wait for relocation then release
            private _scootTime = _self get "shootAndScootTime";
            [_gid, _scootTime] spawn {
                params ["_gid", "_scootTime"];
                sleep _scootTime;

                private _groups = FLO_virtualGroups get "_groups";
                private _gdata = _groups get _gid;
                if (!isNil "_gdata") then {
                    // Clear mission flag
                    _gdata set ["onMission", false];

                    // Reset state to idle so virtualization can assign new patrol
                    _gdata set ["state", "idle"];
                    _gdata set ["autoPatrol", false];  // Allow patrol to be reassigned

                    // Deactivate (virtualize) the group
                    [_gid, _gdata] call FLO_fnc_deactivateVirtualGroup;
                };

                if (!isNil "FLO_GTNArtilleryManager") then {
                    (FLO_GTNArtilleryManager get "missions") deleteAt _gid;
                };

                ["GTN Artillery", 3, format["Artillery %1 mission fully complete, revirtualized", _gid]] call FLO_fnc_log;
            };
        }]
    ]];
};

FLO_GTNArtilleryManager

