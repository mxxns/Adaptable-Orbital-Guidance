runpath("CORB.ks").
runpath("NODEEXEC.ks").
runpath("UTIL.ks").
runpath("MSLA.ks").
runpath("MSUI.ks").

from {local x is 20.} until x = 0 step {set x to x-1.} do {
  print "T -" + x.
}
Launch(true, true, true, 81, 90).
Circularisation().