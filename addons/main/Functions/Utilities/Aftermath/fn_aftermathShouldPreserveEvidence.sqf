/*
 * Function: FLO_fnc_aftermathShouldPreserveEvidence
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks whether any dead evidence entities are close enough to players that
 *   they should be preserved instead of being deleted during virtualization.
 *
 * Arguments:
 * 0: Entities <ARRAY>
 *
 * Return Value:
 * BOOL - True when dead evidence should be preserved
 */

params [["_entities", [], [[]]]];

if (!isServer) exitWith { false };
if (_entities isEqualTo []) exitWith { false };

private _playerPositions = (allPlayers select { alive _x }) apply { getPosATL _x };
if (_playerPositions isEqualTo []) exitWith { false };

private _playerEvidenceRadius = FLO_AftermathCleanup get "playerEvidenceRadius";
private _preserveEvidence = false;

{
    if (isNull _x) then { continue };
    if (alive _x) then { continue };

    private _entityPos = getPosATL _x;
    if ((_playerPositions findIf { _entityPos distance2D _x <= _playerEvidenceRadius }) > -1) exitWith {
        _preserveEvidence = true;
    };
} forEach _entities;

_preserveEvidence
