/*
 * Function: FLO_fnc_gtnBuildFriendlyCommanderGroupMarkers
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the friendly force layer for the commander COP from the maintained
 *   virtualization registry.
 *
 * Arguments:
 *   0: GTN world state <HASHMAPOBJECT>
 *
 * Return Value:
 *   ARRAY - Marker records
 */

params [["_worldState", nil]];

if (isNil "_worldState" || {isNil "FLO_virtualGroups"}) exitWith { [] };

private _groups = FLO_virtualGroups get "_groups";
private _ownSide = _worldState get "_ownSide";
private _sideKey = _worldState get "_sideKey";
private _friendlyColor = if (_ownSide isEqualTo east) then { "ColorOPFOR" } else { "ColorBLUFOR" };
private _markers = [];

{
    private _groupId = _x;
    private _groupData = _y;

    if ((_groupData get "side") != _ownSide) then { continue };
    if ((_groupData get "unitCount") <= 0) then { continue };
    if ((_groupData get "mountedIn") != "") then { continue };
    if ((_groupData get "attachedTo") != "") then { continue };

    private _groupType = _groupData get "groupType";
    if (_groupType in ["civilian", "civ_pedestrian", "civ_building", "civilianVehicle", "civ_car"]) then { continue };

    private _isActive = _groupData get "isActive";
    private _inCombat = _groupData get "inCombat";
    private _engagementActive = _groupData get "engagementActive";
    private _missionLock = _groupData get "missionLock";
    private _position = _groupData get "position";
    private _markerType = [_groupType, _ownSide] call FLO_fnc_gtnCommanderIntelMarkerType;
    private _precision = if (_isActive || {_inCombat} || {_engagementActive} || {_missionLock in ["ARTILLERY", "AIR"]}) then {
        0
    } else {
        switch (_groupType) do {
            case "artillery": { 90 };
            case "armor": { 110 };
            case "mechanized": { 120 };
            case "motorized": { 130 };
            case "mobile_aa";
            case "static_aa": { 100 };
            default { 160 };
        }
    };

    private _markerPos = if (_precision > 0) then {
        [_position, _groupId, _precision] call FLO_fnc_gtnApproximateCommanderMarkerPosition
    } else {
        _position
    };

    private _alpha = if (_precision > 0) then { 0.42 } else { 0.7 };
    if (_missionLock == "ARTILLERY") then {
        _alpha = 0.78;
    };
    if (_inCombat || {_engagementActive}) then {
        _alpha = 0.82;
    };

    private _label = switch (true) do {
        case (_groupType == "artillery"): { "ARTY" };
        case (_missionLock == "AIR"): { "AIR" };
        case (_inCombat || {_engagementActive}): { "ENG" };
        default { "" };
    };

    _markers pushBack [
        format ["FLO_GTN_INTEL_%1_FRIENDLY_%2", _sideKey, _groupId],
        _markerPos,
        _markerType,
        [0.5, 0.5],
        _alpha,
        _label,
        _friendlyColor
    ];
} forEach _groups;

_markers
