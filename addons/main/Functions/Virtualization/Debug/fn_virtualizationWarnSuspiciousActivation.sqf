/*
 * Function: FLO_fnc_virtualizationWarnSuspiciousActivation
 * Description:
 *   Emits a warning when a vehicle-bearing virtual group activates much closer
 *   to players than its stored virtual position suggests it should.
 */

params ["_groupId", "_groupData", "_requestedPos", "_spawnAnchorPos", "_realGroup"];

if (isNull _realGroup) exitWith { false };

private _spawnVehicles = [_realGroup] call FLO_fnc_virtualizationCollectRealGroupVehicles;
if (_spawnVehicles isEqualTo []) exitWith { false };

private _eligiblePlayers = allPlayers select { alive _x };
if (_eligiblePlayers isEqualTo []) exitWith { false };

private _requestedNearestDist = 1e10;
private _anchorNearestDist = 1e10;
private _spawnNearestDist = 1e10;
private _nearestPlayer = objNull;
private _closestSpawnVehicle = objNull;

{
    private _player = _x;
    private _requestedDist = _requestedPos distance2D _player;
    if (_requestedDist < _requestedNearestDist) then {
        _requestedNearestDist = _requestedDist;
        _nearestPlayer = _player;
    };

    private _anchorDist = _spawnAnchorPos distance2D _player;
    if (_anchorDist < _anchorNearestDist) then {
        _anchorNearestDist = _anchorDist;
    };

    {
        private _spawnDist = (getPosATL _x) distance2D _player;
        if (_spawnDist < _spawnNearestDist) then {
            _spawnNearestDist = _spawnDist;
            _closestSpawnVehicle = _x;
        };
    } forEach _spawnVehicles;
} forEach _eligiblePlayers;

private _distanceCollapse = _requestedNearestDist - _spawnNearestDist;
private _clearanceMeters = 150;
private _isSuspicious = (_spawnNearestDist < _clearanceMeters) || {_distanceCollapse > 300};
if (!_isSuspicious) exitWith { false };

private _closestSpawnPos = if (isNull _closestSpawnVehicle) then { [] } else { getPosATL _closestSpawnVehicle };
private _requestedNearestRounded = (round (_requestedNearestDist * 10)) / 10;
private _anchorNearestRounded = (round (_anchorNearestDist * 10)) / 10;
private _spawnNearestRounded = (round (_spawnNearestDist * 10)) / 10;
private _collapseRounded = (round (_distanceCollapse * 10)) / 10;
["VIRTUALIZATION", 2, format [
    "Suspicious activation %1 type=%2 requestedPos=%3 requestedNearest=%4m anchorPos=%5 anchorNearest=%6m closestSpawnPos=%7 closestSpawnNearest=%8m collapse=%9m activationDeferred=%10 missionLock=%11 activeUnits=%12/%13 nearestPlayer=%14 clearance=%15m",
    _groupId,
    _groupData get "groupType",
    _requestedPos,
    _requestedNearestRounded,
    _spawnAnchorPos,
    _anchorNearestRounded,
    _closestSpawnPos,
    _spawnNearestRounded,
    _collapseRounded,
    _groupData get "activationDeferred",
    _groupData get "missionLock",
    FLO_VirtUpdate get "activeUnitCount",
    ["activationUnitCap"] call FLO_fnc_virtualizationGetConfigValue,
    if (isNull _nearestPlayer) then { "<none>" } else { name _nearestPlayer },
    _clearanceMeters
] ] call FLO_fnc_log;

true
