/*
 * Copyright (c) 2020 Marco Zeuli
 * Licensed under MIT license.
 * For full license text, see LICENSE file in the repo root or https://opensource.org/licenses/MIT
 * If you would like to contribute https://github.com/maaaaarco/spaghetti-cmd-loader
 */

/**
 * Invoked after a Metadata Api deployment completes (successfully or not), post the result on the
 * user (who triggered the deployment) chatter feed
 */
@NamespaceAccessible
public inherited sharing class CMDDeployCallback implements Metadata.DeployCallback {
  @TestVisible
  static final Integer MAX_FAILURES = 20;

  Metadata.DeployResult result;

  @TestVisible
  private CMDConnectApiDelegate feedApi;

  public CMDDeployCallback() {
    this.feedApi = new CMDConnectApiDelegate();
  }

  public void handleResult(
    Metadata.DeployResult result,
    Metadata.DeployCallbackContext context
  ) {
    if (!result.done) {
      return;
    }

    this.result = result;

    ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
    ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
    ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
    messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

    textSegmentInput.text = parseDeploymentStatus();

    if (!result.success) {
      textSegmentInput.text += parseErrors();
    }

    messageBodyInput.messageSegments.add(textSegmentInput);

    feedItemInput.body = messageBodyInput;
    feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
    feedItemInput.subjectId = result.createdBy;

    feedApi.postFeedElement(Network.getNetworkId(), feedItemInput);
  }

  private String parseDeploymentStatus() {
    String numErrors = this.result.numberComponentErrors != null
      ? String.valueOf(this.result.numberComponentErrors)
      : '0';

    // if there's at least one error then none of the components get deployed
    String numDeployed = numErrors != '0'
      ? '0'
      : this.result.numberComponentsDeployed != null
          ? String.valueOf(this.result.numberComponentsDeployed)
          : '0';
    return String.format(
      '[{0}] - Deployment done, status: {1}\nComponents deployed: {2}\nErrors: {3}\n',
      new List<String>{
        this.result.id,
        this.result.status.name(),
        numDeployed,
        numErrors
      }
    );
  }

  private String parseErrors() {
    String res = '';

    // 1. parse the general error message
    if (String.isNotBlank(this.result.errorMessage)) {
      res += String.format(
        '[ {0} ] - {1}\n',
        new List<String>{
          this.result.errorStatusCode.name(),
          this.result.errorMessage
        }
      );
    }

    // 2. checks for error details
    if (
      this.result.details != null &&
      this.result.details.componentFailures != null
    ) {
      for (
        Integer i = 0;
        i < MAX_FAILURES &&
        i < this.result.details.componentFailures.size();
        i++
      ) {
        Metadata.DeployMessage msg = this.result.details.componentFailures[i];
        res += String.format(
          '{0} : {1} - {2}\n',
          new List<String>{
            msg.fullName,
            msg.lineNumber != null ? String.valueOf(msg.lineNumber) : '0',
            msg.problem
          }
        );
      }

      // are there any more ?
      if (this.result.details.componentFailures.size() > MAX_FAILURES) {
        res += String.format(
          '...{0} more, go to "Setup -> Deployment Status" for additional details',
          new List<String>{
            String.valueOf(
              this.result.details.componentFailures.size() - MAX_FAILURES
            )
          }
        );
      }
    }

    return res;
  }
}
