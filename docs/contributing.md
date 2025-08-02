## Release Model and Process

Development targets the `main` branch. Every PR targets this branch.

After major fixes and features, we fully test the main branch and create a
release, by tagging a commit from there with the `release-YYYY-MM-DD` tag.

### Nixpkgs compatibility
The `nixos-apple-silicon` `main` branch is only tested to work on NixOS unstable.

Whenever a new NixOS release happens, we branch off a `release-YY-MM` branch.
Users of NixOS stable are encouraged to stay on this branch (instead of `main`).
This branch will not be updated unless there's a breakage with stable.

### Release process

 - The installer image (`.#installer-bootstrap`) is built on both aarch64-linux
   and x86_64-linux.
 - Each installer is built, booted from it, and a re-installation is performed,
   to detect problems with booting, networking, and stuff essential to the new
   user experience. After that, important features are tested.
 - The guide is checked to be up to date (check git log for example)
 - The release notes are updated.
 - Once everything is good, the tested commit is tagged with the
   `release-YYYY-MM-DD` tag.
