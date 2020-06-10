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
      WHERE IsCustomizable = true
    ]) {
      if (ed.QualifiedApiName.endsWithIgnoreCase(Constants.MDT_SUFFIX)) {
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
      String cmdTypeBaseName = cmdType.replace(Constants.MDT_SUFFIX, '');
      Schema.DescribeSObjectResult objMetadata = Schema.describeSObjects(
        new List<String>{ cmdType }
      )[0];
      Map<String, Schema.SObjectField> fieldMap = objMetadata.fields.getMap();

      Metadata.DeployContainer container = new Metadata.DeployContainer();
      for (RecordWrapper wrapper : records) {
        Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();

        for (FieldWrapper field : wrapper.fields) {
          if (field.fieldName == Constants.DEVELOPER_NAME_FIELD_NAME) {
            customMetadata.fullName = cmdTypeBaseName + '.' + field.fieldValue;
          } else if (
            Constants.MASTER_LABEL_FIELD_NAMES.contains(field.fieldName)
          ) {
            customMetadata.label = field.fieldValue;
          } else {
            Schema.DisplayType fieldType = fieldMap.get(field.fieldName)
              .getDescribe()
              .getType();
            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = field.fieldName;

            if (String.isNotBlank(field.fieldValue)) {
              switch on fieldType {
                when BOOLEAN {
                  customField.value = (Object) Boolean.valueOf(
                    field.fieldValue
                  );
                }
                when DATE {
                  customField.value = (Object) Date.valueOf(field.fieldValue);
                }
                when DATETIME {
                  customField.value = (Object) Datetime.valueOf(
                    field.fieldValue
                  );
                }
                when DOUBLE {
                  customField.value = (Object) Double.valueOf(field.fieldValue);
                }
                when INTEGER {
                  customField.value = (Object) Integer.valueOf(
                    field.fieldValue
                  );
                }
                when LONG {
                  customField.value = (Object) Long.valueOf(field.fieldValue);
                }
                when EMAIL, PICKLIST, REFERENCE, STRING, TEXTAREA, URL {
                  // string
                  customField.value = field.fieldValue;
                }
              }
            } else {
              customField.value = null;
            }

            customMetadata.values.add(customField);
          }
        }

        container.addMetadata(customMetadata);
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
