/*
 * Copyright (c) 2020 Marco Zeuli
 * Licensed under MIT license.
 * For full license text, see LICENSE file in the repo root or https://opensource.org/licenses/MIT
 * If you would like to contribute https://github.com/maaaaarco/spaghetti-cmd-loader
 */
@IsTest
private class CMDLoaderControllerTest {
  static final Id DEPLOYMENT_ID = '0Af3N00000UeFZiSAN';

  @IsTest
  static void retrieveCustomMetadataTypesReturnsCorrectly() {
    List<String> res = CMDLoaderController.retrieveCustomMetadataTypes();
    System.assertNotEquals(null, res);
  }

  @IsTest
  static void checkDeploymentReturnsCorrectlyWhenDeploymentIsSuccessful() {
    CMDConnectApiDelegateMock feedApiMock = new CMDConnectApiDelegateMock();
    CMDLoaderController.feedApi = (CMDConnectApiDelegate) Test.createStub(
      CMDConnectApiDelegate.class,
      feedApiMock
    );
    CMDLoaderController.DeploymentStatusWrapper res = CMDLoaderController.checkDeployment(
      DEPLOYMENT_ID
    );
    System.assert(feedApiMock.getTodayFeedItemsInvoked);
    System.assertNotEquals(null, res);
    System.assertEquals(DEPLOYMENT_ID, res.id);
    System.assert(res.done);
    System.assert(res.success);
    System.assert(String.isNotBlank(res.result));
  }

  @IsTest
  static void checkDeploymentReturnsCorrectlyWhenDeploymentIsUnsuccessful() {
    CMDConnectApiDelegateMock feedApiMock = new CMDConnectApiDelegateMock(
      Metadata.deployStatus.FAILED
    );
    CMDLoaderController.feedApi = (CMDConnectApiDelegate) Test.createStub(
      CMDConnectApiDelegate.class,
      feedApiMock
    );
    CMDLoaderController.DeploymentStatusWrapper res = CMDLoaderController.checkDeployment(
      DEPLOYMENT_ID
    );
    System.assert(feedApiMock.getTodayFeedItemsInvoked);
    System.assertNotEquals(null, res);
    System.assertEquals(DEPLOYMENT_ID, res.id);
    System.assert(res.done);
    System.assert(!res.success);
    System.assert(String.isNotBlank(res.result));
  }

  @IsTest
  static void checkDeploymentReturnsCorrectlyIfUnexpectedExceptionOccurred() {
    CMDConnectApiDelegateMock feedApiMock = new CMDConnectApiDelegateMock(true);
    CMDLoaderController.feedApi = (CMDConnectApiDelegate) Test.createStub(
      CMDConnectApiDelegate.class,
      feedApiMock
    );
    CMDLoaderController.DeploymentStatusWrapper res = CMDLoaderController.checkDeployment(
      DEPLOYMENT_ID
    );
    System.assertNotEquals(null, res);
    System.assertEquals(DEPLOYMENT_ID, res.id);
    System.assert(res.done);
    System.assert(!res.success);
    System.assert(String.isNotBlank(res.result));
  }

