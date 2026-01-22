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
          version = "1.1.31";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          checksums = {
            "opencode-ai" = "0nvi3xksdixkar9hz968ynkn4xnknw6yd4bp1v1ij4fx3ca8f5fr";
            "opencode-darwin-arm64" = "1ymzxkd5dnbxhqav2amam14wdpbryd8ahl22khr8afsiv4a5x5m5";
            "opencode-darwin-x64" = "1gxja0kc6d44lf2smmaa164cbgnm611cscjdkzr7l60r3rhmf71a";
            "opencode-linux-arm64" = "04ygdhaw4bcza5f22b6nzw4mji741ribb9h0n4q2frbvbac618ya";
            "opencode-linux-x64" = "0qcw11m860g0k2q49awgv2fc65ggfgwzsnhwca78ypnykzs82ygf";
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

