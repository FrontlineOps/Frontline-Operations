/* Validate browser selection at the local preview boundary; checkout remains server owned. */
params ["_display", "_selection"];
if (isNull _display) exitWith {false};
private _state = _display getVariable "FLO_StorePreview";
private _class = _selection getOrDefault ["className", ""];
private _category = _selection getOrDefault ["category", ""];
private _kind = _selection getOrDefault ["entryKind", ""];
if !(_class isEqualType "" && {_category isEqualType ""} && {_kind isEqualType ""}) exitWith {false};
private _man = _state get "man";
deleteVehicle (_state get "model");
_state set ["model", objNull];
_state set ["subject", _man];
_state set ["selection", _selection];
_man hideObject false;
_man setUnitLoadout (_state get "baseline");
private _status = "";
if (_class != "" && {_kind in ["gear", "vehicle", "recruit", "supply"]}) then {
    private _root = switch (true) do {
        case (_kind in ["vehicle", "recruit", "supply"] || {_category == "backpacks"}): {"CfgVehicles"};
        case (_category == "facewear"): {"CfgGlasses"};
        case (_category in ["ammo", "mines"] || {_category == "misc" && {!isClass (configFile >> "CfgWeapons" >> _class)}}): {"CfgMagazines"};
        default {"CfgWeapons"};
    };
    private _cfg = configFile >> _root >> _class;
    if (isClass _cfg) then {
        private _wearable = _kind == "gear" && {_category in ["uniforms", "vests", "backpacks", "headgear", "facewear", "primary", "handgun", "secondary", "attachments", "misc"]};
        if (((_state get "mode") == "character" || {_category == "uniforms"}) && {_wearable}) then {
            [_man, _state get "baseline", _class, _category] call FLO_fnc_storePreviewEquip;
            if (_category == "attachments" && {!(_class in (primaryWeaponItems _man))}) then {_status = "Does not fit your current primary weapon. Use Equipment to inspect it."};
        } else {
            private _path = getText (_cfg >> "model");
            if (_category in ["vests", "headgear"]) then {_path = getText (_cfg >> "ItemInfo" >> "uniformModel")};
            if (_path != "" && {toLower (_path select [(count _path - 4) max 0]) != ".p3d"}) then {_path = _path + ".p3d"};
            if (_path != "" && {fileExists _path}) then {
                private _model = createSimpleObject [[_path, _class] select (_root == "CfgVehicles"), _state get "position", true];
                // Raw weapon models include firing proxies that have no simulation to hide them.
                private _flash = toLower getText (_cfg >> "selectionFireAnim");
                {
                    private _name = toLower _x;
                    if (_name == _flash || {_name find "zasleh" >= 0} || {_name find "muzzle_flash" >= 0}) then {_model hideSelection [_x, true]};
                } forEach (selectionNames _model);
                _model setDir 180;
                _state set ["model", _model];
                _state set ["subject", _model];
                _man hideObject true;
            } else {_status = "This item has no standalone preview model. Character view is available for wearable gear."};
        };
    } else {_status = "No preview model available for this catalog entry."};
};
[_display] call FLO_fnc_storePreviewUpdateCamera;
private _browser = _display displayCtrl FLO_StoreBrowserIdc;
[_browser, ["ExecJS", format ["FLOStore.previewStatus(%1);", toJSON _status]]] call FLO_fnc_uiWebAction;
true
