/*
 * Function: FLO_fnc_virtualizationRequirePoolEntries
 */

params ["_entries", "_poolName", "_sideKey", "_groupType"];

if (count _entries == 0) then {
    diag_log format ["[VIRTUALIZATION][WARN] Missing %1 pool for %2 on side %3. Using fallback defaults.", _poolName, _groupType, _sideKey];
};

_entries
