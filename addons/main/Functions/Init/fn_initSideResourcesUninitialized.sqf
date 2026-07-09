/*
 * Function: FLO_fnc_initSideResourcesUninitialized
 * Author: Frontline Operations Development Group
 * Description:
 *   Checks whether the side resource system still needs initial startup.
 *
 * Arguments: None
 * Returns:
 * Uninitialized <BOOLEAN>
 */
if (isNil "FLO_SideResources") exitWith { true };
if (!(FLO_SideResources isEqualType createHashMap)) exitWith { true };

(keys FLO_SideResources) isEqualTo []
