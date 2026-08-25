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
          version = "1.18.22";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          checksums = {
            "opencode-ai" = "1rz4ri98s4fc150kf8d2nn3a66hjwpixf9hy2rfqc94zimzy234j";
            "opencode-darwin-arm64" = "15vn926vv1m5f599vmdcc5lmjm6vz60rl9pj8khyfgjqlqcl1kjw";
            "opencode-darwin-x64" = "0781fi873fc97hn6m0bs2phwkcqlmvf2yy2j478kmkx519r1rbgx";
            "opencode-linux-arm64" = "0ssgkzpp3hc2kdi61gzcwy0zsak13zahg2nqk4kwbb5yf5830d48";
            "opencode-linux-x64" = "0pwmppksy1dqlwzxwmwcmsjn75h06s3mlbax7s1d2jjalpjv1pmj";
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

