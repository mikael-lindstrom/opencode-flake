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
          opencode2Version = "2.0.29";

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
            "opencode2-darwin-arm64-version" = "2.0.29";
            "opencode2-darwin-x64-version" = "2.0.29";
            "opencode2-linux-arm64-version" = "2.0.29";
            "opencode2-linux-x64-version" = "2.0.29";
          };

          checksums = {
            "opencode-root" = "1gdi8b3v2iz98gfpw2fvc11xnp57xp7xr5l2aqxkdb53qr3bzf7b";
            "opencode-darwin-arm64" = "118brirk5qf03jcjhy1sxgx90apwszvhpvh95pgfharj309g3k1g";
            "opencode-darwin-x64" = "0gfwxfcjv9lf0gkslbaca0qns5bqcmsvs3v3nnqflgfchyi4i045";
            "opencode-linux-arm64" = "13vpysvy5swci904dhbldvkr0wrbl376cirg5lq16l27bln110c4";
            "opencode-linux-x64" = "10kjbagbdi5n63m30i9l1y5hv15qq108ddv5ilm1a338gx4visbc";
            "opencode2-root" = "1qgw1h24azvvsfkw85r0n7jy1sr7hbdvi8253gmhqfshrbp1li88";
            "opencode2-darwin-arm64" = "059fd57s3pdqqljvrlhfcyy9vfw5fvsi0zj0w3qxgzz6wwb9mxz4";
            "opencode2-darwin-x64" = "1b9hb1dxg4hmy8akn6qrczxylpjp4ps9g8a6f5vpx7wglbrr1fdh";
            "opencode2-linux-arm64" = "1bl348ijy9qlhr8h6hh8116b9h6wnigz67jkiw7w5b6zvdsrxwqa";
            "opencode2-linux-x64" = "18ihcpi8qrnc5il4p104bm29phhh9f29qnc4sk4kl28si9isdd8l";
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
