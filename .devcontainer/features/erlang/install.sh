#!/bin/bash -e

PACKAGES_URL=${PACKAGES_URL:-"https://packages.erlang-solutions.com/ubuntu/pool/"};

declare -A UTIL_PACKAGES;
UTIL_PACKAGES[libssl1.0.0]="http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.13_amd64.deb"
UTIL_PACKAGES[libtinfo5]="http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.4-2_amd64.deb"
UTIL_PACKAGES[libncurses5]="http://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.4-2_amd64.deb ${UTIL_PACKAGES[libtinfo5]}"
UTIL_PACKAGES[libwxbase3.0-0]="http://archive.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxbase3.0-0_3.0.0-2_amd64.deb"
UTIL_PACKAGES[libwxbase3.0-0v5]="http://archive.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxbase3.0-0v5_3.0.5.1+dfsg-4_amd64.deb"
UTIL_PACKAGES[multiarch-support]="http://archive.ubuntu.com/ubuntu/pool/main/g/glibc/multiarch-support_2.27-3ubuntu1_amd64.deb"
UTIL_PACKAGES[libpng12-0]="http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb"
UTIL_PACKAGES[libtiff5]="http://archive.ubuntu.com/ubuntu/pool/main/t/tiff/libtiff5_4.3.0-6ubuntu0.10_amd64.deb"
UTIL_PACKAGES[libwxgtk3.0-0]="http://archive.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxgtk3.0-0_3.0.0-2_amd64.deb ${UTIL_PACKAGES[multiarch-support]} ${UTIL_PACKAGES[libpng12-0]} ${UTIL_PACKAGES[libtiff5]} ${UTIL_PACKAGES[libwxbase3.0-0]}"
UTIL_PACKAGES[libwxgtk3.0-0v5]="http://archive.ubuntu.com/ubuntu/pool/universe/w/wxwidgets3.0/libwxgtk3.0-0v5_3.0.4+dfsg-3_amd64.deb ${UTIL_PACKAGES[libtiff5]} ${UTIL_PACKAGES[libwxbase3.0-0v5]}"

declare -A VERSIONS;
VERSIONS=(
	[18.1]="$PACKAGES_URL/esl-erlang_18.1-1~ubuntu~precise_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]} ${UTIL_PACKAGES[libssl1.0.0]}"
	[18.3.4.11]="$PACKAGES_URL/esl-erlang_18.3.4.11-1~ubuntu~bionic_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]} ${UTIL_PACKAGES[libssl1.0.0]}"
	[19.3.6.13]="$PACKAGES_URL/esl-erlang_19.3.6.13-1~ubuntu~bionic_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]} ${UTIL_PACKAGES[libssl1.0.0]}"
	[20.3.8.26]="$PACKAGES_URL/esl-erlang_20.3.8.26-1~ubuntu~bionic_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]} ${UTIL_PACKAGES[libssl1.0.0]}"
	[21.3.8.17]="$PACKAGES_URL/esl-erlang_21.3.8.17-1~ubuntu~bionic_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]} ${UTIL_PACKAGES[libssl1.0.0]}"
	[22.3.4.9]="$PACKAGES_URL/esl-erlang_22.3.4.9-1~ubuntu~bionic_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]} ${UTIL_PACKAGES[libssl1.0.0]}"
	[23.3.4.5]="$PACKAGES_URL/esl-erlang_23.3.4.5-1~ubuntu~bionic_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]} ${UTIL_PACKAGES[libssl1.0.0]}"
	[24.3.3]="$PACKAGES_URL/esl-erlang_24.3.3-1~ubuntu~bionic_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]} ${UTIL_PACKAGES[libssl1.0.0]}"
	[25.3]="$PACKAGES_URL/esl-erlang_25.3-1~ubuntu~bionic_amd64.deb ${UTIL_PACKAGES[libncurses5]} ${UTIL_PACKAGES[libwxgtk3.0-0]}"
)

function validate_var() {
	if [[ -n "$1" ]]; then
		return;
	fi;
	test -n "$2" && echo "$2" >&2;
	if [[ -z "$NO_USAGE" ]]; then
		usage;
	fi;
	exit 1;
}

function install() {
	local otp_ver="$1";
	validate_var "$otp_ver" "No OTP version provided!";

	if [[ -d /usr/local/erlang/${otp_ver}/ ]]; then
		echo "Erlang installation already exists at /usr/local/erlang/${otp_ver}" >&2;
		exit 0;
	fi;

	local packages=( ${VERSIONS[$otp_ver]} );
	validate_var "$packages" "No packages found for version '$otp_ver'"

    if [[ "${packages[@]}" =~ "${UTIL_PACKAGES[libpng12-0]}" ]]; then
		if [[ -L /lib ]]; then
			rm -f /lib;
		fi;
		if [[ ! -d /lib ]]; then
			echo "==> Creating /lib directory"
			mkdir /lib;
		fi;
    fi;
    
	echo "==> Downloading packages: $(echo $(for url in ${packages[@]}; do basename $url; done))"
    for url in ${packages[@]}; do
        echo "==> Downloading $(basename $url)"
        wget -q --no-check $url;
    done;
    echo "==> Installing deb files"
    apt install -y ./*.deb
    echo "==> Cleaning up deb files"
    rm -f ./*.deb
}

function setup_erlangls_config() {
	local erlang_ls_config="$(cat <<EOF
otp_path: "/usr/lib/erlang"
deps_dirs:
  - "lib/*"
  - "deps/*"
diagnostics:
  enabled:
  	- bound_var_in_pattern
	- compiler
    - crossref
	- dialyzer
	- elvis
	- unused_includes
	- unused_macros
include_dirs:
  - "include"
  - "src"
  - "deps/*/include"
  - "deps/*/src"
lenses:
  enabled:
    - ct-run-test
	- function-references
	- server-info
    - show-behaviour-usages
	- suggest-spec
providers:
  enabled:
	- text-document-sync
	- hover
	- completion
    - signature-help
	- definition
	- references
	- document-highlight
	- document-symbol
	- workspace-symbol
	- code-action
	- execute-command
	- document-formatting
	- document-range-formatting
	- folding-range
	- implementation
	- code-lens
	- rename
	- call-hierarchy
	- semantic-token
EOF
)"

	su -s /bin/bash ${_REMOTE_USER} << EOF
		mkdir -p $_REMOTE_USER_HOME/.config/erlang_ls
		echo "$erlang_ls_config" >> $_REMOTE_USER_HOME/.config/erlang_ls/erlang_ls.config
EOF
	
	
}

if ! which wget >/dev/null; then
	echo "==> Install prerequisites"
	apt update -y;
	apt install -y wget;
fi;

install "${OTP_VERSION}"