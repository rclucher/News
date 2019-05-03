public class Agreement_Helper{

    public static void HandleAgreement (List<Id> lstAgreeId, Agreement_Helper.NotificationType nType) {

        List<List<String>> batchAccountAgree = buildBatchAccountAgree(lstAgreeId);
        // call @future method for each batch of records
        for (List<Id> aa : batchAccountAgree) {
            system.debug(aa);
            Agreement_Helper.CreateAccountAgreePosts (aa, nType.name());
        }
    }
    
    private static List<List<String>> buildBatchAccountAgree(List<Id> lstAgreeId)
    {
        // get account agreement relationships
        // only process each unique Account:Agreement once, even if many relationships
        List<AggregateResult> accountAgree = [SELECT MIN(Id) aaId
                                                FROM Account_Agreement_Relationship__c 
                                               WHERE Agreement__c IN :lstAgreeId
                                            GROUP BY Agreement__c, Account__c
                                            ORDER BY Agreement__c];
        
        // split the list into batches of rows that match the DML Limit
        List<String> lstAccountAgreeId = new List<String>();
        List<List<String>> batchAccountAgree = new List<List<String>>();
        Integer batchSize = Limits.getLimitDMLStatements();
        Integer i = 0;
        Integer j = 0; 
        for (AggregateResult aa : accountAgree) {
            i++; 
            lstAccountAgreeId.add (String.valueOf (aa.get('aaId')));
            // every 'batchSize' records, add the list and reset
            if (Math.mod(i, batchSize) == 0 || i == accountAgree.size()) {
                system.debug('add batch ' + i);
                batchAccountAgree.add(lstAccountAgreeId);   
                lstAccountAgreeId = new List<Id>();
            }
        }
        
        // @future limits
        /* not handling now: trigger size = 200; DML size = 150. Never >2 batches
        if (batchAccountAgree.size() > Limits.getLimitFutureCalls()) {
            // ## we have a problem - more @future than allowed
            // ## create batches of @futures...? 
        }
        */ 
        return batchAccountAgree; 
    }



    @future
    public static void CreateAccountAgreePosts (List<String> lstAccountAgreeId, String nType) {
        
        // Get Agreement: Account
        List<Account_Agreement_Relationship__c> accountAgree = [SELECT Agreement__c, Account__c 
                                                             	  FROM Account_Agreement_Relationship__c 
                                                           		 WHERE Id IN :lstAccountAgreeId
                                                                ORDER BY Agreement__c]; 
        
        Set<Id> lstAgreeId = new Set<Id>();
        Set<Id> lstAccountId = new Set<Id>();
        
        for (Account_Agreement_Relationship__c aa : accountAgree) {
            lstAgreeId.add (aa.Agreement__c);
            lstAccountId.add(aa.Account__c);
        }
               
        Map<Id, Account> accounts = new Map<Id, Account>([SELECT Id, Name, OwnerId FROM Account WHERE Id IN :lstAccountId]);
        Map<Id, Agreement__c> agreements = new Map<Id, Agreement__c>([SELECT Id, Name, End_Date__c FROM Agreement__c WHERE Id IN :lstAgreeId]);

        String feedText = '';
        for (Account_Agreement_Relationship__c aa : accountAgree) {
            Agreement__c agree = agreements.get(aa.Agreement__c);
			Account acc = accounts.get(aa.Account__c);
            
            if(nType == NotificationType.EXPIRY.name())
            {
                feedText = String.format('The agreement associated with this account is expiring in {0} days. \nPlease prepare to renegotiate this agreement.\n', 
                                     new String[]{String.valueOf(Date.today().daysBetween(agree.End_Date__c))});
            }
            else if(nType == NotificationType.QUARTELYREVIEW.name()) 
            {
                feedText = 'A quarterly period of the agreement associated to this account is nearing completion. Please prepare a quarterly review if required.';
            }


            Agreement_Helper.CreateFeedItem(acc.Id, feedText, 
                                            acc.OwnerId,
                                            null,
                                            '/' + agree.Id, agree.Name);
        }            
    }
    
    public static void CreateFeedItem(String subjectId, String text1, String userToMention, String text2, String refUrl, String refName) {
    // Post a feed item that has an @-mention.
    // Structure is: text1 @usersToMention text2 linkRefUrl
    
        String communityId = null;
        ConnectApi.FeedType feedType = ConnectApi.FeedType.Record;
        
        ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
        messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
        // add first text section
        if (text1 != null && text1.length() > 0) {
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = text1;
            messageInput.messageSegments.add(textSegment);
        }
        
        // mention user
        if (userToMention != null && userToMention.length() > 0) {
            ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
            mentionSegment.id = userToMention;
            messageInput.messageSegments.add(mentionSegment);
        }
        
        // add second text section
        if (text2 != null && text2.length() > 0) {
            ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
            textSegment.text = text2;
            messageInput.messageSegments.add(textSegment);
        }
        
        ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
        input.body = messageInput;

        // attach link
        if (refUrl != null) {
            ConnectApi.LinkAttachmentInput attachmentInput = new ConnectApi.LinkAttachmentInput();
            attachmentInput.url = refUrl;
            attachmentInput.urlName = refName;
	        input.attachment = attachmentInput;
        }
           
        ConnectApi.FeedItem feedItemRep = ConnectApi.ChatterFeeds.postFeedItem(communityId, feedType, subjectId, input, null);
            
    }


    public enum NotificationType {EXPIRY, QUARTELYREVIEW}
    
    public class AgreementHelperException extends Exception {}

}