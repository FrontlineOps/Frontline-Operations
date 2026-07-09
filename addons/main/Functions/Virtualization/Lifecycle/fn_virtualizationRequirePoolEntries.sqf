/*
 * Function: FLO_fnc_virtualizationRequirePoolEntries
 */

params ["_entries", "_poolName", "_sideKey", "_groupType"];

if (_entries isEqualTo []) then {
    throw format ["[VIRTUALIZATION] Missing %1 pool for %2 on side %3", _poolName, _groupType, _sideKey];
};

_entries
