/*
 * Function: FLO_fnc_minefieldObjectiveHasNearbyPlayer
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks whether an objective has an alive active-side player close enough
 *   to allow GTN minefield construction.
 *
 * Arguments:
 * 0: Objective ID <STRING>
 * 1: Player side <SIDE>
 * 2: Radius in meters <NUMBER> - Default derives from virtualization activation distance plus minefield buffer
 * 3: Cached player positions <ARRAY> - Optional
 *
 * Return Value:
 * BOOL
 */

params [
    ["_objectiveId", ""],
    ["_playerSide", sideUnknown],
    ["_radius", -1],
    ["_playerPositions", []]
];

if (_objectiveId == "" || {!(_playerSide in [east, west])}) exitWith { false };
if (_playerPositions isEqualTo []) then {
    {
        if (alive _x && {(side group _x) isEqualTo _playerSide}) then {
            _playerPositions pushBack (getPosATL _x);
        };
    } forEach ([] call FLO_fnc_getConnectedHumanPlayers);
};
if (_playerPositions isEqualTo []) exitWith { false };

private _objective = FLO_Objectives get _objectiveId;
private _objectivePos = _objective get "position";
private _nearRadius = if (_radius >= 0) then {
    _radius
} else {
    (["activationDistance"] call FLO_fnc_virtualizationGetConfigValue) + (FLO_MinefieldConfig get "playerProximityActivationBufferMeters")
};

({_objectivePos distance2D _x <= _nearRadius} count _playerPositions) > 0
