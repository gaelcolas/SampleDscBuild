# Build Output

This is where the Build process will output the artifacts by default.
As those artefacts are re-produceable, they're not kept in the VCS, hence the entry in the .gitignore file: `modules/*`

# Artefacts subfolders
The folder created by default during a complete build are the followings:
- Modules: Zipped and versioned Modules as expected by the pull server
- Tools: A copy of the DSC_Tooling folder (useful when DSC_Tooling uses symlinks)
- Configurations: The Compiled MOFs
- TestResults: The result of the (Pester) tests (NUnitXML and Pester out as CLIXML)