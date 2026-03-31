/*
 * Function: FLO_fnc_civilianManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-owned civilian manager for local mood, ambient state, and
 *   reputation-driven civilian policy.
 *
 * Return Value:
 * HASHMAP OBJECT - Civilian manager
 */

if (!isServer) exitWith { createHashMap };

if (!isNil "FLO_CivilianManager") exitWith {
    FLO_CivilianManager
};

private _civilianClass = [
    ["#type", "CivilianManager"],
    ["CONFIG", FLO_CivilianConfig],
    ["_objectiveContexts", createHashMap],
    ["_lastUpdate", -1],
    ["_loopPfhId", -1],

    ["getReputation", {
        FLO_ReputationHandle get "value"
    }],

    ["getObjectiveContext", {
        params [["_objectiveId", "", [""]], ["_reportingSide", FLO_ActivePlayerSide, [east]]];

        if !(_reportingSide in [east, west]) then {
            _reportingSide = west;
        };

        private _contexts = _self get "_objectiveContexts";
        private _cacheKey = format ["%1|%2", _objectiveId, _reportingSide];
        if (_cacheKey in _contexts) exitWith {
            _contexts get _cacheKey
        };

        private _context = [_objectiveId, "resident", _reportingSide] call FLO_fnc_civilianResolveObjectiveContext;
        _contexts set [_cacheKey, _context];
        _context
    }],

    ["getDisposition", {
        params [["_objectiveId", "", [""]], ["_reportingSide", FLO_ActivePlayerSide, [east]]];
        (_self call ["getObjectiveContext", [_objectiveId, _reportingSide]]) get "disposition"
    }],

    ["shouldFlee", {
        params [["_position", [0, 0, 0], [[]], [3]]];

        private _objectiveId = [_position] call FLO_fnc_civilianResolveObjective;
        if (_objectiveId == "") exitWith { false };

        private _reportingSide = FLO_ActivePlayerSide;
        if !(_reportingSide in [east, west]) then {
            _reportingSide = west;
        };

        private _context = _self call ["getObjectiveContext", [_objectiveId, _reportingSide]];
        if ((_context get "disposition") == "FRIENDLY") exitWith { false };

        private _cfg = _self get "CONFIG";
        private _radius = _cfg get "FLEE_RADIUS";
        private _nearbyPlayers = allPlayers select { alive _x && {_position distance2D (getPosATL _x) <= _radius} };
        if ((count _nearbyPlayers) == 0) exitWith { false };

        private _objective = FLO_Objectives get _objectiveId;
        (_objective get "contested") || {(_context get "disposition") in ["WARY", "HOSTILE"]}
    }],

    ["update", {
        if (isNil "FLO_Objectives") exitWith { false };

        private _contexts = createHashMap;
        {
            private _objectiveId = _x;
            {
                private _side = _x;
                private _cacheKey = format ["%1|%2", _objectiveId, _side];
                _contexts set [_cacheKey, [_objectiveId, "resident", _side] call FLO_fnc_civilianResolveObjectiveContext];
            } forEach [east, west];
        } forEach (keys FLO_Objectives);

        _self set ["_objectiveContexts", _contexts];
        _self set ["_lastUpdate", diag_tickTime];

        ["CIVILIAN", 3, format [
            "Civilian manager updated %1 objective contexts at rep %2",
            count (keys _contexts),
            _self call ["getReputation", []]
        ]] call FLO_fnc_log;

        true
    }],

    ["start", {
        if ((_self get "_loopPfhId") >= 0) exitWith { true };

        private _interval = ((_self get "CONFIG") get "UPDATE_INTERVAL") max 5;
        private _pfhId = [{
            params ["_args", "_pfhId"];
            _args params ["_manager"];

            if (isNil "FLO_CivilianManager") exitWith {
                [_pfhId] call CBA_fnc_removePerFrameHandler;
            };

            _manager call ["update", []];
        }, _interval, [_self]] call CBA_fnc_addPerFrameHandler;

        _self set ["_loopPfhId", _pfhId];
        true
    }],

    ["init", {
        _self call ["update", []];
        _self call ["start", []];
        ["CIVILIAN", 2, "Civilian manager initialized and worker started"] call FLO_fnc_log;
        true
    }]
];

FLO_CivilianManager = createHashMapObject [_civilianClass];
FLO_CivilianManager call ["init", []];

FLO_CivilianManager
