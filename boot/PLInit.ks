copypath("0:/mission/payload.ks", "").
copypath("0:/CORB.ks", "").
copypath("0:/NODEEXEC.ks", "").
copypath("0:/UTIL.ks", "").
copypath("0:/MSLA.ks", "").
copypath("0:/MSUI.ks", "").

local partList to ship:parts.

set core:bootfilename to "payload.ks".
wait until ship:parts:length < (partList:length-4) and altitude > body:atm:height*0.5.
print ("Lowerstage separation").

run payload.