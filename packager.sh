#!/bin/bash

# Spin up a build container
podman run \
  --pull always \
  --userns keep-id \
  --detach \
  --name aur \
  --rm \
  --volume /opt/media/git:/git \
  docker.io/library/archlinux sleep 800

# Update library packages and install required packages (root)
podman exec \
  --user 0 \
  --tty \
  --interactive \
  aur \
  /bin/bash -c 'pacman -Sy && pacman --noconfirm -Su && pacman --noconfirm -S git binutils fakeroot sudo python debugedit'

# Update packages: client and server
podman exec \
  --user 1000:1000 \
  --tty \
  --interactive \
  --env GIT_AUR_PATH=/git/aur \
  aur \
    /bin/bash -c 'cd /git/sft-aur/ && ./sft_track.sh -c && ./sft_track.sh -s'
 
# Update url package, but first install it's dependencies
podman exec \
  --user 0 \
  --tty \
  --interactive \
  aur \
  /bin/bash -c 'pacman --noconfirm -U $( ls -t /git/aur/scaleft-client-tools-bin/scaleft-client-tools-*.zst |head -1 )'

# Update URL
podman exec \
  --user 1000:1000 \
  --tty \
  --interactive \
  --env GIT_AUR_PATH=/git/aur \
  aur \
    /bin/bash -c 'cd /git/sft-aur/ && ./sft_track.sh -u'

