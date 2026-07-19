#!/usr/bin/bash

set ${SET_X:+-x} -eou pipefail

trap '[[ $BASH_COMMAND != echo* ]] && [[ $BASH_COMMAND != log* ]] && echo "+ $BASH_COMMAND"' DEBUG

log() {
  echo "=== $* ==="
}

log "Installing RPM packages"
for rpm_file in ctx/rpm/*.rpm; do
    if [ -f "$rpm_file" ]; then
        dnf5 install -y "$rpm_file"
    fi
done

log "Enabling COPR repos"
COPR_REPOS=(
    ilyaz/LACT
    zliced13/YACR
    atim/heroic-games-launcher
    #lnvso/heroic-games-launcher
    zeno/scrcpy
    pvermeer/sunshine
)
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr enable "$repo"
done

dnf5 -y install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm && \
dnf5 -y config-manager setopt "*rpmfusion*".priority=5 "*rpmfusion*".exclude="mesa-*" "*rpmfusion*".enabled=0 && \

# ZeroTier repo
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

# Gaze (facial-auth)
rpm --import https://packages.gundulabs.com/keys/gundulabs-repo.asc
tee /etc/yum.repos.d/gundulabs.repo >/dev/null <<'EOF'
[gundulabs]
name=Gundu Labs
baseurl=https://packages.gundulabs.com/rpm/fedora/$releasever/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.gundulabs.com/keys/gundulabs-repo.asc
EOF
dnf makecache

log "Install layered applications"
LAYERED_PACKAGES=(
    aria2c
    kcalc
    konsole
    krename
    haruna
    okular
    gwenview
    syncthing
    filezilla
    firefox
    firefox-langpacks
    thunderbird
    naps2
    lact
    SDL2_ttf
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
    python-elevate
    python-keyboard
    python-pyv4l2
    opencv
    v4l-utils
    xorg-x11-font-utils
    merkuro
    kdepim-runtime
    kdepim-addons
    akonadi
    lsp-plugins-lv2
    sunshine-beta
    zerotier-one
    gaze
    gaze-gui
)
dnf5 install --setopt=install_weak_deps=False --allowerasing --skip-unavailable --enable-repo="*rpmfusion*" -y "${LAYERED_PACKAGES[@]}"

log "Installing Citrix"
/ctx/download-icaclient.sh
rpm -i --nodeps ICAClient-rhel-*.rpm
rm ICAClient-rhel-*.rpm

log "Installing Microsoft fonts"    
rpm -i --nodigest --nodeps https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm

log "Disable COPR repos as we do not need it anymore"
for repo in "${COPR_REPOS[@]}"; do
    dnf5 -y copr disable "$repo"
done


rm /etc/yum.repos.d/zerotier.repo -f