  @IsTest
  static void upsertRecordsReturnsDeployIdCorrectly() {
    CMDMetadataOperationsDelegateMock deployApiMock = new CMDMetadataOperationsDelegateMock();
    CMDLoaderController.deployApi = (CMDMetadataOperationsDelegate) Test.createStub(
      CMDMetadataOperationsDelegate.class,
      deployApiMock
    );
    // seems silly but it works :P
    String cmdType = 'Opportunity';
    CMDLoaderController.RecordWrapper record = new CMDLoaderController.RecordWrapper();

    CMDLoaderController.FieldWrapper devName = new CMDLoaderController.FieldWrapper();
    devName.fieldName = 'DeveloperName';
    devName.fieldValue = 'abc';

    CMDLoaderController.FieldWrapper label = new CMDLoaderController.FieldWrapper();
    label.fieldName = 'MasterLabel';
    label.fieldValue = 'the label';

    CMDLoaderController.FieldWrapper boolField = new CMDLoaderController.FieldWrapper();
    boolField.fieldName = 'IsClosed';
    boolField.fieldValue = 'false';

    CMDLoaderController.FieldWrapper dateField = new CMDLoaderController.FieldWrapper();
    dateField.fieldName = 'CloseDate';
    dateField.fieldValue = '2020-01-01';

    CMDLoaderController.FieldWrapper dateTimeField = new CMDLoaderController.FieldWrapper();
    dateTimeField.fieldName = 'CreatedDate';
    dateTimeField.fieldValue = '2020-01-01 00:00:01';

    CMDLoaderController.FieldWrapper doubleField = new CMDLoaderController.FieldWrapper();
    doubleField.fieldName = 'Amount';
    doubleField.fieldValue = '1000.00';

    CMDLoaderController.FieldWrapper integerField = new CMDLoaderController.FieldWrapper();
    integerField.fieldName = 'TotalOpportunityQuantity';
    integerField.fieldValue = '10';

    CMDLoaderController.FieldWrapper textField = new CMDLoaderController.FieldWrapper();
    textField.fieldName = 'Description';
    textField.fieldValue = 'Oppty description';

    CMDLoaderController.FieldWrapper blankField = new CMDLoaderController.FieldWrapper();
    blankField.fieldName = 'AccountId';

    record.fields.add(devName);
    record.fields.add(label);
    record.fields.add(boolField);
    record.fields.add(dateField);
    record.fields.add(dateTimeField);
    record.fields.add(doubleField);
    record.fields.add(integerField);
    record.fields.add(textField);
    record.fields.add(blankField);

    Id res = CMDLoaderController.upsertRecords(
      cmdType,
      new List<CMDLoaderController.RecordWrapper>{ record }
    );

    System.assert(deployApiMock.enqueueDeploymentInvoked);
    System.assertEquals(DEPLOYMENT_ID, res);
  }

  @IsTest
  static void upsertRecordsThrowsAuraExceptionIfFieldDoesNotExist() {
    CMDMetadataOperationsDelegateMock deployApiMock = new CMDMetadataOperationsDelegateMock();
    CMDLoaderController.deployApi = (CMDMetadataOperationsDelegate) Test.createStub(
      CMDMetadataOperationsDelegate.class,
      deployApiMock
    );
    // seems silly but it works :P
    String cmdType = 'Opportunity';
    CMDLoaderController.RecordWrapper record = new CMDLoaderController.RecordWrapper();

    CMDLoaderController.FieldWrapper devName = new CMDLoaderController.FieldWrapper();
    devName.fieldName = 'DeveloperName';
    devName.fieldValue = 'abc';

    CMDLoaderController.FieldWrapper label = new CMDLoaderController.FieldWrapper();
    label.fieldName = 'MasterLabel';
    label.fieldValue = 'the label';

    CMDLoaderController.FieldWrapper boolField = new CMDLoaderController.FieldWrapper();
    boolField.fieldName = 'spaghettiCMD__PastaAlPomodoro__c';
    boolField.fieldValue = 'false';

    record.fields.add(devName);
    record.fields.add(label);
    record.fields.add(boolField);

    Boolean thrown = false;

    try {
      CMDLoaderController.upsertRecords(
        cmdType,
        new List<CMDLoaderController.RecordWrapper>{ record }
      );
    } catch (AuraHandledException expected) {
      thrown = true;
    }
    
    System.assert(thrown);
    System.assert(!deployApiMock.enqueueDeploymentInvoked);
  }

  @IsTest
  static void upsertRecordsThrowsAuraExceptionIfDeployIdIsNull() {
    CMDMetadataOperationsDelegateMock deployApiMock = new CMDMetadataOperationsDelegateMock();
    deployApiMock.deployId = null;
    CMDLoaderController.deployApi = (CMDMetadataOperationsDelegate) Test.createStub(
      CMDMetadataOperationsDelegate.class,
      deployApiMock
    );
    // seems silly but it works :P
    String cmdType = 'Opportunity';
    CMDLoaderController.RecordWrapper record = new CMDLoaderController.RecordWrapper();

    CMDLoaderController.FieldWrapper devName = new CMDLoaderController.FieldWrapper();
    devName.fieldName = 'DeveloperName';
    devName.fieldValue = 'abc';

    CMDLoaderController.FieldWrapper label = new CMDLoaderController.FieldWrapper();
    label.fieldName = 'MasterLabel';
    label.fieldValue = 'the label';

    record.fields.add(devName);
    record.fields.add(label);

    Boolean thrown = false;

    try {
      CMDLoaderController.upsertRecords(
        cmdType,
        new List<CMDLoaderController.RecordWrapper>{ record }
      );
    } catch (AuraHandledException expected) {
      thrown = true;
    }
    
    System.assert(thrown);
    System.assert(deployApiMock.enqueueDeploymentInvoked);
  }

