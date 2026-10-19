# Foundation tests

Run the contract and fail-closed tests from the repository root with:

```sh
swift test
```

The suite checks the exact health paths and HTTPS-only request construction, health/error JSON decoding, the complete current backend error-code set, rejection of unknown codes, the blocked SecurityChain-P0 status, and the explicit lack of Keychain support on non-Apple platforms.

This suite does not validate Xcode app bundles, actual Apple Keychain behavior, authentication, server connectivity, permissions, sensors, device pairing, or physical-device behavior. Those remain separate macOS/Xcode and approved device acceptance gates documented under `docs/`.
