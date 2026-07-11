if (!isServer) exitWith { false };
if ((FLO_ObjectiveDevelopmentRuntime get "pfhId") >= 0) exitWith { true };

{
    FLO_Objectives set [_x, [_x, _y] call FLO_fnc_objectiveDevelopmentInitializeObjective];
} forEach FLO_Objectives;
{ [_x] call FLO_fnc_objectiveDevelopmentGetActiveObjectiveIds; } forEach ["WEST", "EAST"];

[] call FLO_fnc_objectiveDevelopmentTick;
private _pfhId = [{
    [] call FLO_fnc_objectiveDevelopmentTick;
}, FLO_ObjectiveDevelopmentConfig get "tickInterval", []] call CBA_fnc_addPerFrameHandler;
FLO_ObjectiveDevelopmentRuntime set ["pfhId", _pfhId];
["ECONOMY", 2, format [
    "Objective development worker started for EAST and WEST with %1 concurrent projects per side",
    FLO_ObjectiveDevelopmentConfig get "maximumConcurrentProjects"
]] call FLO_fnc_log;
true
