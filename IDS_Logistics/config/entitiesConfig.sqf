/**
 * @name IDS_Logistics_EntitiesConfig
 * @category Logistics_Configuration
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Defines all buildable entities available in the logistics system.
 * This configuration file serves as the master database of all entities
 * that players can place in the game world, organized by category.
 * Display names are pulled directly from the object configs.
 */

/**
 * Master array of all buildable entities
 * Format: [Class Name, Category, Cost]
 * 
 * Categories should match those defined in categoryConfig.sqf
 * Cost represents the resource points required to build the entity
 * Display names are retrieved from object configs
 */
IDS_Logistics_Entities = [
    //------------------------------------------
    // Fortification
    //------------------------------------------
    ["Land_HBarrier_3_F", "Fortification", 5],
    ["Land_HBarrier_5_F", "Fortification", 8],
    ["Land_HBarrier_Big_F", "Fortification", 10],
    ["Land_HBarrierWall4_F", "Fortification", 15],
    ["Land_HBarrierWall6_F", "Fortification", 20],
    ["Land_HBarrierTower_F", "Fortification", 25],
    ["Land_BagBunker_Tower_F", "Fortification", 25],
    ["Land_Cargo_Patrol_V1_F", "Fortification", 20],
    ["Land_BagBunker_Small_F", "Fortification", 10],
    ["Land_BagBunker_Large_F", "Fortification", 20],
    ["Land_Razorwire_F", "Fortification", 5],
    
    //------------------------------------------
    // Structures
    //------------------------------------------
    ["Land_Cargo_House_V1_F", "Structures", 15],
    ["Land_Cargo_HQ_V1_F", "Structures", 30],
    ["Land_Medevac_house_V1_F", "Structures", 25],
    ["Land_Cargo_Tower_V1_F", "Structures", 30],
    
    //------------------------------------------
    // Logistics
    //------------------------------------------
    ["StorageBladder_01_fuel_forest_F", "Logistics", 15],
    ["Land_PlasticCase_01_medium_F", "Logistics", 5],
    ["Land_PlasticCase_01_large_F", "Logistics", 8],
	["B_SupplyCrate_f", "Logistics", 10],
	["C_SupplyCrate_f", "Logistics", 10],
	["Box_East_Ammoord_f", "Logistics", 2],
	["Box_East_Ammoveh_f", "Logistics", 15],
	["Box_East_Ammo_f", "Logistics", 2],
	["Box_East_Grenades_f", "Logistics", 2],
	["Box_East_Support_f", "Logistics", 2],
	["Box_East_Wpslaunch_f", "Logistics", 2],
	["Box_East_Wps_f", "Logistics", 3],
	["IG_SupplyCrate_f", "Logistics", 10],
	["Box_Ind_Ammoord_f", "Logistics", 2],
	["Box_Ind_Ammoveh_f", "Logistics", 15],
	["Box_Ind_Ammo_f", "Logistics", 2],
	["Box_Ind_Grenades_f", "Logistics", 2],
	["Box_Ind_Support_f", "Logistics", 2],
	["Box_Ind_Wpslaunch_f", "Logistics", 2],
	["Box_Ind_Wps_f", "Logistics", 3],
	["Box_NATO_Ammoord_f", "Logistics", 2],
	["Box_NATO_Ammoveh_f", "Logistics", 15],
	["Box_NATO_Ammo_f", "Logistics", 2],
	["Box_NATO_Grenades_f", "Logistics", 2],
	["Box_NATO_Support_f", "Logistics", 2],
	["Box_NATO_Wpslaunch_f", "Logistics", 2],
	["Box_NATO_Wps_f", "Logistics", 3],
    
    //------------------------------------------
    // Furniture
    //------------------------------------------
    ["Land_CampingChair_V2_F", "Furniture", 2],
    ["Land_CampingTable_F", "Furniture", 3],
    ["Land_Sleeping_bag_F", "Furniture", 2],
    
    //------------------------------------------
    // Equipment
    //------------------------------------------
    ["Land_PortableLight_single_F", "Equipment", 3],
    ["Land_PortableLight_double_F", "Equipment", 5],
    ["Land_FloodLight_F", "Equipment", 6]
];