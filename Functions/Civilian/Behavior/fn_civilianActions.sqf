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

    removeAllActions _unit;
    _unit removeAllEventHandlers "Killed";

    _unit addEventHandler ["Killed", {
        params ["_unit", "_killer"];

        private _activeSide = FLO_ActivePlayerSide;
        if !(_activeSide in [east, west]) then {
            _activeSide = west;
        };

        if (side _killer == _activeSide) then {
            [-0.35, "decrease"] call FLO_fnc_adjustReputation;
        };
    }];

    if (!_isProtester) then {
        [_unit, [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\talk_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Ask About Activity",
            {
                params ["_target", "_caller"];
                [_target, _caller] call FLO_fnc_civilianRequestIntel;
            },
            nil, 1.5, true, true, "", "alive _target && !captive _target", 4, false, "", ""
        ]] remoteExec ["addAction", 0, true];

        [_unit, [
            "<img size=2 color='#7CC2FF' image='Screens\FOBA\defend_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Offer Help",
            {
                params ["_target", "_caller"];
                [_target, _caller] call FLO_fnc_civilianRequestMission;
            },
            nil, 1.5, true, true, "", "alive _target && !captive _target", 4, false, "", ""
        ]] remoteExec ["addAction", 0, true];
    };

    [_unit, [
        "<img size=2 color='#7CC2FF' image='Screens\FOBA\holdAction_secure_ca.paa'/><t font='PuristaBold' color='#7CC2FF'>Detain",
        {
            params ["_target", "_caller"];
            ["DETAIN", [_target, _caller]] remoteExecCall ["FLO_fnc_civilianDetaineeCommand", 2, false];
        },
        nil, 0, true, true, "", "alive _target && !captive _target", 5, false, "", ""
    ]] remoteExec ["addAction", 0, true];

    if (!_isProtester && {!isNil "FLO_CivilianManager"}) then {
        if (FLO_CivilianManager call ["shouldFlee", [getPosATL _unit]]) then {
            private _players = allPlayers select { alive _x };
            if ((count _players) > 0) then {
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
