# Moosh personal release

Moosh is an unofficial GPL-3.0 fork of AltTab. `master` remains the upstream-sync branch and `personal` contains Moosh-specific changes. Release commits and tags must be ancestors of `origin/personal`.

## One-time repository setup

1. Create one stable self-signed code-signing certificate and export it as a password-protected PKCS#12 file. Keep using the same certificate for every Moosh build.
2. Create a Sparkle Ed25519 key pair with Sparkle's `generate_keys` tool. Never commit the private key.
3. Add Actions secrets:
   - `MOOSH_CERTIFICATE_P12_BASE64`: base64-encoded PKCS#12 file.
   - `MOOSH_CERTIFICATE_PASSWORD`: PKCS#12 password.
   - `MOOSH_SPARKLE_PRIVATE_KEY_BASE64`: base64-encoded Sparkle private-key file.
4. Add repository variable `MOOSH_SPARKLE_PUBLIC_KEY` containing the matching Sparkle public key.
5. In repository Settings → Pages, choose **GitHub Actions** as the source.

Changing either signing key after publishing updates breaks continuity. Back up both private keys and their passwords.

## Publish a release

Run **Release Moosh** from Actions while the desired commit is present on `personal`, then enter a semantic version such as `1.2.3`. The workflow builds only arm64, signs with the stable self-signed identity, creates `Moosh-1.2.3.zip` and `Moosh-1.2.3-arm64.dmg`, publishes tag `personal-v1.2.3`, creates a public GitHub Release, and deploys the signed Sparkle feed to GitHub Pages.

The workflow refuses commits outside `origin/personal`, missing secrets, invalid versions, invalid signatures, non-arm64 binaries, or an inaccessible Release archive.

## First launch

The app is not notarized. After copying Moosh to Applications, macOS may block its first launch. Control-click Moosh, choose **Open**, then confirm. Later Moosh updates are verified by Sparkle's Ed25519 signature.
