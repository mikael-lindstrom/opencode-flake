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
          version = "0.3.77";

          architectures = {
            "x86_64-linux" = "linux-x64";
            "aarch64-linux" = "linux-arm64";
            "x86_64-darwin" = "darwin-x64";
            "aarch64-darwin" = "darwin-arm64";
          };
          arch = architectures.${system} or (throw "unsupported system: ${system}");

          checksums = {
            "opencode-ai" = "1w1i7c4xq6cvwjjqfyh62zw65p8v4ll5h5qcm4bsp9m9g0lhns96";
            "opencode-darwin-arm64" = "04i8rja03mpiq48wapj4ccsmmqbffyf99mw3g8x3bn6yqi2fpi06";
            "opencode-darwin-x64" = "0l9rhdsdkrwqy1mfwy9ls75zr75malv06r5jy5nzhznirmxhnz42";
            "opencode-linux-arm64" = "18gdbwapcawpin024s19iy62qr02vpib6c6vgdhw8kaks0g3wa34";
            "opencode-linux-x64" = "1756v3vq71y2zfhpnmksklcck14afkbjag7avjr1siy929ika5f9";
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

