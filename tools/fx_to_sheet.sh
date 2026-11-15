#!/usr/bin/env bash
set -uo pipefail

MAX_TEXTURE_SIZE=16384
ALPHA_CUTOFF=0.02
CORNER_TOLERANCE=4

if [ $# -eq 0 ]; then
	echo "usage: $0 <file-or-folder>..." >&2
	exit 1
fi

median() {
	sort -n | awk '{a[NR]=$1} END{if (NR) print a[int((NR+1)/2)]; else print 0}'
}

corner_rgba() {
	ffmpeg -v error -i "$1" -vf "format=rgba,crop=1:1:$2:$3" -f rawvideo -pix_fmt rgba - | xxd -p
}

channel_alpha() {
	local c="$1" v="$2" light="$3"
	if [ "$light" = 1 ]; then
		echo "if(lt($c(X,Y),$v),($v-$c(X,Y))/$(( v > 0 ? v : 1 )),0)"
	else
		echo "if(gt($c(X,Y),$v),($c(X,Y)-$v)/$(( 255 - v > 0 ? 255 - v : 1 )),0)"
	fi
}

process() {
	local src="$1"
	local out="${src%.*}.png"
	local name
	name=$(basename "$src")
	local tmp
	tmp=$(mktemp -d)
	local delay=0

	case "$src" in
		*.webp)
			local info
			info=$(webpmux -info "$src" 2>/dev/null)
			if echo "$info" | grep -q "Number of frames"; then
				local count
				count=$(echo "$info" | awk '/Number of frames/ {print $4}')
				for i in $(seq 1 "$count"); do
					webpmux -get frame "$i" "$src" -o "$tmp/frame.webp" >/dev/null 2>&1 \
						&& dwebp -quiet "$tmp/frame.webp" -o "$(printf '%s/f%04d.png' "$tmp" "$i")"
				done
				rm -f "$tmp/frame.webp"
				delay=$(echo "$info" | awk '$1 ~ /^[0-9]+:$/ {print $7}' | median)
			else
				dwebp -quiet "$src" -o "$tmp/f0001.png"
			fi
			;;
		*.gif)
			ffmpeg -v error -i "$src" -vsync 0 -pix_fmt rgba "$tmp/f%04d.png"
			delay=$(ffprobe -v error -select_streams v:0 -show_entries frame=pkt_duration_time -of csv=p=0 "$src" \
				| awk '{print int($1 * 1000 + 0.5)}' | median)
			;;
		*)
			rm -rf "$tmp"
			return
			;;
	esac

	local n
	n=$(find "$tmp" -name 'f*.png' | wc -l | tr -d ' ')
	if [ "$n" -eq 0 ]; then
		echo "SKIP $name: could not read frames"
		rm -rf "$tmp"
		return
	fi

	local wh w h
	wh=$(ffprobe -v error -show_entries stream=width,height -of csv=p=0 "$tmp/f0001.png")
	w=${wh%,*}
	h=${wh#*,}

	local corners=()
	corners+=("$(corner_rgba "$tmp/f0001.png" 0 0)")
	corners+=("$(corner_rgba "$tmp/f0001.png" $((w - 1)) 0)")
	corners+=("$(corner_rgba "$tmp/f0001.png" 0 $((h - 1)))")
	corners+=("$(corner_rgba "$tmp/f0001.png" $((w - 1)) $((h - 1)))")

	local transparent=0 bg=""
	for c in "${corners[@]}"; do
		[ $((16#${c:6:2})) -lt 16 ] && transparent=$((transparent + 1))
	done
	if [ "$transparent" -lt 3 ]; then
		for c in "${corners[@]}"; do
			local matches=0
			for d in "${corners[@]}"; do
				local dr=$((16#${c:0:2} - 16#${d:0:2})) dg=$((16#${c:2:2} - 16#${d:2:2})) db=$((16#${c:4:2} - 16#${d:4:2}))
				if [ ${dr#-} -le $CORNER_TOLERANCE ] && [ ${dg#-} -le $CORNER_TOLERANCE ] && [ ${db#-} -le $CORNER_TOLERANCE ]; then
					matches=$((matches + 1))
				fi
			done
			if [ "$matches" -ge 3 ]; then
				bg=$c
				break
			fi
		done
		if [ -z "$bg" ]; then
			echo "SKIP $name: no solid background color"
			rm -rf "$tmp"
			return
		fi
	fi

	local cols=$((MAX_TEXTURE_SIZE / w))
	[ "$cols" -gt "$n" ] && cols=$n
	if [ "$cols" -lt 1 ]; then
		echo "SKIP $name: frame too wide"
		rm -rf "$tmp"
		return
	fi
	local rows=$(((n + cols - 1) / cols))
	if [ $((rows * h)) -gt "$MAX_TEXTURE_SIZE" ]; then
		echo "SKIP $name: too many frames for one sheet"
		rm -rf "$tmp"
		return
	fi

	local vf="format=rgba"
	local mode="already transparent"
	if [ -n "$bg" ]; then
		local r0=$((16#${bg:0:2})) g0=$((16#${bg:2:2})) b0=$((16#${bg:4:2}))
		local light=0
		[ $((r0 + g0 + b0)) -ge 384 ] && light=1
		local a="max(max($(channel_alpha r "$r0" $light),$(channel_alpha g "$g0" $light)),$(channel_alpha b "$b0" $light))"
		local keep="gt(ld(0),$ALPHA_CUTOFF)"
		vf="$vf,geq=a='st(0,$a);255*clip((ld(0)-$ALPHA_CUTOFF)/(1-$ALPHA_CUTOFF),0,1)'"
		vf="$vf:r='st(0,$a);if($keep,clip($r0+(r(X,Y)-$r0)/ld(0),0,255),0)'"
		vf="$vf:g='st(0,$a);if($keep,clip($g0+(g(X,Y)-$g0)/ld(0),0,255),0)'"
		vf="$vf:b='st(0,$a);if($keep,clip($b0+(b(X,Y)-$b0)/ld(0),0,255),0)'"
		mode="removed #${bg:0:6}"
	fi
	vf="$vf,tile=${cols}x${rows}:color=0x00000000"

	if ffmpeg -v error -y -i "$tmp/f%04d.png" -vf "$vf" -frames:v 1 "$out"; then
		echo "OK $(basename "$out") frame=${w}x${h} frames=$n grid=${cols}x${rows} delay=${delay}ms ($mode)"
	else
		echo "SKIP $name: ffmpeg failed"
	fi
	rm -rf "$tmp"
}

for arg in "$@"; do
	if [ -d "$arg" ]; then
		for f in "$arg"/*.gif "$arg"/*.webp; do
			[ -e "$f" ] && process "$f"
		done
	else
		process "$arg"
	fi
done
