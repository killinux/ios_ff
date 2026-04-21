#!/bin/bash
cd "$(dirname "$0")"
pkill -f feed_server.py 2>/dev/null
sleep 1
nohup python3 feed_server.py 0.0.0.0 8085 > /tmp/feed.log 2>&1 &
echo $! > /tmp/feed.pid
echo "started pid $!"
