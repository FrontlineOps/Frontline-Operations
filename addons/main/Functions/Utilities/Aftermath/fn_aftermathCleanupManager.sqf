/*
 * Function: FLO_fnc_aftermathCleanupManager
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-owned cleanup manager for corpses, wrecks, and weapon holders.
 *
 * Arguments:
 * 0: Mode <STRING> - "init", "start", "stop"
 *
 * Return Value:
 * BOOL - True on success
 */

params [["_mode", "start", [""]]];

if (!isServer) exitWith { false };

if (isNil "FLO_AftermathCleanup") then {
    FLO_AftermathCleanup = createHashMapFromArray [
        ["enabled", false],
        ["pfhId", -1],
        ["entityKilledEhId", -1],
        ["interval", 30],
        ["playerEvidenceRadius", 300],
        ["corpseGraceTime", 900],
        ["wreckGraceTime", 1200],
        ["weaponHolderGraceTime", 900],
        ["wreckSettleMaxSpeed", 1.5],
        ["wreckSurfaceClearance", 5],
        ["trackedEntities", createHashMap],
        ["weaponHolderClasses", ["GroundWeaponHolder", "WeaponHolder", "WeaponHolderSimulated"]]
    ];
};

private _state = FLO_AftermathCleanup;

switch (toLower _mode) do {
    case "init": {
        if ((_state get "entityKilledEhId") < 0) then {
            private _ehId = addMissionEventHandler ["EntityKilled", {
                params ["_entity"];

                if (isNull _entity) exitWith {};
                if (_entity isKindOf "CAManBase") exitWith {
                    [_entity, "corpse"] call FLO_fnc_aftermathRegisterEntity;
                };
                if (_entity isKindOf "LandVehicle" || {_entity isKindOf "Air"} || {_entity isKindOf "Ship"}) exitWith {
                    [_entity, "wreck"] call FLO_fnc_aftermathRegisterEntity;
                };
            }];
            _state set ["entityKilledEhId", _ehId];
        };

        {
            [_x, "corpse"] call FLO_fnc_aftermathRegisterEntity;
        } forEach allDeadMen;

        {
            [_x, "wreck"] call FLO_fnc_aftermathRegisterEntity;
        } forEach (vehicles select { !alive _x });

        {
            {
                [_x, "weaponHolder"] call FLO_fnc_aftermathRegisterEntity;
            } forEach (allMissionObjects _x);
        } forEach (_state get "weaponHolderClasses");

        ["AFTERMATH_CLEANUP", 3, "Aftermath cleanup manager initialized"] call FLO_fnc_log;
        true
    };

    case "start": {
        ["init"] call FLO_fnc_aftermathCleanupManager;
        if (_state get "enabled") exitWith { true };

        _state set ["enabled", true];
        private _pfhId = [FLO_fnc_aftermathCleanupRun, _state get "interval", []] call CBA_fnc_addPerFrameHandler;
        _state set ["pfhId", _pfhId];

        ["AFTERMATH_CLEANUP", 2, format [
            "Aftermath cleanup started (interval=%1s corpseGrace=%2s wreckGrace=%3s holderGrace=%4s radius=%5m settleSpeed=%6m/s)",
            _state get "interval",
            _state get "corpseGraceTime",
            _state get "wreckGraceTime",
            _state get "weaponHolderGraceTime",
            _state get "playerEvidenceRadius",
            _state get "wreckSettleMaxSpeed"
        ]] call FLO_fnc_log;
        true
    };

    case "stop": {
        if !(_state get "enabled") exitWith { true };

        _state set ["enabled", false];
        private _pfhId = _state get "pfhId";
        if (_pfhId >= 0) then {
            [_pfhId] call CBA_fnc_removePerFrameHandler;
            _state set ["pfhId", -1];
        };

        private _ehId = _state get "entityKilledEhId";
        if (_ehId >= 0) then {
            removeMissionEventHandler ["EntityKilled", _ehId];
            _state set ["entityKilledEhId", -1];
        };

        _state set ["trackedEntities", createHashMap];
        ["AFTERMATH_CLEANUP", 3, "Aftermath cleanup stopped"] call FLO_fnc_log;
        true
    };

    default {
        ["AFTERMATH_CLEANUP", 1, format ["Unknown manager mode: %1", _mode]] call FLO_fnc_log;
        false
    };
};
