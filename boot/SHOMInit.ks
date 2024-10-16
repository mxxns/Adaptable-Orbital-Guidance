CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
print("Processeur prêt au lancement").
wait 1.

if status = "PRELAUNCH" {
copypath("0:/OM/SHOM.ks", "").
copypath("0:/OM/MSLA.ks", "").
copypath("0:/OM/MSUI.ks", "").
run SHOM.

}
else {
    runpath("SHOM.ks").
    rebootInterruptionRoutine().
}