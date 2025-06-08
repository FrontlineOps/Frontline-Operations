/*
 * Function: FLO_fnc_buildObjectiveGraph
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds road-linked graph between objectives. Uses road pathfinding
 *   to generate cached waypoint arrays between linked objectives.
 *   Results are stored in FLO_ObjectiveLinks hashmap. When _debug is true
 *   lines are drawn between objectives to visualize the links.
 *
 * Arguments:
 *   0: Debug mode <BOOLEAN> (optional, default: false)
 *
 * Example:
 *   [true] call FLO_fnc_buildObjectiveGraph;
 */

params [ ["_debug", false, [true]] ];

if (isNil "FLO_Objectives") exitWith {false};

// Ensure pathfinding is initialized
if (isNil "FLO_PF_RoadGraph") then {
    [] call FLO_fnc_initRoadGraph;
};

FLO_ObjectiveLinks = createHashMap;

// Storage for debug drawing
if (_debug) then {
    if (isNil "FLO_ObjectiveLinkDebug") then {
        FLO_ObjectiveLinkDebug = [];
        addMissionEventHandler ["Draw3D", {
            {
                private _pts = _x;
                for "_i" from 1 to (count _pts - 1) do {
                    drawLine3D [_pts select (_i-1), _pts select _i, [0,1,0,0.6]];
                };
            } forEach FLO_ObjectiveLinkDebug;
        }];
    } else { FLO_ObjectiveLinkDebug resize 0; };
};

private _ids = keys FLO_Objectives;
{
    private _id = _x;
    private _data = FLO_Objectives get _id;
    private _pos = _data get "position";
    private _links = _data getOrDefault ["linkedObjectives", []];
    {
        private _other = _x;
        if (_ids find _other == -1) exitWith {};
        // Avoid duplicate entries
        if (_id > _other) then { continue; };
        private _otherData = FLO_Objectives get _other;
        if (isNil "_otherData") then { continue; };
        private _otherPos = _otherData get "position";

        private _path = [_pos, _otherPos] call FLO_fnc_findRoadPathSync;
        if (count _path == 0) then { _path = [_otherPos]; };
        private _linkMap = createHashMapFromArray [
            ["from", _id],
            ["to", _other],
            ["waypoints", _path]
        ];
        private _key = format ["%1_%2", _id, _other];
        FLO_ObjectiveLinks set [_key, _linkMap];
        if (_debug) then {
            private _draw = [_pos] + _path;
            FLO_ObjectiveLinkDebug pushBack _draw;
        };
    } forEach _links;
} forEach _ids;

publicVariable "FLO_ObjectiveLinks";
true
