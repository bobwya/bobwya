#!/bin/bash
java -Dunixfs=false -Xmx256m -Dapplication.deployment=Portage -Dapplication.dir=$HOME/.filebot -Djava.io.tmpdir=$HOME/.filebot/temp -Djna.library.path=/opt/filebot -Djava.library.path=/opt/filebot -Dsun.net.client.defaultConnectTimeout=5000 -Dsun.net.client.defaultReadTimeout=25000 -jar /opt/filebot/FileBot.jar "$@"
