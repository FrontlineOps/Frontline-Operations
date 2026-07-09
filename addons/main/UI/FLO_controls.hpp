/*
 * FLO Styled Control Classes
 * Author: Frontline Operations
 *
 * Description:
 * FLO-specific styled variants of base controls. These provide consistent
 * theming across all mission dialogs. Use these instead of raw base classes.
 *
 * Dependencies:
 * Must be included AFTER UI/addon_defines.hpp declares vanilla base controls.
 */

// ============================================================================
// FLO TEXT VARIANTS
// ============================================================================

class FLO_RscText: RscText
{
	colorText[] = FLO_COLOR_TEXT;
	font = "RobotoCondensed";
	sizeEx = FLO_FONT_SIZE;
	shadow = 1;
};

class FLO_RscText_Title: FLO_RscText
{
	colorText[] = FLO_COLOR_TEXT_TITLE;
	font = "RobotoCondensedBold";
	sizeEx = FLO_FONT_SIZE_LG;
};

class FLO_RscText_Muted: FLO_RscText
{
	colorText[] = FLO_COLOR_TEXT_MUTED;
	sizeEx = FLO_FONT_SIZE_SM;
	shadow = 0;
};

class FLO_RscText_Label: FLO_RscText
{
	colorText[] = FLO_COLOR_TEXT_TITLE;
	sizeEx = FLO_FONT_SIZE_SM;
	font = "RobotoCondensed";
};

// ============================================================================
// FLO BACKGROUND/PANEL CLASSES
// ============================================================================

class FLO_RscBackground: RscText
{
	colorBackground[] = FLO_COLOR_BACKGROUND;
	colorText[] = FLO_COLOR_TRANSPARENT;
	text = "";
};

class FLO_RscSurface: RscText
{
	colorBackground[] = FLO_COLOR_SURFACE;
	colorText[] = FLO_COLOR_TRANSPARENT;
	text = "";
};

class FLO_RscTitleBar: RscText
{
	style = ST_CENTER;
	colorBackground[] = FLO_COLOR_HEADER;
	colorText[] = FLO_COLOR_TEXT;
	font = "RobotoCondensedBold";
	sizeEx = FLO_FONT_SIZE;
	shadow = 1;
};

class FLO_RscCard: RscText
{
	colorBackground[] = FLO_COLOR_SURFACE;
	colorText[] = FLO_COLOR_TEXT_SECONDARY;
	font = "RobotoCondensed";
	sizeEx = FLO_FONT_SIZE_SM;
	shadow = 0;
};

// ============================================================================
// FLO BUTTON VARIANTS
// ============================================================================

class FLO_RscButton: RscButton
{
	colorText[] = FLO_COLOR_TEXT;
	colorBackground[] = FLO_COLOR_BUTTON_BG;
	colorBackgroundActive[] = FLO_COLOR_BUTTON_HOVER;
	colorFocused[] = FLO_COLOR_BUTTON_HOVER;
	font = "RobotoCondensed";
	sizeEx = FLO_FONT_SIZE;
};

class FLO_RscButton_Primary: FLO_RscButton
{
	colorBackground[] = FLO_COLOR_PRIMARY;
	colorBackgroundActive[] = FLO_COLOR_PRIMARY_HOVER;
	colorFocused[] = FLO_COLOR_PRIMARY_HOVER;
	font = "RobotoCondensedBold";
};

class FLO_RscButton_Secondary: FLO_RscButton
{
	colorBackground[] = FLO_COLOR_SURFACE;
	colorBackgroundActive[] = FLO_COLOR_SURFACE_HOVER;
	colorFocused[] = FLO_COLOR_SURFACE_HOVER;
};

class FLO_RscButton_Success: FLO_RscButton
{
	colorBackground[] = FLO_COLOR_SUCCESS_BG;
	colorBackgroundActive[] = FLO_COLOR_SUCCESS;
	colorFocused[] = FLO_COLOR_SUCCESS;
	font = "RobotoCondensedBold";
};

class FLO_RscButton_Warning: FLO_RscButton
{
	colorBackground[] = FLO_COLOR_WARNING_BG;
	colorBackgroundActive[] = FLO_COLOR_WARNING;
	colorFocused[] = FLO_COLOR_WARNING;
	font = "RobotoCondensedBold";
};

