/* Clears FLO-owned physical building-garrison state from one live group. */
params [["_group", grpNull, [grpNull]]];

if (isNull _group) exitWith { true };
if !(local _group) then {
    ["VIRTUALIZATION", 1, format ["Cannot release non-local physical garrison %1", _group]] call FLO_fnc_log;
    throw format ["FLO_fnc_taskReleaseGarrison: group %1 is not local", _group];
};

{
    if (
        (_x getVariable ["FLO_garrisonEventHandlers", []]) isNotEqualTo []
        || {(_x getVariable ["FLO_garrisonPosition", []]) isNotEqualTo []}
    ) then {
        [_x, true] call FLO_fnc_taskReleaseGarrisonUnit;
    };
} forEach units _group;

_group setVariable ["FLO_buildingGarrisonAttempted", nil];
_group setVariable ["FLO_buildingGarrisonAnchor", nil];
_group setVariable ["FLO_buildingGarrisonAssigned", nil];

true
