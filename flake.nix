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
          opencodeVersion = "1.19.0";
          opencode2Version = "2.0.28";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.19.0";
            "opencode-darwin-x64-version" = "1.19.0";
            "opencode-linux-arm64-version" = "1.19.0";
            "opencode-linux-x64-version" = "1.19.0";
            "opencode2-darwin-arm64-version" = "2.0.28";
            "opencode2-darwin-x64-version" = "2.0.28";
            "opencode2-linux-arm64-version" = "2.0.28";
            "opencode2-linux-x64-version" = "2.0.28";
          };

          checksums = {
            "opencode-root" = "1gdi8b3v2iz98gfpw2fvc11xnp57xp7xr5l2aqxkdb53qr3bzf7b";
            "opencode-darwin-arm64" = "118brirk5qf03jcjhy1sxgx90apwszvhpvh95pgfharj309g3k1g";
            "opencode-darwin-x64" = "0gfwxfcjv9lf0gkslbaca0qns5bqcmsvs3v3nnqflgfchyi4i045";
            "opencode-linux-arm64" = "13vpysvy5swci904dhbldvkr0wrbl376cirg5lq16l27bln110c4";
            "opencode-linux-x64" = "10kjbagbdi5n63m30i9l1y5hv15qq108ddv5ilm1a338gx4visbc";
            "opencode2-root" = "0icjlz8lzs54h39wyr9zmw5lalhnz4c3f8c18cb354jjgh93i388";
            "opencode2-darwin-arm64" = "08ai5fwxdbc6dvrzk55nzgdpk0adhg4jfyp5fym1q7yx7b62kwiw";
            "opencode2-darwin-x64" = "0f99gv398h4sr702hv931fabfv4f9ry02w86jyfvgbmkyk5ry8kf";
            "opencode2-linux-arm64" = "120xn7csan67pk350f8zkbxp69vr3ipvcxwyih362knrwm4p0p2p";
            "opencode2-linux-x64" = "1yf94v00q2d444bchy7y336yqm3ba96bf1gk53nnasgmm9dm1y3n";
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
