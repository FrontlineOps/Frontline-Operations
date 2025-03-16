/**
 * Dump to the RPT file the list of all existing categories that can be allowed/denied to a creation factory.
 * This is a helper function to define your own white/black list for a creation factory.
 * See USER_FUNCT\init_creation_factory.sqf and the PDF documentation for more information.
 * Note : the RPT file is located here : C:\Users\<profile>\AppData\Local\Arma 3\. See https://community.bistudio.com/wiki/RPT
 * 
 * @param 0 (optional) true to also dump the display name and number of entries as a comment, false to hide (default : true)
 * @param 1 (optional) true to dump the empty categories (i.e. categories with no entry in CfgVehicles) (default : false)
 * 
 * @usage execute the following line in the BIS' debug console or the init line of the player
 * @usage nul = [] execVM "R3F_LOG\USER_FUNCT\dump_creation_factory_categories.sqf";
 * 
 * @usage to not dump the comments after the class names, set the optional param 0 to false
 * @usage nul = [false] execVM "R3F_LOG\USER_FUNCT\dump_creation_factory_categories.sqf";
 * 
 * @usage to dump all categories, including empty ones, set param 1 to true
 * @usage nul = [true, true] execVM "R3F_LOG\USER_FUNCT\dump_creation_factory_categories.sqf";
 */

waitUntil {!isNil "R3F_LOG_active"};

private ["_comment", "_montrer_categories_vides", "_retour_liste_cfgVehicles_par_categories", "_cfgVehicles_categories", "_cfgVehicles_par_categories", "_nb_categories", "_idx_categorie", "_align_comma", "_x"];

_comment = if (count _this > 0) then {_this select 0} else {true};
_montrer_categories_vides = if (count _this > 1) then {_this select 1} else {false};

_retour_liste_cfgVehicles_par_categories = [objNull, _montrer_categories_vides] call R3F_LOG_FNCT_recuperer_liste_cfgVehicles_par_categories;

_cfgVehicles_categories = _retour_liste_cfgVehicles_par_categories select 0;
_cfgVehicles_par_categories = _retour_liste_cfgVehicles_par_categories select 1;

diag_log text "R3F_LOG_CFG_CF_your_own_categories_list =";
diag_log text "[";

_nb_categories = count _cfgVehicles_categories;
for [{_idx_categorie = 0}, {_idx_categorie < _nb_categories}, {_idx_categorie = _idx_categorie+1}] do
{
	if (_comment) then
	{
		// Formatage du tableau sans virgule pour le dernier élément + alignement des commentaires
		_align_comma = if (_idx_categorie != _nb_categories-1) then {","} else {" "};
		for "_x" from 1 to (32 - count toArray (_cfgVehicles_categories select _idx_categorie)) do {_align_comma = _align_comma + " ";};
		
		// Dump des infos de la catégorie
		diag_log text format
		[
			"    ""%1""%2 // %3 (%4 entries)",
			_cfgVehicles_categories select _idx_categorie,
			_align_comma,
			getText (configFile >> "CfgVehicleClasses" >> (_cfgVehicles_categories select _idx_categorie) >> "displayName"),
			count (_cfgVehicles_par_categories select _idx_categorie)
		];
	}
	else
	{
		_align_comma = if (_idx_categorie != _nb_categories-1) then {","} else {""};
		
		// Dump des infos de la catégorie
		diag_log text format
		[
			"    ""%1""%2",
			_cfgVehicles_categories select _idx_categorie,
			_align_comma
		];
	};
};

diag_log text "];";