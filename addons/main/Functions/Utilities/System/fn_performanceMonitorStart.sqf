if (FLO_PerformanceMonitorPfhId >= 0) exitWith {};

[
    { FLO_MissionReady },
    {
        FLO_PerformanceMonitorPfhId = [{
            if (hasInterface && {!isGameFocused}) exitWith {};

            private _fps = diag_fps;
            private _fpsMin = diag_fpsMin;
            if (_fps >= 45 && {_fpsMin >= 30}) exitWith {};

            private _liveUnits = count allUnits;
            private _liveAi = { !isPlayer _x } count allUnits;
            private _liveGroups = count allGroups;
            private _liveVehicles = count vehicles;
            private _virtualGroups = "REMOTE";
            if (isServer) then {
                _virtualGroups = count (keys (call FLO_fnc_virtualizationGetGroupMap));
            };
            private _operationsOpen = hasInterface && {!isNull (findDisplay FLO_OperationsDialogIdd)};
            private _developmentOpen = hasInterface && {!isNull (findDisplay FLO_DevelopmentDialogIdd)};

            diag_log format [
                "[FLO][PERF][FRAME] fps=%1 min=%2 units=%3 ai=%4 groups=%5 vehicles=%6 virtual=%7 operationsOpen=%8 developmentOpen=%9",
                round (_fps * 10) / 10,
                round (_fpsMin * 10) / 10,
                _liveUnits,
                _liveAi,
                _liveGroups,
                _liveVehicles,
                _virtualGroups,
                _operationsOpen,
                _developmentOpen
            ];
        }, 10] call CBA_fnc_addPerFrameHandler;
    }
] call CBA_fnc_waitUntilAndExecute;
