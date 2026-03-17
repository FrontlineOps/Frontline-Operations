/*
    Function: FLO_fnc_gtnArtilleryManager

    Description:
    Manages artillery groups that exist in the virtualization system.
    For live areas (players/active groups nearby), the manager unvirtualizes
    and executes a real fire mission.
    For non-live areas, the manager keeps artillery virtual and applies a
    virtual combat effect instead of spawning real assets.

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

        // Area is "live" when players or already-active groups are nearby.
        // In non-live areas, artillery stays virtual.
        ["_isLiveArea", {
            params ["_targetPos", ["_radius", -1]];

            if (_radius < 0) then { _radius = FLO_VirtualizationDistance; };

            private _playersNear = {
                alive _x &&
                {side group _x in [east, west]} &&
                {(getPosATL _x) distance2D _targetPos <= _radius}
            } count allPlayers;
            if (_playersNear > 0) exitWith { true };

            private _groups = FLO_virtualGroups get "_groups";
            private _activeGroupsNear = 0;
            {
                private _gData = _y;
                private _gType = _gData get "groupType";
                if (_gType in ["static_aa", "radar"]) then { continue };
                if !(_gData get "isActive") then { continue };
                if ((_gData get "position") distance2D _targetPos > _radius) then { continue };
                _activeGroupsNear = _activeGroupsNear + 1;
            } forEach _groups;

            _activeGroupsNear > 0
        }],

        // Applies virtual artillery damage to nearby enemy virtual groups.
        ["_applyVirtualFireEffect", {
            params ["_artySide", "_targetPos", "_rounds", "_accuracy"];

            private _enemySide = if (_artySide isEqualTo east) then { west } else { east };
            private _groups = FLO_virtualGroups get "_groups";
            private _impactRadius = ((_accuracy max 50) * 3) min 700;
            private _candidates = [];

            {
                private _gid = _x;
                private _gData = _y;
                if ((_gData get "side") != _enemySide) then { continue };
                if (_gData get "isActive") then { continue };

                private _dist = (_gData get "position") distance2D _targetPos;
                if (_dist <= _impactRadius) then {
                    _candidates pushBack [_dist, _gid, _gData];
                };
            } forEach _groups;

            if (count _candidates == 0) exitWith { 0 };

            _candidates sort true;

            private _targetsToHit = ((ceil (_rounds / 4)) max 1) min 3;
            private _totalLosses = 0;

            for "_i" from 0 to ((_targetsToHit min (count _candidates)) - 1) do {
                private _entry = _candidates select _i;
                _entry params ["_dist", "_gid", "_gData"];

                private _currentCount = _gData get "unitCount";
                if (_currentCount <= 0) then { continue };

                private _baseLoss = ceil ((_rounds * 0.35) / (_i + 1));
                private _falloff = 1 - ((_dist / _impactRadius) * 0.5);
                private _loss = ceil ((_baseLoss * _falloff) max 1);
                if (_loss > _currentCount) then { _loss = _currentCount; };

                private _newCount = _currentCount - _loss;
                if (_newCount <= 0) then {
                    _gData set ["unitCount", 0];
                    [FLO_virtualGroups, _gid] call (FLO_virtualGroups get "_removeGroup");
                } else {
                    _gData set ["unitCount", _newCount];
                    _groups set [_gid, _gData];
                };

                _totalLosses = _totalLosses + _loss;
            };

            _totalLosses
        }],

        ["_scheduleVirtualMissionRelease", {
            params ["_gid", ["_duration", 60]];

            [_gid, _duration] spawn {
                params ["_gid", "_duration"];
                sleep _duration;

                if (!isNil "FLO_virtualGroups") then {
                    private _groups = FLO_virtualGroups get "_groups";
                    if (_gid in _groups) then {
                        private _gData = _groups get _gid;
                        _gData set ["onMission", false];
                    };
                };

                if (!isNil "FLO_GTNArtilleryManager") then {
                    (FLO_GTNArtilleryManager get "missions") deleteAt _gid;
                };
            };
        }],

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
                private _gData = _y;
                if (_gData get "groupType" == "artillery") then {
                    _artGroups pushBack [_gid, _gData];
                };
            } forEach _groups;

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

            // Select nearest group to target (single pass)
            private _sel = [];
            private _bestDist = 1e12;
            {
                _x params ["_gid", "_gData"];
                private _dist = (_gData get "position") distance2D _targetPos;
                if (_dist < _bestDist) then {
                    _bestDist = _dist;
                    _sel = [_gid, _gData];
                };
            } forEach _artGroups;
            if (count _sel == 0) exitWith { false };

            private _gid = _sel select 0;
            private _gdata = _sel select 1;
            private _isLiveArea = _self call ["_isLiveArea", [_targetPos]];

            ["GTN Artillery", 3, format["Selected group %1, isActive: %2, liveArea: %3", _gid, _gdata get "isActive", _isLiveArea]] call FLO_fnc_log;

            // Non-live area: keep support entirely virtual.
            if (!_isLiveArea) exitWith {
                _gdata set ["onMission", true];
                (_self get "missions") set [_gid, diag_tickTime];

                private _losses = _self call ["_applyVirtualFireEffect", [_gdata get "side", _targetPos, _rounds, _accuracy]];
                private _missionDuration = (40 + (_rounds * 4)) min 180;
                _self call ["_scheduleVirtualMissionRelease", [_gid, _missionDuration]];

                ["GTN Artillery", 3, format[
                    "Virtual-only fire mission by %1 at %2 (losses=%3, duration=%4s)",
                    _gid,
                    _targetPos,
                    _losses,
                    round _missionDuration
                ]] call FLO_fnc_log;
                true
            };

            if !(_gdata get "isActive") then {
                [_gid, _gdata] call FLO_fnc_activateVirtualGroup;
            };

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
