/**
* @author       Kamal Sharma
* @date         2019-01-02
* @className	NXX2_FeedCommentTriggerHandler
* @description  This is the handler class for feed comment trigger.
*/
public class NXX2_FeedCommentTriggerHandler implements NXX2_TriggerHandler
{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  Checks to see if the trigger has been disabled either by custom setting or by running code
    * @param        NA
    * @return       Boolean
    */
    public Boolean IsDisabled()
    {
        NXX2_TriggerSettings__c triggerSettings = NXX2_TriggerSettings__c.getInstance();
        if (triggerSettings.FeedCommentTriggerDisabled__c)
            return true;
        else
            return TriggerDisabled;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will check that if the feed comment belongs to proof ad(SocialAd__c) 
    * 				then this will be allowed to insert only if the proof ad status is not approved.
    * @param        Map<Id, SObject> newItems
    * @return       void
    */
    public void BeforeInsert(List<SObject> newItems) {
        if(UserInfo.getUserType() != 'Standard'){
            Map<Id,FeedComment> proofAdToFeedCommentMap = new Map<Id,FeedComment>();
            for(FeedComment comment : (List<FeedComment>)newItems){
                String parentName = comment.parentId.getSObjectType().getDescribe().getName();
                if(parentName == 'SocialAd__c'){
                    proofAdToFeedCommentMap.put(comment.parentId,comment);
                }
            }
            if(proofAdToFeedCommentMap.size() > 0){
                List<SocialAd__c> proofAds = [SELECT Status__c FROM SocialAd__c WHERE Id IN : proofAdToFeedCommentMap.keySet()];
                for(SocialAd__c proofAd : proofAds){
                    if(proofAd.Status__c == 'Approved'){
                        proofAdToFeedCommentMap.get(proofAd.Id).addError('Comments are not allowed on approved ad.');
                    }
                }
            }
        }
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will check that if the feed comment under updation belongs to proof ad(SocialAd__c) 
    * 				then this will be allowed to update only if the proof ad status is not approved.
    * @param        Map<Id, SObject> newItems
    * @return       void
    */
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        if(UserInfo.getUserType() != 'Standard'){
            Map<Id,FeedComment> proofAdToFeedCommentMap = new Map<Id,FeedComment>();
            for(FeedComment comment : ((Map<Id,FeedComment>)newItems).values()){
                String parentName = comment.parentId.getSObjectType().getDescribe().getName();
                if(parentName == 'SocialAd__c'){
                    proofAdToFeedCommentMap.put(comment.parentId,comment);
                }
            }
            if(proofAdToFeedCommentMap.size() > 0){
                List<SocialAd__c> proofAds = [SELECT Status__c FROM SocialAd__c WHERE Id IN : proofAdToFeedCommentMap.keySet()];
                for(SocialAd__c proofAd : proofAds){
                    if(proofAd.Status__c == 'Approved'){
                        proofAdToFeedCommentMap.get(proofAd.Id).addError('Comments are not allowed on approved ad.');
                    }
                }
            }
        }
    }
    
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
    
    public void AfterInsert(Map<Id, SObject> newItems) {}
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    public void AfterDelete(Map<Id, SObject> oldItems) {}
    
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}