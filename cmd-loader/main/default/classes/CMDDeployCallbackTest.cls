/*
 * Copyright (c) 2020 Marco Zeuli
 * Licensed under MIT license.
 * For full license text, see LICENSE file in the repo root or https://opensource.org/licenses/MIT
 * If you would like to contribute https://github.com/maaaaarco/spaghetti-cmd-loader
 */
@IsTest
private class CMDDeployCallbackTest {
  @IsTest
  static void handleResultDoesNothingIfDeployIsNotCompleted() {
    Metadata.DeployResult deployRes = new Metadata.DeployResult();
    deployRes.done = false;

    CMDDeployCallback deployCallback = new CMDDeployCallback();
    CMDConnectApiDelegateMock feedApiMock = new CMDConnectApiDelegateMock();

    deployCallback.feedApi = (CMDConnectApiDelegate) Test.createStub(
      CMDConnectApiDelegate.class,
      feedApiMock
    );

    deployCallback.handleResult(
      deployRes,
      new Metadata.DeployCallbackContext()
    );

    System.assert(!feedApiMock.postFeedElementInvoked);
  }

  @IsTest
  static void handleResultCreatesFeedItemWhenDeployIsSuccessfull() {
    Metadata.DeployResult deployRes = new Metadata.DeployResult();
    deployRes.id = '0Af3N00000UeFZiSAN';
    deployRes.done = true;
    deployRes.success = true;
    deployRes.numberComponentErrors = 0;
    deployRes.numberComponentsDeployed = 10;
    deployRes.status = Metadata.DeployStatus.SUCCEEDED;

    CMDDeployCallback deployCallback = new CMDDeployCallback();
    CMDConnectApiDelegateMock feedApiMock = new CMDConnectApiDelegateMock();

    deployCallback.feedApi = (CMDConnectApiDelegate) Test.createStub(
      CMDConnectApiDelegate.class,
      feedApiMock
    );

    deployCallback.handleResult(
      deployRes,
      new Metadata.DeployCallbackContext()
    );

    System.assert(feedApiMock.postFeedElementInvoked);

    ConnectApi.TextSegmentInput textSegmentInput = (ConnectApi.TextSegmentInput) (feedApiMock.feedItemInput.body.messageSegments[0]);

    System.assert(textSegmentInput.text.contains('[' + deployRes.id + ']'));
    System.assert(
      textSegmentInput.text.contains(
        'Deployment done, status: ' + Metadata.DeployStatus.SUCCEEDED.name()
      )
    );
    System.assert(
      textSegmentInput.text.contains(
        'Components deployed: ' + deployRes.numberComponentsDeployed
      )
    );
    System.assert(
      textSegmentInput.text.contains(
        'Errors: ' + deployRes.numberComponentErrors
      )
    );
  }

