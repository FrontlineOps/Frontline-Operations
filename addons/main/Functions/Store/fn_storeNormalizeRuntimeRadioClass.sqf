params ["_className"];

if !(_className isEqualType "") then {
    throw "Store radio normalization requires a classname string";
};
if (_className == "") exitWith { "" };

private _lowerClass = toLower _className;
private _normalized = _className;
{
    private _baseClass = _x;
    private _lowerBase = toLower _baseClass;
    if (_lowerClass == _lowerBase || {_lowerClass find (_lowerBase + "_") == 0}) exitWith {
        _normalized = _baseClass;
    };
} forEach FLO_StoreRuntimeRadioBaseClasses;

_normalized
