/**
 * @name IDS_Logistics_CategoryConfig
 * @category Logistics_Configuration
 * 
 * @author IDSolutions
 * @version 1.0
 * @date 2025-03-10
 * 
 * @description
 * Core configuration file defining all building categories in the logistics system.
 * Provides the category data structure and helper functions for accessing category properties.
 * This file serves as the central repository for all category-related constants and utilities.
 */

// Main category definitions array
// Format: [Category ID, Display Name]
IDS_Logistics_Categories = [
    ["Fortification", "Fortifications"],
    ["Shelter", "Shelters & Structures"],
    ["Furniture", "Furniture"],
    ["Storage", "Storage Solutions"],
    ["Utilities", "Utilities"],
    ["Decoration", "Decorative Items"]
];

/**
 * @name IDS_Logistics_fnc_getCategoryProps
 * @description Retrieves the full properties array for a specific category
 * @param {String} _categoryId - The unique identifier for the category
 * @return {Array} - Full category properties [id, name] or empty array if not found
 */
IDS_Logistics_fnc_getCategoryProps = {
    params [["_categoryId", "", [""]]];
    
    if (_categoryId == "") exitWith {[]};
    
    private _props = [];
    {
        if (_x select 0 == _categoryId) exitWith { _props = _x; };
    } forEach IDS_Logistics_Categories;
    
    _props
};

/**
 * @name IDS_Logistics_fnc_getAllCategoryIds
 * @description Returns an array of all category IDs in the system
 * @param {None}
 * @return {Array} - Array of all category ID strings
 */
IDS_Logistics_fnc_getAllCategoryIds = {
    IDS_Logistics_Categories apply { _x select 0 }
};

/**
 * @name IDS_Logistics_fnc_getCategoryDisplayName
 * @description Gets the user-friendly display name for a category
 * @param {String} _categoryId - The unique identifier for the category
 * @return {String} - Display name or original ID if category not found
 */
IDS_Logistics_fnc_getCategoryDisplayName = {
    params [["_categoryId", "", [""]]];
    
    private _props = [_categoryId] call IDS_Logistics_fnc_getCategoryProps;
    if (count _props > 0) then { _props select 1 } else { _categoryId }
};