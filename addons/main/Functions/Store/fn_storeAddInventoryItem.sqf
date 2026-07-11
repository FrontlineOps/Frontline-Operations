params ["_unit", "_className", "_container"];

private _added = false;

switch (_container) do {
    case "uniform": {
        if ((uniform _unit) isEqualTo "") then {
            if (_unit canAdd _className) then {
                _unit addItem _className;
                _added = true;
            };
        } else {
            if (_unit canAddItemToUniform _className) then {
                _unit addItemToUniform _className;
                _added = true;
            };
        };
    };
    case "vest": {
        if ((vest _unit) isEqualTo "") then {
            if (_unit canAdd _className) then {
                _unit addItem _className;
                _added = true;
            };
        } else {
            if (_unit canAddItemToVest _className) then {
                _unit addItemToVest _className;
                _added = true;
            };
        };
    };
    case "backpack": {
        if ((backpack _unit) isEqualTo "") then {
            if (_unit canAdd _className) then {
                _unit addItem _className;
                _added = true;
            };
        } else {
            if (_unit canAddItemToBackpack _className) then {
                _unit addItemToBackpack _className;
                _added = true;
            };
        };
    };
    default {
        if (_unit canAdd _className) then {
            _unit addItem _className;
            _added = true;
        };
    };
};

_added
