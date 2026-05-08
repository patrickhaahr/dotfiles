$env.config.show_banner = false
$env.config.buffer_editor = "nvim"
$env.config.shell_integration = {
    osc2: true
    osc7: true
    osc8: true
    osc133: false
}
$env.config.completions = {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    external: {
        enable: true
        max_results: 100
    }
}

$env.EDITOR = "nvim"
$env.DOTNET_CLI_TELEMETRY_OPTOUT = "true"

let git_sh_path = 'C:\Users\pkh\AppData\Local\Programs\Git\bin'
if ($env.Path | where { |entry| $entry == $git_sh_path } | is-empty) {
    $env.Path = ($env.Path | append $git_sh_path)
}

alias vi = nvim
alias vim = nvim
alias nano = nvim
alias code = opencode -c
alias c = clear
alias e = explorer .
alias .. = cd ..
alias ... = cd ../..
alias .... = cd ../../..
alias ~ = cd $nu.home-path
alias dev = cd C:/Dev
alias appdata = cd ($nu.home-path | path join "AppData")
alias poweroff = cmd /c shutdown /s /f /t 0

let autoload_dir = ($nu.data-dir | path join "vendor" "autoload")
if not ($autoload_dir | path exists) {
    mkdir $autoload_dir
}

if ((which starship | length) > 0) {
    starship init nu | save -f ($autoload_dir | path join "starship.nu")
}

export-env {
    $env.config = (
        $env.config?
        | default {}
        | upsert hooks { default {} }
        | upsert hooks.env_change { default {} }
        | upsert hooks.env_change.PWD { default [] }
    )

    let __zoxide_hooked = (
        $env.config.hooks.env_change.PWD | any { try { get __zoxide_hook } catch { false } }
    )

    if not $__zoxide_hooked {
        $env.config.hooks.env_change.PWD = ($env.config.hooks.env_change.PWD | append {
            __zoxide_hook: true,
            code: {|_, dir| ^zoxide add -- $dir}
        })
    }
}

def --env --wrapped __zoxide_z [...rest: string] {
    let path = match $rest {
        [] => { '~' }
        [ '-' ] => { '-' }
        [ $arg ] if ($arg | path expand | path type) == 'dir' => { $arg }
        _ => {
            ^zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n"
        }
    }

    cd $path
}

def --env --wrapped __zoxide_zi [...rest: string] {
    cd $'(^zoxide query --interactive -- ...$rest | str trim -r -c "\n")'
}

alias z = __zoxide_z
alias zi = __zoxide_zi
alias cd = __zoxide_z

