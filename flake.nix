{
  description = "OpenCode - A powerful terminal-based AI assistant for developers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];

      perSystem = { pkgs, system, ... }:
        let
          opencodeVersion = "1.18.33";
          opencode2Version = "2.0.19";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.18.33";
            "opencode-darwin-x64-version" = "1.18.33";
            "opencode-linux-arm64-version" = "1.18.33";
            "opencode-linux-x64-version" = "1.18.33";
            "opencode2-darwin-arm64-version" = "2.0.19";
            "opencode2-darwin-x64-version" = "2.0.19";
            "opencode2-linux-arm64-version" = "2.0.19";
            "opencode2-linux-x64-version" = "2.0.19";
          };

          checksums = {
            "opencode-root" = "0z09hi7h4chl4k27wbskxxiqcq80w9dg3w5fasfivpq4bm235vbg";
            "opencode-darwin-arm64" = "07dk0yxfzqbqc9b2win9ncqsm39z70r2pjibk5i7n4sksr570b6d";
            "opencode-darwin-x64" = "0cpzns5ksmvwwkbcb1z9wslz1lk3mj5vgds7z7di8qml9mnz6g72";
            "opencode-linux-arm64" = "14sbwpkbnmybicisazp8lk3nnzpa752g2pzi5v8zqlq53jphqv8r";
            "opencode-linux-x64" = "1hd37ipl9pm33f4w8mvb6an2k0scsgdjznmb4rk1jjr2b5mng6hl";
            "opencode2-root" = "0xpyjkjcgk0mmzb67627a6d9klbrls5q9pba5g74s7pi8jrc8wmr";
            "opencode2-darwin-arm64" = "09c2dch57l95jcgl1j4fp9bjsfjc237ijkry7ndlwr45wbix63mq";
            "opencode2-darwin-x64" = "13a7grn47knnq75a2yrbmbn61w6zybyrbgxyw2ck09i279r95a78";
            "opencode2-linux-arm64" = "08gxygyg6f97k8x00r4nxgpi5pakcqdc7rhgxmc51hadhp6nca7x";
            "opencode2-linux-x64" = "1vr7srcfd508jv0d7bjj46lglfsx6zm9bnb480bmicmlmjkfah8h";
          };

          mkOpencode =
            { pname
            , version
            , rootPackage
            , rootTarball
            , platformPackagePrefix
            , platformTarballPrefix
            , sourceBinaryName
            , binaryName
            }:
            let
              platformPackage = "${platformPackagePrefix}${arch}";
              platformTarball = "${platformTarballPrefix}${arch}";
              platformVersion = platformVersions."${pname}-${arch}-version"
                or (throw "no version for: ${pname}-${arch}");
            in
            pkgs.stdenv.mkDerivation {
              inherit pname version;

              src = pkgs.fetchurl {
                url = "https://registry.npmjs.org/${rootPackage}/-/${rootTarball}-${version}.tgz";
                sha256 = checksums."${pname}-root";
              };

              platformSrc = pkgs.fetchurl {
                url = "https://registry.npmjs.org/${platformPackage}/-/${platformTarball}-${platformVersion}.tgz";
                sha256 = checksums."${pname}-${arch}" or (throw "no sha for: ${pname}-${arch}");
              };

              nativeBuildInputs = [ pkgs.makeWrapper ];

              installPhase = ''
                mkdir -p $out/bin $out/lib/${pname}/{root,platform}
                tar -xzf $src --strip-components=1 -C $out/lib/${pname}/root
                tar -xzf $platformSrc --strip-components=1 -C $out/lib/${pname}/platform
                ln -s $out/lib/${pname}/platform/bin/${sourceBinaryName} $out/bin/${binaryName}
                chmod +x $out/bin/${binaryName}
                wrapProgram $out/bin/${binaryName} \
                  --set OPENCODE_BIN_PATH $out/lib/${pname}/platform/bin/${sourceBinaryName}
              '';

              meta = {
                description = "AI coding agent, built for the terminal";
                homepage = "https://github.com/anomalyco/opencode";
                license = pkgs.lib.licenses.mit;
                mainProgram = binaryName;
                platforms = builtins.attrNames architectures;
              };
            };

          opencode = mkOpencode {
            pname = "opencode";
            version = opencodeVersion;
            rootPackage = "opencode-ai";
            rootTarball = "opencode-ai";
            platformPackagePrefix = "opencode-";
            platformTarballPrefix = "opencode-";
            sourceBinaryName = "opencode";
            binaryName = "opencode";
          };

          opencode2 = mkOpencode {
            pname = "opencode2";
            version = opencode2Version;
            rootPackage = "@opencode/cli";
            rootTarball = "cli";
            platformPackagePrefix = "@opencode/cli-";
            platformTarballPrefix = "cli-";
            sourceBinaryName = "opencode";
            binaryName = "opencode2";
          };
        in
        {
          packages = {
            default = opencode;
            inherit opencode opencode2;
          };

          checks.coexistence = pkgs.buildEnv {
            name = "opencode-coexistence";
            paths = [ opencode opencode2 ];
          };

          devShells.default = pkgs.mkShell {
            packages = [ opencode pkgs.curl pkgs.jq ];
          };
        };
    };
}
