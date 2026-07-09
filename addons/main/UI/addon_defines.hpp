/*
 * FLO addon-safe UI definitions.
 *
 * Mission-level UI/defines.hpp keeps legacy Rsc* compatibility classes for
 * description.ext. Addon config must not redefine those vanilla classes because
 * doing so overwrites global game UI controls.
 */

#include "..\include\a3\3den\ui\macros.inc"
#include "..\include\a3\ui_f\hpp\definecommongrids.inc"
#include "..\include\a3\ui_f\hpp\definedikcodes.inc"
#include "..\include\a3\3den\ui\resincl.inc"

#include "constants.hpp"

class IGUIBack;
class RscButton;
class RscCheckbox;
class RscCombo;
class RscControlsGroup;
class RscEdit;
class RscFrame;
class RscListBox;
class RscMap;
class RscPicture;
class RscPictureKeepAspect;
class RscProgress;
class RscSlider;
class RscStructuredText;
class RscText;
class RscTree;

#include "FLO_controls.hpp"
