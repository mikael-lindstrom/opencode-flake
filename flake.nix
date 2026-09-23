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
          opencodeVersion = "1.18.32";
          opencode2Version = "2.0.15";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.18.32";
            "opencode-darwin-x64-version" = "1.18.32";
            "opencode-linux-arm64-version" = "1.18.32";
            "opencode-linux-x64-version" = "1.18.32";
            "opencode2-darwin-arm64-version" = "2.0.15";
            "opencode2-darwin-x64-version" = "2.0.15";
            "opencode2-linux-arm64-version" = "2.0.15";
            "opencode2-linux-x64-version" = "2.0.15";
          };

          checksums = {
            "opencode-root" = "1fp89gf97a3da678hzhycdkkymr5nka3h4c94c9s55fy581vnks5";
            "opencode-darwin-arm64" = "1gnypcmg6xpmw151jzr2zh6zg2hbb3qrfh0wa35crslxrjv7nw51";
            "opencode-darwin-x64" = "11hkb0xnsm22jv8j2wnz541pbg8rf4miyill2fr57jvkz20wvh79";
            "opencode-linux-arm64" = "0090kgipn8l6259hj9lfjrag4kqrp31ib4989lid368flxhjvar9";
            "opencode-linux-x64" = "1pn1w15h7jphcwikvr5zf1k96aak1gxwpbc4y320jrxqbv40626s";
            "opencode2-root" = "1ay8lpsnig03g2l268ywkr17zyyw2y13z1gm1h2bp6zpc4ay0v0v";
            "opencode2-darwin-arm64" = "0hjny2f78364vm1lkqhizdf3a6bwz0jmxdx7r1jzg6380drgqn86";
            "opencode2-darwin-x64" = "0r667p27gndkciw3shlmak86x7hfr1sy086rccvnxkjmdmwaj8fp";
            "opencode2-linux-arm64" = "0bz2c3754piw7n6gf1z7fljfff5b5ks31kvw3frkznq55kwvdmmd";
            "opencode2-linux-x64" = "1k24vbb2clmlbyvdcl6lhb9csynkqshxpb25mbimrpg5kryyi92v";
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
