
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
