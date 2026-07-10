/*
 * Function: FLO_fnc_campaignUpdateDefenderIntel
 * Description:
 *   Promotes coarse PREPARE intelligence to the exact target when the
 *   defender's maintained GTN picture confirms contact on the approach.
 */

params ["_director"];

private _state = _director get "_state";
if ((_state get "phase") != "PREPARE") exitWith { false };
if ((_state get "defenderIntelLevel") != "SECTOR") exitWith { false };

private _objective = FLO_Objectives get (_state get "objectiveId");
if ((_objective get "underAttack") || {_objective get "contested"}) exitWith {
    [_director, "OBJECTIVE_CONTACT"] call FLO_fnc_campaignRevealTarget
};

private _defenderSide = [_state get "defenderSideKey"] call FLO_fnc_campaignSideFromKey;
private _manager = _director get "_resourceManager";
private _commander = _manager call ["_getCommanderBySide", [_defenderSide]];
if (isNil "_commander") then {
    throw format ["FLO_fnc_campaignUpdateDefenderIntel: no commander for %1", _defenderSide];
};

private _worldState = _commander get "_worldState";
private _contactReports = (_worldState call ["_getEnemyIntel", []]) get "contactReports";
private _sector = [_director] call FLO_fnc_campaignBuildThreatSector;
private _contactAfter = _director get "_intelContactAfter";
private _freshSeconds = (_director get "_config") get "operationIntelContactFreshSeconds";
private _now = diag_tickTime;
private _confirmed = false;

{
    _x params ["_contactPosition", "_contactTime"];
    if (_contactTime < _contactAfter) then { continue };
    if ((_now - _contactTime) > _freshSeconds) then { continue };
    if (_contactPosition inArea [
        _sector get "position",
        _sector get "longAxis",
        _sector get "shortAxis",
        _sector get "direction",
        false
    ]) exitWith {
        _confirmed = true;
    };
} forEach _contactReports;

if (!_confirmed) exitWith { false };
[_director, "CONFIRMED_APPROACH_CONTACT"] call FLO_fnc_campaignRevealTarget
