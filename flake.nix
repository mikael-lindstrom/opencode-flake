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
          version = "1.18.9";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          checksums = {
            "opencode-ai" = "0agka4xzl49nm1z3mr3ikcn9mxwszn57ip1b6wd50mpxi7bja06n";
            "opencode-darwin-arm64" = "0wf5km9bwhi2s54qa782q70rqa6sywyndxgl30bb757hd372a7ld";
            "opencode-darwin-x64" = "0byq98s99fkfxfhfkz4xdd39fhxmnj9szrcpfg91yfj0mgl001g8";
            "opencode-linux-arm64" = "1rxac1zh2c6pi5nbknsdsi7mf1ncj6i44r0j17r50ybrf3jafij8";
            "opencode-linux-x64" = "1plwl3x8f671szkd91dmrf120r0yyq5dpnja0sj2wvqd9kz56dkf";
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

