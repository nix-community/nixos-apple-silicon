## Release Model and Process

Development targets the `main` branch. Every feature PR targets this branch.

After major fixes and features, we fully test the main branch and create a
release, tagged as a commit on the main branch with the `release-YYYY-MM-DD`
tag. These releases supply a known-working installer image for new users.

### Nixpkgs compatibility

The `nixos-apple-silicon` `main` branch is only tested to work on NixOS
unstable. It is updated to fix incompatibilities as they arise.

Releases additionally represent a known-working commit of nixpkgs, both that can
build a correctly-functioning installer and that has packages available which
provide a proper user experience. However, they are performed much less
frequently than NixOS itself updates, so many users may prefer to track the
unstable branch directly and accept occasional issues.

Whenever a new NixOS release happens, we branch off a `release-YY.MM` branch,
which is updated to reference the corresponding stable NixOS commit. Users of
NixOS stable are encouraged to stay on this branch (instead of `main`). This
branch will only be updated to address breakages with the corresponding NixOS
stable release.

### Release process

Releases on the `main` branch are performed by maintainers using a PR against
the branch. The PR must be tested as below and contain the updates referenced
below. It may contain e.g. installer fixes as well. The PR should be approved
by at least one other maintainer or contributor before merging, though it does
not need to be tested on multiple machine types.

Stable releases are performed by maintainers first creating the branch to point
to current `main`. Then, a PR is created against the branch for the release.
This PR must contain the corresponding stable commit, and needs to be tested
for installed booting and functionality. It does not need installer testing,
nor a release date update or tag. The PR should be approved by at least one
other maintainer or contributor before merging, though it does not need to be
tested on multiple machine types.

#### Testing

 - The installer image (`.#installer-bootstrap`) is built on both
   `aarch64-linux` and `x86_64-linux`.
 - The installer (ideally `x86_64-linux`) is transferred to a USB drive, booted,
   and used to perform installation (i.e. `nixos-install` is re-run, this does
   not need a disk reformat or a re-run of the Asahi installer). This confirms
   the installer boots and that networking, disk access, and USB are
   functional. Installers for releases containing u-boot and m1n1 updates
   should be tested to boot again after installation as those upgrades can
   cause USB breakage.
 - Once installed, the system is booted and important features are tested.
    - Desktop environment (e.g. Plasma 6) starts and programs work
    - Networking connects
    - Hardware accelerated rendering is used
    - Speakers and microphone work
    - Other items a user would expect
 - Small broken items can be additional commits in the release PR, large items
   might need their own PR.

#### Release

 - Once validated, a release date is picked (might not be date of final merge)
    - Update date and software versions in guide and README
    - Write release notes including date
 - PR is filed with above testing work and commits. It must be updated to
   reference the current `main`! It should also reference the machine used. 
 - If PR falls behind `main`, it is re-based or `main` is merged into it
 - After approval and merge, the merge commit on `main` is tagged with the
   `release-YYYY-MM-DD` tag (filled in with release date) and the installer is
   automatically built and uploaded.
 - If the installer is not buildable in CI for some reason and a commit to fix
   is needed, a new release (on a different day) should be done.
