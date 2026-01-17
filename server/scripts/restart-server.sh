#!/bin/bash

# InfoDigest 服务器重启脚本

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
"$SCRIPT_DIR/stop-server.sh"
sleep 2
"$SCRIPT_DIR/start-server.sh"
