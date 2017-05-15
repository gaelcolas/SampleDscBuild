# DSC Configuration Data

In this folder, you should store the files necessary for the ConfigurationData.

For instance, you could use a Static `.psd1` document and the file to load it, or if you use a custom data source, you could store the required script to load the data.

Should you use [Datum](https://github.com/gaelcolas/Datum), you would store the Datum.yml that contains the structure, the required data files, plus the file that would load the ConfigData in the `$ConfigurationData` variable.