/*
 * Function: FLO_fnc_civilianRunProtestBehavior
 * Author: Frontline Operations Development Group
 * Description:
 *   Runs bounded protest behavior for one active civilian unit until the
 *   protest expires.
 *
 * Arguments:
 * 0: Civilian unit <OBJECT>
 *
 * Return Value:
 * None
 */

params [["_unit", objNull, [objNull]]];
if (isNull _unit || {!alive _unit}) exitWith {};

private _protestAnims = [
    "Acts_Excited_Loop",
    "Acts_CivilListening_1",
    "Acts_CivilTalking_1",
    "Acts_CivilTalking_2",
    "Acts_Ambient_Aggressive"
];
private _throwables = [
    "Land_Stone_sharp_F",
    "Land_Stone_small_F",
    "Land_BottlePlastic_V1_F",
    "Land_BottlePlastic_V2_F"
];

while {alive _unit && {_unit getVariable ["FLO_isProtester", false]}} do {
    private _expiresAt = _unit getVariable ["FLO_ProtestExpiresAt", -1];
    private _target = _unit getVariable ["FLO_ProtestTarget", objNull];
    if (_expiresAt < 0 || {diag_tickTime >= _expiresAt} || {isNull _target} || {!alive _target}) exitWith {};

    detach _unit;
    _unit enableAI "PATH";
    _unit enableAI "MOVE";
    _unit setBehaviour "CARELESS";
    _unit setSpeedMode "NORMAL";

    private _targetPos = getPosATL _target;
    private _distance = _unit distance2D _target;

    if (_distance > 12) then {
        private _gatherPos = _targetPos getPos [6 + random 10, random 360];
        _gatherPos set [2, 0];
        _unit doMove _gatherPos;
    } else {
        _unit doStop _unit;
        _unit setDir (_unit getDir _target);

        private _lastAnimAt = _unit getVariable ["FLO_ProtestLastAnimAt", -1];
        if ((_lastAnimAt + 4) < diag_tickTime) then {
            _unit setVariable ["FLO_ProtestLastAnimAt", diag_tickTime, false];
            _unit playMove (selectRandom _protestAnims);
        };

        private _lastThrowAt = _unit getVariable ["FLO_ProtestLastThrowAt", -1];
        if ((_lastThrowAt + 8) < diag_tickTime && {_distance < 35} && {(random 1) < (FLO_CivilianConfig get "PROTEST_THROW_CHANCE")}) then {
            private _throwDir = _unit getDir _target;
            private _proj = createVehicle [selectRandom _throwables, (getPosATL _unit) vectorAdd [0, 0, 1.5], [], 0, "CAN_COLLIDE"];
            _proj setVelocity [
                (sin _throwDir) * (7 + random 2),
                (cos _throwDir) * (7 + random 2),
                3 + random 2
            ];
            _unit setVariable ["FLO_ProtestLastThrowAt", diag_tickTime, false];
            _unit playMove "Acts_Ambient_Aggressive";

            [_proj] spawn {
                params ["_obj"];
                sleep 10;
                if (!isNull _obj) then { deleteVehicle _obj };
            };
        };
    };

    sleep 2;
};

_unit setVariable ["FLO_isProtester", false, true];
_unit setVariable ["FLO_ProtestTarget", objNull, false];
_unit setVariable ["FLO_ProtestExpiresAt", -1, false];
_unit setVariable ["FLO_ProtestLastAnimAt", -1, false];
_unit switchMove "";
_unit enableAI "PATH";
_unit enableAI "MOVE";
_unit setBehaviour "SAFE";
_unit setSpeedMode "LIMITED";
_unit setVariable ["FLO_ProtestWorkerRunning", false, false];

if (!captive _unit) then {
    [[_unit]] call FLO_fnc_civilianActions;
};
