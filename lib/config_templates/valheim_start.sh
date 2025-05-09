export LD_LIBRARY_PATH=./linux64:$LD_LIBRARY_PATH
export SteamAppId=892970
# NOTE: Minimum password length is 5 characters & Password cant be in the server name.
# NOTE: You need to make sure the ports 2456-2458 is being forwarded to your server through your local router & firewall.
exec ./valheim_server.x86_64 -nographics -batchmode -name "$SERVERNAME" -port $PORT -world "$WORLDNAME" -password "$PASSWORD" -savedir "$SAVEDIR" -saveinterval "${WORLDSAVEINTERVAL}" ${FLAGARGS}