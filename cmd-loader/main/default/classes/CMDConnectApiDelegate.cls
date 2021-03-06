/*
 * Copyright (c) 2020 Marco Zeuli
 * Licensed under MIT license.
 * For full license text, see LICENSE file in the repo root or https://opensource.org/licenses/MIT
 * If you would like to contribute https://github.com/maaaaarco/spaghetti-cmd-loader
 */

/**
 * ConnectApi methods are not supported in data siloed tests.
 * This Delegate allows for testing without using the SeeAllData=true
 */
public inherited sharing class CMDConnectApiDelegate {
  /**
   * Creates new FeedItem
   * @return   Created FeedItem
   */
  public ConnectApi.FeedElement postFeedElement(
    Id networkId,
    ConnectApi.FeedItemInput feed
  ) {
    return ConnectApi.ChatterFeeds.postFeedElement(networkId, feed);
  }

  /**
   * Retrieves FeedItem records created in the current day
   * @param  parentId Parent Id of FeedItem records
   * @return          A list of FeedItem or an empty list
   */
  public List<FeedItem> getTodayFeedItems(Id parentId){
    return [
      SELECT Body
      FROM FeedItem
      WHERE ParentId = :UserInfo.getUserId() AND CreatedDate = TODAY
      LIMIT 1000
    ];
  }
}
