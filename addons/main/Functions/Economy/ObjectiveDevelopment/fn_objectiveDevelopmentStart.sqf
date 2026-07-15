if (!isServer) exitWith { false };
if ((FLO_ObjectiveDevelopmentRuntime get "pfhId") >= 0) exitWith { true };

{
    FLO_Objectives set [_x, [_x, _y] call FLO_fnc_objectiveDevelopmentInitializeObjective];
} forEach FLO_Objectives;
[] call FLO_fnc_objectiveDevelopmentValidateFundingReservations;
{ [_x] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds; } forEach ["WEST", "EAST"];

[] call FLO_fnc_objectiveDevelopmentTick;
private _pfhId = [{
    [] call FLO_fnc_objectiveDevelopmentTick;
}, FLO_ObjectiveDevelopmentConfig get "tickInterval", []] call CBA_fnc_addPerFrameHandler;
FLO_ObjectiveDevelopmentRuntime set ["pfhId", _pfhId];
["ECONOMY", 3, format [
    "Objective Development worker started capacity WEST=%1 EAST=%2",
    [west] call FLO_fnc_objectiveDevelopmentGetProjectCapacity,
    [east] call FLO_fnc_objectiveDevelopmentGetProjectCapacity
]] call FLO_fnc_log;
true
