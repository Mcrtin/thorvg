{
  description = "Zig build of ThorVG";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "aarch64-darwin" "x86_64-darwin" "aarch64-linux" "x86_64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems
        (system: f nixpkgs.legacyPackages.${system});
    in
    {
      devShells = forAllSystems (pkgs: {
        default = let
          # wgpu-native splits headers into .dev, and --search-prefix takes one
          # prefix, so join them.
          wgpu = pkgs.symlinkJoin {
            name = "wgpu-native-prefix";
            paths = [ pkgs.wgpu-native pkgs.wgpu-native.dev ];
          };
        in pkgs.mkShell {
          packages = [
            pkgs.zig_0_16 # build.zig.zon: .minimum_zig_version = "0.16.0"
            pkgs.llvmPackages.openmp # -Dopenmp=true: linkSystemLibrary("omp")
            pkgs.emscripten # -Dtarget=wasm32-emscripten: libc headers
          ]
          # -Dmedia_loader=true: sets SDKROOT for `zig build --sysroot "$SDKROOT"`
          ++ pkgs.lib.optional pkgs.stdenv.hostPlatform.isDarwin pkgs.apple-sdk;

          # zig build -Dtarget=wasm32-emscripten --sysroot "$EM_SYSROOT"
          EM_SYSROOT = "${pkgs.emscripten}/share/emscripten/cache/sysroot";

          # zig build -Dwg-engines=true --search-prefix "$WGPU_PREFIX"
          WGPU_PREFIX = "${wgpu}";
        };
      });
    };
}

