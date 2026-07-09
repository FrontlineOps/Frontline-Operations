// Get serialized weapon loadout details from a composition inventory config.

params ["_invCfg", "_weapon"];

private _weaponCfg = _invCfg >> _weapon;

[
	getText (_weaponCfg >> "name"),
	getText (_weaponCfg >> "muzzle"),
	getText (_weaponCfg >> "flashlight"),
	getText (_weaponCfg >> "optics"),
	[
		getText (_weaponCfg >> "primaryMuzzleMag" >> "name"),
		getNumber (_weaponCfg >> "primaryMuzzleMag" >> "ammoLeft")
	],
	[
		getText (_weaponCfg >> "secondaryMuzzleMag" >> "muzzle"),
		getNumber (_weaponCfg >> "secondaryMuzzleMag" >> "ammoLeft")
	],
	getText (_weaponCfg >> "underBarrel")
]
