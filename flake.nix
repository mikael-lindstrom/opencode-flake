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
          opencodeVersion = "1.19.5";
          opencode2Version = "2.2.6";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.19.5";
            "opencode-darwin-x64-version" = "1.19.5";
            "opencode-linux-arm64-version" = "1.19.5";
            "opencode-linux-x64-version" = "1.19.5";
            "opencode2-darwin-arm64-version" = "2.2.6";
            "opencode2-darwin-x64-version" = "2.2.6";
            "opencode2-linux-arm64-version" = "2.2.6";
            "opencode2-linux-x64-version" = "2.2.6";
          };

          checksums = {
            "opencode-root" = "103ng2f8ywwfr670lhcl5qpdd5mak2zgivw2jii2m97qh69y95qz";
            "opencode-darwin-arm64" = "1x4anyy1wkrlg4j7piw3d91hlhvyxwwwxk95yghcyx8578qx9r20";
            "opencode-darwin-x64" = "035a6qjmil9li418z1v0ll6cf1a5n094pwdix6gxh3hc6wrmgvp6";
            "opencode-linux-arm64" = "16jjini4hqf6ji4rcdxawwfnxnkyzsm5075c1fh6grcgbk7g855s";
            "opencode-linux-x64" = "1q6m3p0153zwb9a86xg5xasy4g5hb3i1pzr2vfycpipc7lqgqz1d";
            "opencode2-root" = "1nqvpiagh58kbg2vzvnfq0l2lb17hg88ha6076m2xcmswspki85x";
            "opencode2-darwin-arm64" = "18rph5kvk8b8a2c3h5bzl9mr9nf481xs6hnlp5xpdzwfvmsbngk1";
            "opencode2-darwin-x64" = "05cslhc3vjv172nfrl6f7lcgc7kwbzys5m6vh4kf7v22nv07a52g";
            "opencode2-linux-arm64" = "164qd3xwarvz0qfdhn1603jqlci7nv1gbfb5iaj63v1h0qh2wd92";
            "opencode2-linux-x64" = "0l9msclpmfiqv9lwpkk4mb20q45qhhfv8s37cbni1bhispqnkkfz";
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
