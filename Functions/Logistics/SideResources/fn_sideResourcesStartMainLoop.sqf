/*
 * Function: FLO_fnc_sideResourcesStartMainLoop
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts the shared periodic side-resource generation worker using a single
 *   CBA PFH instead of per-side spawned loops.
 *
 * Arguments:
 *   None
 *
 * Return Value:
 *   Success <BOOL>
 *
 * Example:
 *   [] call FLO_fnc_sideResourcesStartMainLoop;
 */

if (isNil "FLO_SideResourceSystem") then {
    FLO_SideResourceSystem = createHashMapFromArray [
        ["pfhId", -1],
        ["updateInterval", -1]
    ];
};

private _pfhId = FLO_SideResourceSystem get "pfhId";
if (_pfhId >= 0) exitWith { true };

private _eastResources = FLO_SideResources get "EAST";
private _interval = _eastResources get "UPDATE_INTERVAL";

[] call FLO_fnc_sideResourcesTick;

_pfhId = [{
    [] call FLO_fnc_sideResourcesTick;
}, _interval, []] call CBA_fnc_addPerFrameHandler;

FLO_SideResourceSystem set ["pfhId", _pfhId];
FLO_SideResourceSystem set ["updateInterval", _interval];

["SIDE_RES", 3, format ["Side resource main loop started (%1s PFH)", _interval]] call FLO_fnc_log;

true
