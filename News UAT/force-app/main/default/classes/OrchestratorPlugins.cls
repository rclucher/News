global class OrchestratorPlugins { 

    global class ChatterConnectApiProvider implements CSPOFA.ChatterApiProvider_V1 {
        /*
        * @description Post feed item to chatter feed.
         ConnectApi.RateLimitException is not handled, the client code MUST wrap the call in a try-catch block and handle this exception! 
        *
        * @paramfeedItemInput: a properly prepared ConnectAPI.FeedItemInput class instance
         @paramsubjectID: string representation of the ID of target object to whose stream the post will be made.
        
        * */ 
        public void post(String subjectId, ConnectApi.FeedItemInput feedItemInput) { 
            Id subject = normalizeId(subjectId); 
            ConnectApi.FeedType targetFeedType = ConnectApi.FeedType.Record; 
            if (subject != null && subject.getSObjectType().getDescribe().getName().toLowerCase().startsWith('user')) { 
                targetFeedType = ConnectApi.FeedType.UserProfile; 
            } //can throw RateLimitException
            ConnectApi.ChatterFeeds.postFeedItem(null, targetFeedType, subjectID, feedItemInput, null); 
        } 
        
        private Id normalizeId(String idText) { 
            try {
                return Id.valueOf(idText); 
            } catch(Exception e) {
                return null;
            } 
        }
    }

    global class ChatterApiProviderFactory implements CSPOFA.PluginFactory { 
        public Object create() { 
            return new ChatterConnectApiProvider(); 
        } 
    }
}