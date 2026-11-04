
install-system-flatpaks:
    #!/usr/bin/bash
    set -euo pipefail
    FLATPAK_LIST="$(tr '\n' ' ' < /usr/share/kohega/flatpaks)"
    flatpak --system -y install ${FLATPAK_LIST}

install-appimages:
    #!/usr/bin/env bash
    set -euo pipefail

    DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-${HOME}/Downloads}"
    [ ! -d "$DOWNLOAD_DIR" ] && DOWNLOAD_DIR="$HOME"

    # Install Gear Lever if not installed
    flatpak list | grep -q "it.mijorus.gearlever" || flatpak --user -y install it.mijorus.gearlever

    while IFS=, read -r name url; do
      [ -z "$name" -o -z "$url" ] && continue
      echo "Processing $name..."

      # Skip if installed
      if flatpak run it.mijorus.gearlever --list-installed | grep -qi "$name"; then
        echo "$name already installed"
        continue
      fi

      # Initialize variables for update source
      repo=""
      release_file_pattern=""

      # Handle GitHub URLs
      if [[ "$url" =~ github.com/([^/]+/[^/]+)/releases/download/ ]]; then
        repo="${BASH_REMATCH[1]}"
        # Extract the release file pattern from the URL
        release_file_pattern=$(echo "$url" | grep -oE '[^/]+$' | sed 's/\*/\*/g')
        # Resolve wildcard URL for GitHub
        if [[ "$url" == *"*"* ]]; then
          pattern=$(echo "$release_file_pattern" | sed 's/\./\\./g; s/\*/.*/g')
          assets_url="https://api.github.com/repos/$repo/releases"
          url=$(curl -sL -H "User-Agent: kohega-appimage-installer" "$assets_url" | \
                jq -r ".[].assets[].browser_download_url" | \
                grep -E "$pattern" | \
                head -n1)
          [ -z "$url" ] && { echo "No matching release found for $name"; continue; }
        fi
      fi

      # Download and install
      appimage="$DOWNLOAD_DIR/${name}.AppImage"
      if aria2c --dir="$(dirname "$appimage")" --out="$(basename "$appimage")" --max-tries=3 --connect-timeout=30 "$url" && \
        chmod +x "$appimage" && \
        flatpak run it.mijorus.gearlever --integrate "$appimage" -y; then
        echo "$name integrated successfully."

        # Find the AppImage path in Gear Lever's Applications directory
        app_path="${HOME}/Applications/${name}.appimage"

        # Set update source for GitHub AppImages
        if [ -n "$repo" ] && [ -n "$release_file_pattern" ]; then
          echo "Setting update source for $name..."
          flatpak run it.mijorus.gearlever --set-update-source "$app_path" \
            --manager GithubUpdater \
            repo="$repo" \
            repo_filename="$release_file_pattern" \
            allow_prereleases=false
          echo "Update source configured for $name."
        else
          echo "No update source configured for $name (not a GitHub AppImage)."
        fi
      else
        echo "Failed to install $name"
      fi
      rm -f "$appimage"
    done < /usr/share/kohega/appimages

    echo "AppImages installation and update source configuration complete."
    echo "Restart Gear Lever GUI to see the changes."

# Restart Bluetooth to fix issues
fix-bt:
    #!/usr/bin/env bash
    set -euo pipefail
    trap '[[ $BASH_COMMAND != echo* ]] && echo "+ $BASH_COMMAND"' DEBUG

    echo "Fixing Bluetooth..."
    sudo rfkill unblock all
    sudo rmmod btusb
    sudo modprobe btusb
    echo "Bluetooth fix complete."

# Restart Webcam to fix issues
fix-webcam:
    #!/usr/bin/env bash
    set -euo pipefail
    trap '[[ $BASH_COMMAND != echo* ]] && echo "+ $BASH_COMMAND"' DEBUG

    echo "Fixing Webcam..."
    sudo rmmod uvcvideo
    sudo modprobe uvcvideo
    echo "Webcam fix complete."

# Clean up old packages and container images
clean:
    #!/usr/bin/env bash
    # Pas de -e : une commande en échec ne doit pas bloquer les suivantes
    set -uo pipefail

    echo "Cleaning up system..."
    for engine in docker podman; do
        command -v "$engine" > /dev/null || continue
        "$engine" image prune -af
        sudo "$engine" image prune -af
    done
    flatpak uninstall --unused -y
    rpm-ostree cleanup -bm
    if command -v nix-collect-garbage > /dev/null; then
        nix-collect-garbage -d
        sudo -i nix-collect-garbage -d
    fi

# Enable AMD GPU overclocking capability. This can then be changed in for example LACT.
enable-amdgpu-oc:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Enabling AMD GPU overclocking"

    if ! rpm-ostree kargs | grep -q "amdgpu.ppfeaturemask="; then
      echo "Updating rpm-ostree kernel arguments"
      sudo rpm-ostree kargs --append "amdgpu.ppfeaturemask=0xFFF7FFFF"
    else
      echo "Already enabled"
    fi

# Add a Virtual Display from a EDID file
virtual-display:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Enabling Virtual Dummy Display"

    if ! rpm-ostree kargs | grep -q "drm.edid_firmware="; then
      echo "Updating rpm-ostree kernel arguments"
      sudo rpm-ostree kargs --append "drm.edid_firmware=HDMI-A-1:edid/dummy-new-2026-latest.bin video=HDMI-A-1:e"
    else
      echo "Already enabled"
    fi

