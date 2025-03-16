/**
 * Launch the tool helping to edit the logistics configuration.
 * 
 * THIS TOOL IS UNOFFICIAL AND FOR EXPERT ONLY !
 * READ THE PDF DOCUMENTATION TO KNOW HOW TO USE IT !
 * 
 * @usage Don't forget to fill the list of class names to configure in list_of_objects_to_config.sqf.
 * @usage execVM "R3F_LOG\addons_config\logistics_config_maker_tool\launch_config_tool.sqf";
 * 
 * Copyright (C) 2014 Team ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
waitUntil {!isNil "R3F_LOG_active"};
waitUntil {!isNull player};

if (!isServer || {isPlayer _x} count playableUnits > 1) exitWith {systemChat "NOT FOR USE IN MULTIPLAYER !";};
if (!isNil "BOOL_continue" && {BOOL_continue}) exitWith {systemChat "CONFIG TOOLS ALREADY IN USE !";};
R3F_LOG_CFG_string_condition_allow_logistics_on_this_client = "false";

TAB_class_names_to_config = [
	#include "list_of_objects_to_config.sqf"
];

/*
 * On inverse l'ordre de toutes les listes de noms de classes pour donner
 * la priorité aux classes spécifiques sur les classes génériques
 */
reverse R3F_LOG_CFG_can_tow;
reverse R3F_LOG_CFG_can_be_towed;
reverse R3F_LOG_CFG_can_lift;
reverse R3F_LOG_CFG_can_be_lifted;
reverse R3F_LOG_CFG_can_transport_cargo;
reverse R3F_LOG_CFG_can_be_transported_cargo;
reverse R3F_LOG_CFG_can_be_moved_by_player;
reverse R3F_LOG_classes_transporteurs;
reverse R3F_LOG_classes_objets_transportables;

R3F_LOG_spawn_position = player modelToWorld [0, 30, 0];

player addAction ["Dump config to RPT", "R3F_LOG\addons_config\logistics_config_maker_tool\dump_config.sqf"];
player addAction ["Set new spawn position", {R3F_LOG_spawn_position = player modelToWorld [0, 30, 0]; systemChat "New spawn position defined.";}];
player addEventHandler ["HandleDamage", {0}];

BOOL_continue = true;
IDX_requested_vehicle = 0;

KEY_mode = "";
INT_capacity = 0;

