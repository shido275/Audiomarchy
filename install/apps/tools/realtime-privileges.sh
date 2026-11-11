#!/bin/bash
# pack: core
# Realtime privileges — the 'realtime' group and memlock/rtprio limits.
source "$AUDIOMARCHY_INSTALL/helpers/pkg.sh"
au_pkg_add realtime-privileges
