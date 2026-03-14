{ ... }:

{
  # Fingerprint reader (Framework 16)
  services.fprintd.enable = true;
  security.pam.services.sudo.fprintAuth = true;
  security.pam.services.hyprlock.fprintAuth = true;
}
