runpath("CORB.ks").
runpath("BB.ks").
runpath("SB.ks").
runpath("NODEEXEC.ks").
runpath("UTIL.ks").
runpath("MSLA.ks").
runpath("MSUI.ks").


local function SBTest {
    wait until alt:radar > 200.

    stage. rcs on. brakes on.

    preLaunchRoutine().
    utilitiesRoutine().
    suicideBurn(KSCLaunchPad).
}

local function BBTestPlusSBTest {
    wait until alt:radar > 2000.

    stage. rcs on. brakes off.
    sas on.

    preLaunchRoutine().
    utilitiesRoutine().
    boostBack(KSCLaunchPad).
    brakes on.
    suicideBurn(KSCLaunchPad).
}

local function LaunchPlusBBPlusSBTest {
    rcs on.
    Launch().
    boostBack(KSCLaunchPad).
    brakes on.
    suicideBurn(KSCLaunchPad).
}

LaunchPlusBBPlusSBTest().

// BBTestPlusSBTest().

// SBTest().
