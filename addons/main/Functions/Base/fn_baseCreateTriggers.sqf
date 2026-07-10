/*
 * Function: FLO_fnc_baseCreateTriggers
 * Author: Frontline Operations Development Group
 * Description:
 *   Creates shared civilian/resource triggers for FOB/COP buildings.
 *
 * Arguments:
 * 0: Building <OBJECT>
 * 1: Base config <HASHMAP>
 *
 * Returns:
 * Created triggers <ARRAY>
 */
params ["_building", "_config"];

private _type = _config get "type";
private _triggers = [];

try {
    private _civTrigger = createTrigger ["EmptyDetector", getPos _building];
    _civTrigger setTriggerArea [5, 5, 0, false, 7];
    _civTrigger setTriggerTimeout [3, 3, 3, true];
    _civTrigger setTriggerActivation ["NONE", "PRESENT", true];
    _civTrigger setTriggerStatements [
        "((thisTrigger nearEntities [['Man'], 5]) select {(alive _x) && {side _x isEqualTo civilian}}) isNotEqualTo []",
        "
        private _civilian = (nearestObjects [thisTrigger, ['Man'], 7] select {(alive _x) && ((side _x) isEqualTo civilian)}) param [0, objNull];

        if (!isNull _civilian) then {
            if (_civilian getUnitTrait 'engineer') then {
                [50, ""INSURGENT""] call FLO_fnc_sendRewardNotification;
                private _reportSide = missionNamespace getVariable ['FLO_ActivePlayerSide', west];
                if !(_reportSide in [east, west]) then { _reportSide = west; };
                [50, _reportSide, 'Insurgent turned in at a campaign base', netId _civilian] call FLO_fnc_addReward;
                [_civilian, _reportSide] call FLO_fnc_gtnAlertCivilianReport;
                deleteVehicle _civilian;
                [0.35, 'increase'] call FLO_fnc_adjustReputation;
            } else {
                [0, ""CIVILIAN""] call FLO_fnc_sendRewardNotification;
                deleteVehicle _civilian;
                [-0.35, 'decrease'] call FLO_fnc_adjustReputation;
            };
        };
        ", ""
    ];
    _civTrigger attachTo [_building, [0, 0, 0]];
    _triggers pushBack _civTrigger;

    [_type, 3, format["Created %1 triggers", count _triggers]] call FLO_fnc_log;
} catch {
    [_type, 1, format["Failed to create triggers: %1", _exception]] call FLO_fnc_log;
};

_triggers
