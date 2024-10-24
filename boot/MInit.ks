CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
print("Processeur prêt au lancement").
wait 1.

if status = "PRELAUNCH" {
copypath("0:/mission.ks", "").
copypath("0:/CORB.ks", "").
copypath("0:/BB.ks", "").
copypath("0:/SB.ks", "").
copypath("0:/NODEEXEC.ks", "").
copypath("0:/UTIL.ks", "").
copypath("0:/MSLA.ks", "").
copypath("0:/MSUI.ks", "").
run mission.

}
else {
    runpath("UTIL.ks").
    rebootInterruptionRoutine().
}