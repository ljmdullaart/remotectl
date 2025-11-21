#!/bin/bash

name="$1"
title="$2"

if [ ! -f "$name.keys" ] ; then
	echo "No keys file found for $name"
	exit
fi

if [ "$title" = "" ] ; then
	title="$name"
fi

rekey(){
	case $1 in
		(blue) 		echo '<div style="font-size:x-large;color:blue;">&#9632;</div>' ;;
		(channeldown)	echo '<div style="font-size:x-large;">&#8659;</div>' ;;
		(chan_down)	echo '<div style="font-size:x-large;">&#8659;</div>' ;;
		(channelup)	echo '<div style="font-size:x-large;">&#8657;</div>' ;;
		(chan_up)	echo '<div style="font-size:x-large;">&#8657;</div>' ;;
		(circle)	echo '<div style="font-size:x-large;">&#9711;</div>' ;;
		(down)		echo '<div style="font-size:xx-large;">&#9660;</div>' ;;
		(forward)	echo '<div style="font-size:x-large;">&#9654;&#9654;</div>' ;;
		(green) 	echo '<div style="font-size:x-large;color:green;">&#9632;</div>' ;;
		(left)		echo '<div style="font-size:x-large;">&#9664;</div>' ;;
		(next)		echo '<div style="font-size:xx-large;">&rarrb;</div>' ;;
		(pause)		echo '<div style="font-size:x-large;">&#8214;</div>' ;;
		(play)		echo '<div style="font-size:x-large;">&#9654;</div>' ;;
		(previous)	echo '<div style="font-size:xx-large;">&larrb;</div>' ;;
		(rec)		echo '<div style="font-size:x-large;color:red;">&#9673;</div>' ;;
		(record)	echo '<div style="font-size:x-large;color:red;">&#9673;</div>' ;;
		(red) 		echo '<div style="font-size:x-large;color:red;">&#9632;</div>' ;;
		(rewind)	echo '<div style="font-size:x-large;">&#9664;&#9664;</div>' ;;
		(right)		echo '<div style="font-size:x-large;">&#9654;</div>' ;;
		(scanback)	echo '<div style="font-size:x-large;">&#9664;&#9664;</div>' ;;
		(scanforward)	echo '<div style="font-size:x-large;">&#9654;&#9654;</div>' ;;
		(skipback)	echo '<div style="font-size:xx-large;">&larrb;</div>' ;;
		(skipforward)	echo '<div style="font-size:xx-large;">&rarrb;</div>' ;;
		(stop)		echo '<div style="font-size:xx-large;">&#9632;</div>' ;;
		(up)		echo '<div style="font-size:xx-large;">&#9650;</div>' ;;
		(volumedown)	echo '<div style="font-size:xx-large;">&#128264;&#9660;</div>' ;;
		(volume_down)	echo '<div style="font-size:xx-large;">&#128264;&#9660;</div>' ;;
		(volumeup)	echo '<div style="font-size:xx-large;">&#128264;&#9650;</div>' ;;
		(volume_up)	echo '<div style="font-size:xx-large;">&#128264;&#9650;</div>' ;;
		(yellow) 	echo '<div style="font-size:x-large;color:yellow;">&#9632;</div>' ;;
		(*)		echo $1 ;;
		
	esac
}
cat > "$name.html" <<EOF
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="icon" href="https://public-frontend-cos.metadl.com/mgx/img/favicon.png" type="image/png">
    <title>IR Remote Control</title>
    <link rel="stylesheet" href="./style.css">
</head>

<body>
    <div class="container">
        <div class="scripts-section">
EOF

echo "            <h2>$title</h2>" >>"$name.html"

intable=0
inrow=0

cat "$name.keys" | while read keyline ; do
	key=${keyline%% *}
	descr=${keyline#* }
	ir="${name}__${key}_"
	if [ "$key" = "" ] ; then
		:
	elif [ "$key" = "->" ] ; then
		other=${descr%%__*}
		otherkey=${descr#*__}
		otherkey=${otherkey%_}
		otherdisp=$(rekey $otherkey)
		if [ $intable = 0 ] ; then
			echo '<table class="remote-table">' >>"$name.html"
			intable=1
		fi
		if [ $inrow = 0 ] ; then
			echo '<tr>' >>"$name.html"
			inrow=1
		fi
                echo "<td><button class=\"ir-button\" id=\"input\" onclick=\"sendCommand('$descr')\">$otherdisp</button></td>" >> "$name.html"
		inrow=1
		intable=1

	elif [ "$key" = "##" ] ; then
		if [ $inrow = 1 ] ; then
			echo '</tr>' >>"$name.html"
			inrow=0
		fi
		if [ $intable = 1 ] ; then
			echo '</table>' >>"$name.html"
			intable=0
		fi
		echo "<h2>$descr</h2>" >> "$name.html"
		echo '<table class="remote-table">' >>"$name.html"
		intable=1
		echo '<tr>' >>"$name.html"
		inrow=1
	elif [ "$key" = "#" ] ; then
		if [ "$descr" = "#" ] ; then descr='' ; fi
		if [ $intable = 0 ] ; then
			echo '<table class="remote-table">' >>"$name.html"
			intable=1
		fi
		if [ $inrow = 0 ] ; then
			echo '<tr>' >>"$name.html"
			inrow=1
		fi
		echo "<td><h2>$descr</h2></td>" >> "$name.html"
	elif [ "$key" = "===" ] ; then
		if [ $inrow = 1 ] ; then
			echo '</tr>' >>"$name.html"
			inrow=0
		fi
		if [ $intable = 1 ] ; then
			echo '</table>' >>"$name.html"
			intable=0
		fi
		echo '<table class="remote-table">' >>"$name.html"
		intable=1
		echo '<tr>' >>"$name.html"
		inrow=1
	elif [ "$key" = '---' ] ; then
		if [ $intable = 0 ] ; then
			echo '<table class="remote-table">' >>"$name.html"
			intable=1
		fi
		if [ $inrow = 1 ] ; then
			echo '</tr>' >>"$name.html"
			inrow=0
		fi
		echo '<tr>' >>"$name.html"
		inrow=1
	elif [ -f ir/$ir.ir ] ; then
		if [ $intable = 0 ] ; then
			echo '<table class="remote-table">' >>"$name.html"
			intable=1
		fi
		if [ $inrow = 0 ] ; then
			echo '<tr>' >>"$name.html"
			inrow=1
		fi
		descr=$(rekey $descr)
                echo "<td><button class=\"ir-button\" id=\"input\" onclick=\"sendCommand('$ir')\">$descr</button></td>" >> "$name.html"
		inrow=1
		intable=1
	else
		echo "Unknown $key $ir"
	fi

done

echo '</tr>' >>"$name.html"
echo '</table>' >>"$name.html"
cat >> "$name.html" <<EOF
        </div>

        <div class="output-section">
            <h2>Output</h2>
            <div id="output" class="output-box">
                <p class="placeholder">Command output will appear here...</p>
            </div>
        </div>
    </div>
    <script type="module" src="./script.js"></script>
</body>

</html>
EOF
