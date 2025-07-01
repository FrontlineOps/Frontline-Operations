/*
 * Function: FLO_fnc_sideMissionSabotage
 * Author: Frontline Operations Development Group
 * Description:
 *   Starts a mission to sabotage enemy technology or supplies.
 */

params [];

private _GNRT = "YES";
private _DVRT = "NO";
[_DVRT, _GNRT] spawn {
    params ["_DVRT", "_GNRT"];
    private _result = [
        "Intel reports a valuable enemy device in the area. Destroy it (Optional Mission: Sabotage Tech)",
        "", _DVRT, _GNRT, nil, false, false
    ] call BIS_fnc_guiMessage;

    if (_result) then {
        [player] call FLO_fnc_revealRandomEnemyGroup;
    } else {
        private _pos = player getPos [300 + random 300, random 360];
        private _obj = createVehicle ["Land_CargoBox_V1_F", _pos, [], 0, "NONE"];
        
        [_obj] spawn {
            params ["_target"];
            
            // Initial planting animation
            titleText ["Planting Explosives Charges . . .", "BLACK IN", 1];
            sleep 2;
            
            // Countdown display using a single function
            private _fnc_showCountdown = {
                params ["_time"];
                [format ["<t color='#ff0000' size='0.5'>CLEAR OUT<br />Exploding in %1</t>", _time], -1, -1, 1, 0.1, 0, 789] spawn BIS_fnc_dynamicText;
            };
            
            // Execute countdown
            for "_i" from 10 to 2 step -1 do {
                [_i] call _fnc_showCountdown;
                sleep 1;
            };
            
            // Trigger explosion
            [_target, "Sh_82mm_AMOS", 0, 1, 1] spawn BIS_fnc_fireSupportVirtual;
            sleep 1.5;
            _target setDamage 1;
            
            // Send rewards
            [30, "STR_FLO_TECH"] call FLO_fnc_sendRewardNotification;
            [30] call FLO_fnc_addReward;
            
            sleep 6;
        };
    };
};
