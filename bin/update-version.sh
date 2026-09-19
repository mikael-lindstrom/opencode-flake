#!/usr/bin/env bash

set -euo pipefail

FLAKE_FILE="flake.nix"
ARCHITECTURES=(darwin-arm64 darwin-x64 linux-arm64 linux-x64)

if [[ ! -f "$FLAKE_FILE" ]]; then
	printf 'Error: %s not found in current directory\n' "$FLAKE_FILE" >&2
	exit 1
fi

replace_value() {
	local pattern=$1
	local replacement=$2
	local expression
	printf -v expression 's|(%s = ")[^"]*(";)|\\1%s\\2|' "$pattern" "$replacement"

	if [[ "$OSTYPE" == "darwin"* ]]; then
		sed -i '' -E "$expression" "$FLAKE_FILE"
	else
		sed -i -E "$expression" "$FLAKE_FILE"
	fi
}

replace_attr() {
	local key=$1
	local replacement=$2
	local pattern
	printf -v pattern '"%s"' "$key"

	replace_value "$pattern" "$replacement"
}

update_channel() {
	local pname=$1
	local versionKey=$2
	local metadataPackage=$3
	local tag=$4
	local rootPackage=$5
	local rootTarball=$6
	local platformPackagePrefix=$7
	local platformTarballPrefix=$8
	local metadataUrl="https://registry.npmjs.org/${metadataPackage}/${tag}"
	local metadata
	local version
	local platformVersion
	local hash
	local arch
	local package
	local tarball

	printf 'Fetching %s@%s metadata...\n' "$rootPackage" "$tag"
	metadata=$(curl --fail --silent --show-error "$metadataUrl")
	version=$(jq -er '.version' <<<"$metadata")
	printf 'Latest %s version: %s\n' "$pname" "$version"

	printf 'Fetching %s hash... ' "$rootPackage"
	hash=$(nix-prefetch-url --type sha256 \
		"https://registry.npmjs.org/${rootPackage}/-/${rootTarball}-${version}.tgz" 2>/dev/null)
	printf '%s\n' "$hash"
	replace_attr "${pname}-root" "$hash"

	for arch in "${ARCHITECTURES[@]}"; do
		package="${platformPackagePrefix}${arch}"
		tarball="${platformTarballPrefix}${arch}"
		platformVersion=$(jq -er --arg package "$package" \
			'.optionalDependencies[$package]' <<<"$metadata")
		printf 'Fetching %s@%s hash... ' "$package" "$platformVersion"
		hash=$(nix-prefetch-url --type sha256 \
			"https://registry.npmjs.org/${package}/-/${tarball}-${platformVersion}.tgz" 2>/dev/null)
		printf '%s\n' "$hash"
		replace_attr "${pname}-${arch}-version" "$platformVersion"
		replace_attr "${pname}-${arch}" "$hash"
	done

	replace_value "$versionKey" "$version"
}

update_channel \
	"opencode" \
	"opencodeVersion" \
	"opencode-ai" \
	"latest" \
	"opencode-ai" \
	"opencode-ai" \
	"opencode-" \
	"opencode-"

update_channel \
	"opencode2" \
	"opencode2Version" \
	"@opencode%2fcli" \
	"latest" \
	"@opencode/cli" \
	"cli" \
	"@opencode/cli-" \
	"cli-"

printf 'Successfully updated %s\n' "$FLAKE_FILE"
