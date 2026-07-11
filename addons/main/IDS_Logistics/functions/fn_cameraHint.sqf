/**
 * @name IDS_Logistics_fnc_cameraHint
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Displays structured hints for the build camera system.
 * Creates a visible GUI overlay on top of the camera view.
 * Supports both temporary notifications and persistent help texts.
 * Uses layered hints to avoid conflicts between different types of messages.
 * Automatically clears hints when camera no longer exists.
 *
 * @param {String|Array} _content - The content to display. Can be a simple string or structured text
 * @param {Number} _duration - How long to display the hint (0 = indefinite)
 * @param {Boolean} [_clearOnly] - If true, only clears the hint layer without showing anything
 *
 * @return {Nothing}
 *
 * @example
 * ["Entity placed", 2] call IDS_Logistics_fnc_cameraHint
 * [_structuredText, 0, false] call IDS_Logistics_fnc_cameraHint
 */

params [
    ["_content", "", ["", []]],
    ["_duration", 0, [0]],
    ["_clearOnly", false, [false]]
];

// Check if camera exists, if not just exit after clearing
if (isNil "IDS_Logistics_Camera" || {isNull IDS_Logistics_Camera}) exitWith {
    // Camera doesn't exist, so clear any existing hints
    if (!isNil "IDS_Logistics_CameraHintLayer") then {
        IDS_Logistics_CameraHintLayer cutText ["", "PLAIN"];
    };
    if (!isNil "IDS_Logistics_CameraFlashLayer") then {
        IDS_Logistics_CameraFlashLayer cutText ["", "PLAIN"];
    };
};

// Create hint layers if they don't exist
if (isNil "IDS_Logistics_CameraHintLayer") then { IDS_Logistics_CameraHintLayer = ["IDS_Logistics_Camera_Hint"] call BIS_fnc_rscLayer; };

if (isNil "IDS_Logistics_CameraFlashLayer") then { IDS_Logistics_CameraFlashLayer = ["IDS_Logistics_Camera_Flash"] call BIS_fnc_rscLayer; };

// Handle clearing only
if (_clearOnly) exitWith {
    IDS_Logistics_CameraHintLayer cutText ["", "PLAIN"];
    IDS_Logistics_CameraFlashLayer cutText ["", "PLAIN"];
};

// Determine header title based on the type of hint
private _title = "Information";
if (_duration > 0) then { _title = "Notification"; };

// Specific headers for certain content types if content is a string
if (typeName _content == "STRING") then {
    if (_content find "<t color='#FF4444'>" != -1) then { _title = "Error"; };
    if (_content find "<t color='#FFAA44'>" != -1) then { _title = "Warning"; };
    if (_content find "<t color='#44AAFF'>" != -1) then { _title = "Rotation"; };
    if (_content find "<t color='#44FF44'>" != -1) then { _title = "Height"; };
    if (_content find "<t color='#FFAA44' size='1.0'>DISTANCE" != -1) then { _title = "Distance"; };
    if (_content find "<t color='#FF8844' size='1.0'>CANCELLED" != -1) then { _title = "Action Cancelled"; };
    if (_content find "<t color='#AAFFAA' size='1.2'>CONTROLS" != -1) then { _title = "Help"; };
};

// Define common UI elements
// private _headerBgColor = "#00d3f2"; // Cyan header background
private _headerBgColor = "#801A1A"; // Dark Red header background
private _headerTextColor = "#FFFFFF"; // White header text

