/*
    Function: FLO_fnc_setupCaptureSystem
    
    Description:
    Sets up the capture system for all outposts and cities in the mission.
    Adds necessary triggers to handle capturing objectives between sides.
    
    Parameters:
    _outpostMarkerTypes - Array of marker types for outposts [Array] (default: ["o_support"])
    _cityMarkerTypes - Array of marker types for cities [Array] (default: ["o_installation"])
    
    Returns:
    Number - Count of objectives set up with capture system
    
    Example:
    [["o_support"], ["o_installation", "n_installation"]] call FLO_fnc_setupCaptureSystem;
*/

params [
    ["_outpostMarkerTypes", ["o_support"], [[]]],
    ["_cityMarkerTypes", ["o_installation"], [[]]]
];

// Initialize global variables if not already done
if (isNil "FLO_capturedOutposts") then {
    FLO_capturedOutposts = createHashMap;
};

if (isNil "FLO_activeTasks") then {
    FLO_activeTasks = createHashMap;
};

// Count how many objectives we set up
private _objectivesSetUp = 0;

// Process outpost markers
{
    private _markerType = _x;
    private _outpostMarkers = allMapMarkers select {markerType _x == _markerType && markerColor _x in ["colorOPFOR", "ColorEAST"]};
    
    diag_log format ["[FLO][Outpost] Found %1 outpost markers of type %2", count _outpostMarkers, _markerType];
    
    {
        private _marker = _x;
        private _position = getMarkerPos _marker;
        
        // Create a capture trigger for this outpost
        private _trigger = createTrigger ["EmptyDetector", _position, false];
        _trigger setTriggerArea [120, 120, 0, false, 200];
        _trigger setTriggerTimeout [10, 10, 10, true];
        _trigger setTriggerActivation ["WEST SEIZED", "PRESENT", true];
        _trigger setTriggerStatements [
            "this",
            format [
                "[thisTrigger, 'outpost', 'west'] call FLO_fnc_flipObjective;",
                _marker
            ],
            format [
                "
                _allMarks = allMapMarkers select {markerType _x == '%1'};
                _objMarker = [_allMarks, thisTrigger] call FLO_fnc_findNearestMarker;
                _objMarker setMarkerColor 'colorOPFOR';
                ",
                _markerType
            ]
        ];
        
        _objectivesSetUp = _objectivesSetUp + 1;
        diag_log format ["[FLO][Outpost] Set up capture system for outpost at %1", _position];
        
    } forEach _outpostMarkers;
} forEach _outpostMarkerTypes;

// Process city markers
{
    private _markerType = _x;
    private _cityMarkers = allMapMarkers select {markerType _x == _markerType && markerColor _x in ["colorOPFOR", "ColorEAST"]};
    
    diag_log format ["[FLO][Outpost] Found %1 city markers of type %2", count _cityMarkers, _markerType];
    
    {
        private _marker = _x;
        private _position = getMarkerPos _marker;
        
        // Create a capture trigger for this city
        private _trigger = createTrigger ["EmptyDetector", _position, false];
        _trigger setTriggerArea [220, 220, 0, false, 200];
        _trigger setTriggerTimeout [10, 10, 10, true];
        _trigger setTriggerActivation ["WEST SEIZED", "PRESENT", true];
        _trigger setTriggerStatements [
            "this",
            format [
                "[thisTrigger, 'city', 'west'] call FLO_fnc_flipObjective;",
                _marker
            ],
            format [
                "
                _allMarks = allMapMarkers select {markerType _x == '%1'};
                _objMarker = [_allMarks, thisTrigger] call FLO_fnc_findNearestMarker;
                _objMarker setMarkerColor 'colorOPFOR';
                ",
                _markerType
            ]
        ];
        
        _objectivesSetUp = _objectivesSetUp + 1;
        diag_log format ["[FLO][Outpost] Set up capture system for city at %1", _position];
        
    } forEach _cityMarkers;
} forEach _cityMarkerTypes;

// Log the result
diag_log format ["[FLO][Outpost] Capture system setup complete. %1 objectives configured.", _objectivesSetUp];

// Return count of objectives set up
_objectivesSetUp 