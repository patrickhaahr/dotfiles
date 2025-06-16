#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Helper Functions for Logging ---
info() {
  echo -e "\n\033[1;34m[INFO]\033[0m $1"
}

warn() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}

error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1" >&2
  exit 1
}

# --- 1. Install Pacman Packages (Official Repositories) ---
info "Installing packages from official repositories..."
PKGS=(
  # --- System & Utilities ---
  'base-devel' 'git' 'git-lfs' 'stow' 'amd-ucode' 'zsh' 'lsd' 'zoxide' 'neovim'
  'fzf' 'tmux' 'ffmpeg' 'wl-clipboard' 'ghostty' 'cmake' 'playerctl'
  'btop' 'fastfetch' 'zsh-syntax-highlighting' 'zsh-autosuggestions'
  'zsh-completions' 'grub' 'plymouth' 'mpv'

  # --- SDDM & Qt Dependencies ---
  'sddm' 'qt6-svg' 'qt6-virtualkeyboard' 'qt6-multimedia-ffmpeg'

  # --- Audio ---
  'pipewire' 'pipewire-audio' 'pipewire-pulse' 'wireplumber'
  'blueman'

  # --- Wayland & GUI ---
  'hyprland' 'hyprpaper' 'hyprlock' 'hypridle' 'waybar' 'hyprshot'
  'rofi-wayland' 'xdg-desktop-portal-hyprland' 'swaync' 'nwg-look'
  'mpvpaper'

  # Fonts
  'ttf-jetbrains-mono-nerd' 'ttf-cascadia-code-nerd' 'papirus-icon-theme'
  'ttf-dejavu'

  # --- Runtimes & SDKs ---
  'dotnet-sdk-8.0' 'go'
  'python' 'python-pipx' 'python-pillow'

  # --- Applications ---
  'steam' 'gamescope' 'qbittorrent' 'vlc'
  'mission-center' 'loupe' 'pavucontrol' 'loupe'
)

sudo pacman -Syu --needed --noconfirm "${PKGS[@]}"

# --- 2. Install AUR Helper (paru) ---
if ! command -v paru &>/dev/null; then
  info "AUR helper 'paru' not found. Installing..."
  git clone https://aur.archlinux.org/paru.git /tmp/paru
  (cd /tmp/paru && makepkg -si --noconfirm)
  rm -rf /tmp/paru
else
  info "'paru' is already installed."
fi

# --- 3. Install AUR Packages ---
info "Installing packages from the AUR..."
AUR_PKGS=(
  # --- Applications & Tools ---
  'bun-bin'
  'oh-my-zsh-git'
  'fzf-tab-git'
  'nvchad-git'
  'zen-browser-bin'
  'vesktop-bin'
  'spotify'
  'spicetify-cli'
  'nordvpn-bin'
  'plymouth-theme-hud-3-git'
  'openlinkhub-bin'
)

paru -S --needed --noconfirm "${AUR_PKGS[@]}"

# --- 4. System Theming ---

info "Applying system-wide themes (GRUB, SDDM, Plymouth)..."

# --- GRUB Theme (minegrub-theme) ---
info "Installing and configuring Minegrub theme with auto-updating features..."

if [ -d /boot/grub ]; then
  grub_path="/boot/grub"
elif [ -d /boot/grub2 ]; then
  grub_path="/boot/grub2"
else
  error "Could not find a GRUB installation. Aborting theme install."
fi

info "Detected GRUB path: $grub_path"