// Choose which layer to use based on duration
if (_duration > 0) then {
    // Flash hints (temporary notifications) - top right
    IDS_Logistics_CameraFlashLayer cutRsc ["RscTitleDisplayEmpty", "PLAIN"];
    
    private _display = uiNamespace getVariable "RscTitleDisplayEmpty";
    
    // Create the container control
    private _container = _display ctrlCreate ["RscControlsGroupNoScrollbars", 9999];
    _container ctrlSetPosition [
        0.8 * safeZoneW + safeZoneX,
        0.1 * safeZoneH + safeZoneY,
        0.15 * safeZoneW,
        0.15 * safeZoneH
    ];
    _container ctrlCommit 0;
    
    // Create header background
    private _headerBg = _display ctrlCreate ["RscText", 10001, _container];
    _headerBg ctrlSetPosition [0, 0, 0.15 * safeZoneW, 0.03 * safeZoneH];
    _headerBg ctrlSetBackgroundColor [
        parseNumber ("0x" + (_headerBgColor select [1, 2])) / 255,
        parseNumber ("0x" + (_headerBgColor select [3, 2])) / 255,
        parseNumber ("0x" + (_headerBgColor select [5, 2])) / 255,
        1
    ];
    _headerBg ctrlCommit 0;
    
    // Create header text
    private _headerText = _display ctrlCreate ["RscText", 10002, _container];
    _headerText ctrlSetPosition [0, 0, 0.15 * safeZoneW, 0.03 * safeZoneH];
    _headerText ctrlSetText _title;
    _headerText ctrlSetFont "PuristaBold";
    _headerText ctrlSetFontHeight 0.03;  // Original font height
    _headerText ctrlSetTextColor [1, 1, 1, 1];
    _headerText ctrlSetBackgroundColor [0, 0, 0, 0];
    _headerText ctrlCommit 0;
    
    // Create content background
    private _contentBg = _display ctrlCreate ["RscText", 10003, _container];
    _contentBg ctrlSetPosition [0, 0.03 * safeZoneH, 0.15 * safeZoneW, 0.12 * safeZoneH];
    _contentBg ctrlSetBackgroundColor [0, 0, 0, 0.5];
    _contentBg ctrlCommit 0;
    
    // Process content based on its type
    private _processedContent = _content;
    if (typeName _content == "STRING" && _content != "") then { _processedContent = _content; };
    
    // Create content text
    private _contentText = _display ctrlCreate ["RscStructuredText", 10004, _container];
    _contentText ctrlSetPosition [0.005 * safeZoneW, 0.035 * safeZoneH, 0.14 * safeZoneW, 0.11 * safeZoneH];
    _contentText ctrlSetStructuredText parseText _processedContent;
    _contentText ctrlCommit 0;
    
    // Add border to the whole thing
    private _border = _display ctrlCreate ["RscFrame", 10005, _container];
    _border ctrlSetPosition [0, 0, 0.15 * safeZoneW, 0.15 * safeZoneH];
    _border ctrlSetTextColor [0.8, 0.8, 0.8, 0.5];
    _border ctrlCommit 0;
    
    // Set up fade-out after duration and check if camera still exists
    [_duration, _container] spawn {
        params ["_duration", "_container"];
        
        // Wait for duration
        private _endTime = time + _duration;
        waitUntil { time >= _endTime || (isNil "IDS_Logistics_Camera" || { isNull IDS_Logistics_Camera }) };
        
        // If container still exists, fade it out
        if (!isNull _container) then {
            _container ctrlSetFade 1;
            _container ctrlCommit 0.5;
            sleep 0.5;
            ctrlDelete _container;
        };
    };
} else {
    // Persistent hints - bottom right
    IDS_Logistics_CameraHintLayer cutRsc ["RscTitleDisplayEmpty", "PLAIN"];
    
    private _display = uiNamespace getVariable "RscTitleDisplayEmpty";
    
    // Create the container control
    private _container = _display ctrlCreate ["RscControlsGroupNoScrollbars", 9999];
    _container ctrlSetPosition [
        0.8 * safeZoneW + safeZoneX,
        0.55 * safeZoneH + safeZoneY,
        0.15 * safeZoneW,
        0.35 * safeZoneH
    ];
    _container ctrlCommit 0;
    
    // Create header background
    private _headerBg = _display ctrlCreate ["RscText", 10001, _container];
    _headerBg ctrlSetPosition [0, 0, 0.15 * safeZoneW, 0.03 * safeZoneH];
    _headerBg ctrlSetBackgroundColor [
        parseNumber ("0x" + (_headerBgColor select [1, 2])) / 255,
        parseNumber ("0x" + (_headerBgColor select [3, 2])) / 255,
        parseNumber ("0x" + (_headerBgColor select [5, 2])) / 255,
        1
    ];
    _headerBg ctrlCommit 0;
    
    // Create header text
    private _headerText = _display ctrlCreate ["RscText", 10002, _container];
    _headerText ctrlSetPosition [0, 0, 0.15 * safeZoneW, 0.03 * safeZoneH];
    _headerText ctrlSetText _title;
    _headerText ctrlSetFont "PuristaBold";
    _headerText ctrlSetFontHeight 0.03;
    _headerText ctrlSetTextColor [1, 1, 1, 1];
    _headerText ctrlSetBackgroundColor [0, 0, 0, 0];
    _headerText ctrlCommit 0;
    
    // Create content background
    private _contentBg = _display ctrlCreate ["RscText", 10003, _container];
    _contentBg ctrlSetPosition [0, 0.03 * safeZoneH, 0.15 * safeZoneW, 0.32 * safeZoneH];
    _contentBg ctrlSetBackgroundColor [0, 0, 0, 0.5];
    _contentBg ctrlCommit 0;
    
    // Process content based on its type
    private _processedContent = _content;
    if (typeName _content == "STRING" && _content != "") then {
        _processedContent = _content;
    };
    
    // Create content text
    private _contentText = _display ctrlCreate ["RscStructuredText", 10004, _container];
    _contentText ctrlSetPosition [0.005 * safeZoneW, 0.035 * safeZoneH, 0.14 * safeZoneW, 0.305 * safeZoneH];
    _contentText ctrlSetStructuredText parseText _processedContent;
    _contentText ctrlCommit 0;
    
    // Add border to the whole thing
    private _border = _display ctrlCreate ["RscFrame", 10005, _container];
    _border ctrlSetPosition [0, 0, 0.15 * safeZoneW, 0.35 * safeZoneH];
    _border ctrlSetTextColor [0.8, 0.8, 0.8, 0.5];
    _border ctrlCommit 0;
    
    // Start monitoring for camera existence
    [_container] spawn {
        params ["_container"];
        waitUntil {isNil "IDS_Logistics_Camera" || { isNull IDS_Logistics_Camera } || {isNull _container}};
        
        // If container still exists but camera doesn't, remove it
        if (!isNull _container && (isNil "IDS_Logistics_Camera" || { isNull IDS_Logistics_Camera })) then {
            _container ctrlSetFade 1;
            _container ctrlCommit 0.5;
            sleep 0.5;
            ctrlDelete _container;
        };
    };
};
