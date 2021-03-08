#!/bin/sh
executable_name="valheim_server.x86_64"
# Whether or not to enable Doorstop. Valid values: TRUE or FALSE
export DOORSTOP_ENABLE=TRUE
# What .NET assembly to execute. Valid value is a path to a .NET DLL that mono can execute.
export DOORSTOP_INVOKE_DLL_PATH="${PWD}/BepInEx/core/BepInEx.Preloader.dll"
# Which folder should be put in front of the Unity dll loading path
export DOORSTOP_CORLIB_OVERRIDE_PATH=./unstripped_corlib

# ----- DO NOT EDIT FROM THIS LINE FORWARD  ------
doorstop_libs="${PWD}/doorstop_libs"
arch="x64"
executable_path="${PWD}/${executable_name}"
lib_postfix="so"

executable_type=`LD_PRELOAD="" file -b "${executable_path}"`;

doorstop_libname=libdoorstop_${arch}.${lib_postfix}
export LD_LIBRARY_PATH="${doorstop_libs}":${LD_LIBRARY_PATH}
export LD_PRELOAD=$doorstop_libname:$LD_PRELOAD
export DYLD_LIBRARY_PATH="${doorstop_libs}"
export DYLD_INSERT_LIBRARIES="${doorstop_libs}/$doorstop_libname"

export templdpath=$LD_LIBRARY_PATH
export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970

"${PWD}/${executable_name}" -name "${SERVERNAME}" -password "${PASSWORD}" -port "${PORT}" -world "${WORLDNAME}" -public "${PUBLIC}" -savedir "${SAVEDIR}"

export LD_LIBRARY_PATH=$templdpath