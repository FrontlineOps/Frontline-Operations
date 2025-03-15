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
 * that players can place in the game world, organized by category and subcategory.
 * Each entry includes the class name, display name, categorization, and resource cost.
 */

/**
 * Master array of all buildable entities
 * Format: [Class Name, Display Name, Category, Subcategory, Cost]
 * 
 * Categories should match those defined in categoryConfig.sqf
 * Subcategories provide additional filtering options within categories
 * Cost represents the resource points required to build the entity
 */
IDS_Logistics_Entities = [
    //------------------------------------------
    // Fortification
    //------------------------------------------
    ["Land_HBarrier_3_F", "HESCO Barrier (Small)", "Fortification", "Walls", 5],
    ["Land_HBarrier_5_F", "HESCO Barrier (Medium)", "Fortification", "Walls", 8],
    ["Land_HBarrier_Big_F", "HESCO Barrier (Large)", "Fortification", "Walls", 10],
    ["Land_HBarrierWall4_F", "HESCO Wall", "Fortification", "Walls", 15],
    ["Land_HBarrierWall6_F", "HESCO Wall (Long)", "Fortification", "Walls", 20],
    ["Land_HBarrierTower_F", "HESCO Watchtower", "Fortification", "Towers", 25],
    ["Land_BagBunker_Tower_F", "Sandbag Tower", "Fortification", "Towers", 25],
    ["Land_Cargo_Patrol_V1_F", "Guard Tower", "Fortification", "Towers", 20],
    ["Land_BagBunker_Small_F", "Sandbag Bunker (Small)", "Fortification", "Bunkers", 10],
    ["Land_BagBunker_Large_F", "Sandbag Bunker (Large)", "Fortification", "Bunkers", 20],
    ["Land_Razorwire_F", "Razor Wire", "Fortification", "Barriers", 5],
    
    //------------------------------------------
    // Structures
    //------------------------------------------
    ["Land_Cargo_House_V1_F", "Container House", "Structures", "Shelters", 15],
    ["Land_Cargo_HQ_V1_F", "Command Post", "Structures", "Command", 30],
    ["Land_Medevac_house_V1_F", "Medical Building", "Structures", "Medical", 25],
    
    //------------------------------------------
    // Logistics
    //------------------------------------------
    ["StorageBladder_01_fuel_forest_F", "Fuel Bladder", "Logistics", "Fuel", 15],
    ["Land_PlasticCase_01_medium_F", "Medium Container", "Logistics", "Storage", 5],
    ["Land_PlasticCase_01_large_F", "Large Container", "Logistics", "Storage", 8],
    
    //------------------------------------------
    // Furniture
    //------------------------------------------
    ["Land_CampingChair_V2_F", "Camping Chair", "Furniture", "Seating", 2],
    ["Land_CampingTable_F", "Camping Table", "Furniture", "Tables", 3],
    ["Land_Workbench_01_F", "Workbench", "Furniture", "Utility", 5],
    ["Land_ToolTrolley_02_F", "Tool Trolley", "Furniture", "Utility", 4],
    ["Land_Sleeping_bag_F", "Sleeping Bag", "Furniture", "Bedding", 2],
    ["Land_Sleeping_bag_blue_F", "Sleeping Bag (Blue)", "Furniture", "Bedding", 2],
    
    //------------------------------------------
    // Equipment
    //------------------------------------------
    ["Land_PortableLight_single_F", "Portable Light", "Equipment", "Lighting", 3],
    ["Land_PortableLight_double_F", "Double Portable Light", "Equipment", "Lighting", 5],
    ["Land_FloodLight_F", "Flood Light", "Equipment", "Lighting", 6],
    
    //------------------------------------------
    // Signs
    //------------------------------------------
    ["Land_Sign_WarningMilitaryArea_F", "Military Area Sign", "Signs", "Warning", 1],
    ["Land_SignM_WarningMilitaryArea_english_F", "Military Area Sign (English)", "Signs", "Warning", 1],
    ["Land_Sign_WarningMilAreaSmall_F", "Military Area Sign (Small)", "Signs", "Warning", 1]
];