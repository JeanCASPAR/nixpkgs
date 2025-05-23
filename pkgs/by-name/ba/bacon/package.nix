{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  pkg-config,
  alsa-lib,
  versionCheckHook,
  bacon,
  buildPackages,
  nix-update-script,

  withSound ? false,
}:

let
  soundDependencies =
    lib.optionals stdenv.hostPlatform.isLinux [
      alsa-lib
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      # bindgenHook is only included on darwin as it is needed to build `coreaudio-sys`, a darwin-specific crate
      rustPlatform.bindgenHook
    ];
in

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "bacon";
  version = "3.13.0";

  src = fetchFromGitHub {
    owner = "Canop";
    repo = "bacon";
    tag = "v${finalAttrs.version}";
    hash = "sha256-8wxxg3Ahp8n2Zpr/3paqDkUShONLDBW/rgMSj9Vx5TQ=";
  };

  useFetchCargoVendor = true;
  cargoHash = "sha256-o5va9iEz/wKFNoosLYVtY3VRFwXwkOaROdxo7RBmfZk=";

  buildFeatures = lib.optionals withSound [
    "sound"
  ];

  nativeBuildInputs =
    [
      installShellFiles
    ]
    ++ lib.optionals withSound [
      pkg-config
    ];

  buildInputs = lib.optionals withSound soundDependencies;

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  doInstallCheck = true;

  postInstall =
    let
      bacon = "${stdenv.hostPlatform.emulator buildPackages} $out/bin/bacon";
    in
    lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) ''
      installShellCompletion --cmd bacon \
        --bash <(COMPLETE=bash ${bacon}) \
        --fish <(COMPLETE=fish ${bacon}) \
        --zsh <(COMPLETE=zsh ${bacon})
    '';

  passthru = {
    tests = {
      withSound = bacon.override { withSound = true; };
    };
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Background rust code checker";
    mainProgram = "bacon";
    homepage = "https://github.com/Canop/bacon";
    changelog = "https://github.com/Canop/bacon/blob/v${finalAttrs.version}/CHANGELOG.md";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [
      FlorianFranzen
      matthiasbeyer
    ];
  };
})
