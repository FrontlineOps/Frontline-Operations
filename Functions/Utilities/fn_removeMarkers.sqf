/*
    Function: FLO_fnc_removeMarkers
    
    Description:
    Removes map markers provided in an array.
    
    Parameters:
    _markers (required) - Array of marker names to remove. [Array]
    
    Returns:
    Number - Count of markers removed
    
    Example:
    // Remove a pre-selected array of markers
    [_civilianMarkers] call FLO_fnc_removeMarkers;
*/

params [
    ["_markers", [], [[]]]
];

if (_markers isEqualTo [] || {typeName _markers != "ARRAY"}) exitWith {0};

{
    deleteMarker _x;
} forEach _markers;

count _markers; 