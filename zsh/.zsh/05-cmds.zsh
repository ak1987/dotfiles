function chpwd() {
    if [[ -x ${BIN_HOME}/Z ]]; then
        [[ "${PWD}" -ef "${HOME}" ]] || Z -a "${PWD}"
    fi
    hash setup_prompt 2> /dev/null && setup_prompt
}

local readonly use_cope_path=false
if [[ ${use_cope_path} == true  ]]; then
    if [[ -x $(which cope_path 2> /dev/null) ]]; then
        # to prevent slow cope_path evaluation
        local copepath=$(cope_path)
        for i in "${copepath}"/*; alias $(basename ${i})=\"$i\"
        alias df="${copepath}/df -hT"
    else
        alias df="df -hT"
    fi
else
    local copepath=${SCRIPT_HOME}/Cope
    for i in "${copepath}"/*; alias $(basename ${i})=\"$i\"
    alias df="${copepath}/df -hT"
fi
unset copepath

function zc(){
    autoload -U zrecompile
    for z in ${ZSH}/*.zsh ${HOME}/.zshrc; do 
        zrecompile -p ${z}; 
        print $(zpref) $(zfwrap "${z}"); 
        rm -fv "${z}.zwc.old"
    done
    for f in ${zcompdumpfile};
        zrecompile -p "${f}" && \
        rm -f "${f}.zwc.old"
    source ${HOME}/.zshrc
}

# grep for running process, like: 'any vime
function any() {
    emulate -L zsh
    unsetopt KSH_ARRAYS
    if [[ -z "$1" ]] ; then
        if [[ -x $(which fzf-tmux) ]]; then
            ps xauwww | fzf-tmux
        fi
    else
        ps xauwww | grep  --color=auto -i "[${1[1]}]${1[2,-1]}"
    fi
}

function imv() {
    local src dst
    for src; do
        [[ -e ${src} ]] || { print -u2 "${src} does not exist"; continue }
        dst=${src}
        vared dst
        [[ ${src} != ${dst} ]] && mkdir -p ${dst:h} && mv -n ${src} ${dst}
    done
}

fasd_cache="${XDG_CACHE_HOME}/fasd-init-cache"
if [ "$(command -v fasd)" -nt "${fasd_cache}" -o ! -s "${fasd_cache}" ]; then
    fasd --init auto >| "${fasd_cache}"
fi
source "${fasd_cache}"
unset fasd_cache

function dropcache { sync && command sudo /bin/zsh -c 'echo 3 > /proc/sys/vm/drop_caches' }

function lastfm_scrobbler_toggle(){
    local is_run="active (running)"
    local use_mpdscribble=false
    if [[ use_mpdscribble == true ]]; then
        if [[ "$(systemctl --user status mpdscribble.service|grep -o "${is_run}")" != "" ]]; then
            systemctl --user stop mpdscribble
            =mpdscribble --conf ${XDG_CONFIG_HOME}/mpdscribble/hextrick.conf --no-daemon &!
        else
            pkill mpdscribble
            systemctl --user start mpdscribble.service
        fi
        builtin printf "$(zpref) $(zfwrap "$(any mpdscribble | awk  '{print substr($0, index($0,$11))}'|
            sed "s|${HOME}|$fg[green]~|;s|/|$fg[blue]&$fg[white]|g")")\n"
    else
        if [[ "$(systemctl --user status mpdas.service|grep -o "${is_run}")" != "" ]]; then
            systemctl --user stop mpdas.service
            =mpdas -c ${XDG_CONFIG_HOME}/mpdas/hextrick.rc 2&> /dev/null &!
        else
            pkill mpdas
            systemctl --user start mpdas.service
        fi
        builtin printf "$(zpref) $(zfwrap "$(any mpdas | awk  '{print substr($0, index($0,$11))}'|
            sed "s|${HOME}|$fg[green]~|;s|/|$fg[blue]&$fg[white]|g")")\n"
    fi
    unset is_run use_mpdscribble
}

function pid2xid(){ wmctrl -lp | awk "\$3 == $(pgrep $1) {print \$1}" }

function ql(){
    if [[ $1 != "" ]]; then
        local file=$(resolve_file "$1")
        local upload_dir=${HOME}/1st_level/upload/
        cp "${file}" "${upload_dir}" && \
        builtin printf "$(zfwrap ${file})\n"
        xsel -o <<< "${upload_dir}/$(basename ${file})"
    fi
}

function which() {
    if [[ $# > 0 ]]; then
        if [[ -x /usr/bin/ccat ]]; then
            builtin which "$@" | ccat
        else            
            builtin which "$@"
        fi
    fi
}

function py23switch(){
    python_path="$(which python)"

    if [[ $(basename $(readlink /usr/sbin/python)) == python3 ]]; then
        echo ':: set python (3 to 2) ::'
        sudo ln -fs /usr/sbin/python2 /usr/sbin/python && \
            l ${python_path}
    elif
        [[ $(basename $(readlink /usr/sbin/python)) == python2 ]]; then
        echo ':: set python (2 to 3) ::'
        sudo ln -fs /usr/sbin/python3 /usr/sbin/python && \
            l ${python_path}
    fi
}

if hash nvim > /dev/null && hash nvr > /dev/null; then
    function gv(){
        nvr --remote-send ":e $(pwd)<CR>:GV<CR>"
    }
fi

local noglob_list=(
    fc find {,s,l}ftp history locate rake rsync scp
    eix {z,m}mv wget clive{,scan} youtube-{dl,viewer}
    translate links{,2} lynx you-get bower pip task
)

local rlwrap_list=(
    bigloo clisp irb guile
)

local sudo_list=({u,}mount ch{mod,own} modprobe i7z aircrack-ng)

local user_commands=(
    list-units is-active status show help list-unit-files
    is-enabled list-jobs show-environment cat
)

local systemctl_sudo_commands=(
    start stop reload restart try-restart isolate kill
    reset-failed enable disable reenable preset mask unmask
    link load cancel set-environment unset-environment
    edit
)

local logind_sudo_list=(
    reboot halt poweroff
)

local nocorrect_commands=(
    ebuild gist heroku hpodder man mkdir mv mysql sudo
)

for c in ${user_commands}; do; alias sc-${c}="systemctl ${c}"; done
for c in ${systemctl_sudo_commands}; do; alias sc-${c}="sudo systemctl ${c}"; done

for i in ${sudo_list[@]}; alias "${i}=sudo ${i}";
for i in ${noglob_list[@]}; alias "${i}=noglob ${i}";
for i in ${rlwrap_list[@]}; alias "${i}=rlwrap ${i}";
for i in ${nocorrect_list[@]}; alias "${i}=nocorrect ${i}";
    
[[ -x /usr/bin/systemctl ]] && sysctl_pref="systemctl"
for i in ${logind_sudo_list[@]}; alias "${i}=sudo ${sysctl_pref} ${i}"

unset noglob_list rlwrap_list sudo_list sys_sudo_list

if [[ ! -x "${BIN_HOME}/l" ]] && [[ ! -x $(which l) ]]; then
    alias l="ls -aChkopl --group-directories-first --color=auto"
else
    alias l='l -g'
fi
alias ls="ls --color=auto" # do we have GNU ls with color-support?

alias s="sudo"
alias x='xargs'
alias e="mimeo"
alias u='umount'

alias magnet2torrent="aria2c -q --bt-metadata-only --bt-save-metadata"

function mp(){
    for i; vid_fancy_print "${i}"
    mpv --input-ipc-server=/tmp/mpvsocket --vo=gpu "$@" > ${HOME}/tmp/mpv.log
}

alias mpa="mpv -mute > ${HOME}/tmp/mpv.log"
alias mpA="mpv -fs -ao null > ${HOME}/tmp/mpv.log"

alias love="mpc sendmessage mpdas love"
alias unlove="mpc sendmessage mpdas unlove"

alias grep="grep --color=auto"
alias rg="rg --colors 'match:fg:magenta' --colors 'line:fg:cyan'"

alias mutt="dtach -A ${HOME}/1st_level/mutt.session neomutt"

alias pstop='ps -eo cmd,fname,pid,pcpu,time --sort=-pcpu | head -n 11 && echo && ps -eo cmd,fname,pid,pmem,rss --sort=-rss | head -n 9'
alias '?=bc -l <<<'

alias {z,m}mv="noglob zmv -Wn"
alias mv="mv -i"
alias mk="mkdir -p"
alias rd="rmdir"

alias acpi="acpi -V"
alias se="patool extract"
alias pk="patool create"
alias url-quote='autoload -U url-quote-magic ; zle -N self-insert url-quote-magic'

if hash git 2>/dev/null; then
    alias gs='git status --short -b'
    alias gp='git push'
    alias gdd='git diff'
    alias gc='git commit'

    # http://neurotap.blogspot.com/2012/04/character-level-diff-in-git-gui.html
    intra_line_diff='--word-diff-regex="[^[:space:]]|([[:alnum:]]|UTF_8_GUARD)+"'
    intra_line_less='LESS="-R +/-\]|\{\+"' # jump directly to changes in diffs
    alias gdiff="${intra_line_less} git diff ${intra_line_diff}"
    alias gdiff2="git diff -w -U0 --word-diff-regex=[^[:space:]]"

    # commit staged changes with the given message
    alias gcm='git commit -m'

    function git_confclicts() {
        # list all conflicted files
        alias gkl='git ls-files --unmerged | cut -f2 | uniq'
        # add changes from all conflicted files
        alias gka='git add $(gkl)'
        # edit conflicted files
        alias gke='vim +"set hlsearch" +"/^[<=>]\{7\}/\( \|$\)" $(gkl)'
        # use local version of the given files
        alias gko='git checkout --$(test -f .git/MERGE_HEAD && echo ours || echo theirs) --'
        # use local version of all conflicted files
        alias gkO='gko $(gkl)'
        # use upstream version of the given files
        alias gkt='git checkout --$(test -f .git/MERGE_HEAD && echo theirs || echo ours) --'
        # use upstream version of all conflicted files
        alias gkT='gkt $(gkl)'
    }
    eval "$(hub alias -s)"
    [[ -x ${SCRIPT_HOME}/git-cal ]] && alias git-cal=${SCRIPT_HOME}/git-cal
fi

for i in x q Q; eval alias :${i}=\' exit\'

alias iostat='iostat -mtx'
alias yt="youtube-dl"
alias ytt='you-get'

function yr(){
    ${XDG_CONFIG_HOME}/i3/send ns toggle youtube
    sleep 1s
    echo "$@" | xsel -i
    xdotool key shift+Insert
}

alias qe='cd *(/om[1])'
if hash ccat > /dev/null; then
    alias {cat,hi}='ccat -G String="_default_" -G Plaintext="white" -G Punctuation="blue" -G Literal="fuscia" -G Keyword="fuscia" 2>/dev/null'
fi

alias history='history 0'

alias objdump='objdump -M intel -d'
alias memgrind='valgrind --tool=memcheck "$@" --leak-check=full'

alias cal="task calendar"

if [[ $(whence python) != "" ]]; then
    alias urlencode='python -c "import sys, urllib; print(urllib.quote_plus(sys.argv[1]))"'
    alias urldecode='python -c "import sys, urllib; print(urllib.unquote_plus(sys.argv[1]))"'
elif [[ $(whence xxd) != "" ]]; then
    function urlencode() {echo $@ | tr -d "\n" | xxd -plain | sed "s/\(..\)/%\1/g"}
    function urldecode() {printf $(echo -n $@ | sed 's/\\/\\\\/g;s/\(%\)\([0-9a-fA-F][0-9a-fA-F]\)/\\x\2/g')"\n"}
fi

zleiab() {
    declare -A abk
    abk=(
        'G'    '|& rg -i '
        'C'    '| wc -l'
        'H'    '| head'
        'T'    '| tail'
        'N'    '&>/dev/null'
        'S'    '| sort -h '
        'V'    '|& nvim -'
        "jk"   "!-2$"
        "j2"   "!-3$"
        "j3"   "!-4$"
    )

    emulate -L zsh
    setopt extendedglob
    local MATCH

    matched_chars='[.-|_a-zA-Z0-9]#'
    LBUFFER=${LBUFFER%%(#m)[.-|_a-zA-Z0-9]#}
    LBUFFER+=${abk[$MATCH]:-$MATCH}
}

alias vmpd='command cava -i fifo -p /tmp/mpd.fifo -b 20'

zle -N zleiab

hash nmap > /dev/null && {
    # -- [ nmap ] ---------------------------------------------------
    #  -sS - TCP SYN scan
    #  -v - verbose
    #  -T1 - timing of scan. Options are paranoid (0), sneaky (1), polite (2), normal (3), aggressive (4), and insane (5)
    #  -sF - FIN scan (can sneak through non-stateful firewalls)
    #  -PE - ICMP echo discovery probe
    #  -PP - timestamp discovery probe
    #  -PY - SCTP init ping
    #  -g - use given number as source port
    #  -A - enable OS detection, version detection, script scanning, and traceroute (aggressive)
    #  -O - enable OS detection
    #  -sA - TCP ACK scan
    #  -F - fast scan
    #  --script=vulscan - also access vulnerabilities in target
    alias nmap_open_ports="nmap --open"
    alias nmap_list_interfaces="nmap --iflist"
    alias nmap_slow="nmap -sS -v -T1"
    alias nmap_fin="nmap -sF -v"
    alias nmap_full="nmap -sS -T4 -PE -PP -PS80,443 -PY -g 53 -A -p1-65535 -v"
    alias nmap_check_for_firewall="nmap -sA -p1-65535 -v -T4"
    alias nmap_ping_through_firewall="nmap -PS -PA"
    alias nmap_fast="nmap -F -T5 --version-light --top-ports 300"
    alias nmap_detect_versions="nmap -sV -p1-65535 -O --osscan-guess -T4 -Pn"
    alias nmap_check_for_vulns="nmap --script=vulscan"
    alias nmap_full_udp="nmap -sS -sU -T4 -A -v -PE -PS22,25,80 -PA21,23,80,443,3389 "
    alias nmap_traceroute="nmap -sP -PE -PS22,25,80 -PA21,23,80,3389 -PU -PO --traceroute "
    alias nmap_full_with_scripts="sudo nmap -sS -sU -T4 -A -v -PE -PP -PS21,22,23,25,80,113,31339 -PA80,113,443,10042 -PO --script all "
    alias nmap_web_safe_osscan="sudo nmap -p 80,443 -O -v --osscan-guess --fuzzy "
}

hash journalctl > /dev/null && {
    alias log='journalctl -f | ccze -A' #follow log
}

hash iotop > /dev/null && {
    alias iotop='sudo iotop -oPa'
    alias diskact="sudo iotop -Po"
}

hash nc > /dev/null && alias nyan='nc -v nyancat.dakko.us 23'

alias twitch="streamlink -p mpv twitch.tv/$1 720p60"
alias recordmydesktop="recordmydesktop --no-frame"
alias up="rtv -s unixporn"

alias taco='curl -L git.io/taco'
alias starwars='telnet towel.blinkenlights.nl'

alias gdb8="gdb -x ${XDG_CONFIG_HOME}/gdb/gdbinit8.gdb"
alias gdbv="gdb -x ${XDG_CONFIG_HOME}/gdb/voltron.gdb"
alias gdbp="gdb -x ${XDG_CONFIG_HOME}/gdb/peda.gdb"

clojure(){ drip -cp /usr/share/clojure/clojure.jar clojure.main }

alias -s Dockerfile="docker build - < "

pacnews() { sudo find /etc -name '*.pacnew' | sed -e 's|^/etc/||' -e 's/.pacnew$//' }
alias pkglist="comm -23 <(pacman -Qeq | sort) <(pacman -Qgq base base-devel | sort)"

# upload to imgur with modified zmwangx/imgur
if [[ ${USE_IMGUR_QT} ]]; then
    alias img="imgur-upload $@"
else
    alias img="imgur-screenshot $@"
fi

alias @r=${SCRIPT_HOME}/music_rename

[[ -x =nvim ]] && alias vim=nvim

alias ip='ip -c'
alias fd='fd -H'

alias куищще='reboot'
alias учше='exit'
alias :й=':q'

function mimemap() {
    default=${1}; shift
    for i in $@; do alias -s ${i}=${default}; done
}

alias sp='cdu -idh -s -r -c "#"'

alias v="${BIN_HOME}/nwim"

function allip(){
    netstat -lantp \
    | grep ESTABLISHED \
    | awk '{print }' \
    | awk -F: '{print }' \
    | sort -u
}

function flac2mp3(){
    for infile in "$@"; do
        [[ "${infile}" != *.flac ]] && continue
        album="$(metaflac --show-tag=album "${infile}" | sed 's/[^=]*=//')"
        artist="$(metaflac --show-tag=artist "${infile}" | sed 's/[^=]*=//')"
        date="$(metaflac --show-tag=date "${infile}" | sed 's/[^=]*=//')"
        title="$(metaflac --show-tag=title "${infile}" | sed 's/[^=]*=//')"
        year="$(metaflac --show-tag=date "${infile}" | sed 's/[^=]*=//')"
        genre="$(metaflac --show-tag=genre "${infile}" | sed 's/[^=]*=//')"
        tracknumber="$(metaflac --show-tag=tracknumber "${infile}" | sed 's/[^=]*=//')"

        flac --decode --stdout "${infile}" | lame -b 320 --add-id3v2 \
            --tt "${title}" \
            --ta "${artist}" \
            --tl "${album}" \
            --ty "${year}" \
            --tn "${tracknumber}" \
            --tg "${genre}" - "${infile%.flac}.mp3"
    done
}

function fun::fonts(){
    alias 2023='toilet -f future'
    alias gaym='toilet --gay -f mono9 -t'
    alias gayf='toilet --gay -f future -t'
    alias gayt='toilet --gay -f term -t'
    alias gayp='toilet --gay -f pagga -t'
    alias metm='toilet --metal -f mono9 -t'
    alias metf='toilet --metal -f future -t'
    alias mett='toilet --metal -f term -t'
    alias metp='toilet --metal -f pagga -t'
    alias 3d='figlet -f 3d'
}

+strip_trailing_workspaces(){  sed ${1:+-i} 's/\s\+$//' "$@" }

# --------------------------------------------------------------------
# ZLE-related stuff

function inplace_mk_dirs() {
    # Press ctrl-xM to create the directory under the cursor or the selected area.
    # To select an area press ctrl-@ or ctrl-space and use the cursor.
    # Use case: you type "mv abc ~/testa/testb/testc/" and remember that the
    # directory does not exist yet -> press ctrl-XM and problem solved
    local PATHTOMKDIR
    if ((REGION_ACTIVE==1)); then
        local F=$MARK T=$CURSOR
        if [[ $F -gt $T ]]; then
            F=${CURSOR}
            T=${MARK}
        fi
        # get marked area from buffer and eliminate whitespace
        PATHTOMKDIR=${BUFFER[F+1,T]%%[[:space:]]##}
        PATHTOMKDIR=${PATHTOMKDIR##[[:space:]]##}
    else
        local bufwords iword
        bufwords=(${(z)LBUFFER})
        iword=${#bufwords}
        bufwords=(${(z)BUFFER})
        PATHTOMKDIR="${(Q)bufwords[iword]}"
    fi
    [[ -z "${PATHTOMKDIR}" ]] && return 1
    PATHTOMKDIR=${~PATHTOMKDIR}
    if [[ -e "${PATHTOMKDIR}" ]]; then
        zle -M " path already exists, doing nothing"
    else
        zle -M "$(mkdir -p -v "${PATHTOMKDIR}")"
        zle end-of-line
    fi
}

# just type '...' to get '../..'
function rationalise-dot() {
    local MATCH
    if [[ $LBUFFER =~ '(^|/| |  |'$'\n''|\||;|&)\.\.$' ]]; then
        LBUFFER+=/
        zle self-insert
        zle self-insert
    else
        zle self-insert
    fi
}
zle -N rationalise-dot

# run command line as user root via sudo:
function sudo-command-line () {
    [[ -z $BUFFER ]] && zle up-history
    if [[ ${BUFFER} != sudo\ * ]]; then
        BUFFER="sudo ${BUFFER}"
        CURSOR=$(( CURSOR+5 ))
    fi
}
zle -N sudo-command-line

function fg-widget() {
    stty icanon echo -inlcr < /dev/tty
    stty lnext '^V' quit '^\' susp '^Z' < /dev/tty
    zle reset-prompt
    if jobs %- >/dev/null 2>&1; then
        fg %-
    else
        fg
    fi
}
zle -N fg-widget

function up-one-dir   { pushd .. 2> /dev/null; zle redisplay; zle -M $(pwd);  }
function back-one-dir { popd     2> /dev/null; zle redisplay; zle -M $(pwd);  }
zle -N up-one-dir
zle -N back-one-dir

function magic-abbrev-expand() {
    local MATCH
    LBUFFER=${LBUFFER%%(#m)[_a-zA-Z0-9]#}
    LBUFFER+=${abbreviations[$MATCH]:-$MATCH}
    zle self-insert
}

function no-magic-abbrev-expand() { LBUFFER+=' ' }

function slash-backward-kill-word () {
    local WORDCHARS="${WORDCHARS:s@/@}"
    zle backward-kill-word
}
zle -N slash-backward-kill-word
