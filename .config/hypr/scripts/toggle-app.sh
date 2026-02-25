#!/bin/bash

app_class="$1"
app_command="$2"

if hyprctl clients | grep -q "class: $app_class"; then
    hyprctl dispatch focuswindow "^($app_class)$"
else
    $app_command &
fi
```
