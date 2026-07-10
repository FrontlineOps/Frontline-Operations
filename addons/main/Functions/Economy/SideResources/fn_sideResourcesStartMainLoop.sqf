if (!isServer) exitWith { false };

if (isNil "FLO_SideResourceSystem") then {
    FLO_SideResourceSystem = createHashMapFromArray [
        ["pfhId", -1],
        ["updateInterval", 0]
    ];
};

if ((FLO_SideResourceSystem get "pfhId") >= 0) exitWith { true };

private _interval = (FLO_SideResources get "EAST") get "UPDATE_INTERVAL";
private _pfhId = [{
    [] call FLO_fnc_sideResourcesTick;
}, _interval] call CBA_fnc_addPerFrameHandler;

FLO_SideResourceSystem set ["pfhId", _pfhId];
FLO_SideResourceSystem set ["updateInterval", _interval];
["ECONOMY", 2, format ["Started side income worker (%1s)", _interval]] call FLO_fnc_log;
true
