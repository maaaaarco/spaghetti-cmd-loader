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

# Installation options <a href="installation"></a>
<a href="https://githubsfdeploy.herokuapp.com/app/githubdeploy/maaaaarco/spaghetti-cmd-loader">
  <img alt="Deploy to Salesforce"
       src="https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png">
</a>

## URL (recommended) <a href="installation-url"></a>
- [Production/Developer](https://login.salesforce.com/packaging/installPackage.apexp?p0=04t1t000003nP5hAAE)
- [Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04t1t000003nP5hAAE)

This approach is recommended since all components will be deployed using a namespace, removing the chance of failures due to conflicting API names.

## Unlocked package (recommended) <a href="installation-unlocked-pkg"></a>
You can install this as an Unlocked Package, using the CLI, by running the following command:
```bash
sfdx force:package:install --package "04t1t000003nP5hAAE" --targetusername YOUR_ORG_ALIAS --wait 10 --publishwait 10
```
This approach is recommended since all components will be deployed using a namespace, removing the chance of failures due to conflicting API names.

## Manual <a href="installation-clone-repo"></a>
You can install this by cloning the repository and deploying the content of _cmd-loader_ folder. Before that you should remove the _namespace_ property in the _sfdx-project.json_ file.
```json
"namespace": "spaghettiCMD"
```

# User Guide <a href="user-guide"></a>
1. Assign yourself, or ask your System Administrator to assign, the _Custom Metadata Loader_ permission set to your user
1. In the App Launcher search for _Custom Metadata Loader_ tab
1. Select the CSV file
1. Select the Custom Metadata Type
1. Click on _Load Records_ button

## Field types supported <a href="user-guide-fields"></a>
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

## CSV columns <a href="user-guide-csv-cols"></a>
CSV columns must match the API name on your Custom Metadata Type fields. The CSV file must include these columns: 
- _DeveloperName_, is the unique identifier for the record 
- One between _MasterLabel_ or _Label_, for the record's label

## Limitations <a href="user-guide-limitations"></a>
The only limitation that I have encountered so far during testing is the CSV file size.
Even though the theoretical limit would be around 6Mb (Apex heap size limit) the practical one is more like 140Kb. After multiple tests that seems to be a safe size that would not cause the application to hit any Governor Limit (like Apex CPU time, ecc...).

If your file is bigger than 140Kb you can still try to load it. If it fails then split it in smaller chunks. In future I plan to automate this.

# Demo <a href="demo"></a>
YouTube video:

[![Demo Video](https://img.youtube.com/vi/abYr7B-5vsA/0.jpg)](https://www.youtube.com/watch?v=abYr7B-5vsA)

# Credits <a href="credits"></a>
- [Papa Parse](https://www.papaparse.com/) for its amazing Javascript CSV parser