runpath("CORB.ks").
runpath("UTIL.ks").
runpath("NODEEXEC.ks").
runpath("MSLA.ks").
runpath("MSUI.ks").

preLaunchRoutine().
stagingInterruptionRoutine().
utilitiesRoutine().

CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
UI("Payload online", "", "", "").
set STR to prograde.
set THR to 0.2.
wait 3.
set THR to 0.
if (status = "SUB_ORBITAL" or status = "FLYING") if periapsis < 0 {
    Circularisation().
}