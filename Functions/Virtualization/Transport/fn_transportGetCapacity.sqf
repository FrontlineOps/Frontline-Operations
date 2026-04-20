/*
 * Function: FLO_fnc_transportGetCapacity
 * Author: Frontline Operations Development Group
 * Description:
 *   Get cargo capacity for a vehicle class or group type.
 *   Uses config transportSoldier when available, falls back to estimates.
 *
 * Arguments:
 *   0: Vehicle class or group type <STRING>
 *
 * Return Value:
 *   Capacity <NUMBER>
 *
 * Example:
 *   ["O_APC_Wheeled_02_rcws_v2_F"] call FLO_fnc_transportGetCapacity; // Returns 8
 *   ["motorized"] call FLO_fnc_transportGetCapacity; // Returns 8
 */

params [["_classOrType", "", [""]]];

if (_classOrType == "") exitWith { 0 };

// Try config lookup first (if capacity > 0)
private _cfg = configFile >> "CfgVehicles" >> _classOrType;
if (isClass _cfg) then {
    private _cfgCap = getNumber (_cfg >> "transportSoldier");
    if (_cfgCap > 0) exitWith { _cfgCap };
};

// Falls back to discovered estimates or type-based defaults
if (_classOrType in FLO_Transport_CapacityEstimates) exitWith {
    FLO_Transport_CapacityEstimates get _classOrType
};

// Final safety default
diag_log format ["[TRANSPORT][WARN] Missing capacity estimate for %1 - Using default (4)", _classOrType];
4
