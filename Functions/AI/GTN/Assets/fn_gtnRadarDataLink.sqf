/*
 * Function: FLO_fnc_gtnRadarDataLink
 * Author: Frontline Operations Development Group
 * Description:
 *   Server-side radar data link system.
 *   Detects enemy aircraft and reveals them to all OPFOR groups.
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
    
    // Find all active static_aa groups (which include radars)
    private _activeRadars = [];
    private _groups = FLO_virtualGroups get "_groups";
    {
        private _groupData = _y;
        if ((_groupData get "groupType") == "static_aa" && {_groupData getOrDefault ["alwaysActive", false]}) then {
            _activeRadars pushBack (_groupData get "position");
        };
    } forEach _groups;
    
    if (count _activeRadars == 0) then { continue; };
    
    // Detect aircraft within radar range (50km per radar)
    private _detectedAircraft = [];
    {
        private _radarPos = _x;
        private _aircraft = _radarPos nearEntities [["Air"], 50000];
        {
            if (side _x == west && {alive _x}) then {
                _detectedAircraft pushBackUnique _x;
            };
        } forEach _aircraft;
    } forEach _activeRadars;
    
    if (count _detectedAircraft == 0) then { continue; };

    private _eastLeaders = [];
    {
        private _gData = _y;
        if ((_gData get "side") != east) then { continue };
        if !(_gData get "isActive") then { continue };
        private _realGroup = _gData get "realGroup";
        if (isNull _realGroup) then { continue };
        private _leader = leader _realGroup;
        if (isNull _leader || {!alive _leader}) then { continue };
        _eastLeaders pushBackUnique _leader;
    } forEach _groups;

    if (count _eastLeaders == 0) then { continue };
    
    // Reveal detected aircraft to active OPFOR leaders
    {
        private _aircraft = _x;
        {
            _x reveal [_aircraft, 1];
        } forEach _eastLeaders;
    } forEach _detectedAircraft;
    
    ["RADAR", 4, format["Data link: %1 radars detected %2 aircraft", count _activeRadars, count _detectedAircraft]] call FLO_fnc_log;
};
