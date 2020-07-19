![betaver](https://img.shields.io/badge/version-beta-yellow)

# Custom Metadata Loader
Create or Update Custom Metadata Type records from CSV file

- [Installation options](#installation)
  - [Url](#installation-url)
  - [Unlocked package](#installation-unlocked-pkg)
  - [Manual](#installation-clone-repo)
- [User guide](#user-guide)
  - [Supported field types](#user-guide-fields)
  - [CSV columns](#user-guide-csv-cols)
  - [Limitations](#user-guide-limitations)
- [Demo](#demo)
- [Credits](#credits)

# Installation options <a id="installation"></a>
<a href="https://githubsfdeploy.herokuapp.com/app/githubdeploy/maaaaarco/spaghetti-cmd-loader">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## URL (recommended) <a id="installation-url"></a>
- [Production/Developer](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t1t000002hzNuAAI)
- [Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t1t000002hzNuAAI)

This approach is recommended since all components will be deployed using a namespace, removing the chance of failures due to conflicting API names.

## Unlocked package (recommended) <a id="installation-unlocked-pkg"></a>
You can install this as an Unlocked Package, using the CLI, by running the following command:
```bash
sfdx force:package:install --package "04t1t000002hzNuAAI" --targetusername YOUR_ORG_ALIAS --wait 10 --publishwait 10
```
This approach is recommended since all components will be deployed using a namespace, removing the chance of failures due to conflicting API names.

## Manual <a id="installation-clone-repo"></a>
You can install this by cloning the repository and deploying the content of _cmd-loader_ folder. Before that you should remove the _namespace_ property in the _sfdx-project.json_ file.
```json
"namespace": "spaghettiCMD"
```

# User Guide <a id="user-guide"></a>
After deploying the application follow these step to enable it for your users:

1. Assign yourself, or ask your System Administrator to assign, the _Custom Metadata Loader_ permission set to your user
1. In the App Launcher search for _Custom Metadata Loader_ tab
1. Select the CSV file
1. Select the Custom Metadata Type
1. Click on _Load Records_ button

## Field types supported <a id="user-guide-fields"></a>
- Checkbox
- Date, the specified string should use the standard date format “yyyy-MM-dd”.
- Datetime, the specified string should use the standard date format “yyyy-MM-dd HH:mm:ss” in the local time zone.
- Email
- Number
- Percent
- Phone
- Picklist
- Text
- Text Area, supports multiline text
- Text Area Long, supports multiline text
- URL

## CSV columns <a id="user-guide-csv-cols"></a>
CSV columns must match the API name on your Custom Metadata Type fields. The CSV file must include these columns: 
- _DeveloperName_, is the unique identifier for the record 
- One between _MasterLabel_ or _Label_, for the record's label

## Limitations <a id="user-guide-limitations"></a>
This application does not impose any hard limit on the CSV file size or number of rows but it is subjected to all [Apex Governor Limit](https://developer.salesforce.com/docs/atlas.en-us.salesforce_app_limits_cheatsheet.meta/salesforce_app_limits_cheatsheet/salesforce_app_limits_platform_apexgov.htm).

If your CSV file contains more than 250 rows the application will automatically split it into smaller chunks of 250 rows each. Chunks will be loaded sequentially.

Since June 2020 the [Salesforce CLI](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm) released new commands to work with Custom Metadata Types. Among these there's one that allows records creation from a CSV file. You can read more about those commands [here](https://github.com/forcedotcom/cli/blob/master/releasenotes/README.md#48181-june-11-2020).

# Demo <a id="demo"></a>
YouTube video:

[![Demo Video](https://img.youtube.com/vi/abYr7B-5vsA/0.jpg)](https://www.youtube.com/watch?v=abYr7B-5vsA)

# Credits <a id="credits"></a>
- [Papa Parse](https://www.papaparse.com/) for its amazing Javascript CSV parser