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
          opencodeVersion = "1.19.4";
          opencode2Version = "2.1.4";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.19.4";
            "opencode-darwin-x64-version" = "1.19.4";
            "opencode-linux-arm64-version" = "1.19.4";
            "opencode-linux-x64-version" = "1.19.4";
            "opencode2-darwin-arm64-version" = "2.1.4";
            "opencode2-darwin-x64-version" = "2.1.4";
            "opencode2-linux-arm64-version" = "2.1.4";
            "opencode2-linux-x64-version" = "2.1.4";
          };

          checksums = {
            "opencode-root" = "0dwid95plx67wxbdcya2sx3mcr23xm8xdmplsgfm1g8bgrfa9v1c";
            "opencode-darwin-arm64" = "0ax15xnb4fmflrw6h9shzy8ba811p0lb2h8s2k99w7a65gyfir3r";
            "opencode-darwin-x64" = "043jzv4y2ikaw4jvz2pqxj51v12wyfxp4vn3zxaksm5804n412pa";
            "opencode-linux-arm64" = "14d9y1fx44231rbh57i8yg4hpvly3xp2s7fz5hn5vbxk7r73g701";
            "opencode-linux-x64" = "03cdcnpbflyg6rry9s4rjdnkayq5539rqy8vd2riljjfpdmv19yw";
            "opencode2-root" = "1mpwdmvx7i7hc1gfb6654pzr1f3jl5pn78938fnajxfyi6mzpx07";
            "opencode2-darwin-arm64" = "19dza4w3h6sjjjfhmjwwhjkq1g0lcl6rxvdfrh6hk1bqy82gx8ns";
            "opencode2-darwin-x64" = "1zmksq334jj46i0klspvlqfvz0si0csg9svy18sazyqcmff7yrsq";
            "opencode2-linux-arm64" = "0qc8g27a8n9l12z4qf9kcnadibd6amj1dalkjq9k5i4s7bib9b79";
            "opencode2-linux-x64" = "1q8i3r29q26bdn2aqwhy8zyl1xk6l26xp37cr28i6171vkian1ff";
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
