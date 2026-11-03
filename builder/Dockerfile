FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install essential Debian ISO creation tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    debootstrap \
    squashfs-tools \
    xorriso \
    grub-pc-bin \
    grub-efi-amd64-bin \
    mtools \
    dosfstools \
    isolinux \
    syslinux-common \
    binutils \
    ca-certificates \
    curl \
    wget \
    rsync \
    xz-utils \
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash", "/workspace/builder/run-builder.sh"]
