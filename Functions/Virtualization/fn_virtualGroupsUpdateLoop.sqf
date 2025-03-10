/*
 * Function: FLO_fnc_virtualGroupsUpdateLoop
 * Author: Frontline Operations Development Group
 * Description:
 * Update loop for the virtualization system. Checks distances to players and activates/deactivates groups.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * None
 *
 * Example:
 * [] spawn FLO_fnc_virtualGroupsUpdateLoop;
 */

// Ensure we're running on the server
if (!isServer) exitWith {};

["VIRTUALIZATION", 3, "Starting virtual groups update loop"] call FLO_fnc_log;

// Main update loop
while {true} do {
    // Only process if the virtualization system is enabled
    if (!isNil "FLO_virtualGroups" && {FLO_virtualGroups get "_enabled"}) then {
        private _activationDistance = FLO_virtualGroups get "_activationDistance";
        private _groups = FLO_virtualGroups get "_groups";
        
        // Get all players
        private _allPlayers = allPlayers select {alive _x && side _x == west};
        
        // Process each virtual group
        {
            private _groupId = _x;
            private _groupData = _y;
            private _position = _groupData getOrDefault ["position", [0,0,0]];
            private _isActive = _groupData getOrDefault ["isActive", false];
            private _realGroup = _groupData getOrDefault ["realGroup", grpNull];
            
            // Check if any player is within activation distance
            private _shouldActivate = false;
            {
                if (_position distance _x < _activationDistance) exitWith {
                    _shouldActivate = true;
                };
            } forEach _allPlayers;
            
            // Activate or deactivate group based on distance
            if (_shouldActivate && !_isActive) then {
                [_groupId, _groupData] call FLO_fnc_activateVirtualGroup;
            } else {
                if (!_shouldActivate && _isActive) then {
                    [_groupId, _groupData] call FLO_fnc_deactivateVirtualGroup;
                };
            };
            
            // If the group is active and has a real group that's been killed, remove it from the system
            if (_isActive && !isNull _realGroup) then {
                // Check if the group has been eliminated
                if ({alive _x} count units _realGroup == 0) then {
                    // Removed dead group
                    [FLO_virtualGroups, _groupId] call (FLO_virtualGroups get "_removeGroup");
                };
            };
        } forEach _groups;
    };
    
    // Sleep for a reasonable interval - adjust as needed for performance
    sleep 5;
};

["VIRTUALIZATION", 3, "Virtual groups update loop ended"] call FLO_fnc_log; 