# Add drives
setup-fstab:
    #!/usr/bin/env bash
    set -euo pipefail

    sudo cp /etc/fstab /etc/fstab.bak
    add_entry() {
        local key="$1"; shift
        if grep -qF -- "$key" /etc/fstab; then
            echo "Déjà présent : $key"
        else
            printf '%s\n' "$@" | sudo tee -a /etc/fstab > /dev/null
            echo "Ajouté : $key"
        fi
    }

    add_entry "92a4365b-522a-4375-a054-3d8f1e85f8d9" \
        "" \
        "#DATA" \
        "UUID=92a4365b-522a-4375-a054-3d8f1e85f8d9   /data       btrfs   rw,noatime,lazytime,commit=120,compress-force=zstd:2,ssd,exec,space_cache=v2   0 0"

    add_entry "e2231536-a24b-428e-9f8c-ea456d43cb88" \
        "" \
        "#VIDEOS" \
        "UUID=e2231536-a24b-428e-9f8c-ea456d43cb88   /videos     xfs   defaults,noatime,nofail   0 0"

    add_entry "192.168.6.254" \
        "" \
        "#FREEBOX" \
        '//192.168.6.254/Disque\040dur/  /freebox cifs _netdev,nofail,noauto,rw,iocharset=utf8,uid=kohega,credentials=/home/kohega/.config/.freeboxcredentials,file_mode=0660,dir_mode=0775 0 0'

    for d in /data /videos /freebox; do
        [ -d "$d" ] || echo "ATTENTION : le point de montage $d n'existe pas"
    done

    sudo systemctl daemon-reload
    sudo mount /data || echo "Montage de /data impossible"
    sudo mount /videos || echo "Montage de /videos impossible"
    echo "Fstab à jour."

install-spotx:
    #!/usr/bin/env bash
    set -euo pipefail
    
    flatpak run com.spotify.Client &
    sleep 5
    flatpak kill com.spotify.Client || true
    bash <(curl -fsSL https://spotx-official.github.io/run.sh)

install-discord-rpc:
    git clone https://github.com/Arcitec/discord-flatpak-rpc-bridge.git /tmp/discord-rpc
    cd /tmp/discord-rpc && chmod +x install.sh && ./install.sh

setup-sudoers:
    #!/usr/bin/env bash
    set -euo pipefail

    echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/shutdown, /usr/sbin/reboot, /usr/bin/screenprofilercmd, /usr/bin/screenprofilerback, /usr/bin/screenprofilerswap" | sudo tee /etc/sudoers.d/"$USER" >/dev/null

    sudo chmod 440 /etc/sudoers.d/"$USER"
    sudo visudo -cf /etc/sudoers.d/"$USER"

# Configure SSH port privately
setup-ssh:
   #!/usr/bin/env bash
    set -euo pipefail

    SSH_PORT=$(awk '/^[[:space:]]*Port[[:space:]]+/ {print $2; exit}' ~/.ssh/config)

    if [[ ! "$SSH_PORT" =~ ^[0-9]+$ ]]; then
        echo "SSH port not found in ~/.ssh/config"
        exit 1
    fi

    sudo sed -i -E "s/^[#[:space:]]*Port[[:space:]].*/Port $SSH_PORT/" /etc/ssh/sshd_config
    sudo semanage port -a -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || \
        sudo semanage port -m -t ssh_port_t -p tcp "$SSH_PORT"

    sudo sshd -t
    sudo systemctl restart sshd

# Restore main PC
restore-khg: install-system-flatpaks
    #!/usr/bin/env bash
    set -euo pipefail
    command -v chezmoi >/dev/null || brew install chezmoi
    gh auth login
    
    chezmoi init --apply kohega/dotfiles
    
    sudo loginctl enable-linger kohega
    sudo usermod -aG kvm,libvirt kohega
    sudo setsebool -P container_use_dri_devices 1
    sudo setsebool -P samba_enable_home_dirs 1
    sudo timedatectl set-local-rtc '0'
    sudo systemctl disable NetworkManager-wait-online.service
    systemctl disable --now --user ntfs-nag.service
    sudo systemctl enable --now sshd lactd smb
    systemctl --user enable --now ydotoold.service
    systemctl mask --now --user ntfs-nag.service
    

    echo "" | sudo tee /etc/systemd/zram-generator.conf
    echo "unShaderBackgroundProcessingThreads 10" >> ~/.steam/steam/steam_dev.cfg
    echo "@nClientDownloadEnableHTTP2PlatformLinux 0" >> ~/.steam/steam/steam_dev.cfg
    
    sudo firewall-cmd --change-interface=enp34s0 --zone=home --permanent
    sudo firewall-cmd --set-default-zone=home
    sudo firewall-cmd --permanent --add-port={29997,47984,47989,47990,48010}/tcp --add-port={47998,47999,48000,48002,48010}/udp
    sudo firewall-cmd --permanent --add-service={ssh,samba,samba-client,syncthing,syncthing-gui,syncthing-relay,zerotier,spotify-sync,steam-lan-transfer,steam-streaming}
    sudo firewall-cmd --reload

    mkdir -p "$HOME/.var/app/tv.kodi.Kodi"
    ln -sfn "$HOME/.kodi" "$HOME/.var/app/tv.kodi.Kodi/data"

    mkdir -p "$HOME/.var/app/org.prismlauncher.PrismLauncher/data"
    rm -rf "$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher"
    ln -sfn "$HOME/.config/PrismLauncher" "$HOME/.var/app/org.prismlauncher.PrismLauncher/data/PrismLauncher"

    just install-discord-rpc
    just install-spotx
    just wol
    just setup-fstab
    just setup-ssh
    just setup-sudoer

    sudo systemctl daemon-reload
    sudo udevadm control --reload-rules && sudo udevadm trigger
    sudo fc-cache -fv