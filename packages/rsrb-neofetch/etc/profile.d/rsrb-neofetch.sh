# RSRB: neofetch uses the RSRB preset unless you have your own config
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/neofetch/config.conf" ] || alias neofetch='neofetch --config /etc/rsrb/neofetch.conf'
