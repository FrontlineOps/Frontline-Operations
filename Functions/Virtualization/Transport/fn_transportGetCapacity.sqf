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

// Try config lookup first
private _cfg = configFile >> "CfgVehicles" >> _classOrType;
if (isClass _cfg) exitWith {
    getNumber (_cfg >> "transportSoldier")
};

if !(_classOrType in FLO_Transport_CapacityEstimates) then {
    throw format ["[TRANSPORT] Missing capacity estimate for %1", _classOrType];
};

FLO_Transport_CapacityEstimates get _classOrType
