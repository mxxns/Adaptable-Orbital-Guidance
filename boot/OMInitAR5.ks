CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
wait 1.

if status = "PRELAUNCH" {
copypath("0:/OM/OMAR5.ks", "").
copypath("0:/OM/MSLA.ks", "").
copypath("0:/OM/MSUI.ks", "").
run OMAR5.

}
else {
    runpath("OMAR5.ks").
    rebootInterruptionRoutine().
}