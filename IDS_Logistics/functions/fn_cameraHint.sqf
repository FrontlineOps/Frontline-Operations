/**
 * @name IDS_Logistics_fnc_cameraHint
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.5
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
if (isNil "IDS_LOGISTICS_CAM" || {isNull IDS_LOGISTICS_CAM}) exitWith {
    // Camera doesn't exist, so clear any existing hints
    if (!isNil "IDS_LOGISTICS_CAM_HINT_LAYER") then {
        IDS_LOGISTICS_CAM_HINT_LAYER cutText ["", "PLAIN"];
    };
    if (!isNil "IDS_LOGISTICS_CAM_FLASH_LAYER") then {
        IDS_LOGISTICS_CAM_FLASH_LAYER cutText ["", "PLAIN"];
    };
};

// Create hint layers if they don't exist
if (isNil "IDS_LOGISTICS_CAM_HINT_LAYER") then {
    IDS_LOGISTICS_CAM_HINT_LAYER = ["IDS_Logistics_Camera_Hint"] call BIS_fnc_rscLayer;
};

if (isNil "IDS_LOGISTICS_CAM_FLASH_LAYER") then {
    IDS_LOGISTICS_CAM_FLASH_LAYER = ["IDS_Logistics_Camera_Flash"] call BIS_fnc_rscLayer;
};

// Handle clearing only
if (_clearOnly) exitWith {
    IDS_LOGISTICS_CAM_HINT_LAYER cutText ["", "PLAIN"];
    IDS_LOGISTICS_CAM_FLASH_LAYER cutText ["", "PLAIN"];
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
private _headerBgColor = "#00d3f2"; // Cyan header background
private _headerTextColor = "#FFFFFF"; // White header text

// Choose which layer to use based on duration
if (_duration > 0) then {
    // Flash hints (temporary notifications) - top right
    IDS_LOGISTICS_CAM_FLASH_LAYER cutRsc ["RscTitleDisplayEmpty", "PLAIN"];
    
    private _display = uiNamespace getVariable "RscTitleDisplayEmpty";
    
    // Create the container control
    private _container = _display ctrlCreate ["RscControlsGroupNoScrollbars", 9999];
    _container ctrlSetPosition [
        0.8 * safezoneW + safezoneX,
        0.1 * safezoneH + safezoneY,
        0.15 * safezoneW,
        0.15 * safezoneH
    ];
    _container ctrlCommit 0;
    
    // Create header background
    private _headerBg = _display ctrlCreate ["RscText", 10001, _container];
    _headerBg ctrlSetPosition [0, 0, 0.15 * safezoneW, 0.03 * safezoneH];
    _headerBg ctrlSetBackgroundColor [
        parseNumber ("0x" + (_headerBgColor select [1, 2])) / 255,
        parseNumber ("0x" + (_headerBgColor select [3, 2])) / 255,
        parseNumber ("0x" + (_headerBgColor select [5, 2])) / 255,
        1
    ];
    _headerBg ctrlCommit 0;
    
    // Create header text
    private _headerText = _display ctrlCreate ["RscText", 10002, _container];
    _headerText ctrlSetPosition [0, 0, 0.15 * safezoneW, 0.03 * safezoneH];
    _headerText ctrlSetText _title;
    _headerText ctrlSetFont "PuristaBold";
    _headerText ctrlSetFontHeight 0.03;  // Original font height
    _headerText ctrlSetTextColor [1, 1, 1, 1];
    _headerText ctrlSetBackgroundColor [0, 0, 0, 0];
    _headerText ctrlCommit 0;
    
    // Create content background
    private _contentBg = _display ctrlCreate ["RscText", 10003, _container];
    _contentBg ctrlSetPosition [0, 0.03 * safezoneH, 0.15 * safezoneW, 0.12 * safezoneH];
    _contentBg ctrlSetBackgroundColor [0, 0, 0, 0.5];
    _contentBg ctrlCommit 0;
    
    // Process content based on its type
    private _processedContent = _content;
    if (typeName _content == "STRING" && _content != "") then { _processedContent = _content; };
    
    // Create content text
    private _contentText = _display ctrlCreate ["RscStructuredText", 10004, _container];
    _contentText ctrlSetPosition [0.005 * safezoneW, 0.035 * safezoneH, 0.14 * safezoneW, 0.11 * safezoneH];
    _contentText ctrlSetStructuredText parseText _processedContent;
    _contentText ctrlCommit 0;
    
    // Add border to the whole thing
    private _border = _display ctrlCreate ["RscFrame", 10005, _container];
    _border ctrlSetPosition [0, 0, 0.15 * safezoneW, 0.15 * safezoneH];
    _border ctrlSetTextColor [0.8, 0.8, 0.8, 0.5];
    _border ctrlCommit 0;
    
    // Set up fade-out after duration and check if camera still exists
    [_duration, _container] spawn {
        params ["_duration", "_container"];
        
        // Wait for duration
        private _endTime = time + _duration;
        waitUntil { time >= _endTime || (isNil "IDS_LOGISTICS_CAM" || { isNull IDS_LOGISTICS_CAM }) };
        
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
    IDS_LOGISTICS_CAM_HINT_LAYER cutRsc ["RscTitleDisplayEmpty", "PLAIN"];
    
    private _display = uiNamespace getVariable "RscTitleDisplayEmpty";
    
    // Create the container control
    private _container = _display ctrlCreate ["RscControlsGroupNoScrollbars", 9999];
    _container ctrlSetPosition [
        0.8 * safezoneW + safezoneX,
        0.65 * safezoneH + safezoneY,
        0.15 * safezoneW,
        0.3 * safezoneH
    ];
    _container ctrlCommit 0;
    
    // Create header background
    private _headerBg = _display ctrlCreate ["RscText", 10001, _container];
    _headerBg ctrlSetPosition [0, 0, 0.15 * safezoneW, 0.03 * safezoneH];
    _headerBg ctrlSetBackgroundColor [
        parseNumber ("0x" + (_headerBgColor select [1, 2])) / 255,
        parseNumber ("0x" + (_headerBgColor select [3, 2])) / 255,
        parseNumber ("0x" + (_headerBgColor select [5, 2])) / 255,
        1
    ];
    _headerBg ctrlCommit 0;
    
    // Create header text
    private _headerText = _display ctrlCreate ["RscText", 10002, _container];
    _headerText ctrlSetPosition [0, 0, 0.15 * safezoneW, 0.03 * safezoneH];
    _headerText ctrlSetText _title;
    _headerText ctrlSetFont "PuristaBold";
    _headerText ctrlSetFontHeight 0.03;
    _headerText ctrlSetTextColor [1, 1, 1, 1];
    _headerText ctrlSetBackgroundColor [0, 0, 0, 0];
    _headerText ctrlCommit 0;
    
    // Create content background
    private _contentBg = _display ctrlCreate ["RscText", 10003, _container];
    _contentBg ctrlSetPosition [0, 0.03 * safezoneH, 0.15 * safezoneW, 0.27 * safezoneH];
    _contentBg ctrlSetBackgroundColor [0, 0, 0, 0.5];
    _contentBg ctrlCommit 0;
    
    // Process content based on its type
    private _processedContent = _content;
    if (typeName _content == "STRING" && _content != "") then {
        _processedContent = _content;
    };
    
    // Create content text
    private _contentText = _display ctrlCreate ["RscStructuredText", 10004, _container];
    _contentText ctrlSetPosition [0.005 * safezoneW, 0.035 * safezoneH, 0.14 * safezoneW, 0.26 * safezoneH];
    _contentText ctrlSetStructuredText parseText _processedContent;
    _contentText ctrlCommit 0;
    
    // Add border to the whole thing
    private _border = _display ctrlCreate ["RscFrame", 10005, _container];
    _border ctrlSetPosition [0, 0, 0.15 * safezoneW, 0.3 * safezoneH];
    _border ctrlSetTextColor [0.8, 0.8, 0.8, 0.5];
    _border ctrlCommit 0;
    
    // Start monitoring for camera existence
    [_container] spawn {
        params ["_container"];
        waitUntil {isNil "IDS_LOGISTICS_CAM" || { isNull IDS_LOGISTICS_CAM } || {isNull _container}};
        
        // If container still exists but camera doesn't, remove it
        if (!isNull _container && (isNil "IDS_LOGISTICS_CAM" || { isNull IDS_LOGISTICS_CAM })) then {
            _container ctrlSetFade 1;
            _container ctrlCommit 0.5;
            sleep 0.5;
            ctrlDelete _container;
        };
    };
};