  @IsTest
  static void upsertRecordsThrowsAuraExceptionIfUnexpectedErrorOccurrs() {
    CMDMetadataOperationsDelegateMock deployApiMock = new CMDMetadataOperationsDelegateMock(true);
    CMDLoaderController.deployApi = (CMDMetadataOperationsDelegate) Test.createStub(
      CMDMetadataOperationsDelegate.class,
      deployApiMock
    );
    // seems silly but it works :P
    String cmdType = 'Opportunity';
    CMDLoaderController.RecordWrapper record = new CMDLoaderController.RecordWrapper();

    CMDLoaderController.FieldWrapper devName = new CMDLoaderController.FieldWrapper();
    devName.fieldName = 'DeveloperName';
    devName.fieldValue = 'abc';

    CMDLoaderController.FieldWrapper label = new CMDLoaderController.FieldWrapper();
    label.fieldName = 'MasterLabel';
    label.fieldValue = 'the label';

    record.fields.add(devName);
    record.fields.add(label);

    Boolean thrown = false;

    try {
      CMDLoaderController.upsertRecords(
        cmdType,
        new List<CMDLoaderController.RecordWrapper>{ record }
      );
    } catch (AuraHandledException expected) {
      thrown = true;
    }
    
    System.assert(thrown);
  }

  public class CMDConnectApiDelegateMock implements System.StubProvider {
    public Boolean getTodayFeedItemsInvoked;
    public Boolean throwException;
    public Metadata.DeployStatus deployStatus;

    public CMDConnectApiDelegateMock() {
      this.getTodayFeedItemsInvoked = false;
      this.throwException = false;
      this.deployStatus = Metadata.DeployStatus.SUCCEEDED;
    }

    public CMDConnectApiDelegateMock(Boolean throwException) {
      this();
      this.throwException = throwException;
    }

    public CMDConnectApiDelegateMock(Metadata.DeployStatus deployStatus) {
      this();
      this.deployStatus = deployStatus;
    }

    public Object handleMethodCall(
      Object stubbedObject,
      String stubbedMethodName,
      Type returnType,
      List<Type> listOfParamTypes,
      List<String> listOfParamNames,
      List<Object> listOfArgs
    ) {
      if (throwException) {
        Integer i = 1 / 0;
      }

      if (stubbedMethodName == 'getTodayFeedItems') {
        this.getTodayFeedItemsInvoked = true;
        return new List<FeedItem>{
          new FeedItem(
            Body = '[' +
              DEPLOYMENT_ID +
              '] Deployment done, status is: ' +
              this.deployStatus.name()
          )
        };
      }
      return null;
    }
  }

  public class CMDMetadataOperationsDelegateMock implements System.StubProvider {
    public Boolean enqueueDeploymentInvoked;
    public Boolean throwException;
    public Id deployId;

    public CMDMetadataOperationsDelegateMock() {
      this.deployId = DEPLOYMENT_ID;
      this.throwException = false;
      this.enqueueDeploymentInvoked = false;
    }

    public CMDMetadataOperationsDelegateMock(Boolean throwException) {
      this();
      this.throwException = true;
    }

    public Object handleMethodCall(
      Object stubbedObject,
      String stubbedMethodName,
      Type returnType,
      List<Type> listOfParamTypes,
      List<String> listOfParamNames,
      List<Object> listOfArgs
    ) {
      if (throwException) {
        Integer i = 1/0;
      }

      if (stubbedMethodName == 'enqueueDeployment') {
        this.enqueueDeploymentInvoked = true;
        return this.deployId;
      }
      return null;
    }
  }
}
