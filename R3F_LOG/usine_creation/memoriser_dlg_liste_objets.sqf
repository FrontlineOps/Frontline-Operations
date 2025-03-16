/**
 * Enregistre les valeurs des champs avant fermeture de la boîte de dialogue de l'usine de création.
 * ouvrir_usine.sqf s'en servira pour la préremplir à l'ouverture
 * 
 * Copyright (C) 2014 Team ~R3F~
 * 
 * This program is free software under the terms of the GNU General Public License version 3.
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

disableSerialization; // A cause des displayCtrl

private ["_dlg_liste_objets"];

#include "dlg_constantes.h"

_dlg_liste_objets = findDisplay R3F_LOG_IDD_dlg_liste_objets;

(uiNamespace getVariable "R3F_LOG_dlg_LO_usine") setVariable ["R3F_LOG_CF_mem_idx_categorie", lbCurSel (_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_liste_categories)];
(uiNamespace getVariable "R3F_LOG_dlg_LO_usine") setVariable ["R3F_LOG_CF_mem_idx_objet", lbCurSel (_dlg_liste_objets displayCtrl R3F_LOG_IDC_dlg_LO_liste_objets)];