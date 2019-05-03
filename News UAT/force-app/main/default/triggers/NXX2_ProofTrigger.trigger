trigger NXX2_ProofTrigger on SocialCampaign__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    private Static Boolean hasExecuted = false;
    if(!hasExecuted){
        hasExecuted = true;
    	NXX2_TriggerDispatcher.Run(new NXX2_ProofTriggerHandler());
    }
}