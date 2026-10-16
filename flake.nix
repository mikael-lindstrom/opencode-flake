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
          opencodeVersion = "1.19.2";
          opencode2Version = "2.0.30";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.19.2";
            "opencode-darwin-x64-version" = "1.19.2";
            "opencode-linux-arm64-version" = "1.19.2";
            "opencode-linux-x64-version" = "1.19.2";
            "opencode2-darwin-arm64-version" = "2.0.30";
            "opencode2-darwin-x64-version" = "2.0.30";
            "opencode2-linux-arm64-version" = "2.0.30";
            "opencode2-linux-x64-version" = "2.0.30";
          };

          checksums = {
            "opencode-root" = "0h54grwy6xf3jw2p61dx6k6n6z709jwpczsr42ax3x5gdli4gijc";
            "opencode-darwin-arm64" = "1l71s23r5mjqxk4w636i40jhr5384q714gd0h360622cmgl41sp8";
            "opencode-darwin-x64" = "0ykffrcivp60k0vgg1zry3b1kwcpp2vwvxdbz2mnjfvn1dlgi658";
            "opencode-linux-arm64" = "09554xkmd9h7jvwxgj8bf21yixgsqs19ki4y2ynlpcnjlax64lvw";
            "opencode-linux-x64" = "118i4fp3pvxdylkyzwmv06hxh90w27ibmf3hysyj4v8xcis1v66i";
            "opencode2-root" = "1liqd5a2v0z03rhbq6sm9jxjgbaqqv6id0n0sah36n79jjn8krpd";
            "opencode2-darwin-arm64" = "0fm8vmrrfhw1s7pxny6jl8vygp47k6c9spvs7qsws3drlx5sdicg";
            "opencode2-darwin-x64" = "1ssbq7gwk0qzmw649mq161qmx6x476p75jcyrc868191vpk1csgn";
            "opencode2-linux-arm64" = "1kn9dqg98dqlxrjinp62mfnlxx4g8dn4hh0x4xn4il9sqdqx9sln";
            "opencode2-linux-x64" = "019jlgzj3n9xky19yrlvcxs84m9jwnhsbl9v4pb06bylzj3gvgpv";
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
