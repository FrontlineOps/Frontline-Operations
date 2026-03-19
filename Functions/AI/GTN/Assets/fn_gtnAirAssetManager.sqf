/*
    Function: FLO_fnc_gtnAirAssetManager

    Description:
    Manages air groups that exist in the virtualization system.
    For live areas (players/active groups nearby), the manager unvirtualizes
    and assigns a real aircraft.
    For non-live areas, the manager keeps aircraft virtual and applies a
    virtual combat effect instead of spawning real assets.

    Returns:
    HashMap object with methods to request and release air assets.

    Example:
        private _mgr = call FLO_fnc_gtnAirAssetManager;
        private _result = _mgr call ["_requestAirAsset", [getPos player]];
        if (count _result > 0) then {
            private _aircraft = _result select 0;
            // Use the aircraft for support
        };
*/

params [];

if (isNil "FLO_GTNAirAssetManager") then {
    FLO_GTNAirAssetManager = createHashMapObject [[
        ["missions", createHashMap],

        // Area is "live" when players or already-active groups are nearby.
        // In non-live areas, air support stays virtual.
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

        ["_getVirtualMissionDuration", {
            params ["_missionType"];
            switch (toUpper _missionType) do {
                case "CAP": { 600 };
                case "SAD": { 480 };
                case "RECON": { 180 };
                case "CAS";
                case "BOMB";
                case "LASER": { 300 };
                default { 300 };
            };
        }],

        ["_applyVirtualAirEffect", {
            params ["_airSide", "_targetPos", "_missionType"];

            private _enemySide = if (_airSide isEqualTo east) then { west } else { east };
            private _groups = FLO_virtualGroups get "_groups";
            private _radius = switch (toUpper _missionType) do {
                case "CAP": { 1800 };
                case "SAD": { 1000 };
                case "BOMB";
                case "LASER": { 900 };
                default { 800 };
            };

            private _candidates = [];
            {
                private _gid = _x;
                private _gData = _y;
                if ((_gData get "side") != _enemySide) then { continue };
                if (_gData get "isActive") then { continue };

                private _dist = (_gData get "position") distance2D _targetPos;
                if (_dist <= _radius) then {
                    _candidates pushBack [_dist, _gid, _gData];
                };
            } forEach _groups;

            if (count _candidates == 0) exitWith { 0 };

            _candidates sort true;

            private _targetsToHit = switch (toUpper _missionType) do {
                case "CAP": { 1 };
                case "SAD": { 2 };
                case "BOMB";
                case "LASER": { 2 };
                default { 1 };
            };

            private _lossFactor = switch (toUpper _missionType) do {
                case "CAP": { 0.20 };
                case "SAD": { 0.30 };
                case "BOMB";
                case "LASER": { 0.40 };
                default { 0.25 };
            };

            private _totalLosses = 0;
            for "_i" from 0 to ((_targetsToHit min (count _candidates)) - 1) do {
                private _entry = _candidates select _i;
                _entry params ["_dist", "_gid", "_gData"];

                private _currentCount = _gData get "unitCount";
                if (_currentCount <= 0) then { continue };

                private _falloff = 1 - ((_dist / _radius) * 0.5);
                private _loss = ceil ((_currentCount * _lossFactor * _falloff) max 1);
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
            params ["_gid", "_duration"];

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

                if (!isNil "FLO_GTNAirAssetManager") then {
                    (FLO_GTNAirAssetManager get "missions") deleteAt _gid;
                };

                ["GTN Air Asset Manager", 3, format["Virtual air mission complete for %1", _gid]] call FLO_fnc_log;
            };
        }],

        ["_requestAirAsset", {
            params ["_targetPos", ["_missionType", "CAS"], ["_requestSide", sideUnknown]];

            if (isNil "FLO_virtualGroups") exitWith {[]};
            private _groups = FLO_virtualGroups get "_groups";
            private _airGroups = [];
            {
                private _gData = _y;
                private _gType = _gData get "groupType";
                if (_gType in ["helicopter", "jet", "air"]) then {
                    if (_requestSide in [east, west] && {(_gData get "side") != _requestSide}) then {
                        continue;
                    };
                    _airGroups pushBack [_x, _gData];
                };
            } forEach _groups;

            if (count _airGroups == 0) exitWith {[]};

            // Filter out groups already on mission
            private _missions = _self get "missions";
            _airGroups = _airGroups select {
                private _id = _x select 0;
                !(_id in _missions)
            };
            if (count _airGroups == 0) exitWith {[]};

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
            } forEach _airGroups;
            if (count _sel == 0) exitWith { [] };

            private _gid = _sel select 0;
            private _gdata = _sel select 1;
            private _isLiveArea = _self call ["_isLiveArea", [_targetPos]];

            if (!_isLiveArea) exitWith {
                _gdata set ["onMission", true];
                (_self get "missions") set [_gid, "VIRTUAL"];

                private _duration = _self call ["_getVirtualMissionDuration", [_missionType]];
                private _losses = _self call ["_applyVirtualAirEffect", [_gdata get "side", _targetPos, _missionType]];
                _self call ["_scheduleVirtualMissionRelease", [_gid, _duration]];

                ["GTN Air Asset Manager", 3, format[
                    "Virtual-only %1 mission by %2 at %3 (losses=%4, duration=%5s)",
                    toUpper _missionType,
                    _gid,
                    _targetPos,
                    _losses,
                    round _duration
                ]] call FLO_fnc_log;

                [objNull, _gid, "VIRTUAL"]
            };

            if !(_gdata get "isActive") then {
                [_gid, _gdata] call FLO_fnc_activateVirtualGroup;
            };

            private _realGroup = _gdata get "realGroup";
            if (isNull _realGroup) exitWith { [] };
            
            // Mark group as on mission to prevent deactivation
            _gdata set ["onMission", true];
            ["GTN Air Asset Manager", 3, format["Marked group %1 as onMission=true to prevent deactivation", _gid]] call FLO_fnc_log;

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
            if (isNull _veh) exitWith { [] };

            (_self get "missions") set [_gid, _veh];

            [_veh, _gid, "REAL"]
        }],
        ["_releaseAirAsset", {
            params ["_gid"];
            private _missions = _self get "missions";

            ["GTN Air Asset Manager", 4, format["_releaseAirAsset called for: '%1'", _gid]] call FLO_fnc_log;

            if (_gid in _missions) then {
                private _missionState = _missions get _gid;
                private _groups = FLO_virtualGroups get "_groups";
                if (_gid in _groups) then {
                    private _data = _groups get _gid;
                    _data set ["onMission", false];
                    if !(_missionState isEqualTo "VIRTUAL") then {
                        _self call ["_sendToRTB", [_gid]];
                    };
                } else {
                    ["GTN Air Asset Manager", 2, format["Group %1 not found in virtualGroups - may have been destroyed", _gid]] call FLO_fnc_log;
                };
                (_self get "missions") deleteAt _gid;
                ["GTN Air Asset Manager", 3, format["Released air asset %1", _gid]] call FLO_fnc_log;
            };
        }],

        // Get RTB position for an aircraft (returns original spawn position)
        ["_getRTBPosition", {
            params ["_groupId"];
            private _groups = FLO_virtualGroups get "_groups";
            if !(_groupId in _groups) exitWith {
                ["GTN Air Asset Manager", 2, format["_getRTBPosition: Group %1 not in virtualGroups", _groupId]] call FLO_fnc_log;
                [0,0,0]
            };
            private _gData = _groups get _groupId;
            _gData get "spawnPosition"
        }],

        // Send aircraft to RTB - works for both active (real) and virtual groups
        ["_sendToRTB", {
            params ["_groupId"];

            private _groups = FLO_virtualGroups get "_groups";
            if !(_groupId in _groups) exitWith {
                ["GTN Air Asset Manager", 2, format["_sendToRTB: Group %1 not in virtualGroups", _groupId]] call FLO_fnc_log;
            };

            private _rtbPos = _self call ["_getRTBPosition", [_groupId]];
            private _gData = _groups get _groupId;
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

                // _realGroup setCurrentWaypoint [_realGroup, 1];

                ["GTN Air Asset Manager", 3, format["RTB waypoints set for %1 to %2", _groupId, _rtbPos]] call FLO_fnc_log;
            } else {
                // Virtual group - use virtual waypoint system
                private _waypoints = [
                    [_rtbPos, "MOVE", "SAFE", "NORMAL", "COLUMN", "GREEN", 50],
                    [_rtbPos, "LOITER", "SAFE", "LIMITED", "COLUMN", "GREEN", 500]
                ];
                [_groupId, _waypoints, false, true, "GTN_AIR"] call FLO_fnc_updateVirtualGroupWaypoints;

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

