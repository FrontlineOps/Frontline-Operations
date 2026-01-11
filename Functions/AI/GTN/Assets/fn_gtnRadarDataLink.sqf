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

["RADAR", 3, "Radar data link system starting"] call FLO_fnc_log;

// Track active radars
private _updateInterval = 30; // seconds

while {true} do {
    sleep _updateInterval;
    
    // Find all active static_aa groups (which include radars)
    private _activeRadars = [];
    {
        private _groupData = FLO_virtualGroups get "_groups" getOrDefault [_x, nil];
        if (!isNil "_groupData") then {
            if ((_groupData get "groupType") == "static_aa" && {_groupData getOrDefault ["alwaysActive", false]}) then {
                _activeRadars pushBack (_groupData get "position");
            };
        };
    } forEach (keys (FLO_virtualGroups get "_groups"));
    
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
    
    // Reveal detected aircraft to all OPFOR groups
    {
        private _aircraft = _x;
        {
            if (side _x == east) then {
                _x reveal [_aircraft, 4]; // Maximum knowledge
            };
        } forEach allGroups;
    } forEach _detectedAircraft;
    
    ["RADAR", 4, format["Data link: %1 radars detected %2 aircraft", count _activeRadars, count _detectedAircraft]] call FLO_fnc_log;
};
