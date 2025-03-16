/**
 * Récupère les liste des catégories (CfgVehicleClasses) et pour chacune d'elles les véhicules associés (CfgVehicles)
 * 
 * @param 0 (optionnel) l'éventuelle usine pour laquelle récupérer les catégories autorisées (en fonction de la white ou black list)
 * @param 1 (optionnel) true pour conserver les catégories vides (càd sans entrée dans le CfgVehicles) (défaut : false)
 * 
 * @return tableau au format [tableau des catégories, tableau 2D des véhicules associés à chaque catégorie]
 * 
 * Copyright (C) 2014 Team ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

private ["_usine", "_montrer_categories_vides", "_nb_config", "_idx_categorie", "_idx_config", "_config"];
private ["_cfgVehicles_categories", "_cfgVehicles_categories_toLower", "_cfgVehicles_par_categories", "_clean_cfgVehicles_categories", "_clean_cfgVehicles_par_categories"];

_usine = if (count _this > 0) then {_this select 0} else {objNull};
_montrer_categories_vides = if (count _this > 1) then {_this select 1} else {false};

_cfgVehicles_categories = [];
_cfgVehicles_categories_toLower = [];
_cfgVehicles_par_categories = [];

// Récupération de la liste des catégories de véhicules
_nb_config = count (configFile >> "CfgVehicleClasses");
for [{_idx_config = 0}, {_idx_config < _nb_config}, {_idx_config = _idx_config+1}] do
{
	_config = (configFile >> "CfgVehicleClasses") select _idx_config;
	if (isClass _config) then
	{
		// Si la catégorie est autorisé (en fonction de la white ou black list)
		if (isNull _usine || {(_usine getVariable "R3F_LOG_CF_blackwhitelist_mode" == "white") isEqualTo (toLower configName _config in (_usine getVariable "R3F_LOG_CF_blackwhitelist_categories"))}) then
		{
			_cfgVehicles_categories pushBack (configName _config);
			_cfgVehicles_categories_toLower pushBack (toLower configName _config);
			_cfgVehicles_par_categories pushBack [];
		};
	};
};

// Création de la liste des véhicules, classés par catégorie
_nb_config = count (configFile >> "CfgVehicles");
for [{_idx_config = 0}, {_idx_config < _nb_config}, {_idx_config = _idx_config+1}] do
{
	_config = (configFile >> "CfgVehicles") select _idx_config;
	if (isClass _config) then
	{
		// Objet instanciable
		if (getNumber (_config >> "scope") == 2 && !(configName _config isKindOf "Man")) then
		{
			// Si l'objet correspond à une side valide
			if (isNull _usine || {getNumber (_config >> "side") in (_usine getVariable "R3F_LOG_CF_num_sides")}) then
			{
				_idx_categorie = _cfgVehicles_categories_toLower find (toLower getText (_config >> "vehicleClass"));
				
				if (_idx_categorie != -1) then
				{
					(_cfgVehicles_par_categories select _idx_categorie) pushBack (configName _config);
				};
			};
		};
	};
};

// Suppression des catégories ne possédant aucun objet
_clean_cfgVehicles_categories = [];
_clean_cfgVehicles_par_categories = [];
{
	if (_montrer_categories_vides || count (_cfgVehicles_par_categories select _forEachIndex) > 0) then
	{
		_clean_cfgVehicles_categories pushBack _x;
		_clean_cfgVehicles_par_categories pushBack (_cfgVehicles_par_categories select _forEachIndex);
	};
} forEach _cfgVehicles_categories;

[_clean_cfgVehicles_categories, _clean_cfgVehicles_par_categories]