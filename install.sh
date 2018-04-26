#!/bin/sh
#
# This script is meant for quick & easy install via:
#   'curl -sSL https://raw.githubusercontent.com/SmartFinn/eve-ng-integration/master/install.sh | sh'
# or:
#   'wget -qO- https://raw.githubusercontent.com/SmartFinn/eve-ng-integration/master/install.sh | sh'

set -e

url="https://github.com/Mutilador/eve-ng-integration/archive/master.tar.gz"

_command_exists() { command -v "$@" > /dev/null 2>&1; }
_msg() { echo "=>" "$@" >&2; }

_unsupported() {
	cat <<-'EOF' >&2

	Your Linux distribution is not supported.

	Feel free to ask support for it by opening an issue at:
	  https://github.com/SmartFinn/eve-ng-integration/issues

	EOF
	exit 1
}

_get_file() {
	if _command_exists wget; then
		wget -qO- "$1"
	else
		curl -sLo- "$1"
	fi
}

do_install() {
	temp_dir="$(mktemp -d)"

	_msg "Download and extract into '$temp_dir'..."
	_get_file "$url" | tar --strip-components=1 -C "$temp_dir" -xzf -

	_msg "Installing..."
	sudo mkdir -p /usr/bin
	sudo wget 'https://download.mikrotik.com/routeros/winbox/3.13/winbox.exe' -o /usr/local/bin/winbox
	sudo chmod +x /usr/local/bin/winbox
	sudo install -m 755 "$temp_dir/bin/eve-ng-integration" /usr/bin/
	sudo install -m 755 "$temp_dir/bin/eni-rdp-wrapper" /usr/bin/
	sudo mkdir -p /usr/share/applications
	sudo install -m 644 "$temp_dir/data/eve-ng-integration.desktop" \
		/usr/share/applications/
	sudo install -m 644 "$temp_dir/data/eni-rdp-wrapper.desktop" \
		/usr/share/applications/
	sudo mkdir -p /usr/share/mime/packages
	sudo install -m 644 "$temp_dir/data/eni-rdp-wrapper.xml" \
		/usr/share/mime/packages/

	# build cache database of MIME types handled by desktop files
	sudo update-desktop-database -q || true
	sudo update-mime-database -n /usr/share/mime || true

	_msg "Clearing cache ..."
	rm -rf "$temp_dir"

	_msg "Complete!"

	cat <<-'EOF' >&2

	  Do not forget add the user to the wireshark group:

	    # You will need to log out and then log back in
	    # again for this change to take effect.
	    sudo usermod -a -G wireshark $USER

	EOF

	exit 0
}

# Detect Linux distribution
if [ -r /etc/os-release ]; then
	. /etc/os-release
elif _command_exists lsb_release; then
	ID=$(lsb_release -si)
	VERSION_ID=$(lsb_release -sr)
else
	_unsupported
fi

_msg "Detected distribution: $ID $VERSION_ID (${ID_LIKE:-"none"})"

# Check if python is installed
if _command_exists python; then
	# declare a variable
	PYTHON=""
fi

for dist_id in $ID $ID_LIKE; do
	case "$dist_id" in
		debian|ubuntu)
			_msg "Install dependencies..."
			sudo apt-get install -y ${PYTHON-"python"} \
				ssh-askpass telnet vinagre wireshark wine
			do_install
			;;
		arch|archlinux|manjaro)
			_msg "Install dependencies..."
			sudo pacman -S ${PYTHON-"python"} \
				inetutils vinagre wireshark-qt x11-ssh-askpass wine
			do_install
			;;
		fedora)
			_msg "Install dependencies..."
			sudo dnf install -y ${PYTHON-"python"} \
				openssh-askpass telnet vinagre wireshark-qt wine
			do_install
			;;
		opensuse|suse)
			_msg "Install dependencies..."
			sudo zypper install -y ${PYTHON-"python"} \
				openssh-askpass telnet vinagre wireshark-ui-qt wine
			do_install
			;;
		centos|CentOS|rhel)
			_msg "Install dependencies..."
			sudo yum install -y ${PYTHON-"python"} \
				openssh-askpass telnet vinagre wireshark-gnome wine
			do_install
			;;
		*)
			continue
			;;
	esac
done

_unsupported
