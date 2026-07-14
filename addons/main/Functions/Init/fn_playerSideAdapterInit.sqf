/* Initializes the runtime adapter for generic lobby slots. */
if (isServer) then {
    FLO_PlayerSideAdapterGroups = createHashMap;
    ["INIT", 3, "Runtime player-side adapter initialized"] call FLO_fnc_log;
};

if (hasInterface) then {
    FLO_PlayerSideAdapterUnitHandler = ["unit", {
        params ["_newUnit", "_oldUnit"];
        if (isNull _newUnit) exitWith {};

        [{
            params ["_unit"];
            [_unit] remoteExecCall ["FLO_fnc_playerSideAdapterRequest", 2];
        }, [_newUnit]] call CBA_fnc_execNextFrame;
    }] call CBA_fnc_addPlayerEventHandler;

    if (!isNull player) then {
        [{
            params ["_unit"];
            [_unit] remoteExecCall ["FLO_fnc_playerSideAdapterRequest", 2];
        }, [player]] call CBA_fnc_execNextFrame;
    };
};

true
