#!/bin/bash

INK=/Applications/Inkscape.app/Contents/Resources/bin/inkscape
IMAGEW=imagew

if [[ -z "$1" ]] 
then
	echo "SVG file needed."
	exit;
fi

BASE=`basename "$1" .svg`
SVG="$1"
MYPWD=`pwd`

# need to use absolute paths in OSX

$INK -z -D -e "$MYPWD/$BASE-29@2x.png" -f 	$MYPWD/$SVG -w 58 -h 58
$INK -z -D -e "$MYPWD/$BASE-29@3x.png" -f 	$MYPWD/$SVG -w 87 -h 87
$INK -z -D -e "$MYPWD/$BASE-40@2x.png" -f 	$MYPWD/$SVG -w 80 -h 80
$INK -z -D -e "$MYPWD/$BASE-40@3x.png" -f 	$MYPWD/$SVG -w 120 -h 120
$INK -z -D -e "$MYPWD/$BASE-60@2x.png" -f 	$MYPWD/$SVG -w 120 -h 120
$INK -z -D -e "$MYPWD/$BASE-60@3x.png" -f 	$MYPWD/$SVG -w 180 -h 180
$INK -z -D -e "$MYPWD/$BASE-1024.png" -f 	$MYPWD/$SVG -w 1024 -h 1024
$IMAGEW "$MYPWD/$BASE-1024.png" "$MYPWD/$BASE-1024-noalpha.png"