disableSerialization;
while {isNull (findDisplay 46)} do {sleep 1;};
FNCT_onKeyDown =
{
	private ["_ret"];
	_ret = false;
	
	switch (_this select 1) do
	{
		// Left key - previous
		case 203:
		{
			IDX_requested_vehicle = 0 max (IDX_requested_vehicle - 1);
			_ret = true;
		};
		// Right key - next
		case 205:
		{
			IDX_requested_vehicle = (count TAB_class_names_to_config - 1) min (IDX_requested_vehicle + 1);
			_ret = true;
		};
		// Enter key - add the selected feature
		case 28:
		{
			private ["_class_name"];
			_class_name = toLower configName (configFile >> "CfgVehicles" >> (TAB_class_names_to_config select IDX_requested_vehicle));
			
			switch (KEY_mode) do
			{
				case "m":
				{
					R3F_LOG_CFG_can_be_moved_by_player = R3F_LOG_CFG_can_be_moved_by_player - [_class_name];
					R3F_LOG_CFG_can_be_moved_by_player = R3F_LOG_CFG_can_be_moved_by_player + [_class_name];
				};
				case "l":
				{
					R3F_LOG_CFG_can_be_lifted = R3F_LOG_CFG_can_be_lifted - [_class_name];
					R3F_LOG_CFG_can_be_lifted = R3F_LOG_CFG_can_be_lifted + [_class_name];
				};
				case "t":
				{
					R3F_LOG_CFG_can_be_towed = R3F_LOG_CFG_can_be_towed - [_class_name];
					R3F_LOG_CFG_can_be_towed = R3F_LOG_CFG_can_be_towed + [_class_name];
				};
				case "L":
				{
					R3F_LOG_CFG_can_lift = R3F_LOG_CFG_can_lift - [_class_name];
					R3F_LOG_CFG_can_lift = R3F_LOG_CFG_can_lift + [_class_name];
				};
				case "T":
				{
					R3F_LOG_CFG_can_tow = R3F_LOG_CFG_can_tow - [_class_name];
					R3F_LOG_CFG_can_tow = R3F_LOG_CFG_can_tow + [_class_name];
				};
				case "c":
				{
					private ["_idx"];
					
					R3F_LOG_classes_objets_transportables = R3F_LOG_classes_objets_transportables - [_class_name];
					R3F_LOG_classes_objets_transportables = R3F_LOG_classes_objets_transportables + [_class_name];
					
					R3F_LOG_CFG_objets_transportables_new = [];
					for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_be_transported_cargo}, {_idx = _idx+1}] do
					{
						if (toLower (R3F_LOG_CFG_can_be_transported_cargo select _idx select 0) != _class_name) then
						{
							R3F_LOG_CFG_objets_transportables_new = R3F_LOG_CFG_objets_transportables_new + [R3F_LOG_CFG_can_be_transported_cargo select _idx];
						};
					};
					R3F_LOG_CFG_can_be_transported_cargo = +R3F_LOG_CFG_objets_transportables_new;
					
					R3F_LOG_CFG_can_be_transported_cargo = R3F_LOG_CFG_can_be_transported_cargo + [[_class_name, INT_capacity]];
				};
				case "C":
				{
					private ["_idx"];
					
					R3F_LOG_classes_transporteurs = R3F_LOG_classes_transporteurs - [_class_name];
					R3F_LOG_classes_transporteurs = R3F_LOG_classes_transporteurs + [_class_name];
					
					R3F_LOG_CFG_transporteurs_new = [];
					for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_transport_cargo}, {_idx = _idx+1}] do
					{
						if (toLower (R3F_LOG_CFG_can_transport_cargo select _idx select 0) != _class_name) then
						{
							R3F_LOG_CFG_transporteurs_new = R3F_LOG_CFG_transporteurs_new + [R3F_LOG_CFG_can_transport_cargo select _idx];
						};
					};
					R3F_LOG_CFG_can_transport_cargo = +R3F_LOG_CFG_transporteurs_new;
					
					R3F_LOG_CFG_can_transport_cargo = R3F_LOG_CFG_can_transport_cargo + [[_class_name, INT_capacity]];
				};
			};
			KEY_mode = "";
			INT_capacity = 0;
			_ret = true;
		};
		// Del key - delete the selected feature
		case 211:
		{
			private ["_class_name"];
			_class_name = toLower configName (configFile >> "CfgVehicles" >> (TAB_class_names_to_config select IDX_requested_vehicle));
			
			switch (KEY_mode) do
			{
				case "m":
				{
					R3F_LOG_CFG_can_be_moved_by_player = R3F_LOG_CFG_can_be_moved_by_player - [_class_name];
				};
				case "l":
				{
					R3F_LOG_CFG_can_be_lifted = R3F_LOG_CFG_can_be_lifted - [_class_name];
				};
				case "t":
				{
					R3F_LOG_CFG_can_be_towed = R3F_LOG_CFG_can_be_towed - [_class_name];
				};
				case "L":
				{
					R3F_LOG_CFG_can_lift = R3F_LOG_CFG_can_lift - [_class_name];
				};
				case "T":
				{
					R3F_LOG_CFG_can_tow = R3F_LOG_CFG_can_tow - [_class_name];
				};
				case "c":
				{
					private ["_idx"];
					
					R3F_LOG_classes_objets_transportables = R3F_LOG_classes_objets_transportables - [_class_name];
					
					R3F_LOG_CFG_objets_transportables_new = [];
					for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_be_transported_cargo}, {_idx = _idx+1}] do
					{
						if (toLower (R3F_LOG_CFG_can_be_transported_cargo select _idx select 0) != _class_name) then
						{
							R3F_LOG_CFG_objets_transportables_new = R3F_LOG_CFG_objets_transportables_new + [R3F_LOG_CFG_can_be_transported_cargo select _idx];
						};
					};
					R3F_LOG_CFG_can_be_transported_cargo = +R3F_LOG_CFG_objets_transportables_new;
				};
				case "C":
				{
					private ["_idx"];
					
					R3F_LOG_classes_transporteurs = R3F_LOG_classes_transporteurs - [_class_name];
					
					R3F_LOG_CFG_transporteurs_new = [];
					for [{_idx = 0}, {_idx < count R3F_LOG_CFG_can_transport_cargo}, {_idx = _idx+1}] do
					{
						if (toLower (R3F_LOG_CFG_can_transport_cargo select _idx select 0) != _class_name) then
						{
							R3F_LOG_CFG_transporteurs_new = R3F_LOG_CFG_transporteurs_new + [R3F_LOG_CFG_can_transport_cargo select _idx];
						};
					};
					R3F_LOG_CFG_can_transport_cargo = +R3F_LOG_CFG_transporteurs_new;
				};
			};
			KEY_mode = "";
			INT_capacity = 0;
			_ret = true;
		};
		case 39:{KEY_mode = "m"; _ret = true;};
		case 38:{KEY_mode = if (_this select 2) then {"L"} else {"l"}; _ret = true;};
		case 20:{KEY_mode = if (_this select 2) then {"T"} else {"t"}; _ret = true;};
		case 46:{KEY_mode = if (_this select 2) then {"C"} else {"c"}; _ret = true;};
		case 82:{INT_capacity = INT_capacity * 10 + 0; _ret = true;};
		case 79:{INT_capacity = INT_capacity * 10 + 1; _ret = true;};
		case 80:{INT_capacity = INT_capacity * 10 + 2; _ret = true;};
		case 81:{INT_capacity = INT_capacity * 10 + 3; _ret = true;};
		case 75:{INT_capacity = INT_capacity * 10 + 4; _ret = true;};
		case 76:{INT_capacity = INT_capacity * 10 + 5; _ret = true;};
		case 77:{INT_capacity = INT_capacity * 10 + 6; _ret = true;};
		case 71:{INT_capacity = INT_capacity * 10 + 7; _ret = true;};
		case 72:{INT_capacity = INT_capacity * 10 + 8; _ret = true;};
		case 73:{INT_capacity = INT_capacity * 10 + 9; _ret = true;};
	};
	
	_ret
};
(findDisplay 46) displayAddEventHandler ["KeyDown", "_this call FNCT_onKeyDown"];

