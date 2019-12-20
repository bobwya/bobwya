#!/bin/env bash

APP_ROOT="/usr/share/filebot/lib"

if [[ -z "${HOME}" ]]; then
	echo 'HOME env variable must be set'
	exit 1
fi

# append APP_ROOT to LD_LIBRARY_PATH
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}${LD_LIBRARY_PATH:+:}${APP_ROOT}"

# select application data folder
APP_DATA="${HOME}/.filebot"

java -Dunixfs=false -DuseGVFS=true -DuseExtendedFileAttributes=true -DuseCreationDate=false -Djava.net.useSystemProxies=true -Djna.nosys=false -Djna.nounpack=true -Dapplication.deployment=deb -Dnet.filebot.gio.GVFS="${XDG_RUNTIME_DIR}/gvfs" -Dapplication.dir="${APP_DATA}" -Djava.io.tmpdir="${APP_DATA}/temp" -Dnet.filebot.AcoustID.fpcalc="/usr/bin/fpcalc" ${JAVA_OPTS} -jar "${APP_ROOT}/filebot.jar" "$@"
