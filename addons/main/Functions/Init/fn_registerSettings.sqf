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

private _debugLevel = [
    "FLO_Debug_Level",
    "LIST",
    ["RPT logging level", "Information is the production default. Debug and Trace add investigation detail and can materially increase RPT volume."],
    ["FLO", "Diagnostics"],
    [[1, 2, 3, 4, 5], ["Errors", "Warnings", "Information", "Debug", "Trace"], 2],
    1
];

_debugLevel call _settingsFn;

private _artillerySideCooldown = [
    "FLO_ArtillerySideCooldownSeconds",
    "SLIDER",
    ["Side fire mission cooldown", "Minimum time between successful artillery missions for the same side, regardless of target or battery."],
    ["FLO", "Artillery"],
    [60, 1800, 300, 0],
    1
];

private _artilleryBatteryCooldown = [
    "FLO_ArtilleryBatteryCooldownSeconds",
    "SLIDER",
    ["Battery rearm time", "Minimum time before the same artillery battery can start another fire mission."],
    ["FLO", "Artillery"],
    [60, 3600, 600, 0],
    1
];

private _artilleryTreasuryCost = [
    "FLO_ArtilleryTreasuryCostPerRound",
    "SLIDER",
    ["Treasury cost per round", "Shared side treasury resources committed for each requested artillery round."],
    ["FLO", "Artillery"],
    [25, 500, 100, 0],
    1
];

private _artilleryLocalSupplyCost = [
    "FLO_ArtilleryLocalSupplyCostPerRound",
    "SLIDER",
    ["Local Supplies per round", "Local Supplies consumed from the connected source sustaining the artillery battery."],
    ["FLO", "Artillery"],
    [25, 500, 150, 0],
    1
];

_artillerySideCooldown call _settingsFn;
_artilleryBatteryCooldown call _settingsFn;
_artilleryTreasuryCost call _settingsFn;
_artilleryLocalSupplyCost call _settingsFn;

private _airActivationMultiplier = [
    "FLO_AirActivationDistanceMultiplier",
    "SLIDER",
    ["Aircraft activation distance multiplier", "Aircraft physically spawn at the normal virtualization distance multiplied by this value."],
    ["FLO", "Virtualization"],
    [1, 4, 2, 1],
    1
];

_airActivationMultiplier call _settingsFn;

missionNamespace setVariable ["FLO_SettingsRegistered", true];
diag_log "[FLO_SETTINGS] Registered CBA settings";
