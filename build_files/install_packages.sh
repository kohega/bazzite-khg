#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Install Howdy"

git clone https://github.com/boltgolt/howdy
cd /tmp/howdy

dnf install -y \
    git \
    python3-devel \
    cmake \
    gcc-c++ \
    pam-devel \
    inih-devel \
    opencv \
    opencv-devel \
    meson

meson setup build
meson compile -C build
meson install -C build

rm -rf /tmp/howdy
dnf remove -y \
    cmake \
    gcc-c++ \
    meson

log "Installing RPM packages"

# Install RPMs
for rpm_file in ctx/rpm/*.rpm; do
    if [ -f "$rpm_file" ]; then
        dnf5 install -y "$rpm_file"
    fi
done

log "Enable Copr repos"
COPR_REPOS=(
    ilyaz/LACT
    zliced13/YACR
    atim/heroic-games-launcher
    zeno/scrcpy
    lnvso/heroic-games-launcher
    principis/howdy-beta
)
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

log "Install layered applications"
# Layered Applications
LAYERED_PACKAGES=(
    aria2c
    kcalc
    konsole
    kate
    krename
    haruna
    okular
    gwenview
    ark
    syncthing
    filezilla
    firefox
    firefox-langpacks
    thunderbird
    naps2
    lact
    SDL2_ttf
    kget
    heroic-games-launcher-bin
    kodi
    kodi-inputstream-adaptive
    audacity
    bleachbit
    scrcpy
    virt-manager
    gh
    qbittorrent
    discord
    #python-elevate
    #python-keyboard
    #python-pyv4l2
    opencv
    opencv-devel
    v4l-utils
    #howdy
    xorg-x11-font-utils
    merkuro
    kdepim-runtime
    kdepim-addons
    akonadi  
)
dnf5 install --setopt=install_weak_deps=False --allowerasing --skip-unavailable --enable-repo="*rpmfusion*" -y "${LAYERED_PACKAGES[@]}"

# Install Citrix
/ctx/download-icaclient.sh
rpm -i --nodeps ICAClient-rhel-*.rpm
rm ICAClient-rhel-*.rpm

# Microsoft fonts    
rpm -i --nodigest --nodeps https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

log "Disable Copr repos as we do not need it anymore"

for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done

log "Installing ZeroTier"
# Add ZeroTier GPG key
curl -s https://raw.githubusercontent.com/zerotier/ZeroTierOne/master/doc/contact%40zerotier.com.gpg | tee /etc/pki/rpm-gpg/RPM-GPG-KEY-zerotier

# Add ZeroTier repository
cat << 'EOF' | tee /etc/yum.repos.d/zerotier.repo
[zerotier]
name=ZeroTier, Inc. RPM Release Repository
baseurl=http://download.zerotier.com/redhat/fc/42
enabled=1
gpgcheck=0
EOF

# Install ZeroTier
dnf install -y zerotier-one

# Remove repos
rm /etc/yum.repos.d/zerotier.repo -f
