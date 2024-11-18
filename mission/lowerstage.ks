runpath("CORB.ks").
runpath("UTIL.ks").
runpath("MSLA.ks").
runpath("MSUI.ks").
runpath("SB.ks").
runpath("BB.ks").

set core:bootfilename to "lowerstage.ks".
preLaunchRoutine().
utilitiesRoutine().
set fairingD to true.

if status = "PRELAUNCH" {
    Launch(false, false, false).
    stage.
    local tZ to time:seconds.
    until time:seconds >= tZ + 4 { 
        if time:seconds < tZ + 2 set ship:control:starboard to -1.
        else set ship:control:starboard to 0.
        set ship:control:fore to -1.
        wait 0.2.
    }
}

set ship:control:fore to 0.
kuniverse:forcesetactivevessel(ship).
boostBack(KSCLaunchPad).
brakes on.
suicideBurn(KSCLaunchPad).