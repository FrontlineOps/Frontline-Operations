/*
 * Function: FLO_fnc_virtualizationSetEnabled
 * Author: Frontline Operations Development Group
 * Description:
 *   Enables or disables the virtualization system.
 */

params [["_enable", true, [true]]];

["enabled", _enable] call FLO_fnc_virtualizationSetConfigValue;

if (_enable) then {
    ["start"] call FLO_fnc_virtualizationUpdatePFH;
} else {
    ["stop"] call FLO_fnc_virtualizationUpdatePFH;
};

["VIRTUALIZATION", 3, format ["Virtualization %1", ["disabled", "enabled"] select (_enable)]] call FLO_fnc_log;

true
