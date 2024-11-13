copypath("0:/mission/payload.ks", "").
copypath("0:/CORB.ks", "").
copypath("0:/NODEEXEC.ks", "").
copypath("0:/UTIL.ks", "").
copypath("0:/MSLA.ks", "").
copypath("0:/MSUI.ks", "").

local partList to ship:parts.

wait until ship:parts:length < partList:length-2.
set core:bootfilename to "payload.ks".
print ("Lowerstage separation").

run payload.