inpath() { [[ -x "$(which "$1" 2>/dev/null)" ]]; }
nexec() { [[ -z $(pidof "$1") ]]; }

systemctl --user import-environment PATH
systemctl --user import-environment XDG_CONFIG_HOME
systemctl --user import-environment DISPLAY XAUTHORITY
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
        dbus-update-activation-environment DISPLAY XAUTHORITY
fi

if [[ -o LOGIN  ]]; then
    setterm -bfreq 0 # disable annoying pc speaker
    if [[ "${TERM}" = "linux" ]]; then
        local run_yaft=0
        if hash yaft 2> /dev/null; then
            if [[ ${run_yaft} == 1 ]]; then
                yaft
            fi
        fi

        echo -en "\e]P0000000" #black
        echo -en "\e]P83d3d3d" #darkgrey
        echo -en "\e]P18c4665" #darkred
        echo -en "\e]P9bf4d80" #red
        echo -en "\e]P2287373" #darkgreen
        echo -en "\e]PA53a6a6" #green
        echo -en "\e]P37c7c99" #brown
        echo -en "\e]PB9e9ecb" #yellow
        echo -en "\e]P4395573" #darkblue
        echo -en "\e]PC477ab3" #blue
        echo -en "\e]P55e468c" #darkmagenta
        echo -en "\e]PD7e62b3" #magenta
        echo -en "\e]P631658c" #darkcyan
        echo -en "\e]PE6096bf" #cyan
        echo -en "\e]P7899ca1" #lightgrey
        echo -en "\e]PFc0c0c0" #white
    fi
    (( $#commands[tmux]  )) && tmux list-sessions 2>/dev/null
fi
