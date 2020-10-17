@IsTest
private class CMDConnectApiDelegateTest {
    @IsTest
    static void getTodayFeedItemsReturnsCorrectly() {
      List<FeedItem> res = new CMDConnectApiDelegate().getTodayFeedItems(UserInfo.getUserId());
      System.assertNotEquals(null, res);
    }
}
