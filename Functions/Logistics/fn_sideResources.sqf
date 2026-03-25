/*
 * Function: FLO_fnc_sideResources
 * Author: Frontline Operations Development Group
 * Description:
 *   Initializes side-scoped resource objects for EAST and WEST and starts
 *   the shared periodic generation worker.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   HashMap of side resource objects <HASHMAP>
 */

if (!isServer) exitWith { createHashMap };

if (!isNil "FLO_SideResources" && {FLO_SideResources isEqualType createHashMap} && {(count (keys FLO_SideResources)) > 0}) exitWith {
    FLO_SideResources
};

private _savedResources = createHashMap;
if (!isNil "FLO_SavedGameData" && {FLO_SavedGameData isEqualType createHashMap} && {"sideResources" in FLO_SavedGameData}) then {
    private _savedRaw = FLO_SavedGameData get "sideResources";
    if (_savedRaw isEqualType createHashMap) then {
        _savedResources = _savedRaw;
    };
};

private _sideResourceClass = [
    ["#type", "SideResources"],

    ["RESOURCE_VALUES", createHashMapFromArray [
        ["capital", 28],
        ["city", 18],
        ["marine", 16],
        ["local", 12],
        ["village", 6],
        ["cluster", 2]
    ]],

    ["STARTING_VALUES", createHashMapFromArray [
        ["capital", 131],
        ["city", 79],
        ["marine", 67],
        ["local", 49],
        ["village", 25],
        ["cluster", 11]
    ]],

    ["CONTEST_MODIFIERS", createHashMapFromArray [
        ["SECURE", 1.0],
        ["DEFENDED", 0.85],
        ["CONTESTED", 0.65],
        ["OVERRUN", 0.35]
    ]],

    ["SPENDING_TYPES", createHashMapFromArray [
        ["garrison", [1.0, 10, 0.05]],
        ["reinforcement", [1.0, 20, 0.02]],
        ["qrf", [1.5, 100, 0.08]],
        ["offensiveops", [4.0, 500, 0.15]],
        ["air_support", [2.0, 250, 0.12]],
        ["artillery", [3.0, 150, 0.07]],
        ["transport", [0.5, 15, 0.02]]
    ]],

    ["EFFICIENCY_FLOOR", 0.35],
    ["EFFICIENCY_RECOVERY", 0.02],

    ["UPDATE_INTERVAL", 180],
    ["OBJECTIVE_CAPTURE_REWARD", 200],

    ["_side", east],
    ["_sideKey", "EAST"],
    ["_enemySide", west],
    ["_resources", 0],
    ["_lastUpdate", 0],
    ["_efficiencies", createHashMap],

    ["#create", {
        ([_self] + _this) call FLO_fnc_sideResourcesCreate;
    }],

    ["_calculateStartingResources", {
        [_self] call FLO_fnc_sideResourcesCalculateStartingResources;
    }],

    ["getResources", {
        _self get "_resources"
    }],

    ["addResources", {
        ([_self] + _this) call FLO_fnc_sideResourcesAddResources;
    }],

    ["canAfford", {
        ([_self] + _this) call FLO_fnc_sideResourcesCanAfford;
    }],

    ["spendResources", {
        ([_self] + _this) call FLO_fnc_sideResourcesSpendResources;
    }],

    ["serialize", {
        [_self] call FLO_fnc_sideResourcesSerialize;
    }]
];

FLO_SideResources = createHashMap;

{
    private _side = _x;
    private _sideKey = ([_side] call FLO_fnc_gtnSideContext) get "sideKey";
    private _savedPayload = objNull;
    if (_sideKey in _savedResources) then {
        _savedPayload = _savedResources get _sideKey;
    };

    private _obj = createHashMapObject [_sideResourceClass, [_side, _savedPayload]];
    FLO_SideResources set [_sideKey, _obj];
} forEach [east, west];

[] call FLO_fnc_sideResourcesPublishState;
[] call FLO_fnc_sideResourcesStartMainLoop;

["SIDE_RES", 2, "Initialized side resource system (EAST/WEST)"] call FLO_fnc_log;

FLO_SideResources
