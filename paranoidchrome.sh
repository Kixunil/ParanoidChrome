#!/bin/bash

if env | grep HOME &>/dev/null;
then
	env -i DISPLAY=$DISPLAY "$0" "$@" # strip environment variables to prevent information leaking
else
	# Default settings
	DISJAVASCRIPT=0	# Disable JavaScript
	DISJAVA=1	# Disable Java plugin
	DISPLUGINS=1	# Disable plugins
	INCOGNITO=1	# Use incognito mode (browser should be more careful about privacy)
	TOR=1		# Use Tor
	RANDUA=1	# Use random user-agent every time
	AUTOTORCHECK=1	# Automaticaly open chceck.torproject.org
	BROWSER=chromium-browser # or google-chrome
	TMPDIR=/dev/shm # basicaly RAMdisk

	# Parse parameters
	while [ $# -gt 0 ];
	do
		case $1 in
			--disable-images)
				CHROMEFLAGS="$CHROMEFLAGS --disable-images"
				;;
			--disable-incognito)
			       INCOGNITO=0
			       ;;
			--enable-incognito)
			       INCOGNITO=1
			       ;;
			--disable-tor)
				TOR=0
				AUTOTORCHECK=0
				;;
			--enable-tor)
				TOR=1
				AUTOTORCHECK=1
				;;
			--disable-tor-check)
				AUTOTORCHECK=0
				;;
			--enable-tor-check)
				AUTOTORCHECK=1
				;;
			--enable-javascript)
				DISJAVASCRIPT=0
				;;
			--disable-javascript)
				DISJAVASCRIPT=1
				;;
			--enable-java)
				DISJAVA=0
				;;
			--disable-java)
				DISJAVA=1
				;;
			--enable-plugins)
				DISPLUGINS=0
				;;
			--disable-plugins)
				DISPLUGINS=1
				;;
			--default-user-agent)
				RANDUA=0
				;;
			--random-user-agent)
				RANDUA=1
				;;
			--user-agent)
				UA="$2"
				RANDUA=0
				shift
				;;
			--proxy-server)
				PROXY="$2"
				shift
				;;
			--url)
				URL="$2"
				shift
				;;
			--temp-dir)
				TMPDIR="$2"
				shift
				;;
			--home-dir)
				HOMEDIR="$2"
				shift
				;;
			--flags) # additional arguments
				CHROMEFLAGS="$CHROMEFLAGS $2"
				shift
				;;
		esac

		shift
	done

	# Setup variables
	test $AUTOTORCHECK = 1 && OPENURL="http://check.torproject.org"
	test $INCOGNITO = 1 && CHROMEFLAGS="$CHROMEFLAGS --incognito"
	test $TOR = 1 && PROXYSERVER="http://localhost:8118"
	test -n "$PROXY" && PROXYSERVER="$PROXY" # overrides previous setting
	test -n "$PROXYSERVER" && CHROMEFLAGS="$CHROMEFLAGS --proxy-server=$PROXYSERVER"
	test $DISJAVASCRIPT = 1 && CHROMEFLAGS="$CHROMEFLAGS --disable-javascript"
	test $DISJAVA = 1 && CHROMEFLAGS="$CHROMEFLAGS --disable-java"
	test $DISPLUGINS = 1 && CHROMEFLAGS="$CHROMEFLAGS --disable-plugins"
	test $RANDUA = 1 && USERAGENT="`wget -O - 'http://www.user-agents.org/index.shtml?moz' | grep Mozilla | grep -v 'http://' | grep -vi 'bot' | shuf | head -1 | sed -re 's/^ *(.*)&nbsp;.*$/\1/'`"
	test -n "$UA" && USERAGENT="$UA"
	test -n "$USERAGENT" && USERAGENT="--user-agent=$USERAGENT"
	if [ -n "$HOMEDIR" ];
	then
		HOME="$HOMEDIR"
	else
		HOME="$(mktemp -d "$TMPDIR/paranoid.XXXXXXXXXXX")" || exit 1
	fi
	test -n "$URL" && OPENURL="$URL"

	# Setup environment
	export HOME
	cd "$HOME"
	
	# Run browser
	"$BROWSER" "$USERAGENT" $CHROMEFLAGS "$OPENURL"

	# Clean
	if [ -z "$HOMEDIR" ]; # if we've created temporary home directory
	then
		cd ..
		find "$HOME" -type f -exec shred -u '{}' ';' # overwrite data to remove footprint
		rm -rf "$HOME"
	fi
fi
