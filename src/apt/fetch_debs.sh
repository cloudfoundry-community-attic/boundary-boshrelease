set -e          # exit immediately if a simple command exits with a non-zero status
set -u          # report the usage of uninitialized variables
set -o pipefail # return value of a pipeline is the value of the last (rightmost) command to exit with a non-zero status

# Usage: src/common/fetch_debs.sh postgresql [src/apt/postgresql]
#
#   src/common/fetch_debs.sh postgresql
#   src/common/fetch_debs.sh postgresql src/apt/postgresql
#
PACKAGE_NAME=$1
RELEASE_DIR=${RELEASE_DIR:-/vagrant}
if [[ "${2:-X}" == "X" ]]; then
    PACKAGE_SRC_DIR=$RELEASE_DIR/src/apt/$PACKAGE_NAME
else
    PACKAGE_SRC_DIR=$RELEASE_DIR/$2
fi
APTFILE=$PACKAGE_SRC_DIR/aptfile
APT_CACHE_DIR="$RELEASE_DIR/tmp/apt/cache/$PACKAGE_NAME"
APT_STATE_DIR="$RELEASE_DIR/tmp/apt/state"
BLOBS_DIR=$RELEASE_DIR/blobs/apt/$PACKAGE_NAME

function error() {
  echo " !     $*" >&2
  exit 1
}

function topic() {
  echo "-----> $*"
}

function indent() {
  c='s/^/       /'
  case $(uname) in
    Darwin) sed -l "$c";;
    *)      sed -u "$c";;
  esac
}

topic "Environment information"
echo $0                | indent
uname -a               | indent
pwd                    | indent

# Invoke apt-get to ensure it exists
if [[ "$(which apt-get)X" == "X" ]]; then
    error "Cannot find apt-get executable. Run this script within a Debian/Ubuntu environment."
fi
which apt-get          | indent

echo $APTFILE          | indent
if [[ ! -f $APTFILE ]]; then
    error "Missing source file $APTFILE"
fi

mkdir -p "$APT_CACHE_DIR/archives/partial"
mkdir -p "$APT_STATE_DIR/lists/partial"
mkdir -p $BLOBS_DIR

APT_OPTIONS="-o debug::nolocking=true -o dir::cache=$APT_CACHE_DIR -o dir::state=$APT_STATE_DIR"

BOUNDARY_APT_STRING="deb https://apt.boundary.com/ubuntu/ lucid universe"
sudo su -c "echo \"$BOUNDARY_APT_STRING\" > /etc/apt/sources.list.d/boundary.list"

set -x
sudo apt-key add - <<-EOS
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1.4.10 (GNU/Linux)

mQENBE3WllEBCADlEuA7DCcI0B1/1rXJ4SzzQGXcHwmsxLVGnRR9FX4Fu3oCz4sc
18/FkPHb2AwFfClv4xH6gOUBJVCDyub/C6PJeLolkc51SLA2lO3y5e3OpJ7uC8Ln
/P5AC96FDhIEPH+vVnBVxgYRFj/1vDlqUcJXUSN3ZnLxzHwnHJ+lATNydbTi3ltL
Kr53YOD5FmuKpc2hkNzT+9Lg1/aVEKXpnSjzlNT/1VIrXgJOzv/xyKvpSD2fb5M3
QZMjEkrod5botvclt/y6P8LNWsmlG0eM+JiewnDzwJ3OnhekSzHqoh3kVKQ3YJed
i1ZKInNthXQ5sSiHrsxHhJFGuVAQVA0/AmJfABEBAAG0G0JvdW5kYXJ5IDxvcHNA
Ym91bmRhcnkuY29tPokBOAQTAQIAIgUCTdaWUQIbAwYLCQgHAwIGFQgCCQoLBBYC
AwECHgECF4AACgkQQ4Go5GUyzCAqWggAjuJgzEYO1nTVd4hBhkhuxH1d/9R5eDzN
SvxMk9gI2kKd71DsVP7PCVlPPIkzqL/IMv5ffO3me3R0S3bZzquhCOhrUc987GgZ
+rPEcb0sDjT4fzcVeAOuaIf3T8oysx9ngB5pE4i3fatD43WvTGbj4LmU9XxiwZ6z
AKzIYltGy/+Cq2JJjYgg80O2RmG8FFf8k/FujkbsNgNICQwWnAGKKlpJ4b65M5zu
oNNUGFcJopGGufKLxXAiRwJqOx8a+EvD7/MEs5VYQJGeBgoaE6ZgXwufYJYn0Lv3
6fxTtkLlIrD27gvTbV1oF8tj+T+7ayKj75YGnaH03QYBOG8tmbqV/A==
=p4gi
-----END PGP PUBLIC KEY BLOCK-----
EOS

topic "Updating apt caches"
apt-get $APT_OPTIONS update | indent

for PACKAGE in $(cat $APTFILE); do
  topic "Fetching .debs for $PACKAGE"
  apt-get $APT_OPTIONS -y -d install $PACKAGE | indent
done

topic "Copying .debs to blobs"
cp -a $APT_CACHE_DIR/archives/*.deb $BLOBS_DIR/
