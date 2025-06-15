# My Arch Linux & Hyprland Dotfiles 🐧

![A placeholder image of a desktop setup. Replace this with a screenshot of your desktop!](https://raw.githubusercontent.com/keyitdev/sddm-astronaut-theme/master/Previews/jake_the_dog.png)

Welcome to my personal configuration for a highly customized, aesthetic, and performant Arch Linux desktop environment. This setup is built around **Hyprland** and is designed for both software development and gaming on a modern Wayland stack.

The entire installation process is automated via a single script, which handles package installation, theming, and dotfile symlinking with **GNU Stow**.

---

## 🎨 Core Components & Theming

This setup aims for a cohesive look and feel, from the boot screen to the desktop.

| Component         | Software                                        | Theme/Config                               |
| ----------------- | ----------------------------------------------- | ------------------------------------------ |
| **OS**            | Arch Linux                                      | -                                          |
| **WM**            | [Hyprland](https://hyprland.org/)               | Custom configuration in `hypr/`            |
| **Bar**           | [Waybar](https://github.com/Alexays/Waybar)     | Custom configuration in `waybar/`          |
| **Launcher**      | [Rofi](https://github.com/lbonn/rofi)           | Custom configuration in `rofi/`            |
| **Terminal**      | [Ghostty](https://github.com/mitchellh/ghostty) | Custom configuration in `ghostty/`         |
| **Shell**         | [Zsh](https://www.zsh.org/)                     | `oh-my-zsh`, `fzf-tab`, plugins in `zsh/`  |
| **Editor**        | [Neovim](https://neovim.io/)                    | NVChad-based setup in `nvim/`              |
| **Login Manager** | [SDDM](https://github.com/sddm/sddm)            | `sddm-astronaut-theme` (Jake the Dog)      |
| **Boot Splash**   | [Plymouth](https://www.freedesktop.org/wiki/Software/Plymouth/) | `plymouth-theme-hud-3`                     |
| **GRUB**          | [GRUB](https://www.gnu.org/software/grub/)      | `minegrub-theme` with auto-updating splash |
| **Multiplexer**   | [Tmux](https://github.com/tmux/tmux)            | Custom configuration in `tmux/`            |
| **Git**           | [Git](https://git-scm.com/)                     | Global `.gitconfig` in `git/`              |

---

## 🚀 Installation

> **Warning:** This installation script is tailored to **my specific hardware and software preferences** (Arch Linux, AMD hardware). It will install numerous packages and overwrite system configuration files. Please read the `install.sh` script to understand what it does before running it. Use at your own risk!

### Prerequisites

-   A fresh Arch Linux installation.
-   `git` and `base-devel` packages installed.

### Automated Setup

1.  **Clone the repository:**
    ```sh
    git clone https://github.com/patrickhaahr/dotfiles.git
    cd dotfiles
    ```

2.  **Make the script executable:**
    ```sh
    chmod +x install.sh
    ```

3.  **Run the installation script:**
    ```sh
    ./install.sh
    ```

The script will handle everything:
-   Installing packages from official repositories and the AUR.
-   Setting up GRUB, Plymouth, and SDDM themes.
-   Configuring system services.
-   Using `stow` to symlink all the configuration files from this repository into your home directory.

---

## 🔧 Post-Installation & Usage

### Stow Management

This repository uses **GNU Stow** to manage symlinks. The `install.sh` script runs this for you initially, but you can manage packages individually later.

-   **To stow a package (e.g., nvim):**
    ```sh
    stow nvim
    ```
-   **To unstow a package:**
    ```sh
    stow -D nvim
    ```
-   **To restow everything:**
    ```sh
    stow -R *
    ```

### Change Default Shell

If Zsh is not your default shell after the script finishes, you can set it manually:
```sh
chsh -s /bin/zsh
```

### Reboot
A reboot is recommended to ensure all services (SDDM, Plymouth, etc.) are loaded correctly.

---

## ❤️ Acknowledgements

This setup wouldn't be possible without the incredible work of the open-source community. Special thanks to:
-   **vaxersk** and the **Hyprland** team for an amazing Wayland compositor - [Hyprland](https://github.com/hyprwm/Hyprland).
-   **Lxtharia** for the [minegrub-theme](https://github.com/Lxtharia/minegrub-theme).
-   **keyitdev** for the [sddm-astronaut-theme](https://github.com/keyitdev/sddm-astronaut-theme).
-   **adi1090x** for the [plymouth-themes](https://github.com/adi1090x/plymouth-themes).
-   All the developers behind the tools and applications used in this configuration.
