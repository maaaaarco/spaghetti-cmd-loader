# Custom Metadata Loader
Create or Update Custom Metadata Type records from CSV file

# Installation Options

## As Unlocked package
You can install this as an Unlocked Package, using the CLI, by running the following command:
```
sfdx force:package:install --package "04t1t000003nP5NAAU" --targetusername YOUR_ORG_ALIAS --wait 10 --publishwait 10
```

## Clone repository
You can install this by cloning the repository and deploying the content of _cmd-loader_ folder. Before that you should remove the _namespace_ property in the _sfdx-project.json_ file.
```
"namespace": "spaghettiCMD"
```

# User Guide

1. Assign yourself, or ask your System Administrator to assign, the _Custom Metadata Loader_ permission set to your user
2. In the App Launcher search for _Custom Metadata Loader_ tab
3. Select the CSV file
4. Select the Custom Metadata Type
5. Press Load Records

## Demo
[![Demo Video](https://img.youtube.com/vi/abYr7B-5vsA/0.jpg)](https://www.youtube.com/watch?v=abYr7B-5vsA)

# Notes
## CSV columns
CSV columns must match the API name on your Custom Metadata Type fields. The CSV file must include these columns: 
- _DeveloperName_, is the unique identifier for the record 
- One between _MasterLabel_ or _Label_, for the record's label
## Date field
The specified string should use the standard date format “yyyy-MM-dd”.
## Datetime field
The specified string should use the standard date format “yyyy-MM-dd HH:mm:ss” in the local time zone.