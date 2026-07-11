/*
 * Function: FLO_fnc_civilianActions
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies civilian interaction and casualty behavior to active civilians.
 *
 * Arguments:
 * 0: Civilian units <ARRAY>
 *
 * Return Value:
 * None
 */

params ["_civUnits"];

{
    private _unit = _x;
    if (isNull _unit || {!alive _unit}) then { continue };
    private _isProtester = _unit getVariable ["FLO_isProtester", false];
    private _isDetained = captive _unit || {_unit getVariable ["FLO_CivilianDetained", false]};
    private _killedEhId = _unit getVariable ["FLO_CivilianKilledEhId", -1];

    if (_killedEhId >= 0) then {
        _unit removeEventHandler ["Killed", _killedEhId];
    };

    _killedEhId = _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];

        private _activeSide = FLO_ActivePlayerSide;
        if !(_activeSide in [east, west]) then {
            _activeSide = west;
        };

        if (side _killer == _activeSide) then {
            [-0.35, "decrease"] call FLO_fnc_adjustReputation;
        };
    }];
    _unit setVariable ["FLO_CivilianKilledEhId", _killedEhId];

    [_unit, _isProtester, _isDetained] remoteExec ["FLO_fnc_civilianConfigureActionsLocal", 0, _unit];

    if (!_isProtester && {!_isDetained} && {!isNil "FLO_CivilianManager"}) then {
        if (FLO_CivilianManager call ["shouldFlee", [getPosATL _unit]]) then {
            private _players = allPlayers select { alive _x };
            if (_players isNotEqualTo []) then {
                private _nearestPlayer = _players param [0, objNull];
                private _nearestDistance = 1e12;
                {
                    private _distance = _unit distance2D _x;
                    if (_distance < _nearestDistance) then {
                        _nearestPlayer = _x;
                        _nearestDistance = _distance;
                    };
                } forEach _players;

                if (!isNull _nearestPlayer) then {
                    private _fleePos = (getPosATL _unit) getPos [(FLO_CivilianConfig get "FLEE_DISTANCE") + random 40, ((getPosATL _nearestPlayer) getDir (getPosATL _unit))];
                    _unit setBehaviour "CARELESS";
                    _unit setSpeedMode "FULL";
                    _unit doMove _fleePos;
                };
            };
        };
    };
} forEach _civUnits
