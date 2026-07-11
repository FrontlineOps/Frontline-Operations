/*
 * Function: FLO_fnc_vehicleCleanupBuildContext
 * Author: Frontline Operations Development Group
 * Description:
 *   Builds the shared context used by live vehicle cleanup discovery and
 *   candidate rechecks.
 *
 * Arguments:
 * None
 *
 * Return Value:
 * HASHMAP - Cleanup context
 */

private _trackedVehicleKeys = createHashMap;
if (!isNil "FLO_VirtualForceRegistry" && {FLO_VirtualForceRegistry isEqualType createHashMap}) then {
    {
        private _groupData = _y;
        {
            if (!isNull _x) then {
                _trackedVehicleKeys set [str _x, true];
            };
        } forEach (_groupData get "realVehicles");

        private _realGroup = _groupData get "realGroup";
        if (!isNull _realGroup) then {
            {
                private _veh = vehicle _x;
                if (_veh == _x) then {
                    _veh = assignedVehicle _x;
                };

                if (!isNull _veh) then {
                    _trackedVehicleKeys set [str _veh, true];
                };
            } forEach units _realGroup;
        };
    } forEach (call FLO_fnc_virtualizationGetGroupMap);
};

createHashMapFromArray [
    ["trackedVehicleKeys", _trackedVehicleKeys],
    ["playerPositions", call FLO_fnc_aftermathGetPlayerPositions],
    ["installationPositions", (allMapMarkers select { markerType _x == "b_installation" }) apply { getMarkerPos _x }],
    ["playerSafeRadius", FLO_AftermathCleanup get "playerEvidenceRadius"],
    ["installationSafeRadius", FLO_VehicleCleanup get "installationSafeRadius"]
]
