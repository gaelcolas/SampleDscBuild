# Tools for build

This folder is a general purpose store for tools used during the development or build of DSC configurations. It is a convenient place to store scripts such as `New-SymLink.ps1` or `New-SelfSignedCertificateEx` that helps the development process on systems below Windows 10/2016.

It is also a pre-define place within the DSC Build repo to store unreleased tools, that can be injected by test-kitchen during testing, via symlinks to the [`modules`](../modules/) folder.