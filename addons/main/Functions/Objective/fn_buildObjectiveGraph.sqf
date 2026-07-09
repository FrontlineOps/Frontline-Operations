/*
 * Function: FLO_fnc_buildObjectiveGraph
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the objective adjacency graph from linked objective metadata.
 *   Results are stored in FLO_ObjectiveLinks hashmap. When _debug is true
 *   line markers are created to visualize the links on the map.
 *
 * Arguments:
 *   0: Debug mode <BOOLEAN> (optional, default: false)
 *
 * Example:
 *   [true] call FLO_fnc_buildObjectiveGraph;
 */

params [ ["_debug", false, [true]] ];

if (isNil "FLO_Objectives") exitWith {false};

FLO_ObjectiveLinks = createHashMap;

// Storage for debug drawing
if (_debug) then {
    if (isNil "FLO_ObjectiveLinkMarkers") then {
        FLO_ObjectiveLinkMarkers = [];
    } else {
        {
            deleteMarker _x;
        } forEach FLO_ObjectiveLinkMarkers;
        FLO_ObjectiveLinkMarkers resize 0;
    };
} else {
    if !(isNil "FLO_ObjectiveLinkMarkers") then {
        { deleteMarker _x } forEach FLO_ObjectiveLinkMarkers;
        FLO_ObjectiveLinkMarkers = [];
    };
};

private _ids = keys FLO_Objectives;
{
    private _id = _x;
    private _objData = FLO_Objectives get _id;
    private _pos = _objData get "position";
    private _links = _objData getOrDefault ["linkedObjectives", []];
    {
        private _other = _x;
        if (_ids find _other == -1) then { continue; };

        // Avoid duplicate entries by sorting ids for key generation
        private _sorted = [_id, _other];
        _sorted sort true;
        private _key = format ["%1_%2", _sorted select 0, _sorted select 1];
        if (_key in FLO_ObjectiveLinks) then { continue; };

        private _otherData = FLO_Objectives get _other;
        if (isNil "_otherData") then { continue; };

        // Store adjacency metadata only. Path routes are not cached on links.
        private _linkMap = createHashMapFromArray [
            ["from", _id],
            ["to", _other]
        ];
        FLO_ObjectiveLinks set [_key, _linkMap];

        if (_debug) then {
            private _otherPos = _otherData get "position";
            private _p1 = _pos;
            private _p2 = _otherPos;
            private _name = format ["objLink_%1_%2", _sorted select 0, _sorted select 1];
            private _mid = [
                (_p1 select 0) + ((_p2 select 0) - (_p1 select 0)) / 2,
                (_p1 select 1) + ((_p2 select 1) - (_p1 select 1)) / 2
            ];
            createMarkerLocal [_name, _mid];
            _name setMarkerShapeLocal "RECTANGLE";
            _name setMarkerColorLocal "ColorBrown";
            _name setMarkerAlphaLocal 1;
            _name setMarkerSizeLocal [5, (_p1 distance2D _p2) / 2];
            _name setMarkerDir ([_p1, _p2] call BIS_fnc_dirTo);
            FLO_ObjectiveLinkMarkers pushBack _name;
        };
    } forEach _links;
} forEach _ids;

publicVariable "FLO_ObjectiveLinks";
true
