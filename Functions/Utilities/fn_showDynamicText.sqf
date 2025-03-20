/*
 * Author: FLOPS Team
 * Shows dynamic text on player's screen
 *
 * Arguments:
 * 0: Text to display <STRING>
 * 1: Duration <NUMBER>
 *
 * Return Value:
 * None
 *
 * Example:
 * ["Hello World", 5] call FLO_fnc_showDynamicText;
 */

params [["_text", "", [""]], ["_duration", 5, [0]]];

// Convert to structured text if not already
if (typeName _text == "STRING") then {
    _text = parseText _text;
};

// Use standard parameters for positioning
[_text, true, nil, _duration, 0.7] spawn BIS_fnc_textTiles;