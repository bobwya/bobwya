# TODO write some simple tools/instructions:
# create desktop files
# extract icons (from .ico file)
# etc.

Manually install Doom 3 & Resurrection of Evil data files from your source medium.

1) Steam Library directory source:
	export DHEWM3_MOUNT="/usr/share/dhewm3"
	export STEAM_LIBRARY_ROOT_DIRECTORY=""
	for MOD in "base" "d3xp"; do
		mkdir -p "${DHEWM3_MOUNT}/${MOD}"
		rsync -achv --progress "${STEAMLIBRARY}/steamapps/common/Doom 3/${MOD}/*.pk4" "${DHEWM3_MOUNT}/${MOD}/"
	done

2) Steam Library directory systemd bind (auto)mount units:
	export DHEWM3_MOUNT="/usr/share/dhewm3"
	export STEAM_LIBRARY_ROOT_DIRECTORY=""
	export SYSTEMD_UNIT_DIRECTORY="/etc/systemd/system"
	for MOD in "base" "d3xp"; do
		export DHEWM3_SYSTEMD_UNIT="$(systemd-escape "${DHEWM3_MOUNT}/${MOD}")"
		export DHEWM3_SYSTEMD_UNIT="${DHEWM3_SYSTEMD_UNIT#-}"
		cat >"${SYSTEMD_UNIT_DIRECTORY}/${DHEWM3_SYSTEMD_UNIT}.mount" <<EOF_MOUNT_UNIT
[Unit]
Description=local partition mount ${STEAM_LIBRARY_ROOT_DIRECTORY}/steamapps/common/Doom 3/${MOD} @ ${DHEWM3_MOUNT}/${MOD} mount
Wants=local-fs.target
After=local-fs.target

[Mount]
What=${STEAM_LIBRARY_ROOT_DIRECTORY}/steamapps/common/Doom 3/${MOD}
Where=${DHEWM3_MOUNT}/${MOD}

[Mount]
Type=none
Options=bind
EOF_MOUNT_UNIT

		cat >"${SYSTEMD_UNIT_DIRECTORY}/${DHEWM3_SYSTEMD_UNIT}.automount" <<EOF_AUTOMOUNT_UNIT
[Unit]
Description=local partition automount ${STEAM_LIBRARY_ROOT_DIRECTORY}/steamapps/common/Doom 3/${MOD} @ ${DHEWM3_MOUNT}/${MOD} automount
Wants=local-fs.target
After=local-fs.target

[Automount]
Where=${DHEWM3_MOUNT}/${MOD}

[Install]
WantedBy=multi-user.target
EOF_AUTOMOUNT_UNIT

		systemctl daemon-reload
		systemctl enable "${SYSTEMD_UNIT_DIRECTORY}/${DHEWM3_SYSTEMD_UNIT}.automount"
	done

3) 	DVD Doom3 source (using app-arch/unshield):
	cd "${DVD_ROOT}"
	unshield -d "/usr/share/games/dhewm/" x data1.cab game00.pk4 pak000.pk4 pak001.pk4 pak002.pk4 pak003.pk4 pak004.pk4

	CD Resurrection of Evil source:
	rsync -achv --progress "${CD_ROOT}/Setup/Data/d3xp/*.pk4" "/usr/share/games/dhewm/d3xp/"