  @IsTest
  static void handleResultCreatesFeedItemWhenDeployIsUnsuccessfull() {
    Metadata.DeployResult deployRes = new Metadata.DeployResult();
    deployRes.id = '0Af3N00000UeFZiSAN';
    deployRes.done = true;
    deployRes.success = false;
    deployRes.numberComponentErrors = 1;
    deployRes.numberComponentsDeployed = 10;
    deployRes.errorMessage = 'Required field is missing. MasterLabel cannot be blank';
    deployRes.errorStatusCode = Metadata.StatusCode.REQUIRED_FIELD_MISSING;
    deployRes.status = Metadata.DeployStatus.FAILED;
    deployRes.details = new Metadata.DeployDetails();
    deployRes.details.componentFailures = new List<Metadata.DeployMessage>();

    Metadata.DeployMessage errMsg1 = new Metadata.DeployMessage();
    errMsg1.fullName = 'Metadata_Record_x';
    errMsg1.lineNumber = 1;
    errMsg1.problem = 'Required field is missing';

    deployRes.details.componentFailures.add(errMsg1);

    CMDDeployCallback deployCallback = new CMDDeployCallback();
    CMDConnectApiDelegateMock feedApiMock = new CMDConnectApiDelegateMock();

    deployCallback.feedApi = (CMDConnectApiDelegate) Test.createStub(
      CMDConnectApiDelegate.class,
      feedApiMock
    );

    deployCallback.handleResult(
      deployRes,
      new Metadata.DeployCallbackContext()
    );

    System.assert(feedApiMock.postFeedElementInvoked);

    ConnectApi.TextSegmentInput textSegmentInput = (ConnectApi.TextSegmentInput) (feedApiMock.feedItemInput.body.messageSegments[0]);

    System.assert(textSegmentInput.text.contains('[' + deployRes.id + ']'));
    System.assert(
      textSegmentInput.text.contains(
        'Deployment done, status: ' + Metadata.DeployStatus.FAILED.name()
      )
    );
    System.assert(textSegmentInput.text.contains('Components deployed: 0'));
    System.assert(
      textSegmentInput.text.contains(
        'Errors: ' + deployRes.numberComponentErrors
      )
    );
    System.assert(textSegmentInput.text.contains('Metadata_Record_x'));
  }

  @IsTest
  static void handleResultParsesOnlyFirst20ErrorMessages() {
    Metadata.DeployResult deployRes = new Metadata.DeployResult();
    deployRes.id = '0Af3N00000UeFZiSAN';
    deployRes.done = true;
    deployRes.success = false;
    deployRes.numberComponentErrors = 40;
    deployRes.numberComponentsDeployed = 10;
    deployRes.errorMessage = 'Required field is missing. MasterLabel cannot be blank';
    deployRes.errorStatusCode = Metadata.StatusCode.REQUIRED_FIELD_MISSING;
    deployRes.status = Metadata.DeployStatus.FAILED;
    deployRes.details = new Metadata.DeployDetails();
    deployRes.details.componentFailures = new List<Metadata.DeployMessage>();

    for (Integer i = 0; i < CMDDeployCallback.MAX_FAILURES + 20; i++) {
      Metadata.DeployMessage errMsg1 = new Metadata.DeployMessage();
      errMsg1.fullName = 'Metadata_Record_x';
      errMsg1.lineNumber = 1;
      errMsg1.problem = 'Required field is missing';
      deployRes.details.componentFailures.add(errMsg1);
    }

    CMDDeployCallback deployCallback = new CMDDeployCallback();
    CMDConnectApiDelegateMock feedApiMock = new CMDConnectApiDelegateMock();

    deployCallback.feedApi = (CMDConnectApiDelegate) Test.createStub(
      CMDConnectApiDelegate.class,
      feedApiMock
    );

    deployCallback.handleResult(
      deployRes,
      new Metadata.DeployCallbackContext()
    );

    System.assert(feedApiMock.postFeedElementInvoked);

    ConnectApi.TextSegmentInput textSegmentInput = (ConnectApi.TextSegmentInput) (feedApiMock.feedItemInput.body.messageSegments[0]);

    System.assert(textSegmentInput.text.contains('...20 more, go to "Setup -> Deployment Status" for additional details'));
  }

  public class CMDConnectApiDelegateMock implements System.StubProvider {
    public Boolean postFeedElementInvoked;
    public ConnectApi.FeedItemInput feedItemInput;

    public CMDConnectApiDelegateMock() {
      this.postFeedElementInvoked = false;
    }

    public Object handleMethodCall(
      Object stubbedObject,
      String stubbedMethodName,
      Type returnType,
      List<Type> listOfParamTypes,
      List<String> listOfParamNames,
      List<Object> listOfArgs
    ) {
      if (stubbedMethodName == 'postFeedElement') {
        this.postFeedElementInvoked = true;
        this.feedItemInput = (ConnectApi.FeedItemInput) listOfArgs[1];
      }

      return null;
    }
  }
}
