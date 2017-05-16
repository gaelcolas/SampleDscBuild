# Modules for Test-kitchen

This folder is specific to Test-kitchen's DSC provisionner (Kitchen-DSC), as it automatically injects those dependencies to the target node (packs and send the content via WinRM).

I've put this for documentation purposes mainly, as my trick to avoid duplicate data is to use SymLinks.

You could use a SymLink to the DSC_Tooling, or to individual Subfolder (more flexible IMO).