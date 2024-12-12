runpath("CORB.ks").
runpath("BB.ks").
runpath("SB.ks").
runpath("UTIL.ks").
runpath("MSLA.ks").
runpath("MSUI.ks").

local deliveryLocation to latlng(0, 0).

wait until altitude > 3000.

preLaunchRoutine().
utilitiesRoutine(false).

boostBack(deliveryLocation).
suicideBurn(deliveryLocation, 0, 10).