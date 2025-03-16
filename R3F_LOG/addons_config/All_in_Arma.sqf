/**
 * Logistics configuration for All in Arma.
 * The configuration is splitted in categories dispatched in the included files.
 */

// Load the logistics config only if the addon is used
if (isClass (configfile >> "CfgPatches" >> "AiA_Core")) then
{
	#include "All_in_Arma\Air.sqf"
	#include "All_in_Arma\LandVehicle.sqf"
	#include "All_in_Arma\Ship.sqf"
	#include "All_in_Arma\Building.sqf"
	#include "All_in_Arma\ReammoBox.sqf"
	#include "All_in_Arma\Others.sqf"
};