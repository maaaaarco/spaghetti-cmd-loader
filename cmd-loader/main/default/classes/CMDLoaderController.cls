public with sharing class CMDLoaderController {
  public class RecordWrapper {
    @AuraEnabled
    public List<FieldWrapper> fields { get; set; }

    public RecordWrapper() {
      this.fields = new List<FieldWrapper>();
    }

    public Boolean isValid() {
      // todo: implement this
      return true;
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

  @AuraEnabled
  public static DeploymentStatusWrapper checkDeployment(String deployId) {
    DeploymentStatusWrapper res = new DeploymentStatusWrapper();

    try {
      for (FeedItem feed : [
        SELECT Body
        FROM FeedItem
        WHERE ParentId = :UserInfo.getUserId() AND CreatedDate = TODAY
      ]) {
        if (feed.Body.containsIgnoreCase(deployId)) {
          res.done = true;
          res.success = feed.Body.split('\n')[0].contains(Metadata.DeployStatus.SUCCEEDED.name());
          res.result = feed.Body;
        }
      }
    } catch (Exception unexpected) {
      res.done = true;
      res.success = false;
      res.result = unexpected.getMessage();
    }

    return res;
  }

  @AuraEnabled
  public static Id upsertRecords(String cmdType, List<RecordWrapper> records) {
    Id deployJobId = null;

    // todo: check cmdType
    // todo: check validity of all records
    String cmdTypeBaseName = cmdType.replace(Constants.MDT_SUFFIX, '');
    Metadata.DeployContainer container = new Metadata.DeployContainer();
    for (RecordWrapper wrapper : records) {
      if (!wrapper.isValid()) {
        // todo: flag record as in error
        continue;
      }
      Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();

      for (FieldWrapper field : wrapper.fields) {
        if (field.fieldName == Constants.DEVELOPER_NAME_FIELD_NAME) {
          customMetadata.fullName = cmdTypeBaseName + '.' + field.fieldValue;
        } else if (
          Constants.MASTER_LABEL_FIELD_NAMES.contains(field.fieldName)
        ) {
          customMetadata.label = field.fieldValue;
        } else {
          Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
          customField.field = field.fieldName;
          // todo: what if field value is empty?
          // todo: cast to correct data type before assigning to value
          
          // customField.value = field.fieldName == 'IsActive__c'
          //   ? (Object) Boolean.valueOf(field.fieldValue)
          //   : (Object) field.fieldValue;

          customField.value = field.fieldValue;
          
            customMetadata.values.add(customField);
        }
      }

      container.addMetadata(customMetadata);
    }

    deployJobId = Metadata.Operations.enqueueDeployment(
      container,
      new CMDDeployCallback()
    );

    return deployJobId;
  }
}
