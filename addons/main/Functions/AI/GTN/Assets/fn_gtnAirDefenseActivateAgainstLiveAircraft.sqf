/* Activates virtual AA groups that can physically engage one live aircraft. */
params [
    ["_aircraft", objNull, [objNull]],
    ["_airSide", sideUnknown]
];

if (isNull _aircraft || {!alive _aircraft}) exitWith { 0 };
if !(_airSide in [east, west]) exitWith { 0 };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _state = call FLO_fnc_gtnAirDefenseGetState;
private _airPos = getPosATL _aircraft;
private _enemySide = [east, west] select (_airSide isEqualTo east);
private _activated = 0;

{
    private _aaId = _x;
    private _aaData = _y;
    private _aaType = _aaData get "groupType";
    if !(_aaType in ["static_aa", "mobile_aa"]) then { continue };
    if ((_aaData get "side") isNotEqualTo _enemySide) then { continue };
    if ((_aaData get "unitCount") <= 0) then { continue };
    if ((_aaData get "replacementState") != "") then { continue };

    private _engagementRange = [_state get "mobileEngagementRange", _state get "staticEngagementRange"] select (_aaType == "static_aa");
    if (((_aaData get "position") distance2D _airPos) > _engagementRange) then { continue };

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
} forEach _groups;

_activated
