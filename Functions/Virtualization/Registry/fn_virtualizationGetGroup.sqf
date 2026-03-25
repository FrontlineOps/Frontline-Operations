/*
 * Function: FLO_fnc_virtualizationGetGroup
 */

params ["_virt", "_groupId"];

(_virt get "_groups") get _groupId
