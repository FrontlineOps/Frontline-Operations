class UI {
    file = "\z\flo\addons\main\Functions\UI";

    class safeConfirm {};
};

class UICapture {
    file = "\z\flo\addons\main\Functions\UI\CaptureUI";

    class captureUI {};
    class initCaptureUIEvents {};
};

class UISetup {
    file = "\z\flo\addons\main\Functions\UI\Setup";

    class shouldOpenFactionDialog {};
    class openFactionDialog {};
    class factionDialogOnLoad {};
    class factionDialogOnUnload {};
    class factionDialogAddFactionItems {};
    class factionDialogAddItems {};
    class factionDialogBuildFactionHandle {};
    class factionDialogBuildGarrisonHandle {};
    class factionDialogBuildScalarHandle {};
    class factionDialogCreateObjectiveEdit {};
    class factionDialogCreateObjectiveGroupControls {};
    class factionDialogCreateObjectiveLabel {};
    class factionDialogCreateObjectiveSideControls {};
    class factionDialogFillCompositionDefaults {};
    class factionDialogGetSelection {};
    class factionDialogGetSelections {};
    class factionDialogJoinSelectionNames {};
    class factionDialogNormalizeMultiSelection {};
    class factionDialogPopulate {};
    class factionDialogSelectDefault {};
    class factionDialogShowCompositionTab {};
    class factionDialogStart {};
    class factionDialogValidateFactionSelections {};
};

class OperationsUI {
    file = "\z\flo\addons\main\Functions\UI\Operations";

    class operationsAddWebEventHandler {};
    class operationsBuildMapDrawData {};
    class operationsDrawMap {};
    class operationsFocusMap {};
    class operationsHandleMapClick {};
    class operationsHandleUiEvent {};
    class operationsInitClient { postInit = 1; };
    class operationsOpenDialog {};
    class operationsPreInit { preInit = 1; };
    class operationsReceiveSnapshot {};
    class operationsRequestSnapshot {};
    class operationsRestoreMapFocus {};
    class operationsSelectObjective {};
    class operationsUpdateDialog {};
    class operationsWebAction {};
};
