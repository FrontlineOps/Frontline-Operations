/* Reveals individual PREPARE targets from maintained defender contacts. */
params ["_director"];

private _state = _director get "_state";
private _operations = _state get "operations";
private _defenderSide = [_state get "defenderSideKey"] call FLO_fnc_campaignSideFromKey;
private _manager = _director get "_resourceManager";
private _commander = _manager call ["_getCommanderBySide", [_defenderSide]];
if (isNil "_commander") then {
    throw format ["FLO_fnc_campaignUpdateDefenderIntel: no commander for %1", _defenderSide];
};

private _worldState = _commander get "_worldState";
private _contactReports = (_worldState call ["_getEnemyIntel", []]) get "contactReports";
private _freshSeconds = (_director get "_config") get "operationIntelContactFreshSeconds";
private _now = diag_tickTime;
private _revealedCount = 0;

{
    private _operationId = _x;
    private _operation = _operations get _operationId;
    if ((_operation get "phase") != "PREPARE") then { continue };
    if ((_operation get "defenderIntelLevel") != "SECTOR") then { continue };

    private _objective = FLO_Objectives get (_operation get "objectiveId");
    if ((_objective get "underAttack") || {_objective get "contested"}) then {
        if ([_director, _operationId, "OBJECTIVE_CONTACT"] call FLO_fnc_campaignRevealTarget) then {
            _revealedCount = _revealedCount + 1;
        };
        continue;
    };

    private _sector = [_director, _operationId] call FLO_fnc_campaignBuildThreatSector;
    private _contactAfter = _operation get "intelContactAfter";
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

    if (_confirmed && {[_director, _operationId, "CONFIRMED_APPROACH_CONTACT"] call FLO_fnc_campaignRevealTarget}) then {
        _revealedCount = _revealedCount + 1;
    };
} forEach (_state get "operationOrder");
_revealedCount
