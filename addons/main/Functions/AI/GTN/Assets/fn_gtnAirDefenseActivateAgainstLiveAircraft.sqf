/* Activates virtual AA groups that can physically engage one live aircraft. */
params [
    ["_aircraft", objNull, [objNull]],
    ["_airSide", sideUnknown],
    ["_groups", createHashMap, [createHashMap]],
    ["_contactIndex", createHashMap, [createHashMap]],
    ["_aircraftObserved", false, [true]]
];

if (isNull _aircraft || {!alive _aircraft}) exitWith { 0 };
if !(_airSide in [east, west]) exitWith { 0 };

private _state = call FLO_fnc_gtnAirDefenseGetState;
private _airPos = getPosATL _aircraft;
private _enemySide = [east, west] select (_airSide isEqualTo east);
private _enemySideKey = [_enemySide] call FLO_fnc_sideKey;
private _aaGroupIds = (_contactIndex get "aaGroupIdsBySide") get _enemySideKey;
private _activated = 0;

{
    private _aaId = _x;
    private _aaData = _groups get _aaId;
    private _aaType = _aaData get "groupType";

    private _engagementRange = [_state get "mobileEngagementRange", _state get "staticEngagementRange"] select (_aaType == "static_aa");
    if (((_aaData get "position") distance2D _airPos) > _engagementRange) then { continue };
    if (
        !_aircraftObserved
        && {!([[_airPos], _aaData get "position"] call FLO_fnc_gtnAirDefenseIsObservedEngagement)}
    ) then { continue };

    private _lock = _aaData get "missionLock";
    if (_lock != "" && {_lock != "AIR_DEFENSE"}) then { continue };

    if !(_aaData get "isActive") then {
        if !([_aaId] call FLO_fnc_virtualizationForceActivateGroup) then {
            ["GTN Air Defense", 2, format ["Unable to activate AA group %1 against live aircraft", _aaId]] call FLO_fnc_log;
            continue;
        };
        _activated = _activated + 1;
    };

    [_aaData, "AIR_DEFENSE", "LIVE_CONTACT"] call FLO_fnc_virtualizationSetMissionLock;
    (_state get "lastLiveContactAt") set [_aaId, diag_tickTime];

    private _realGroup = _aaData get "realGroup";
    if (!isNull _realGroup) then {
        { _x reveal [_aircraft, 4] } forEach units _realGroup;
    };
} forEach _aaGroupIds;

_activated
