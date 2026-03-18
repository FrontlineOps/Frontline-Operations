/*
 * Function: FLO_fnc_logisticsNetworkFindRearObjectives
 * Author: Frontline Operations Development Group
 * Description:
 *   Finds managed-side objectives that are outside the player-live area and
 *   can be used as quiet rear-area reinforcement targets.
 *
 * Arguments:
 *   0: Logistics network object <HASHMAP>
 *   1: Minimum player distance <NUMBER> - Default 3000
 *
 * Return Value:
 *   ARRAY - Rear objective IDs
 */

params ["_net", ["_minPlayerDistance", 3000]];

private _managedSide = _net get "_managedSide";
private _players = allPlayers;
private _objectiveIds = keys FLO_Objectives;

if (count _players == 0) exitWith {
    _objectiveIds select {
        ((FLO_Objectives get _x) get "owner") isEqualTo _managedSide
    }
};

_objectiveIds select {
    private _objData = FLO_Objectives get _x;
    if ((_objData get "owner") isNotEqualTo _managedSide) exitWith { false };

    private _objPos = _objData get "position";
    ({ _x distance2D _objPos < _minPlayerDistance } count _players) isEqualTo 0
}
