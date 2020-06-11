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
        'Unexpected exception occurred while checking deployment status, message is: ' +
        unexpected.getMessage();
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
      // in case cmdType is not a valid object this will throw an exception
      Schema.DescribeSObjectResult[] objMetadata = Schema.describeSObjects(
        new List<String>{ cmdType }
      );

      Map<String, Schema.SObjectField> fieldMap = objMetadata[0]
        .fields.getMap();

      // component's name without __mdt suffix, used to set fullName attribute on records
      final String cmdTypeBaseName = cmdType.replace(
        CMDConstants.MDT_SUFFIX,
        ''
      );

      // deploy container
      Metadata.DeployContainer container = new Metadata.DeployContainer();

      for (RecordWrapper recordWrapper : records) {
        Metadata.CustomMetadata customMetadataRecord = new Metadata.CustomMetadata();

        for (FieldWrapper fieldWrapper : recordWrapper.fields) {
          if (
            fieldWrapper.fieldName == CMDConstants.DEVELOPER_NAME_FIELD_NAME
          ) {
            customMetadataRecord.fullName =
              cmdTypeBaseName +
              '.' +
              fieldWrapper.fieldValue;
          } else if (
            CMDConstants.MASTER_LABEL_FIELD_NAMES.contains(
              fieldWrapper.fieldName
            )
          ) {
            customMetadataRecord.label = fieldWrapper.fieldValue;
          } else {
            Schema.SObjectField objField = fieldMap.get(fieldWrapper.fieldName);

            if (objField == null) {
              throw new AuraHandledException(
                String.format(
                  'Field {0} does not exist on {1}. CSV columns must match field API name.',
                  new List<String>{ fieldWrapper.fieldName, cmdType }
                )
              );
            }

            Schema.DisplayType fieldType = objField.getDescribe().getType();

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
                  customField.value = (Object) Date.valueOf(
                    fieldWrapper.fieldValue
                  );
                }
                when DATETIME {
                  customField.value = (Object) Datetime.valueOf(
                    fieldWrapper.fieldValue
                  );
                }
                when DOUBLE, PERCENT {
                  customField.value = (Object) Double.valueOf(
                    fieldWrapper.fieldValue
                  );
                }
                when INTEGER {
                  customField.value = (Object) Integer.valueOf(
                    fieldWrapper.fieldValue
                  );
                }
                when LONG {
                  customField.value = (Object) Long.valueOf(
                    fieldWrapper.fieldValue
                  );
                }
                when EMAIL, PICKLIST, REFERENCE, STRING, TEXTAREA, URL, PHONE {
                  // string
                  customField.value = fieldWrapper.fieldValue;
                }
                when else {
                  // tries with string
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

      if (String.isBlank(deployJobId)) {
        // it is not 100% clear why this happen, usually with large CSV file
        throw new AuraHandledException(
          'Failed to schedule deploy. If your CSV file is very big (more than 500 rows) try to split it in smaller chunks and try again'
        );
      }
    } catch (AuraHandledException reThrow) {
      throw reThrow;
    } catch (Exception unexpected) {
      throw new AuraHandledException(
        String.format(
          'Unexpected exception occurred, message is: {0}\nStackTrace: {1}',
          new List<String>{
            unexpected.getMessage(),
            unexpected.getStackTraceString()
          }
        )
      );
    }

    return deployJobId;
  }
}
