#!/bin/bash

#Released in GNU GPLv3 by OctaviaPone

#removes &amp; and eventuals " from strings
function normalize(){ #string
    TMP="${1/&amp;/&}"
    echo "${TMP/\"/}"
}

#fetch from 4chan
function chanfetch(){ #board, number, link
	inform "Download from 4chan started"
	wget -q -O - "http://boards.4chan.org/"$1"/thread/"$2 | grep $3 | awk -F"$3" '{
		for(i = 2; i <= NF; i++){
			split($i, tmp, "</");
			split(tmp[1], out, " ")
			print out[1]
		}
	}' | while read LINK ; do
		normalize $3/"${LINK/<wbr>/}"
	done | cut -d"<" -f1
}

#fetch from archives (generic)
function archfetch(){ #archive, board, number, link
    wget -q -O - "http://"$1"/"$2"/thread/"$3"/#"$3 | grep $4 | awk -F'<a href="'$4 '{
		for(i = 2; i <= NF; i++){
			split($i, out, "\"");
			print out[1]
		}
	}' | while read LINK ; do
		normalize $4/$LINK
	done
}

function plebfetch(){ #board, number, link
	inform "Download from 4plebs started"
	archfetch "archive.4plebs.org" $1 $2 $
}


function desufetch(){ #board, number, link
	inform "Download from desuarchive started"
	archfetch "desuarchive.org" $1 $2 $3
}

# -v function
function inform(){ #message
	if [ $VERBOSE ] ; then
		echo "[INFO] $1"
	fi
}

#debug level function
function debug(){ #message
	if [ $DEBUG ] ; then
		echo "[DEBUG] $1"
	fi
}

#stderr function
function error(){ #message
	>&2 echo "[ERROR] $1"
	if [ $GRAPHIC ] ; then
	    zenity --error --text "$1"
	fi
}

#check if zenity is installed
if command -v zenity > /dev/null ; then
	ZEN="YES"
	debug "Zenity found"
fi

#default is desuarchive
FROM="d"
#getopts cycle
while getopts 'b:n:s:hvf:gd' OPTION ; do
    case $OPTION in
	f)  #from what site to fetch
	    FROM=$OPTARG
	    FROMSET="YES"
	    ;;
        b)  #board
            BOARD=$OPTARG
            ;;
        n)  #number
            NUMBER=$OPTARG
            ;;
        s)  #type of link
            SITE=$OPTARG
            ;;
        h)  #help
            echo $(basename $0)
	    echo "Allows to download all links posted in a thread from either 4chan, desuarchive or the 4plebs archive. By default it fetchs from desuarchive. Remember to check if the given informations exists. Since this program returns links you can just pipe it with wget or an equivalent program to also download what you fetch. Easier way is probably $(basename $0) | while read LINK ; do wget "'$LINK'"; done"
	    echo -ne "Usage:\n-b <board>\tThe board to fetch\n-n <number>\tThe number of the thread\n-s <link>\tThe type of the link you want to fetch (exactly spelled as you want)\n-v\t\tVerbose mode\n-h\t\tThis help\n-f <flag>\tFrom what site to fetch (d = desuarchive, 4 = 4chan, p = 4plebs)\n-g\t\tSimulate a GUI with zenity\n-d\t\tDebug mode (prints verbose information and acts like -v too)\n"
	    echo -ne "\nExamples:\n\tFetches all youtube link from a thread from desuarchive\n\t\t$(basename $0) -b mlp -s https://www.youtube.com -n 32712841 -d 4 \n\tFetches all images posted in a thread on 4chan\n\t\t$(basename $0) -b mlp -s is2.4chan.org -n 32712841 -f 4\n"
            exit 0 ;;
	v)  #verbose
	    VERBOSE="YES"
	    ;;
	g)  #graphic
	    if [ $ZEN ] ; then
	    	GRAPHIC="YES"
    	    else
	    	error "You don't appear to have zenity installed"
		inform  "The script will be executed in CLI mode"
	    fi
	    ;;
	d) #debug
	    DEBUG="YES"
	    VERBOSE="YES"
	    debug "Debug mode"
	    ;; 
    esac
done

inform "Made by OctaviaPone with love"
inform "Released in GNU GPLv3"

[ $VERBOSE ] && debug "Verbose mode"
[ -z $FROMSET ] && debug "Default fetch mode"

#if -g was setted
#NOTE: eventual CLI arguments are preserved
if [ $GRAPHIC ] ; then
        if [ -z $BOARD ] ; then
             BOARD=$(zenity --entry --text "Insert the board code")
        fi      
        if [ -z $NUMBER ] ; then
             NUMBER=$(zenity --entry --text "Insert the number of the thread")
        fi
        if [ -z $SITE ] ; then
             SITE=$(zenity --entry --text "Insert the site you want to fetch")
        fi
	if [ -z $FROMSET ] ; then
	     FROM=$(zenity --list --column "Argument" --column "Site" d desuarchive p 4plebs 4 4chan --title="Choose from where to fetch")
     fi
fi

#small argument check
if [ -z $BOARD ] || [ -z $NUMBER ] || [ -z $SITE ] ; then
	error "Needs to specify then board, the number and the site you want to fetch"
	debug "Values setted at $BOARD, $NUMBER, $SITE"
	debug "Program terminated"
	exit 1
fi
#bigger argument check
if ! [[ $NUMBER =~ ^[0-9]+$ ]] ; then
	error "Thread number MUST be a number"
	debug "Input was $NUMBER"
	debug "program terminated"
	exit 2
fi

inform "Fetching from /$BOARD/ thread #$NUMBER"
inform "Selecting $SITE links"
inform "Target site set at $FROM"

#select from where to fetch
case $FROM in
	d)
		desufetch $BOARD $NUMBER $SITE
		;;
	4)	
		chanfetch $BOARD $NUMBER $SITE
		;;
	p)
		plebfetch $BOARD $NUMBER $SITE
		;;
	*)	
		error "invalid site flag"
		debug "Flag was $FROM"
		;;
esac

inform "Execution completed"
