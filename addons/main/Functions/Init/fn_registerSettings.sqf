/*
 * Function: FLO_fnc_registerSettings
 * Author: Frontline Operations Development Group
 * Description:
 *   Registers addon-level CBA settings that replace removed mission lobby
 *   parameters.
 */

if (missionNamespace getVariable ["FLO_SettingsRegistered", false]) exitWith {
    diag_log "[FLO_SETTINGS] CBA settings already registered";
};

private _settingsFn = if (!isNil "cba_settings_fnc_init") then {
    cba_settings_fnc_init
} else {
    if (!isNil "CBA_fnc_addSetting") then {
        CBA_fnc_addSetting
    } else {
        nil
    }
};

if (isNil "_settingsFn") exitWith {
    diag_log "[FLO_SETTINGS] CBA settings API is unavailable; required CBA settings were not registered";
};

private _campaignLaunchMode = [
    "FLO_CampaignLaunchMode",
    "LIST",
    ["Campaign launch mode", "Fresh setup opens the FLO setup dialog. Continue saved progress loads a valid saved campaign. Reset saved progress deletes the saved campaign and opens fresh setup."],
    ["FLO", "Campaign"],
    [[0, 1, 2], ["Fresh setup", "Continue saved progress", "Reset saved progress"], 0],
    1
];

_campaignLaunchMode call _settingsFn;

missionNamespace setVariable ["FLO_SettingsRegistered", true];
diag_log "[FLO_SETTINGS] Registered CBA settings";
