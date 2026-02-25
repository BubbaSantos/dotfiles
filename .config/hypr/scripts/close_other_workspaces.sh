#!/bin/bash
current=$(hyprctl activeworkspace -j | jq '.id')
hyprctl clients -j | jq -r ".[] | select(.workspace.id != $current) | .address" | \
  while read addr; do
    hyprctl dispatch closewindow "address:$addr"
  done
