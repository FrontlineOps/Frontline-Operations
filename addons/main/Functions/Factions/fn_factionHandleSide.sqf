/* Returns the single native config side owned by a faction handle. */
params [["_handle", createHashMap, [createHashMap]]];

private _name = _handle get "name";
if !(_name isEqualType "" && {_name != ""}) then {
    throw format ["Faction handle has invalid name %1", _name];
};
private _source = [_handle] call FLO_fnc_factionHandleSource;
private _side = switch (_source) do {
    case "custom": {
        switch (_name) do {
            case "CUSTOM_BLUFOR_FACTION": { 1 };
            case "CUSTOM_OPFOR_FACTION": { 0 };
            case "CUSTOM_CIVILIAN_FACTION": { 3 };
            default { throw format ["Unsupported custom faction handle %1", _name] };
        }
    };
    case "auto";
    case "auto_multi": {
        private _classes = if ("factionClasses" in _handle) then {
            +(_handle get "factionClasses")
        } else {
            if !("factionClass" in _handle) then {
                throw format ["Auto faction handle %1 has no faction class", _name];
            };
            [_handle get "factionClass"]
        };

        if (_classes isEqualTo []) then {
            throw format ["Auto faction handle %1 has an empty faction class list", _name];
        };

        private _resolvedSide = -1;
        {
            private _cfg = missionConfigFile >> "CfgFactionClasses" >> _x;
            if !(isClass _cfg) then {
                _cfg = configFile >> "CfgFactionClasses" >> _x;
            };
            if !(isClass _cfg) then {
                throw format ["Faction class %1 from handle %2 does not exist", _x, _name];
            };

            private _classSide = getNumber (_cfg >> "side");
            if !(_classSide in [0, 1, 3]) then {
                throw format ["Faction class %1 uses unsupported config side %2", _x, _classSide];
            };
            if (_resolvedSide < 0) then {
                _resolvedSide = _classSide;
            } else {
                if (_classSide != _resolvedSide) then {
                    throw format ["Faction handle %1 mixes config sides %2 and %3", _name, _resolvedSide, _classSide];
                };
            };
        } forEach _classes;

        _resolvedSide
    };
    default { throw format ["Unsupported faction handle source %1 for %2", _source, _name] };
};

private _declaredSide = _handle get "side";
if !(_declaredSide isEqualType 0 && {_declaredSide == _side}) then {
    throw format ["Faction handle %1 declares side %2 but resolves to %3", _name, _declaredSide, _side];
};

_side
