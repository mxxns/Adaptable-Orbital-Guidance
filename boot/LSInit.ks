CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
print("Lowerstage online").

if status = "PRELAUNCH" {
copypath("0:/starship.ks", "").
copypath("0:/CORB.ks", "").
copypath("0:/BB.ks", "").
copypath("0:/SB.ks", "").
copypath("0:/UTIL.ks", "").
copypath("0:/MSLA.ks", "").
copypath("0:/MSUI.ks", "").
run starship.
}
else {
    runpath("UTIL.ks").
    rebootInterruptionRoutine().
}