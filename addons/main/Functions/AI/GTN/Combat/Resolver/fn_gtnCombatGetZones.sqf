/*
 * Function: FLO_fnc_gtnCombatGetZones
 * Author: Frontline Operations Development Group
 * Description:
 *   Returns cached combat engagement zones for the current classification,
 *   rebuilding them only when the combat classification changed.
 *
 * Arguments:
 *   0: Combat classification <HASHMAP>
 *
 * Return Value:
 *   Engagement zones <ARRAY>
 */

params ["_classification"];

private _state = call FLO_fnc_gtnCombatGetState;
private _zones = _state get "zones";
private _classificationBuiltAt = _state get "classificationBuiltAt";
private _seedCellSize = _classification get "seedCellSize";
private _engagementDist = _classification get "engagementDist";

if (
    _zones isEqualTo []
    || {_classificationBuiltAt != (_state get "zonesClassificationBuiltAt")}
    || {_seedCellSize != (_state get "zonesSeedCellSize")}
    || {_engagementDist != (_state get "zonesEngagementDist")}
) then {
    private _seedSide = _classification get "seedSide";
    private _seedGroupsByCell = if (_seedSide isEqualTo east) then {
        _classification get "eastGroupsByCell"
    } else {
        _classification get "westGroupsByCell"
    };
    private _opponentGroupsByCell = if (_seedSide isEqualTo east) then {
        _classification get "westGroupsByCell"
    } else {
        _classification get "eastGroupsByCell"
    };
    private _opponentThreatCells = if (_seedSide isEqualTo east) then {
        _classification get "westThreatCells"
    } else {
        _classification get "eastThreatCells"
    };

    _zones = [
        _classification get "combatGroups",
        _classification get "seedIds",
        _seedSide,
        _classification get "opponentSide",
        _engagementDist,
        _seedCellSize,
        _opponentThreatCells,
        _seedGroupsByCell,
        _opponentGroupsByCell,
        _classification get "cellKeyBase",
        _classification get "cellKeyStride"
    ] call FLO_fnc_gtnCombatCollectEngagementZones;

    _state set ["zones", _zones];
    _state set ["zonesBuiltAt", diag_tickTime];
    _state set ["zonesClassificationBuiltAt", _classificationBuiltAt];
    _state set ["zonesSeedCellSize", _seedCellSize];
    _state set ["zonesEngagementDist", _engagementDist];
};

_zones
