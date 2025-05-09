#!/bin/sh
export DOORSTOP_ENABLE=TRUE
export DOORSTOP_INVOKE_DLL_PATH=./BepInEx/core/BepInEx.Preloader.dll
# Valheim no longer runs with a stripped corelib, so this isn't needed
# export DOORSTOP_CORLIB_OVERRIDE_PATH=./unstripped_corlib

export LD_LIBRARY_PATH="./doorstop_libs:$LD_LIBRARY_PATH"
export LD_PRELOAD="libdoorstop_x64.so:$LD_PRELOAD"

export LD_LIBRARY_PATH="./linux64:$LD_LIBRARY_PATH"
export SteamAppId=892970
# NOTE: Minimum password length is 5 characters & Password cant be in the server name.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
exec ./valheim_server.x86_64 -nographics -batchmode -name "${SERVERNAME}" -password "${PASSWORD}" -port "${PORT}" -world "${WORLDNAME}" -public "${PUBLIC}" -savedir "${SAVEDIR}" -saveinterval "${WORLDSAVEINTERVAL}" ${FLAGARGS}