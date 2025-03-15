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
    ["Land_HBarrier_1_F", "Fortification", 5],
    ["Land_HBarrier_3_F", "Fortification", 8],
    ["Land_HBarrier_5_F", "Fortification", 10],
    ["Land_HBarrier_Big_F", "Fortification", 10],
    ["Land_HBarrierTower_F", "Fortification", 25],
    ["Land_HBarrierWall_corner_F", "Fortification", 10],
    ["Land_HBarrierWall_corridor_F", "Fortification", 10],
    ["Land_HBarrierWall4_F", "Fortification", 10],
    ["Land_HBarrierWall6_F", "Fortification", 10],

    ["Land_HBarrier_01_big_4_green_F", "Fortification", 10],
    ["Land_HBarrier_01_big_tower_green_F", "Fortification", 25],
    ["Land_HBarrier_01_line_1_green_F", "Fortification", 10],
    ["Land_HBarrier_01_line_3_green_F", "Fortification", 10],
    ["Land_HBarrier_01_line_5_green_F", "Fortification", 10],
    ["Land_HBarrier_01_tower_green_F", "Fortification", 25],
    ["Land_HBarrier_01_wall_4_green_F", "Fortification", 10],
    ["Land_HBarrier_01_wall_6_green_F", "Fortification", 10],
    ["Land_HBarrier_01_wall_corner_green_F", "Fortification", 10],
    ["Land_HBarrier_01_wall_corridor_green_F", "Fortification", 10],

    ["Land_BagBunker_Large_F", "Fortification", 20],
    ["Land_BagBunker_Small_F", "Fortification", 10],
    ["Land_BagBunker_Tower_F", "Fortification", 25],

    ["Land_BagBunker_01_Large_Green_F", "Fortification", 20],
    ["Land_BagBunker_01_small_green_F", "Fortification", 10],

    ["Land_BagFence_Corner_F", "Fortification", 5],
    ["Land_BagFence_End_F", "Fortification", 5],
    ["Land_BagFence_Long_F", "Fortification", 5],
    ["Land_BagFence_Round_F", "Fortification", 5],
    ["Land_BagFence_Short_F", "Fortification", 5],

    ["Land_BagFence_01_corner_green_F", "Fortification", 5],
    ["Land_BagFence_01_end_green_F", "Fortification", 5],
    ["Land_BagFence_01_long_green_F", "Fortification", 5],
    ["Land_BagFence_01_round_green_F", "Fortification", 5],
    ["Land_BagFence_01_short_green_F", "Fortification", 5],

    ["Land_Razorwire_F", "Fortification", 5],

    ["CamoNet_BLUFOR_F", "Fortification", 10],
    ["CamoNet_BLUFOR_open_F", "Fortification", 10],
    ["CamoNet_BLUFOR_big_F", "Fortification", 10],
    ["CamoNet_BLUFOR_Curator_F", "Fortification", 10],
    ["CamoNet_BLUFOR_open_Curator_F", "Fortification", 10],
    ["CamoNet_BLUFOR_big_Curator_F", "Fortification", 10],
    
    //------------------------------------------
    // Structures
    //------------------------------------------
    ["Land_Cargo_House_V1_F", "Structures", 15],
    ["Land_Cargo_House_V3_F", "Structures", 15],
    ["Land_Cargo_House_V4_F", "Structures", 15],

    ["Land_Cargo_Patrol_V1_F", "Structures", 20],
    ["Land_Cargo_Patrol_V3_F", "Structures", 20],
    ["Land_Cargo_Patrol_V4_F", "Structures", 20],

    ["Land_Cargo_Tower_V1_F", "Structures", 30],
    ["Land_Cargo_Tower_V3_F", "Structures", 30],
    ["Land_Cargo_Tower_V4_F", "Structures", 30],

    ["Land_Cargo_HQ_V1_F", "Structures", 30],
    ["Land_Cargo_HQ_V3_F", "Structures", 30],
    ["Land_Cargo_HQ_V4_F", "Structures", 30],

    ["Land_Medevac_HQ_V1_F", "Structures", 30],
    ["Land_Medevac_house_V1_F", "Structures", 25],
    
    //------------------------------------------
    // Logistics
    //------------------------------------------
    ["StorageBladder_01_fuel_forest_F", "Logistics", 15],
    ["StorageBladder_01_fuel_sand_F", "Logistics", 15],
    ["StorageBladder_02_water_forest_F", "Logistics", 15],
    ["StorageBladder_02_water_sand_F", "Logistics", 15],
    
	["B_SupplyCrate_f", "Logistics", 10],
	["C_SupplyCrate_f", "Logistics", 10],
	["IG_SupplyCrate_f", "Logistics", 10],

	["Box_East_Ammoord_f", "Logistics", 2],
	["Box_East_Ammoveh_f", "Logistics", 15],
	["Box_East_Ammo_f", "Logistics", 2],
	["Box_East_Grenades_f", "Logistics", 2],
	["Box_East_Support_f", "Logistics", 2],
	["Box_East_Wpslaunch_f", "Logistics", 2],
	["Box_East_Wps_f", "Logistics", 3],

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