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
          version = "1.1.16";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          checksums = {
            "opencode-ai" = "0b6b3f29knj9cm93ynqss9j3d6dw1hgl0wxasx01gghq0dix1b8a";
            "opencode-darwin-arm64" = "0xj5bms760qdm04zcrlzd7dqh2g6rdxd4cwx146bvcj4x5hghlnw";
            "opencode-darwin-x64" = "0san28qpnkzxzaahzap2lk2w5zrbp400w17qw1d3clbipfr0b5i0";
            "opencode-linux-arm64" = "0bbkp1007qb92yk6rrqaas6z47fls44gp24v5z3ljp2wqbfjlykb";
            "opencode-linux-x64" = "0hfqdjrjkn48qs55y0zsqqbqvvfbxdx5p04hrxxxk5j56davvvh2";
          };
          opencodeSha = checksums."opencode-ai";
          platformSha = checksums."opencode-${arch}" or (throw "no sha for: opencode-${arch}");

          platformPackage = "opencode-${arch}";

          opencode = pkgs.stdenv.mkDerivation {
            pname = "opencode";
            inherit version;

            src = pkgs.fetchurl {
              url = "https://registry.npmjs.org/opencode-ai/-/opencode-ai-${version}.tgz";
              sha256 = opencodeSha;
            };

            platformSrc = pkgs.fetchurl {
              url = "https://registry.npmjs.org/${platformPackage}/-/${platformPackage}-${version}.tgz";
              sha256 = platformSha;
            };

            nativeBuildInputs = [ pkgs.makeWrapper ];

            installPhase = ''
              mkdir -p $out/{bin,lib/{opencode-ai,${platformPackage}}}
              tar -xzf $src --strip-components=1 -C $out/lib/opencode-ai
              tar -xzf $platformSrc --strip-components=1 -C $out/lib/${platformPackage}
              ln -s $out/lib/${platformPackage}/bin/opencode $out/bin/opencode
              chmod +x $out/bin/opencode
              wrapProgram $out/bin/opencode --set OPENCODE_BIN_PATH $out/lib/${platformPackage}/bin/opencode
            '';

            meta = {
              description = "AI coding agent, built for the terminal.";
              homepage = "https://github.com/sst/opencode";
              license = pkgs.lib.licenses.mit;
              platforms = [ system ];
            };
          };
        in
        {
          packages.default = opencode;

          devShells.default = pkgs.mkShell {
            buildInputs = [ opencode ];
          };
        };
    };
}

