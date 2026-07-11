/*
 * FLO addon-local UI macros.
 *
 * Do not include BI 3DEN UI macro packs from addon config. Those defines can
 * leak into later preprocessed game scripts and collide with vanilla macros.
 */

#define GUI_GRID_WAbs           ((safezoneW / safezoneH) min 1.2)
#define GUI_GRID_HAbs           (GUI_GRID_WAbs / 1.2)
#define GUI_GRID_W              (GUI_GRID_WAbs / 40)
#define GUI_GRID_H              (GUI_GRID_HAbs / 25)
#define GUI_GRID_X              (safezoneX)
#define GUI_GRID_Y              (safezoneY + safezoneH - GUI_GRID_HAbs)

#define CT_STATIC               0
#define CT_BUTTON               1
#define CT_EDIT                 2
#define CT_SLIDER               3
#define CT_COMBO                4
#define CT_LISTBOX              5
#define CT_CHECKBOXES           7
#define CT_PROGRESS             8
#define CT_TREE                 12
#define CT_STRUCTURED_TEXT      13
#define CT_CONTROLS_GROUP       15
#define CT_XSLIDER              43
#define CT_OBJECT               80
#define CT_MAP                  100

#define ST_LEFT                 0x00
#define ST_CENTER               0x02
#define ST_MULTI                0x10
#define ST_PICTURE              0x30
#define ST_FRAME                0x40
#define ST_LINE                 0xB0
#define ST_SHADOW               0x100
#define ST_KEEP_ASPECT_RATIO    0x800

#define SL_HORZ                 0x400
#define LB_TEXTURES             0x10
#define LB_MULTI                0x20
#define TR_SHOWROOT             1
