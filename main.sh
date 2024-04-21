#!/bin/bash

set -e
root=$PWD
mkdir -p src
cd src

require() {
    if [ ! $1 $2 ]; then
        echo $3
    fi
}

require_file() { require -f $1 "File $1 required but not found"; }

require_executable() {
    require_file "$1"
    chmod +x "$1"
}

require_file "eula.txt"
require_file "server.properties"
require_file "server.jar"
require_executable "ngrok"

echo "Minecraft server starting" > $root/ip.txt

echo "Starting ngrok tunnel"
touch logs/ngrok.log
./ngrok --config ngrokConfig.yml start --all --log=stdout > ./logs/ngrok.log &

while ! grep -q "started tunnel" ./logs/ngrok.log; do sleep 1; done && echo "Started ngrok server"

orig_server_ip=$(grep -o 'tcp://[a-zA-Z0-9.]*\.ngrok.io:[0-9]*' ./logs/ngrok.log | sed 's/tcp:\/\///')
server_ip="${orig_server_ip:-Unavailable}"
echo "Server IP is: $server_ip"
echo "Server running on: $server_ip" > "$root/ip.txt"

echo "Starting server..."
java -Xmx5120M -Xms5120M -XX:+AlwaysPreTouch -XX:+DisableExplicitGC -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1HeapRegionSize=8M -XX:G1HeapWastePercent=5 -XX:G1MaxNewSizePercent=40 -XX:G1MixedGCCountTarget=4 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1NewSizePercent=30 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:G1ReservePercent=20 -XX:InitiatingHeapOccupancyPercent=15 -XX:MaxGCPauseMillis=200 -XX:MaxTenuringThreshold=1 -XX:SurvivorRatio=32 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true -jar server.jar nogui
echo "Exit code $?"