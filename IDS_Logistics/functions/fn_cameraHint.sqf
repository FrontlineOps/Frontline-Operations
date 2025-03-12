/**
 * @name IDS_Logistics_fnc_cameraHint
 * @category Logistics_Core
 * 
 * @author IDSolutions
 * @version 1.1
 * @date 2025-03-10
 * 
 * @description
 * Displays structured hints for the build camera system.
 * Supports both temporary notifications and persistent help texts.
 * Uses layered hints to avoid conflicts between different types of messages.
 *
 * @param {String|Array} _content - The content to display. Can be a simple string or structured text
 * @param {Number} _duration - How long to display the hint (0 = indefinite)
 * @param {Boolean} [_clearOnly] - If true, only clears the hint layer without showing anything
 * @param {Boolean} [_isToggleable] - If true, this hint can be toggled with the H key
 *
 * @return {Nothing}
 *
 * @example
 * ["Entity placed", 2] call IDS_Logistics_fnc_cameraHint
 * [_structuredText, 0, false, true] call IDS_Logistics_fnc_cameraHint
 */

params [
    ["_content", "", ["", []]],
    ["_duration", 0, [0]],
    ["_clearOnly", false, [false]],
    ["_isToggleable", false, [false]]
];

// Create hint layers if they don't exist
if (isNil "IDS_LOGISTICS_CAM_HINT_LAYER") then {
    IDS_LOGISTICS_CAM_HINT_LAYER = ["IDS_Logistics_Camera_Hint"] call BIS_fnc_rscLayer;
};

if (isNil "IDS_LOGISTICS_CAM_FLASH_LAYER") then {
    IDS_LOGISTICS_CAM_FLASH_LAYER = ["IDS_Logistics_Camera_Flash"] call BIS_fnc_rscLayer;
};

// If toggle hint, store it for later use
if (_isToggleable) then {
    IDS_LOGISTICS_TOGGLEABLE_HINT = _content;
};

// Handle clearing only
if (_clearOnly) exitWith {
    IDS_LOGISTICS_CAM_HINT_LAYER cutText ["", "PLAIN"];
};

// Prepare the hint content
private _formattedContent = _content;
if (typeName _content == typeName "") then {
    if (_content != "") then {
        _formattedContent = parseText format [
            "<t align='center' shadow='2' size='0.5'>%1</t>",
            _content
        ];
    };
};

// Choose which layer to use based on duration
if (_duration > 0) then {
    // Flash hints (temporary notifications) - fade in/out
    IDS_LOGISTICS_CAM_FLASH_LAYER cutRsc ["RscDynamicText", "PLAIN"];
    
    private _display = uiNamespace getVariable "BIS_dynamicText";
    private _ctrl = _display displayCtrl 9999;
    
    _ctrl ctrlSetStructuredText _formattedContent;
    _ctrl ctrlSetPosition [
        0.3 * safezoneW + safezoneX,
        0.2 * safezoneH + safezoneY,
        0.4 * safezoneW,
        0.2 * safezoneH
    ];
    _ctrl ctrlCommit 0;
    
    // Set up fade-out after duration
    [_duration, _ctrl] spawn {
        params ["_duration", "_ctrl"];
        sleep _duration;
        _ctrl ctrlSetFade 1;
        _ctrl ctrlCommit 0.5;
    };
} else {
    // Persistent hints - no fade
    IDS_LOGISTICS_CAM_HINT_LAYER cutRsc ["RscDynamicText", "PLAIN"];
    
    private _display = uiNamespace getVariable "BIS_dynamicText";
    private _ctrl = _display displayCtrl 9999;
    
    _ctrl ctrlSetStructuredText _formattedContent;
    _ctrl ctrlSetPosition [
        0.7 * safezoneW + safezoneX,
        0.5 * safezoneH + safezoneY,
        0.25 * safezoneW,
        0.45 * safezoneH
    ];
    _ctrl ctrlSetFade 0;
    _ctrl ctrlCommit 0;
};