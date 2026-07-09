//Get unit inventory and apply

params[ "_invCfg", "_unit" ];

private _loadout = [];

//Weapons
private _fnc_getWeaponDetails = {
	params[ "_weapon" ];

	private _weaponCfg = _invCfg >> _weapon;

	[
		getText( _weaponCfg >> "name" ),
		getText( _weaponCfg >> "muzzle" ),
		getText( _weaponCfg >> "flashlight" ),
		getText( _weaponCfg >> "optics" ),
		[
			getText( _weaponCfg >> "primaryMuzzleMag" >> "name" ),
			getNumber( _weaponCfg >> "primaryMuzzleMag" >> "ammoLeft" )
		],
		[
			getText( _weaponCfg >> "secondaryMuzzleMag" >> "muzzle" ),
			getNumber( _weaponCfg >> "secondaryMuzzleMag" >> "ammoLeft" )
		],
		getText( _weaponCfg >> "underBarrel" )
	]

};

{
	private _nul = _loadout pushBack ( _x call _fnc_getWeaponDetails );
}forEach [ "primaryWeapon", "secondaryWeapon", "handgun" ];


//Containers
private _fnc_getContainerDetails = {
	params[ "_container" ];

	_containerCfg = _invCfg >> _container;

	_containerType = getText( _containerCfg >> "typeName" );
	_items = [];
	{
		_cargoType = _x;
		{
			if ( _cargoType isEqualTo "MagazineCargo" ) then {
				private _nul = _items pushBack [ getText( _x >> "name" ), getNumber( _x >> "count" ), getNumber( _x >> "ammoLeft" ) ];
			}else{
				private _nul = _items pushBack [ getText( _x >> "name" ), getNumber( _x >> "count" ) ];
			};
		}forEach ( "true" configClasses ( _containerCfg >> _cargoType ));
	}forEach [ "MagazineCargo", "ItemCargo" ];

	[ _containerType, _items ]
};

{
	private _nul = _loadout pushBack ( _x call _fnc_getContainerDetails );
}forEach [ "uniform", "vest", "backpack" ];

private _nul = _loadout pushBack getText( _invCfg >> "headgear" );
private _nul = _loadout pushBack getText( _invCfg >> "goggles" );
private _nul = _loadout pushBack ( "binocular" call _fnc_getWeaponDetails );

//linked Items
_nul = _loadout pushBack [
	getText( _invCfg >> "map" ),
	getText( _invCfg >> "gps" ),
	getText( _invCfg >> "radio" ),
	getText( _invCfg >> "compass" ),
	getText( _invCfg >> "watch" ),
	getText( _invCfg >> "hmd" )
];

_unit setUnitLoadout _loadout;
