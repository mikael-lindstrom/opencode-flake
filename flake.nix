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
          opencodeVersion = "1.19.6";
          opencode2Version = "2.4.2";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.19.6";
            "opencode-darwin-x64-version" = "1.19.6";
            "opencode-linux-arm64-version" = "1.19.6";
            "opencode-linux-x64-version" = "1.19.6";
            "opencode2-darwin-arm64-version" = "2.4.2";
            "opencode2-darwin-x64-version" = "2.4.2";
            "opencode2-linux-arm64-version" = "2.4.2";
            "opencode2-linux-x64-version" = "2.4.2";
          };

          checksums = {
            "opencode-root" = "04vx52qd1qp4dcax0h0jz4vfad4zi9f576h0s3fcvka11f82lp7g";
            "opencode-darwin-arm64" = "1n1wdf1j094qwxgrx1hpcknvpi5chv3gs4c8q26lrjwdvwj83gvs";
            "opencode-darwin-x64" = "0gnzcj8n73fs4wjfxrmiy5nacsj7vwk9c7mi634cpsl9xrzs6y72";
            "opencode-linux-arm64" = "1qrjh8cyw9556xip726haiph40i9fnvlcbkfjqmxgpd28yzir4x5";
            "opencode-linux-x64" = "1zr12dvxm25l236k39bizqmj0sy56riv5f9m1qwn2gn64yl7p3rp";
            "opencode2-root" = "01l0gnacbdxn7r3as9r7xx1l7qwkvqcwl7ha4qx5978bixgry7ya";
            "opencode2-darwin-arm64" = "12j173r1iymmasjr4mxanhr0pjg35fzaf2cksij19crdm6xh9yiw";
            "opencode2-darwin-x64" = "0xbyqpxw2q54pkf9nxsc8mgv8f6a6k0n57qjn3kv81m2a9lr0p2n";
            "opencode2-linux-arm64" = "15dfk05q3v71js2yr779vsblyvnx1v2k29p2d6f379ywg9c7z16h";
            "opencode2-linux-x64" = "0nkgyn6b0d7bsz6xfj57s06121wgzfd659fmrci1chb8bk5qillr";
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
