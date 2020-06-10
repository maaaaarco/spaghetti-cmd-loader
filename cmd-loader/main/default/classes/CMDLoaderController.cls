/*
 * Copyright (c) 2020 Marco Zeuli
 * Licensed under MIT license.
 * For full license text, see LICENSE file in the repo root or https://opensource.org/licenses/MIT
 * If you would like to contribute https://github.com/maaaaarco/spaghetti-cmd-loader
 */

/**
 *  Controller class for cmdLoader LWC
 */
public with sharing class CMDLoaderController {
  
  public class RecordWrapper {
    @AuraEnabled
    public List<FieldWrapper> fields { get; set; }

    public RecordWrapper() {
      this.fields = new List<FieldWrapper>();
    }
  }

  public class FieldWrapper {
    @AuraEnabled
    public String fieldName { get; set; }
    @AuraEnabled
    public String fieldValue { get; set; }
  }

  public class DeploymentStatusWrapper {
    @AuraEnabled
    public Boolean done { get; set; }
    @AuraEnabled
    public Boolean success { get; set; }
    @AuraEnabled
    public String result { get; set; }

    public DeploymentStatusWrapper() {
      done = false;
      success = false;
    }
  }

  /**
   * Returns a list of available Custom Metadata Types
   * @return   a list containing Custom Metadata Type API names or an empty one
   */
  @AuraEnabled
  public static List<String> retrieveCustomMetadataTypes() {
    List<String> res = new List<String>();
    for (EntityDefinition ed : [
      SELECT QualifiedApiName
      FROM EntityDefinition
      WHERE IsCustomizable = true AND KeyPrefix LIKE 'm%'
      ORDER BY QualifiedApiName ASC
    ]) {
      if (ed.QualifiedApiName.endsWithIgnoreCase(CMDConstants.MDT_SUFFIX)) {
        res.add(ed.QualifiedApiName);
      }
    }
    return res;
  }

  /**
   * Checks deployment's result by querying the chatter feed of current user.
   * NOTE:
   *    I consider this an hack but I was not able to figure out a quick and easy way to
   *    invoke REST Metadata API from Apex. I don't want to use the SOAP Metadata API because
   *    I do not want to generate and maintain the wsdl classes.
   * @param  deployId Deployment id
   * @return          An instance of DeploymentStatusWrapper
   */
  @AuraEnabled
  public static DeploymentStatusWrapper checkDeployment(String deployId) {
    DeploymentStatusWrapper res = new DeploymentStatusWrapper();

    try {
      for (FeedItem feed : [
        SELECT Body
        FROM FeedItem
        WHERE ParentId = :UserInfo.getUserId() AND CreatedDate = TODAY
        LIMIT 1000
      ]) {
        // looks for deploymentId value in the chatter post
        if (feed.Body.containsIgnoreCase(deployId)) {
          res.done = true;
          // search the word Succeeded in the post
          res.success = feed.Body.split('\n')[0]
            .contains(Metadata.DeployStatus.SUCCEEDED.name());
          res.result = feed.Body;
        }
      }
    } catch (Exception unexpected) {
      res.done = true;
      res.success = false;
      res.result =
        'Unexpected exception occurred, message is: ' + unexpected.getMessage();
    }

    return res;
  }

  /**
   * Insert or update existing Custom Metadata records
   * @param  cmdType Custom Metadata Type api name
   * @param  records Records to insert/update
   * @return         The Metadata Api deployment id
   * @throws  AuraHandledException if an error occurs
   */
  @AuraEnabled
  public static Id upsertRecords(String cmdType, List<RecordWrapper> records) {
    Id deployJobId = null;

    try {
      Schema.DescribeSObjectResult objMetadata = Schema.describeSObjects(
        new List<String>{ cmdType }
      )[0];
      
      Map<String, Schema.SObjectField> fieldMap = objMetadata.fields.getMap();
      
      // component's name without __mdt suffix, used to set fullName attribute on records
      final String cmdTypeBaseName = cmdType.replace(CMDConstants.MDT_SUFFIX, '');

      // deploy container
      Metadata.DeployContainer container = new Metadata.DeployContainer();
      
      for (RecordWrapper recordWrapper : records) {
        Metadata.CustomMetadata customMetadataRecord = new Metadata.CustomMetadata();

        for (FieldWrapper fieldWrapper : recordWrapper.fields) {
          if (fieldWrapper.fieldName == CMDConstants.DEVELOPER_NAME_FIELD_NAME) {
            customMetadataRecord.fullName = cmdTypeBaseName + '.' + fieldWrapper.fieldValue;
          } else if (
            CMDConstants.MASTER_LABEL_FIELD_NAMES.contains(fieldWrapper.fieldName)
          ) {
            customMetadataRecord.label = fieldWrapper.fieldValue;
          } else {
            Schema.DisplayType fieldType = fieldMap.get(fieldWrapper.fieldName)
              .getDescribe()
              .getType();
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = fieldWrapper.fieldName;

            if (String.isNotBlank(fieldWrapper.fieldValue)) {
              // cast generic string value to proper primitive type
              switch on fieldType {
                when BOOLEAN {
                  customField.value = (Object) Boolean.valueOf(
                    fieldWrapper.fieldValue
                  );
                }
                when DATE {
                  customField.value = (Object) Date.valueOf(fieldWrapper.fieldValue);
                }
                when DATETIME {
                  customField.value = (Object) Datetime.valueOf(
                    fieldWrapper.fieldValue
                  );
                }
                when DOUBLE {
                  customField.value = (Object) Double.valueOf(fieldWrapper.fieldValue);
                }
                when INTEGER {
                  customField.value = (Object) Integer.valueOf(
                    fieldWrapper.fieldValue
                  );
                }
                when LONG {
                  customField.value = (Object) Long.valueOf(fieldWrapper.fieldValue);
                }
                when EMAIL, PICKLIST, REFERENCE, STRING, TEXTAREA, URL {
                  // string
                  customField.value = fieldWrapper.fieldValue;
                }
              }
            } else {
              customField.value = null;
            }

            customMetadataRecord.values.add(customField);
          }
        }

        container.addMetadata(customMetadataRecord);
      }

      deployJobId = Metadata.Operations.enqueueDeployment(
        container,
        new CMDDeployCallback()
      );
    } catch (Exception unexpected) {
      throw new AuraHandledException(
        'Unexpected exception occurred, message is: ' + unexpected.getMessage()
      );
    }

    return deployJobId;
  }
}
