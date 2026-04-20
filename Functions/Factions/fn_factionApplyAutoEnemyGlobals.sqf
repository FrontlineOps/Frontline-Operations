/*
 * Function: FLO_fnc_factionApplyAutoEnemyGlobals
 * Author: Frontline Operations Development Group
 * Description:
 *   Applies an auto-generated military catalog to the legacy enemy globals.
 *
 * Arguments:
 *   0: Auto military catalog <HASHMAP>
 *
 * Return Value:
 *   BOOL
 */

params [["_catalog", createHashMap, [createHashMap]]];

East_Ground_Infantry = (_catalog get "groundInfantryGroups") + (_catalog get "groundInfantryUnits");
East_Ground_SpecOps = (_catalog get "groundSpecOpsGroups") + (_catalog get "groundSpecOpsUnits");
East_Ground_Motorized = _catalog get "groundMotorized";
East_Ground_Mechanized = _catalog get "groundMechanized";
East_Ground_Armor = _catalog get "groundArmor";
East_Ground_Transport = _catalog get "groundTransport";
East_Ground_Artillery = _catalog get "groundArtillery";
East_Air_Heli = _catalog get "airHeli";
East_Air_Jet = _catalog get "airJet";
East_Air_Transport = _catalog get "airTransport";
East_Air_Drone = _catalog get "airDrone";
East_Ground_Drone = _catalog get "groundDrone";
East_Mobile_AA = _catalog get "mobileAA";
East_Static_AA = _catalog get "staticAA";
East_Boat = _catalog get "boat";
East_Radar = _catalog get "radar";
East_FireObserver = _catalog get "officers";
East_Transport_Reserve_Ground_Count = _catalog get "transportReserveGroundCount";
East_Transport_Reserve_Air_Count = _catalog get "transportReserveAirCount";
East_Objective_Group_Type_Caps = _catalog get "objectiveGroupTypeCaps";
OPFOR_Objective_Groups = _catalog get "objectiveGroups";
OPFOR_Group_Counts = _catalog get "groupCounts";

true
