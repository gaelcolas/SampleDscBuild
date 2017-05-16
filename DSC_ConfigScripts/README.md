# DSC Configuration Scripts

This folder should contain the DSC Configuration Script(s), used across the infrastructure managed by DSC.
Those Configuration Scripts form the top layer of abstraction, leveraging a mix of multiple Composite Resources and other DSC Resources.

The exact way those Configuration Scripts are used depends on the unique way a company implements its abstraction layers, but I find helpful to follow some principles:
- Have those configuration _self-contained_ so they can be worked on separately and shared/re-used
- Include the ConfigData to set the defaults/examples, while avoiding hard dependencies
- Follow/Define a standard that the community follows, to be able to re-use/share without re-inventing the wheel. See [TemplateConfig](https://github.com/PowerShell/TemplateConfig)


