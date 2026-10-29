#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
version=2.0.39
case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) platform=darwin-arm64; sum=d4aaef68de545727429ce83b9e88ff3273bf068df599e3542e446755b5f3d83a;;
  Darwin-x86_64) platform=darwin-x64; sum=a512cfd1d29ec24c640126a6a640e597b4ea1abe0aefbda7cc57efd85ab56e22;;
  Linux-aarch64) platform=linux-arm64; sum=71b43e1bb9313dd14ac2b0553b854e41c39d65ecaa47040796ebff4a46f54a97;;
  Linux-x86_64) platform=linux-x64; sum=6cf462fd8f70b094a4950ebb709a9c4ffd8f1d1189d9cedf1fd63cd5d041c7ab;;
  *) echo 'Unsupported OS/architecture; use macOS or Linux arm64/x64.' >&2; exit 1;;
esac
mkdir -p .tools
stage=$(mktemp -d .tools/download.XXXXXX)
trap 'rm -rf "$stage"' EXIT
curl --proto '=https' --tlsv1.2 -fsSL "https://github.com/bendlang/bend/releases/download/v$version/bend-$version-$platform.tar.gz" -o "$stage/bend.tar.gz"
if command -v sha256sum >/dev/null 2>&1; then
  actual=$(sha256sum "$stage/bend.tar.gz" | cut -d ' ' -f 1)
else
  actual=$(shasum -a 256 "$stage/bend.tar.gz" | cut -d ' ' -f 1)
fi
[ "$actual" = "$sum" ] || { echo 'Compiler checksum mismatch' >&2; exit 1; }
tar -xzf "$stage/bend.tar.gz" -C "$stage"
[ ! -e .tools/bend ] || { echo '.tools/bend already exists; leaving it unchanged' >&2; exit 1; }
mv "$stage/bend" .tools/bend
printf 'Installed Bend %s in .tools/bend\n' "$version"
