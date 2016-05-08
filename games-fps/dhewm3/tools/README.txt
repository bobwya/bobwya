# TODO write some simple tools/instructions:
# create desktop files
# extract icons (from .ico file)
# etc.

Manually install Doom 3 data files from your source medium.
1) Steam Library folder source:
 rsync -achv --progress "${STEAMLIBRARY}/steamapps/common/Doom 3/base/*.pk4" "/usr/share/games/dhewm/"
2) DVD source (using app-arch/unshield):
 cd "${DVD_ROOT}"
 unshield -d "/usr/share/games/dhewm/" x data1.cab game00.pk4 pak000.pk4 pak001.pk4 pak002.pk4 pak003.pk4 pak004.pk4

(Optional) Manually install Resurrection of Evil data files from your source medium.
1) Steam Library folder source:
 rsync -achv --progress "${STEAMLIBRARY}/steamapps/common/Doom 3/d3xp/*.pk4" "/usr/share/games/dhewm/d3xp/"
2) CD source:
 rsync -achv --progress "${CD_ROOT}/Setup/Data/d3xp/*.pk4" "/usr/share/games/dhewm/d3xp/"

