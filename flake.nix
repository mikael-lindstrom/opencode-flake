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
          opencodeVersion = "1.18.34";
          opencode2Version = "2.0.23";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.18.34";
            "opencode-darwin-x64-version" = "1.18.34";
            "opencode-linux-arm64-version" = "1.18.34";
            "opencode-linux-x64-version" = "1.18.34";
            "opencode2-darwin-arm64-version" = "2.0.23";
            "opencode2-darwin-x64-version" = "2.0.23";
            "opencode2-linux-arm64-version" = "2.0.23";
            "opencode2-linux-x64-version" = "2.0.23";
          };

          checksums = {
            "opencode-root" = "0fxmy23phiqcq409a5f1sg5gr6bny4f419x8ffqi1s2layxj7697";
            "opencode-darwin-arm64" = "01dzsxlfk9fx26giishdn35jmfvsr079kldmci1zbj44xs8n2cws";
            "opencode-darwin-x64" = "02msmhb84szy5jjk94bx015xwxhkfdpizdf5nnr6djlp6rb5r8xx";
            "opencode-linux-arm64" = "04fklfbr03wsr78x6wa954lfkmszvffmar8n5w0p5gr61f1jn8bg";
            "opencode-linux-x64" = "06agp9f5v6rqba10iiqpk36jp8yglb9kk95nskm0abbmdp38lgmq";
            "opencode2-root" = "105i05mgzgkp57gsg5cmi4b5fdrmw2xqyhvx556kpa9gjj57b92b";
            "opencode2-darwin-arm64" = "0grjg3wkc25g44d8brzdc0vns63f9slzwnim4vspfznjnfmkyz6v";
            "opencode2-darwin-x64" = "1bs5jmhxp3whgq2c1iiwwh0nk814ydh103jljs4ddlzsyjkcf5hv";
            "opencode2-linux-arm64" = "152fkn6aq5y1a7d5r89dvm2a7hp2r12bahpqjlxifx69am8w2y3r";
            "opencode2-linux-x64" = "0j62cpy9i57p71ysa4pbnrajq4kza030dw1fiywhd81iq033k9zi";
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
