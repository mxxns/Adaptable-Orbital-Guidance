runpath("CORB.ks").
runpath("NODEEXEC.ks").
runpath("UTIL.ks").
runpath("MSLA.ks").
runpath("MSUI.ks").

Launch(true, false, false, false, 80, 80, 0).
// pre-launch utilities(bool), logging(bool), utilities scripts(bool), CustomFairing(bool), apoapsis(km), periapsis(km), inclination(°), lift off angle(°), 45° at(km).
AscentKeep().
Circularisation().