git clone https://github.com/Lxtharia/minegrub-theme.git /tmp/minegrub-theme
mkdir -p /tmp/minegrub-theme/minegrub/backgrounds
cp /tmp/minegrub-theme/background_options/*.png /tmp/minegrub-theme/minegrub/backgrounds/

sudo cp -r /tmp/minegrub-theme/minegrub "$grub_path/themes/"
sudo sed -i 's|^#\?GRUB_THEME=.*|GRUB_THEME="'"$grub_path"'/themes/minegrub/theme.txt"|' /etc/default/grub
sudo sed -i 's|^#\?GRUB_BACKGROUND=.*|GRUB_BACKGROUND="'"$grub_path"'/themes/minegrub/dirt.png"|' /etc/default/grub
sudo cp /etc/grub.d/00_header /etc/grub.d/00_header.bak
sudo sed --in-place -E 's/(.*)elif(.*"x\$GRUB_BACKGROUND" != x ] && [ -f "\$GRUB_BACKGROUND" ].*)/\1fi; if\2/' /etc/grub.d/00_header

if [ "$grub_path" == "/boot/grub2" ]; then
  sed -i 's|/boot/grub/|/boot/grub2/|' /tmp/minegrub-theme/minegrub-update.service
fi

sudo cp /tmp/minegrub-theme/minegrub-update.service /etc/systemd/system/
sudo systemctl enable minegrub-update.service
sudo grub-mkconfig -o "$grub_path/grub.cfg"

rm -rf /tmp/minegrub-theme

# --- SDDM Theme (sddm-astronaut-theme) ---
info "Installing and configuring sddm-astronaut-theme..."
THEME_NAME="sddm-astronaut-theme"
THEME_DIR="/usr/share/sddm/themes/${THEME_NAME}"
THEME_REPO="https://github.com/keyitdev/sddm-astronaut-theme.git"
THEME_VARIANT="jake_the_dog.conf"

info "Cloning theme repository..."
git clone --depth 1 "${THEME_REPO}" "/tmp/${THEME_NAME}"

if [ -d "${THEME_DIR}" ]; then
  info "Existing theme found. Backing it up..."
  sudo mv "${THEME_DIR}" "${THEME_DIR}_$(date +%s)"
fi

info "Copying theme files to ${THEME_DIR}..."
sudo mv "/tmp/${THEME_NAME}" "${THEME_DIR}"

info "Copying theme fonts and updating font cache..."
sudo cp -r "${THEME_DIR}/Fonts/"* /usr/share/fonts/
sudo fc-cache -f

info "Configuring SDDM..."
sudo mkdir -p /etc/sddm.conf.d
echo "[Theme]
Current=${THEME_NAME}" | sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null

echo "[General]
InputMethod=qtvirtualkeyboard" | sudo tee /etc/sddm.conf.d/20-virtualkbd.conf >/dev/null

info "Setting theme variant to '${THEME_VARIANT}'..."
sudo sed -i "s|^ConfigFile=.*|ConfigFile=Themes/${THEME_VARIANT}|" "${THEME_DIR}/metadata.desktop"

# --- Plymouth Boot Splash ---
if ! grep -q "^HOOKS=.*plymouth" /etc/mkinitcpio.conf; then
  info "Adding Plymouth hook to mkinitcpio..."
  sudo sed -i 's/HOOKS=(base udev/HOOKS=(base udev plymouth/' /etc/mkinitcpio.conf
else
  info "Plymouth hook already present in mkinitcpio."
fi

if ! grep -q "splash" /etc/default/grub; then
  info "Adding 'quiet splash' to kernel parameters in /etc/default/grub..."
  sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 splash"/' /etc/default/grub
else
  info "'splash' parameter already present in GRUB config."
fi

info "Updating GRUB configuration for Plymouth..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

info "Setting default Plymouth theme and rebuilding initramfs..."
sudo plymouth-set-default-theme -R hud-3

# --- 5. Enable System Services ---
info "Enabling core system services..."

info "Enabling SDDM (graphical login manager)..."
sudo systemctl enable sddm.service

info "Enabling Bluetooth service..."
sudo systemctl enable blueman.service

info "Enabling NordVPN service..."
sudo systemctl enable nordvpnd.service

# --- 6. Special Configurations ---
info "Setting up Spicetify..."
sudo chmod a+wr /opt/spotify
sudo chmod a+wr /opt/spotify/Apps -R
spicetify backup apply

info "Applying post-installation fix for OpenLinkHub..."
sudo chown -R openlinkhub:openlinkhub /opt/openlinkhub
info "Enabling and starting the OpenLinkHub service..."
sudo systemctl enable --now openlinkhub.service

# --- 7. Stow Dotfiles ---
info "Stowing dotfiles..."
cd "$(dirname "$0")" # Change to the dotfiles directory

STOW_PACKAGES=(
  'zsh' 'nvim' 'hypr' 'ghostty' 'waybar' 'rofi' 'tmux' 'git'
)

stow -R "${STOW_PACKAGES[@]}"

# --- Final Steps ---
info "Setup complete! 🎉"
warn "You may need to restart your session or reboot for all changes to take effect."
if [[ "$SHELL" != "/bin/zsh" ]]; then
  warn "Your default shell is not Zsh. Change it with: chsh -s /bin/zsh"
fi
