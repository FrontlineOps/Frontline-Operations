/*
 * Function: FLO_fnc_gtnBuildCommanderIntelPicture
 * Author: Frontline Operations Development Group
 * Description:
 *   Normalizes the maintained GTN world-state intel picture into simple marker
 *   records for the player-facing commander common operating picture.
 *
 * Arguments:
 *   0: GTN world state <HASHMAPOBJECT>
 *
 * Return Value:
 *   HASHMAP - Normalized commander picture
 */

params [["_worldState", nil]];

if (isNil "_worldState") exitWith {
    createHashMapFromArray [
        ["enemyGroups", []],
        ["enemyConcentrations", []],
        ["friendlyGroups", []],
        ["supportMarkers", []]
    ]
};

private _sideKey = _worldState get "_sideKey";
private _enemySide = _worldState get "_enemySide";
private _enemyIntel = _worldState call ["_getEnemyIntel", []];
private _engagementPicture = _worldState call ["_getEnemyEngagementPicture", []];
private _engagementGroups = _engagementPicture get "groups";
private _freshSeconds = _worldState get "_enemyEngagementFreshSeconds";
private _enemyColor = if (_enemySide isEqualTo east) then { "ColorOPFOR" } else { "ColorBLUFOR" };

private _enemyGroupMarkers = [];
{
    private _groupId = _x;
    private _entry = _y;
    private _lastSeen = _entry get "lastSeen";
    private _age = diag_tickTime - _lastSeen;
    if (_age > _freshSeconds) then { continue };

    private _confidence = _entry get "confidence";
    if (_confidence < 0) then { _confidence = 0; };
    if (_confidence > 1) then { _confidence = 1; };

    private _freshFactor = (_freshSeconds - _age) / _freshSeconds;
    if (_freshFactor < 0) then { _freshFactor = 0; };

    private _groupType = _entry get "groupType";
    private _markerType = [_groupType, _enemySide] call FLO_fnc_gtnCommanderIntelMarkerType;
    private _size = 0.65;
    private _alpha = 0.2 + (0.7 * _freshFactor * ((_confidence max 0.35) min 1));
    private _label = switch (_groupType) do {
        case "armor": { "ENY ARM" };
        case "mechanized": { "ENY MECH" };
        case "motorized": { "ENY MOT" };
        case "mobile_aa": { "ENY ADA" };
        case "static_aa": { "ENY ADA" };
        case "artillery": { "ENY ARTY" };
        case "infantry": { "ENY INF" };
        default { "ENY" };
    };
    if (_confidence < 0.55) then {
        _markerType = if (_enemySide isEqualTo east) then { "o_unknown" } else { "b_unknown" };
        _size = 0.55;
        _label = "ENY CONTACT";
    };

    _enemyGroupMarkers pushBack [
        format ["FLO_GTN_INTEL_%1_GRP_%2", _sideKey, _groupId],
        _entry get "position",
        _markerType,
        [_size, _size],
        _alpha,
        _label,
        _enemyColor
    ];
} forEach _engagementGroups;

private _enemyConcentrationMarkers = [];
private _concentrationFreshSeconds = _freshSeconds * 2;
{
    private _lastSeen = _x get "lastSeen";
    private _age = diag_tickTime - _lastSeen;
    if (_age > _concentrationFreshSeconds) then { continue };

    private _freshFactor = (_concentrationFreshSeconds - _age) / _concentrationFreshSeconds;
    if (_freshFactor < 0) then { _freshFactor = 0; };

    private _strength = _x get "strength";
    private _radius = 150 + ((_strength min 12) * 25);
    if (_radius > 450) then { _radius = 450; };

    _enemyConcentrationMarkers pushBack [
        format ["FLO_GTN_INTEL_%1_CON_%2", _sideKey, _forEachIndex],
        _x get "position",
        [_radius, _radius],
        0.1 + (0.15 * _freshFactor),
        if (_strength >= 8) then { "ENY FORCE" } else { "" },
        _enemyColor
    ];
} forEach (_enemyIntel get "concentrations");

private _supportMarkers = [_worldState] call FLO_fnc_gtnBuildFriendlySupportMarkers;
_supportMarkers append ([_worldState] call FLO_fnc_gtnBuildFriendlySupplyNodeMarkers);

createHashMapFromArray [
    ["enemyGroups", _enemyGroupMarkers],
    ["enemyConcentrations", _enemyConcentrationMarkers],
    ["friendlyGroups", [_worldState] call FLO_fnc_gtnBuildFriendlyCommanderGroupMarkers],
    ["supportMarkers", _supportMarkers]
]
