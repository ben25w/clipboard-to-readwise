# Clipboard to Readwise

Native macOS menu-bar utility for saving clipboard text to Readwise highlights.

## Behavior

- Click the menu-bar highlighter to send the current clipboard text to Readwise.
- The first paragraph becomes the Readwise document title.
- Following paragraphs, or form-feed page breaks, become individual highlights.
- If the clipboard has one paragraph, it is used as both title and the single highlight.
- Success shows a short green check state in the menu bar. Failures show a macOS notification.

The app posts to `https://readwise.io/api/v2/highlights/` with `source_type: clipboard_to_readwise`, `location_type: order`, and 1-based `location` values.

## Setup

1. Build and run:

   ```bash
   ./script/build_and_run.sh
   ```

2. On first launch, open Settings from the menu-bar icon if it is not already visible.
3. Paste your Readwise API token from `https://readwise.io/access_token`.
4. Choose an optional author and category.
5. Use **Test Connection** to verify the token.

## Privacy

The Readwise token is stored in macOS Keychain. Clipboard text is read only when you choose **Send Clipboard to Readwise** or click the highlighter. The app does not request camera, microphone, contacts, calendar, location, Apple Events, or broad file-system permissions.

## Local Testing

```bash
swift test
./script/build_and_run.sh --verify
```

## Releases

Create an unsigned/ad-hoc local zip for personal testing:

```bash
./script/release.sh
```

Create a Developer ID signed zip:

```bash
SIGN_MODE=developer-id ./script/release.sh
```

Create and notarize with a stored notarytool profile:

```bash
SIGN_MODE=developer-id NOTARY_KEYCHAIN_PROFILE=your-profile ./script/release.sh
```

The default GitHub Release artifact is:

```text
release/Clipboard-to-Readwise-macOS.zip
```

If the app is ad-hoc signed or unsigned, Gatekeeper may warn when opening it on another Mac. Public GitHub releases should use Developer ID signing and notarization.
