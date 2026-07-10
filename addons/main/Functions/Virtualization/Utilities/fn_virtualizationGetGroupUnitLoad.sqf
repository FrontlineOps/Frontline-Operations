/*
 * Function: FLO_fnc_virtualizationGetGroupUnitLoad
 */

params [
    "_groupData",
    ["_includeAttached", false, [true]]
];

private _groupType = _groupData get "groupType";
private _archetype = [_groupType] call FLO_fnc_virtualizationGetArchetype;
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
    switch (_archetype get "loadMode") do {
        case "PERSONNEL": {
            _unitLoad = (_groupData get "unitCount") max 1;
        };

        case "CIVILIAN_VEHICLE": {
            _unitLoad = 1;
        };

        case "STATIC_AA": {
            _unitLoad = ((_groupData get "unitCount") max 1) + 1;
        };

        case "ASSET": {
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
                    _unitLoad = (_archetype get "fallbackCrewPerAsset") * _assetCount;
                };
            };
        };

        default {
            throw format ["Unsupported load mode for virtual-group archetype %1", _groupType];
        };
    };
};

if (_includeAttached) then {
    private _groups = call FLO_fnc_virtualizationGetGroupMap;
    {
        _unitLoad = _unitLoad + ([(_groups get _x), false] call FLO_fnc_virtualizationGetGroupUnitLoad);
    } forEach (_groupData get "attachedGroups");
};

_unitLoad