while {BOOL_continue} do
{
	private ["_idx_current_vehicle", "_class", "_class_name", "_vehicle", "_class_infos"];
	
	_idx_current_vehicle = IDX_requested_vehicle;
	_class = configFile >> "CfgVehicles" >> (TAB_class_names_to_config select _idx_current_vehicle);
	_class_name = toLower configName _class;
	_vehicle = _class_name createVehicle R3F_LOG_spawn_position;
	
	while {_idx_current_vehicle == IDX_requested_vehicle} do
	{
		_class_infos = "<t align='left'>";
		_class_infos = _class_infos + "<t align='center'>%1 (%2/%3)</t><br/>";
		_class_infos = _class_infos + "<br/>";
		_class_infos = _class_infos + "<t color='#6666ff'>Specific config :</t><br/>";
		_class_infos = _class_infos + format ["<t color='#66ffff'>[%1] Movable</t><br/>", if (_class_name in R3F_LOG_CFG_can_be_moved_by_player) then {"M"} else {" "}];
		_class_infos = _class_infos + format ["<t color='#bbbbff'>[%1] Liftable</t><br/>", if (_class_name in R3F_LOG_CFG_can_be_lifted) then {"L"} else {" "}];
		_class_infos = _class_infos + format ["<t color='#ff8888'>[%1] Towable</t><br/>", if (_class_name in R3F_LOG_CFG_can_be_towed) then {"T"} else {" "}];
		_class_infos = _class_infos + format ["<t color='#00ff00'>[%1] Cargo-able (transport)</t><br/>", if (_class_name in R3F_LOG_classes_objets_transportables) then {format ["C%1", R3F_LOG_CFG_can_be_transported_cargo select (R3F_LOG_classes_objets_transportables find _class_name) select 1]} else {" "}];
		_class_infos = _class_infos + "<br/>";
		_class_infos = _class_infos + format ["<t color='#bbbbff'>[%1] Lifter</t><br/>", if (_class_name in R3F_LOG_CFG_can_lift) then {"L"} else {" "}];
		_class_infos = _class_infos + format ["<t color='#ff8888'>[%1] Tower</t><br/>", if (_class_name in R3F_LOG_CFG_can_tow) then {"T"} else {" "}];
		_class_infos = _class_infos + format ["<t color='#00ff00'>[%1] Cargo (transporter)</t><br/>", if (_class_name in R3F_LOG_classes_transporteurs) then {format ["C%1", R3F_LOG_CFG_can_transport_cargo select (R3F_LOG_classes_transporteurs find _class_name) select 1]} else {" "}];
		_class_infos = _class_infos + "<br/>";
		_class_infos = _class_infos + "<t color='#6666ff'>Inherited config :</t><br/>";
		
		private ["_j", "_tab_inheritance_tree"];
		_tab_inheritance_tree = [_class];
		while {isClass inheritsFrom (_tab_inheritance_tree select 0)} do
		{
			_tab_inheritance_tree = [inheritsFrom (_tab_inheritance_tree select 0)] + _tab_inheritance_tree;
		};
		
		for [{_j = 0}, {_j < count _tab_inheritance_tree}, {_j = _j+1}] do
		{
			private ["_class_name_inherit", "_options"];
			
			_class_name_inherit = toLower configName (_tab_inheritance_tree select _j);
			
			_options = "[";
			
			if (_class_name_inherit in R3F_LOG_CFG_can_be_moved_by_player)
			then {_options = _options + "<t color='#00ff00'>M</t>";};
			
			if (_class_name_inherit in R3F_LOG_CFG_can_be_lifted)
			then {_options = _options + "<t color='#00ff00'>L</t>";};
			
			if (_class_name_inherit in R3F_LOG_CFG_can_be_towed)
			then {_options = _options + "<t color='#00ff00'>T</t>";};
			
			if (_class_name_inherit in R3F_LOG_classes_objets_transportables)
			then {_options = _options + format ["<t color='#00ff00'>C%1</t>", R3F_LOG_CFG_can_be_transported_cargo select (R3F_LOG_classes_objets_transportables find _class_name_inherit) select 1];};
			
			_options = _options + "|";
			
			if (_class_name_inherit in R3F_LOG_CFG_can_lift)
			then {_options = _options + "<t color='#00ff00'>L</t>";};
			
			if (_class_name_inherit in R3F_LOG_CFG_can_tow)
			then {_options = _options + "<t color='#00ff00'>T</t>";};
			
			if (_class_name_inherit in R3F_LOG_classes_transporteurs)
			then {_options = _options + format ["<t color='#00ff00'>C%1</t>", R3F_LOG_CFG_can_transport_cargo select (R3F_LOG_classes_transporteurs find _class_name_inherit) select 1];};
			
			_options = _options + "] ";
			
			_class_infos = _class_infos + _options + _class_name_inherit + "<br/>";
		};
		
		_class_infos = _class_infos + "</t>";
	
		hintSilent parseText format [_class_infos, _class_name, (_idx_current_vehicle+1), count TAB_class_names_to_config];
		sleep 0.05;
	};
	
	deleteVehicle _vehicle;
	sleep 0.01;
	
	// Clean potential object spawned by the vehicle (effect, etc.)
	{
		if (_x != player) then
		{
			deleteVehicle _x;
		};
	} forEach nearestObjects [R3F_LOG_spawn_position, ["All"], 50];
	sleep 0.025;
};