class FLO_RscButton_Danger: FLO_RscButton
{
	colorBackground[] = FLO_COLOR_DANGER;
	colorBackgroundActive[] = FLO_COLOR_DANGER_HOVER;
	colorFocused[] = FLO_COLOR_DANGER_HOVER;
	font = "RobotoCondensedBold";
};

class FLO_RscButton_Close: FLO_RscButton_Danger
{
	text = "X";
	w = "1.50 * GUI_GRID_W";
	h = "1.50 * GUI_GRID_H";
	tooltip = "Close";
};

// ============================================================================
// FLO INPUT CONTROLS
// ============================================================================

class FLO_RscCombo: RscCombo
{
	colorText[] = FLO_COLOR_TEXT;
	colorBackground[] = FLO_COLOR_SURFACE;
	colorSelectBackground[] = FLO_COLOR_SELECT_BG;
	colorScrollbar[] = FLO_COLOR_SCROLLBAR;
	font = "RobotoCondensed";
	sizeEx = FLO_FONT_SIZE;
	wholeHeight = "14 * GUI_GRID_H";
};

class FLO_RscEdit: RscEdit
{
	colorBackground[] = FLO_COLOR_INPUT_BG;
	colorText[] = FLO_COLOR_TEXT;
	font = "RobotoCondensed";
	sizeEx = FLO_FONT_SIZE;
};

class FLO_RscListBox: RscListBox
{
	colorText[] = FLO_COLOR_TEXT;
	colorBackground[] = FLO_COLOR_SURFACE;
	colorSelectBackground[] = FLO_COLOR_SELECT_BG;
	font = "RobotoCondensed";
	sizeEx = FLO_FONT_SIZE;
	rowHeight = "1.00 * GUI_GRID_H";
};

class FLO_RscCheckbox: RscCheckbox
{
	colorText[] = FLO_COLOR_TEXT;
	colorBackground[] = FLO_COLOR_INPUT_BG;
	colorTextSelect[] = FLO_COLOR_SUCCESS;
	font = "RobotoCondensed";
	sizeEx = FLO_FONT_SIZE;
};

class FLO_RscSlider: RscSlider
{
	color[] = FLO_COLOR_SURFACE;
	colorActive[] = FLO_COLOR_PRIMARY;
};

class FLO_RscProgress: RscProgress
{
	colorFrame[] = FLO_COLOR_BORDER;
	colorBar[] = FLO_COLOR_PRIMARY;
};

class FLO_RscProgress_Success: FLO_RscProgress
{
	colorBar[] = FLO_COLOR_SUCCESS;
};

class FLO_RscProgress_Warning: FLO_RscProgress
{
	colorBar[] = FLO_COLOR_WARNING;
};

class FLO_RscProgress_Danger: FLO_RscProgress
{
	colorBar[] = FLO_COLOR_DANGER;
};

// ============================================================================
// FLO CONTAINER CONTROLS
// ============================================================================

class FLO_RscControlsGroup: RscControlsGroup
{
	// Inherits scrollbar styling from base
};

class FLO_RscFrame: RscFrame
{
	colorText[] = FLO_COLOR_BORDER;
	sizeEx = FLO_FONT_SIZE_SM;
};

// ============================================================================
// FLO STRUCTURED TEXT
// ============================================================================

class FLO_RscStructuredText: RscStructuredText
{
	colorText[] = FLO_COLOR_TEXT;
	size = FLO_FONT_SIZE;
	class Attributes
	{
		font = "RobotoCondensed";
		color = "#FFFFFF";
		align = "left";
		shadow = 1;
	};
};

// ============================================================================
// FLO PICTURE VARIANTS
// ============================================================================

class FLO_RscPicture: RscPicture
{
	// Standard picture
};

class FLO_RscPictureKeepAspect: RscPictureKeepAspect
{
	// Picture with aspect ratio preserved
};

// ============================================================================
// FLO MAP
// ============================================================================

class FLO_RscMap: RscMap
{
	// Standard map control with default settings
};

// ============================================================================
// FLO TREE
// ============================================================================

class FLO_RscTree: RscTree
{
	colorText[] = FLO_COLOR_TEXT;
	colorBackground[] = FLO_COLOR_SURFACE;
	colorSelectBackground[] = FLO_COLOR_SELECT_BG;
	font = "RobotoCondensed";
	sizeEx = FLO_FONT_SIZE;
};
