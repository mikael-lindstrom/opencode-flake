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
          opencode2Version = "2.2.0";

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
            "opencode2-darwin-arm64-version" = "2.2.0";
            "opencode2-darwin-x64-version" = "2.2.0";
            "opencode2-linux-arm64-version" = "2.2.0";
            "opencode2-linux-x64-version" = "2.2.0";
          };

          checksums = {
            "opencode-root" = "103ng2f8ywwfr670lhcl5qpdd5mak2zgivw2jii2m97qh69y95qz";
            "opencode-darwin-arm64" = "1x4anyy1wkrlg4j7piw3d91hlhvyxwwwxk95yghcyx8578qx9r20";
            "opencode-darwin-x64" = "035a6qjmil9li418z1v0ll6cf1a5n094pwdix6gxh3hc6wrmgvp6";
            "opencode-linux-arm64" = "16jjini4hqf6ji4rcdxawwfnxnkyzsm5075c1fh6grcgbk7g855s";
            "opencode-linux-x64" = "1q6m3p0153zwb9a86xg5xasy4g5hb3i1pzr2vfycpipc7lqgqz1d";
            "opencode2-root" = "1mfy816pn8yq6ihmyvhcmmmm0lwa2gaix6yhhwdxcq6zs1k28d5a";
            "opencode2-darwin-arm64" = "122nib8fybwmj67cfmqg80x3wmd5i9ig0plgmwhzlx7c4lsh6gn1";
            "opencode2-darwin-x64" = "08w879krq1gizn6mff4mnw32ixf0n2kibvgm8davhsdmsldpczp9";
            "opencode2-linux-arm64" = "12qb8vvznkq9vvfwdq8hp2mlcg00xv02cz686yfzyfna1ly68h3a";
            "opencode2-linux-x64" = "0a50ihdqk313i2ckl44kq7zyzwd10548y1b84bv29rkjd2w4cc7y";
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
