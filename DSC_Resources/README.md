# DSC Resources

This is where the Build process will load the DSC resources from, instead of the local system (i.e. It will not load from the $PSmodulePath).
The aim is to decouple the build process with the system so that it can run anywhere (such as on a transient build Agent) to ensure reproduceability, and dependency management.
Also, the Build process should take those resources and make them ready to be published to the DSC Pull server (Module_version.zip).

As it could be inneficient and unpractical to store all modules and DSC Resources within the DSC repository, it is possible to workaround this by using PSDepend to bootstrap the DSC_Resources folder, by pulling the required modules and appropriate version at Build Time.
