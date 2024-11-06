runpath("CORB.ks").
runpath("UTIL.ks").
runpath("NODEEXEC.ks").
runpath("MSLA.ks").
runpath("MSUI.ks").

set core:bootfilename to "payload.ks".

local partList to ship:parts.

wait until ship:parts:length < partList:length-2.

preLaunchRoutine().

CORE:PART:GETMODULE("kOSProcessor"):DOEVENT("Open Terminal").
print("Payload online").
wait 1.

AscentKeep().

Circularisation().