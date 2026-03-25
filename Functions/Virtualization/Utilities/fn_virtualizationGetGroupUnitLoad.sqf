/*
 * Function: FLO_fnc_virtualizationGetGroupUnitLoad
 */

params [
    "_groupData",
    ["_includeAttached", false, [true]]
];

private _groupType = _groupData get "groupType";
private _unitLoad = 0;
private _hasRealGroup = false;

if (_groupData get "isActive") then {
    private _realGroup = _groupData get "realGroup";
    if (!isNull _realGroup) then {
        _hasRealGroup = true;
        _unitLoad = { alive _x } count (units _realGroup);
    };
};

if (!_hasRealGroup && {_unitLoad <= 0}) then {
    switch (_groupType) do {
        case "infantry";
        case "civilian";
        case "civ_pedestrian";
        case "civ_building": {
            _unitLoad = (_groupData get "unitCount") max 1;
        };

        case "civilianVehicle";
        case "civ_car": {
            _unitLoad = 1;
        };

        case "static_aa": {
            _unitLoad = ((_groupData get "unitCount") max 1) + 1;
        };

        default {
            private _composition = _groupData get "comp";

            if (_composition isNotEqualTo []) then {
                {
                    _unitLoad = _unitLoad + ([_x] call FLO_fnc_virtualizationEstimateVehicleCrewCount);
                } forEach _composition;
            } else {
                private _vehicleType = _groupData get "vehicleType";
                private _assetCount = (_groupData get "unitCount") max 1;

                if (_vehicleType != "") then {
                    _unitLoad = ([_vehicleType] call FLO_fnc_virtualizationEstimateVehicleCrewCount) * _assetCount;
                } else {
                    _unitLoad = switch (_groupType) do {
                        case "motorized";
                        case "mechanized";
                        case "armor";
                        case "artillery";
                        case "mobile_aa": { 3 * _assetCount };
                        case "helicopter";
                        case "jet";
                        case "air": { 2 * _assetCount };
                        default { _assetCount };
                    };
                };
            };
        };
    };
};

if (_includeAttached) then {
    private _groups = FLO_virtualGroups get "_groups";
    {
        _unitLoad = _unitLoad + ([(_groups get _x), false] call FLO_fnc_virtualizationGetGroupUnitLoad);
    } forEach (_groupData get "attachedGroups");
};

_unitLoad
