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
// Format: [Category ID, Display Name, Icon Path]
IDS_Logistics_buildingCategories = [
    ["Fortification", "Fortifications", "\a3\ui_f\data\gui\Rsc\RscDisplayArsenal\itemacc_ca.paa"],
    ["Shelter", "Shelters & Structures", "\a3\ui_f\data\gui\Rsc\RscDisplayArsenal\itemoptic_ca.paa"],
    ["Furniture", "Furniture", "\a3\ui_f\data\gui\Rsc\RscDisplayArsenal\itembinocular_ca.paa"],
    ["Storage", "Storage Solutions", "\a3\ui_f\data\gui\Rsc\RscDisplayArsenal\backpack_ca.paa"],
    ["Utilities", "Utilities", "\a3\ui_f\data\gui\Rsc\RscDisplayArsenal\radio_ca.paa"],
    ["Decoration", "Decorative Items", "\a3\ui_f\data\gui\Rsc\RscDisplayArsenal\uniform_ca.paa"]
];

/**
 * @name IDS_Logistics_fnc_getCategoryProps
 * @description Retrieves the full properties array for a specific category
 * @param {String} _categoryId - The unique identifier for the category
 * @return {Array} - Full category properties [id, name, icon] or empty array if not found
 */
IDS_Logistics_fnc_getCategoryProps = {
    params [
        ["_categoryId", "", [""]]
    ];
    
    if (_categoryId == "") exitWith {[]};
    
    private _props = [];
    {
        if (_x select 0 == _categoryId) exitWith { _props = _x; };
    } forEach IDS_Logistics_buildingCategories;
    
    _props
};

/**
 * @name IDS_Logistics_fnc_getAllCategoryIds
 * @description Returns an array of all category IDs in the system
 * @param {None}
 * @return {Array} - Array of all category ID strings
 */
IDS_Logistics_fnc_getAllCategoryIds = {
    IDS_Logistics_buildingCategories apply {_x select 0}
};

/**
 * @name IDS_Logistics_fnc_getCategoryDisplayName
 * @description Gets the user-friendly display name for a category
 * @param {String} _categoryId - The unique identifier for the category
 * @return {String} - Display name or original ID if category not found
 */
IDS_Logistics_fnc_getCategoryDisplayName = {
    params [
        ["_categoryId", "", [""]]
    ];
    
    private _props = [_categoryId] call IDS_Logistics_fnc_getCategoryProps;
    if (count _props > 0) then {_props select 1} else {_categoryId}
};

/**
 * @name IDS_Logistics_fnc_getCategoryIcon
 * @description Gets the UI icon path for a category
 * @param {String} _categoryId - The unique identifier for the category
 * @return {String} - Icon path or empty string if category not found
 */
IDS_Logistics_fnc_getCategoryIcon = {
    params [
        ["_categoryId", "", [""]]
    ];
    
    private _props = [_categoryId] call IDS_Logistics_fnc_getCategoryProps;
    if (count _props > 0) then {_props select 2} else {""}
};