/*
 * Function: FLO_fnc_findRoadpath
 * Author: Frontline Operations Development Group
 * Description:
 * Returns a series of waypoints roughly 1km apart along a set of roads given a start and end position
 *
 * Arguments:
 * 0: Start Postion <ARRAY>
 * 1: End Position <ARRAY> 
 * 2: Callback <CODE> - The code to execute once a path has been found - Arguments passed to callback are as follows:
   [StartPos, EndPos, IntermediatePositionsArray]     
 * 3: (Optional) Additional arguments to pass to callback <ARRAY> (Default: []) 
 * 4: (Optional) Include Trails <BOOL> (Default: False) - for Man units only - vehicles cannot traverse TRAILS
   
 *
 * Return Value:
 *  Nothing
 *
 * Example:
 * private _callback = compileFinal {
        params ["_status", "_posArray", "_args" ];

        // Use _args to pass things like group or unit

        {
            // create intermediate waypoints here
            // last pos will be passed in _endPos
        } foreach _posArray;
    };
 * [_startPos, _endPos, _callback, [], false] call FLO_fnc_findRoadPath;
 */

params [
    ["_startPos",[0,0],[[]],[2,3]],
    ["_endPos",[0,0],[[]],[2,3]],
    ["_code",{},[{}]],
    ["_args",[],[[]]],
    ["_trails",false,[true]]
];

private _search = createhashmapobject [XPS_PF_typ_RoadGraphSearch, [FLO_PF_RoadGraph, _startPos, _endPos]];
_search set ["Doctrine", [FLO_PF_RoadDoctrine_V,FLO_PF_RoadDoctrine_M] select _trails];
_search set ["Callback", _code];
_search set ["CallbackArgs", _args];
FLO_PF_Scheduler call ["AddItem", _search];
