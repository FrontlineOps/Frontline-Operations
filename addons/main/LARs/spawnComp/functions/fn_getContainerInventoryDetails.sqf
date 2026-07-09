// Get serialized container cargo details from a composition inventory config.

params ["_invCfg", "_container"];

private _containerCfg = _invCfg >> _container;
private _containerType = getText (_containerCfg >> "typeName");
private _items = [];

{
	private _cargoType = _x;
	{
		if (_cargoType isEqualTo "MagazineCargo") then {
			_items pushBack [getText (_x >> "name"), getNumber (_x >> "count"), getNumber (_x >> "ammoLeft")];
		} else {
			_items pushBack [getText (_x >> "name"), getNumber (_x >> "count")];
		};
	} forEach ("true" configClasses (_containerCfg >> _cargoType));
} forEach ["MagazineCargo", "ItemCargo"];

[_containerType, _items]
