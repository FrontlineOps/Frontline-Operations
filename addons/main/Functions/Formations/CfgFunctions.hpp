class FormationState {
    file = "\z\flo\addons\main\Functions\Formations\State";

    class formationCreateState {};
    class formationRebuildIndex {};
    class formationSerializeState {};
    class formationValidateState {};
};

class FormationCore {
    file = "\z\flo\addons\main\Functions\Formations\Core";

    class formationApplyRealGroupSkills {};
    class formationBuildName {};
    class formationBuildSnapshot {};
    class formationClassifyBranch {};
    class formationCreate {};
    class formationGetCombatMultiplier {};
    class formationGetRank {};
    class formationReconcile {};
    class formationRecordCombat {};
};

class FormationCommand {
    file = "\z\flo\addons\main\Functions\Formations\Command";

    class formationEvaluateSalientWithdrawal {};
    class formationProcessRoles {};
    class formationSelectDoctrine {};
    class formationStartExploitation {};
    class formationStartFeint {};
};

class FormationSystem {
    file = "\z\flo\addons\main\Functions\Formations\System";

    class formationInitialize {};
    class formationRegisterEvents {};
    class formationUpdate {};
};
