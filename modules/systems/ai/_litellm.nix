# LiteLLM with a working Prisma client for its database
{ pkgs, lib }:
let
  # Prisma (LiteLLM's DB layer) can't download its engines on NixOS: generate the
  # Python client at build time and point it at nixpkgs' engines and CLI
  python = pkgs.python3.override {
    self = python;
    packageOverrides = _: pysuper: {
      prisma = pysuper.prisma.overridePythonAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.prisma_6 ];
        postInstall = (old.postInstall or "") + ''
          # Skips the pinned-engine version check; the engines come from prisma_6
          export HOME=$TMPDIR PRISMA_PY_DEBUG_GENERATOR=1
          mkdir -p $TMPDIR/bin
          printf '#!/bin/sh\nexec ${python.interpreter} -m prisma "$@"\n' > $TMPDIR/bin/prisma-client-py
          chmod +x $TMPDIR/bin/prisma-client-py
          PATH=$TMPDIR/bin:$PATH PYTHONPATH=$out/${python.sitePackages}:$PYTHONPATH \
            prisma generate --schema ${pkgs.litellm.src}/litellm/proxy/schema.prisma
        '';
      });
    };
  };
  litellm = (pkgs.litellm.override { python3Packages = python.pkgs; }).overridePythonAttrs (old: {
    makeWrapperArgs = (old.makeWrapperArgs or [ ]) ++ [
      "--prefix PATH : ${
        lib.makeBinPath [
          pkgs.prisma_6
          pkgs.openssl
        ]
      }"
      "--set PRISMA_QUERY_ENGINE_BINARY ${pkgs.prisma-engines_6}/bin/query-engine"
    ];
  });
in
{
  inherit python litellm;
}
