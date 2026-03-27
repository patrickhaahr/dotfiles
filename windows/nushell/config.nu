$env.config.show_banner = false
$env.config.buffer_editor = "nvim"
$env.config.shell_integration = {
    osc2: true,   # title changes - harmless
    osc7: true,   # directory reporting - useful
    osc8: true,   # hyperlink support
    osc133: false # semantic prompt markers - THE CULPRIT
}

alias c = clear
alias e = explorer .
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..
alias ~ = cd C:/Users/$USER/
alias dev = cd C:/Dev
alias appdata = cd C:/Users/$USER/AppData
alias poweroff = cmd /c shutdown /s /f /t 0

mkdir ($nu.data-dir | path join "vendor/autoload")
starship init nu | save -f ($nu.data-dir | path join "vendor/autoload/starship.nu")

# Zoxide - inline initialization for Nushell 0.110+
$env.__zoxide_hooked = false
if not $env.__zoxide_hooked {
    $env.__zoxide_hooked = true
    $env.config = ($env | default {} config).config
    $env.config = ($env.config | default {} hooks)
    $env.config = ($env.config | update hooks ($env.config.hooks | default {} env_change))
    $env.config = ($env.config | update hooks.env_change ($env.config.hooks.env_change | default [] PWD))
    $env.config = ($env.config | update hooks.env_change.PWD ($env.config.hooks.env_change.PWD | append {|_, dir| zoxide add -- $dir}))
}

def --env z [...rest: string] {
    let arg0 = ($rest | append '~').0
    let path = if (($rest | length) <= 1) and ($arg0 == '-' or ($arg0 | path expand | path type) == dir) {
        $arg0
    } else {
        (zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n")
    }
    cd $path
}

def --env zi [...rest: string] {
    cd (zoxide query --interactive -- ...$rest | str trim -r -c "\n")
}

