#!/bin/bash
makoctl mode | sed 's/do-not-disturb/dnd-active/; s/default/dnd-inactive/'
