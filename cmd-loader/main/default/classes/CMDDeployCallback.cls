public without sharing class CMDDeployCallback implements Metadata.DeployCallback {
  public void handleResult(
    Metadata.DeployResult result,
    Metadata.DeployCallbackContext context
  ) {
    if (result.done) {
      ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
      ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
      ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();

      messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

      textSegmentInput.text = String.format(
        '[ {0} ] - Deployment done, status: {1}\n',
        new List<String>{
          result.id,
          result.status.name()
        }
      );

      if (!result.success) {
        // todo: is there any limit to the body size?
        for (Metadata.DeployMessage errMsg : result.details.componentFailures) {
          textSegmentInput.text +=
            errMsg.componentType +
            ' - ' +
            errMsg.problem +
            '\n';
        }
      }

      messageBodyInput.messageSegments.add(textSegmentInput);

      feedItemInput.body = messageBodyInput;
      feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
      feedItemInput.subjectId = result.createdBy;

      ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(
        Network.getNetworkId(),
        feedItemInput
      );
    }
  }
}
