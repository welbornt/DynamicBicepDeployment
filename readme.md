# Dynamic Bicep Deployment

This is an example project.

While using a .bicepparam file is generally the prefered method, using a JSON file allows us to use a centralized configuration file for both the deployment script and the Bicep file. Additionally, Bicep has issues when passing command line arguments because it causes the Bicep validation to fail in some situations.

This solution allows the parameters to be defined once in the JSON file and then used in both the PowerShell deployment script as well as the Bicep template.
