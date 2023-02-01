# This Dockerfile is based on the last image from dockerpi
# It's just the VM image with a different compressed Raspbian fs img file
# generated from the carlosperate/rpi-os-custom-image repository

# This Dockerfile is based on the last image from dockerpi
# It's just the VM image with a different compressed Raspbian fs img file
# https://github.com/lukechilds/dockerpi/blob/6c1ac8edab988dca8bb36dddc5388e8c4123c824/Dockerfile

# The current lukechilds/dockerpi:vm has an issue uncompressing fs images
# larger than 1 GB, so it has been temporarily forked with the fix
# More info: https://github.com/lukechilds/dockerpi/pull/48
# FROM lukechilds/dockerpi:vm
FROM ghcr.io/carlosperate/dockerpi:vm-fix

LABEL org.opencontainers.image.authors="Mohamed Aly Amin <contact@mohamedalyamin.com>"
LABEL org.opencontainers.image.description="Docker image with Raspberry Pi OS running on QEMU + sensor simulation"
LABEL org.opencontainers.image.source="https://github.com/mohamed9974/rpi-os-custom-image-with-sensors"

# Select the GitHub tag from the release that hosts the OS files
# https://github.com/carlosperate/rpi-os-custom-image/releases/
ARG GH_TAG="v1.0"

# To build a different image type from the release the FILE_SUFFIX variable
# can be overwritten with the `docker build --build-arg` flag
ARG FILE_SUFFIX="autologin-ssh-expanded"

# This only needs to be changed if the releases filename format changes
ARG FILE_PREXIF="2022-04-04-raspios-buster-armhf-lite-mu.img"

ARG FILESYSTEM_IMAGE_URL="https://github.com/mohamed9974/rpi-os-custom-image-with-sensors/releases/download/"${GH_TAG}"/"${FILE_PREXIF}".zip"
ADD $FILESYSTEM_IMAGE_URL /filesystem.zip

# entrypoint.sh has been added in the parent lukechilds/dockerpi:vm
ENTRYPOINT ["/entrypoint.sh"]