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
          opencodeVersion = "1.19.3";
          opencode2Version = "2.1.0";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.19.3";
            "opencode-darwin-x64-version" = "1.19.3";
            "opencode-linux-arm64-version" = "1.19.3";
            "opencode-linux-x64-version" = "1.19.3";
            "opencode2-darwin-arm64-version" = "2.1.0";
            "opencode2-darwin-x64-version" = "2.1.0";
            "opencode2-linux-arm64-version" = "2.1.0";
            "opencode2-linux-x64-version" = "2.1.0";
          };

          checksums = {
            "opencode-root" = "1p4hd485nm785i4v62mlkmkmfvylxf13zvj0rgxvsf4lp5da188c";
            "opencode-darwin-arm64" = "0ckv32r013lx2k578nhchyp992rfaq9di5igf1qzk78gy3qkq3bb";
            "opencode-darwin-x64" = "12474l749ffm76dr2lniz56rcw3j2rczr545j1jc1d7lq02xf9fc";
            "opencode-linux-arm64" = "1g3hzb97px5x2wd4v4aanc90bjflh9hlqx22qw0rp1bdc5f275rc";
            "opencode-linux-x64" = "1insi10sv2z8n84i8c9blwrnbkgdsnqhcs5rivzsfy20xc9pbmki";
            "opencode2-root" = "0xwdfy3l1bqbd0k8avjzwjknymy1rq1lxg4kz5p7bs8f0v7km2nl";
            "opencode2-darwin-arm64" = "0bw4hlsdb6g31zg32ply61b52s059dx5irf8bxyw4wxibbdhzz7r";
            "opencode2-darwin-x64" = "0nswcpqmxklw0j70p8nvh61h0flk3x8h23gpvpd3d82n7hdhxg9p";
            "opencode2-linux-arm64" = "09nkxqi9pmk3gb6rixxxad3k07cm72hbhjkcj74lb2qpsxmnpk07";
            "opencode2-linux-x64" = "1vjjaa5yhmxhvczrbwa09nwi9pqf13v2p4zkhjzvl971mmv9l4ns";
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
