#!/bin/sh

# This script aims to reuse same bootstrap init for all known volumes
# Goal is to create them as nuxeo user, and ensure fixuid will change persmission
read -r -d '' VOLUMES <<-'EOS'
/home/nuxeo/.m2
/home/nuxeo/.m2/repository
/home/nuxeo/workspace
/home/nuxeo/.vscode-server
/home/nuxeo/.vscode-server/extensions
/home/nuxeo/.vscode-server-insiders
/home/nuxeo/.vscode-server-insiders/extensions
EOS

for VOLUME in ${VOLUMES}; do
  # Create directory as nuxeo
  install -d -o nuxeo -g nuxeo -m 775 "${VOLUME}"
  # Append directory to fixuid config file
  echo " - ${VOLUME}" >>/etc/fixuid/config.yml
done

# Remove useless groups
read -r -d '' GRPS <<-'EOS'
wheel
cdrom
dialout
floppy
games
tape
video
lock
audio
EOS
for GRP in ${GRPS}; do groupdel "$GRP"; done
