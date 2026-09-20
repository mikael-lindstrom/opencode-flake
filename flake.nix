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
          opencodeVersion = "1.18.31";
          opencode2Version = "2.0.11";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          platformVersions = {
            "opencode-darwin-arm64-version" = "1.18.31";
            "opencode-darwin-x64-version" = "1.18.31";
            "opencode-linux-arm64-version" = "1.18.31";
            "opencode-linux-x64-version" = "1.18.31";
            "opencode2-darwin-arm64-version" = "2.0.11";
            "opencode2-darwin-x64-version" = "2.0.11";
            "opencode2-linux-arm64-version" = "2.0.11";
            "opencode2-linux-x64-version" = "2.0.11";
          };

          checksums = {
            "opencode-root" = "0n8vvkk8h6maqh44nawbjkka5ark393ajjs7h5lhjbnd0cqabfmn";
            "opencode-darwin-arm64" = "0wfnaymjyfd4j8qi975b0zmc8xvr8pyxs1aznqck82szfq39myp1";
            "opencode-darwin-x64" = "1sll8hs3i2xc6zrqcxy2x02b5iksl0czw836zyk4f7vz42hlmkyz";
            "opencode-linux-arm64" = "1l35fjdzsz5a5ccr1if822rvrxlk74kbakbiwmy2ny62hacgqc4z";
            "opencode-linux-x64" = "1shd2il7nczfn0i85dq1a44zcp266kf9d0vj7s90s0wb58jxm2bd";
            "opencode2-root" = "08vs37p29axb7kl8nxrml1s6f4b4wwkadm1r12382g2ic6my0r0y";
            "opencode2-darwin-arm64" = "1xsckc70imvya7lia6vfwsias3rqysx8hvw1k17n2b99p1jbsimy";
            "opencode2-darwin-x64" = "17sq0ia8vla27nak3750a5b9pnzv4ks5a720wmi8l4wblq9s9dls";
            "opencode2-linux-arm64" = "17b28qycc0j0fh7x59ffmc36xz4qm53rlicwvbkfxka7dw8yvbwh";
            "opencode2-linux-x64" = "1fv68vlnld5zfjh5hhlyq7vgdza51k5sxmpy3ighhby9db26fb4h";
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
