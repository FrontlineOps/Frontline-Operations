/**
 * Initialize a vehicle or an object to be a creation factory (object spawning system)
 * 
 * @param 0 the creation factory, can be a mobile vehicle or any object
 * @param 1 (optional) creation credits limitation, -1 for unlimited credits (default : -1)
 * @param 2 (optional) side to allow accessing to the factory (default : all sides allowed)
 * @param 3 (optional) list of class names of allowed categories (white list)
 *                     if param not set, all the categories are allowed, except those in the black list defined in config_creation_factory.sqf
 *                     if string "FULL", use the white list R3F_LOG_CFG_CF_whitelist_full_categories (config_creation_factory.sqf)
 *                     if string "MEDIUM", use the white list R3F_LOG_CFG_CF_whitelist_medium_categories (config_creation_factory.sqf)
 *                     if string "LIGHT", use the white list R3F_LOG_CFG_CF_whitelist_light_categories (config_creation_factory.sqf)
 *                     if array of CfgVehicleClasses entries (class names, e.g. : ["Furniture", "Fortifications"]), use this array as white list
 * 
 * @usage nul = [my_factory] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"; // Unlimited credits, all sides allowed, all categories except black list in config_creation_factory.sqf
 * @usage nul = [my_factory, 10000] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"; // 10000 credits, all sides allowed, all categories except black list in config_creation_factory.sqf
 * @usage nul = [my_factory, -1, independent] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"; // Unlimited credits, allow to GUER side, all categories except black list
 * @usage nul = [my_factory, -1, nil, "MEDIUM"] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"; // All sides allowed, use white list MEDIUM in config_creation_factory.sqf
 * @usage nul = [my_factory, -1, nil, ["Car", "Armored"]] execVM "R3F_LOG\USER_FUNCT\init_creation_factory.sqf"; // Allow only categories "Car" and "Armored"
 * @usage You can replace "my_factory" by "this" if you put the line in the initialization line in the mission editor.
 * 
 * @note the categories are the same as in the mission editor. Class names can be found in the BIS' config viewer in the config file CfgVehicleClasses.
 */

if (!isDedicated) then
{
	waitUntil {!isNil "R3F_LOG_active"};
	
	if (R3F_LOG_active) then
	{
		_this call R3F_LOG_FNCT_usine_init;
	};
};