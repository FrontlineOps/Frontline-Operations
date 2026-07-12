/* Normalizes idle combat aircraft into side-owned off-map reserves. */
if (!isServer) exitWith { 0 };

private _groups = call FLO_fnc_virtualizationGetGroupMap;
private _parked = 0;
{
    private _groupId = _x;
    private _groupData = _y;
    if !((_groupData get "groupType") in ["helicopter", "air", "jet"]) then { continue };
    if (_groupData get "transportRole") then { continue };
    if (_groupData get "isActive") then { continue };
    if ((_groupData get "missionLock") != "") then { continue };
    if ((_groupData get "replacementState") != "") then { continue };

    if ([_groupId] call FLO_fnc_gtnAirParkCombatGroupOffMap) then {
        _parked = _parked + 1;
    };
} forEach _groups;

["GTN Air", 3, format ["Parked %1 idle combat-air groups in off-map reserves", _parked]] call FLO_fnc_log;
_parked
