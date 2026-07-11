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

private _players = allPlayers;
private _objectiveIds = _net get "_managedObjectiveIds";
private _rearObjectives = [];

if (_players isEqualTo []) then {
    {
        _rearObjectives pushBack _x;
    } forEach _objectiveIds;
} else {
    {
        private _objData = FLO_Objectives get _x;
        private _objPos = _objData get "position";
        private _isRear = true;

        {
            if (_x distance2D _objPos < _minPlayerDistance) exitWith {
                _isRear = false;
            };
        } forEach _players;

        if (_isRear) then {
            _rearObjectives pushBack _x;
        };
    } forEach _objectiveIds;
};

_rearObjectives
