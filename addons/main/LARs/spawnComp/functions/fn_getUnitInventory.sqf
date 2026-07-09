//Get unit inventory and apply

params[ "_invCfg", "_unit" ];

private _loadout = [];

//Weapons
{
	_loadout pushBack ( [ _invCfg, _x ] call LARs_fnc_getWeaponInventoryDetails );
}forEach [ "primaryWeapon", "secondaryWeapon", "handgun" ];


//Containers
{
	_loadout pushBack ( [ _invCfg, _x ] call LARs_fnc_getContainerInventoryDetails );
}forEach [ "uniform", "vest", "backpack" ];

_loadout pushBack getText( _invCfg >> "headgear" );
_loadout pushBack getText( _invCfg >> "goggles" );
_loadout pushBack ( [ _invCfg, "binocular" ] call LARs_fnc_getWeaponInventoryDetails );

//linked Items
_loadout pushBack [
	getText( _invCfg >> "map" ),
	getText( _invCfg >> "gps" ),
	getText( _invCfg >> "radio" ),
	getText( _invCfg >> "compass" ),
	getText( _invCfg >> "watch" ),
	getText( _invCfg >> "hmd" )
];

_unit setUnitLoadout _loadout;
