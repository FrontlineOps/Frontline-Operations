/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

FOBB = nearestObjects [position player, [F_OP_01], 150] select 0;
publicVariable "FOBB";

if (!isNil "FOBB") then {
    [FOBB] call FLO_fnc_initializeOP;
} else {
    ["OP", 1, "Error: OP object not defined for creation factory setup"] call FLO_fnc_log;
};

if (isClass(configFile >> "CfgPatches" >> "ace_main")) then {
    [FOBB, true] remoteExec ["ace_arsenal_fnc_initBox", 0];
};