/*
 * FLO addon-safe UI definitions.
 *
 * Addon config must not redefine vanilla Rsc* classes because doing so
 * overwrites global game UI controls.
 */

#include "addon_macros.hpp"
#include "constants.hpp"

class IGUIBack;
class RscButton;
class RscCheckbox;
class RscCombo;
class RscControlsGroup;
class RscEdit;
class RscFrame;
class RscListBox;
class RscMapControl;
class RscPicture;
class RscPictureKeepAspect;
class RscProgress;
class RscSlider;
class RscStructuredText;
class RscText;
class RscTree;

#include "FLO_controls.hpp"
