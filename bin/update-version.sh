#!/bin/bash

FLAKE_FILE="flake.nix"

if [[ ! -f "$FLAKE_FILE" ]]; then
	echo "Error: $FLAKE_FILE not found in current directory"
	exit 1
fi

echo "Fetching latest version from npm registry..."
VERSION=$(curl -s https://registry.npmjs.org/opencode-ai/latest | grep -o '"version":"[^"]*"' | cut -d'"' -f4)

if [[ -z "$VERSION" ]]; then
	echo "Error: Failed to fetch version from npm registry"
	exit 1
fi

echo -e "Latest version: $VERSION\n"
echo -e "Fetching hashes for version $VERSION..."

# Fetch hash for opencode-ai package
echo -n "Fetching opencode-ai hash... "
OPENCODE_AI_HASH=$(nix-prefetch-url --type sha256 https://registry.npmjs.org/opencode-ai/-/opencode-ai-${VERSION}.tgz 2>/dev/null)
echo "$OPENCODE_AI_HASH"

# Fetch hashes for platform-specific packages
echo -n "Fetching opencode-darwin-arm64 hash... "
DARWIN_ARM64_HASH=$(nix-prefetch-url --type sha256 https://registry.npmjs.org/opencode-darwin-arm64/-/opencode-darwin-arm64-${VERSION}.tgz 2>/dev/null)
echo "$DARWIN_ARM64_HASH"

echo -n "Fetching opencode-darwin-x64 hash... "
DARWIN_X64_HASH=$(nix-prefetch-url --type sha256 https://registry.npmjs.org/opencode-darwin-x64/-/opencode-darwin-x64-${VERSION}.tgz 2>/dev/null)
echo "$DARWIN_X64_HASH"

echo -n "Fetching opencode-linux-arm64 hash... "
LINUX_ARM64_HASH=$(nix-prefetch-url --type sha256 https://registry.npmjs.org/opencode-linux-arm64/-/opencode-linux-arm64-${VERSION}.tgz 2>/dev/null)
echo "$LINUX_ARM64_HASH"

echo -n "Fetching opencode-linux-x64 hash... "
LINUX_X64_HASH=$(nix-prefetch-url --type sha256 https://registry.npmjs.org/opencode-linux-x64/-/opencode-linux-x64-${VERSION}.tgz 2>/dev/null)
echo "$LINUX_X64_HASH"

# Verify all hashes were fetched successfully
if [[ -z "$OPENCODE_AI_HASH" || -z "$DARWIN_ARM64_HASH" || -z "$DARWIN_X64_HASH" || -z "$LINUX_ARM64_HASH" || -z "$LINUX_X64_HASH" ]]; then
	echo "Error: Failed to fetch one or more hashes"
	exit 1
fi

echo -e "\nUpdating $FLAKE_FILE..."

# Update version
sed -i '' "s/version = \"[^\"]*\";/version = \"$VERSION\";/" "$FLAKE_FILE"

# Update checksums
sed -i '' "s/\"opencode-ai\" = \"[^\"]*\";/\"opencode-ai\" = \"$OPENCODE_AI_HASH\";/" "$FLAKE_FILE"
sed -i '' "s/\"opencode-darwin-arm64\" = \"[^\"]*\";/\"opencode-darwin-arm64\" = \"$DARWIN_ARM64_HASH\";/" "$FLAKE_FILE"
sed -i '' "s/\"opencode-darwin-x64\" = \"[^\"]*\";/\"opencode-darwin-x64\" = \"$DARWIN_X64_HASH\";/" "$FLAKE_FILE"
sed -i '' "s/\"opencode-linux-arm64\" = \"[^\"]*\";/\"opencode-linux-arm64\" = \"$LINUX_ARM64_HASH\";/" "$FLAKE_FILE"
sed -i '' "s/\"opencode-linux-x64\" = \"[^\"]*\";/\"opencode-linux-x64\" = \"$LINUX_X64_HASH\";/" "$FLAKE_FILE"

echo "Successfully updated $FLAKE_FILE with new hashes for version $VERSION"
