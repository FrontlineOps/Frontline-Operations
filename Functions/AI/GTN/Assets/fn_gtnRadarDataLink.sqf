/*
 * Function: FLO_fnc_gtnRadarDataLink
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-side radar data link system.
 *   Detects enemy aircraft and reveals them to active friendly groups on both
 *   main sides when they are under radar coverage.
 *   Should be spawned once on server init.
 *
 * Arguments: None
 *
 * Returns: Nothing
 */

if (!isServer) exitWith {};
if (!isNil "FLO_GTN_RadarDataLinkRunning" && {FLO_GTN_RadarDataLinkRunning}) exitWith {};
FLO_GTN_RadarDataLinkRunning = true;
publicVariable "FLO_GTN_RadarDataLinkRunning";

["RADAR", 3, "Radar data link system starting"] call FLO_fnc_log;

// Track active radars
private _updateInterval = 30; // seconds

while {FLO_GTN_RadarDataLinkRunning} do {
    sleep _updateInterval;

    if (isNil "FLO_virtualGroups") then { continue };
    
    // Build active radar coverage by side.
    private _activeRadarsBySide = createHashMapFromArray [
        ["EAST", []],
        ["WEST", []]
    ];
    private _groups = FLO_virtualGroups get "_groups";
    {
        private _groupData = _y;
        private _groupType = _groupData get "groupType";
        if !(_groupType in ["static_aa", "radar", "mobile_aa"]) then { continue };
        if !((_groupData get "alwaysActive") || { _groupData get "isActive" }) then { continue };

        private _sideKey = if ((_groupData get "side") isEqualTo west) then { "WEST" } else { "EAST" };
        private _radars = _activeRadarsBySide get _sideKey;
        _radars pushBack (_groupData get "position");
        _activeRadarsBySide set [_sideKey, _radars];
    } forEach _groups;

    {
        private _friendlySide = if (_x == "WEST") then { west } else { east };
        private _enemySide = if (_friendlySide isEqualTo west) then { east } else { west };
        private _radars = _y;
        if (count _radars == 0) then { continue };

        private _detectedAircraft = [];
        {
            private _radarPos = _x;
            private _aircraft = _radarPos nearEntities [["Air"], 50000];
            {
                if (alive _x && {side _x == _enemySide}) then {
                    _detectedAircraft pushBackUnique _x;
                };
            } forEach _aircraft;
        } forEach _radars;

        if (count _detectedAircraft == 0) then { continue };

        private _friendlyLeaders = [];
        {
            private _gData = _y;
            if ((_gData get "side") != _friendlySide) then { continue };
            if !(_gData get "isActive") then { continue };
            private _realGroup = _gData get "realGroup";
            if (isNull _realGroup) then { continue };
            private _leader = leader _realGroup;
            if (isNull _leader || {!alive _leader}) then { continue };
            _friendlyLeaders pushBackUnique _leader;
        } forEach _groups;

        if (count _friendlyLeaders == 0) then { continue };

        {
            private _aircraft = _x;
            {
                _x reveal [_aircraft, 1];
            } forEach _friendlyLeaders;
        } forEach _detectedAircraft;

        ["RADAR", 4, format["Data link %1: %2 radars detected %3 aircraft", _x, count _radars, count _detectedAircraft]] call FLO_fnc_log;
    } forEach _activeRadarsBySide;
};
