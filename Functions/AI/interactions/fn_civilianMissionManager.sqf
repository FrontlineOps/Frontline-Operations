/*
 * Function: FLO_fnc_civilianMissionManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Manages the lifecycle of civilian missions.
 *
 * Arguments:
 *   0: Mode <STRING> - "INIT", "NEXT_MISSION", "MISSION_COMPLETE"
 *
 * Example:
 *   ["INIT"] call FLO_fnc_civilianMissionManager;
 */

params ["_mode", "_args"];

switch (toUpper _mode) do {
    case "INIT": {
        FLO_CivilianMission_Active = false;
        ["CIV_MISSION", 3, "Civilian Mission Manager Initialized (Waiting for player request)"] call FLO_fnc_log;
    };

    case "NEXT_MISSION": {
        if (isNil "FLO_CivilianMission_Active") then { FLO_CivilianMission_Active = false; };
        if (FLO_CivilianMission_Active) exitWith {
            ["CIV_MISSION", 3, "Mission already active, skipping valid request"] call FLO_fnc_log;
        };

        // Select a random mission from the available pool
        // Assuming missions are named civMission1...N
        private _availableMissions = ["fn_civMission1", "fn_civMission2", "fn_civMission3", "fn_civMission4"];
        private _selectedMission = selectRandom _availableMissions;

        // Execute the mission function
        FLO_CivilianMission_Active = true;
        
        // Dynamic call to the mission function
        private _fncName = "FLO_" + _selectedMission;
        private _function = missionNamespace getVariable ["FLO_" + ( _selectedMission select [3]), ""];
        private _missionId = (floor random 4) + 1; // 1 to 4
        private _fnc = missionNamespace getVariable [format["FLO_fnc_civMission%1", _missionId], ""];
        
        if (!isNil "_fnc") then {
            ["CIV_MISSION", 3, format["Starting Mission %1", _missionId]] call FLO_fnc_log;
            [] call _fnc;
            _missionId
        } else {
            ["CIV_MISSION", 1, format["Failed to start mission %1 - Function not found", _missionId]] call FLO_fnc_log;
            FLO_CivilianMission_Active = false;
            0
        };
    };

    case "MISSION_COMPLETE": {
        // Called by missions when they finish
        FLO_CivilianMission_Active = false;
        
        // Schedule next mission
        private _delay = 600 + (random 600); // 10-20 minutes between missions
        if (!isMultiplayer) then { _delay = 300 + (random 300); };

        // Loop removed
        ["CIV_MISSION", 3, "Mission Complete. Waiting for next player request."] call FLO_fnc_log;
    };
};
