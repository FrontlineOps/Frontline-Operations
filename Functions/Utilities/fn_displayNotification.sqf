/**
 * Function: FLO_fnc_displayNotification
 * 
 * Description:
 * Displays a notification sent from the server
 *
 * Parameters:
 * _titleType : STRING - from string table
 * _msg : STRING or ARRAY - from string table if string or -OR- an array for format command where first index is string table key
 * _color : STRING - in format #RRGGBB
 * _playMusic - BOOL - play a musical sound (mostly for rewards)
 *
 * Returns:
 * Nothing
 *
 * Examples:
 * ["STR_FLO_WARNING_TITLE","STR_FLO_WARNING_EAIR", "#FF1111"] call FLO_fnc_displayNotification;
 * ["STR_FLO_WARNING_TITLE", ["STR_FLO_WARNING_EATTACKOBJ", str _objective], "#FF1111"] call FLO_fnc_displayNotification;
 */

//Only display on clients/servers with user interface
if !(hasInterface) exitwith {};

 params [
    ["_title","",[""]],
    ["_msg","",["",[]]],
    ["_color","#FFFFFF",[""]],
    ["_playMusic", false , [true]]
];

if (_msg isEqualType []) then {
    //localize any strings in format array
    for "_i" from 0 to (count _msg-1) do {
        private _arg = _msg#_i;
        if (_arg isEqualType "" && {_arg find ["STR_",0] isNotEqualTo -1}) then {
            _msg set [_i, localize (_arg)];
        };
    };
    _msg = format _msg;
} else {
    // else localize the msg
    _msg = localize _msg;
};

// TODO:
// 1. Create RscTitles class in description.ext for HUD notification element
// 2. Implement ctrWebBrowser control for HTML/CSS based notifications
// 3. Add BIS or CBA Event System for notification requests
// 4. Create notification types/templates (info, warning, error, reward)
// 5. Add queue system for multiple notifications
// Format and display notification
private _formattedMsg = format [
    "<t color='%1' font='PuristaBold' align='right' shadow='1' size='2'>%2</t><br/><t align='right' shadow='1' size='1'>%3</t>",
    _color,
    localize _title,
    _msg
];

// Play music for all players
if (_playMusic) then {playMusic "EventTrack01_F_Curator";};
[parseText _formattedMsg, [0, 0.5, 1, 1], [10,10], 5, 1.7, 0] call BIS_fnc_TextTiles;