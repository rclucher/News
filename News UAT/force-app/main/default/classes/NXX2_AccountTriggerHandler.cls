/**
* @author      	Paras Prajapati
* @date         2018-10-26
* @className	NXX2_AccountTriggerHandler
* @description  This is the handler class for account trigger.
*/
public with sharing class NXX2_AccountTriggerHandler implements NXX2_TriggerHandler {
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean TriggerDisabled = false;
 
    /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  Checks to see if the trigger has been disabled either by custom setting or by running code
    * @param        NA
    * @return       Boolean
    */
    public Boolean IsDisabled(){
        NXX2_TriggerSettings__c triggerSettings = NXX2_TriggerSettings__c.getInstance();
        if (triggerSettings.AccountTriggerDisabled__c)
            return true;
        else
            return TriggerDisabled;
    }
	public void BeforeInsert(List<SObject> newItems) {}
 
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
 
    public void BeforeDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterInsert(Map<Id, SObject> newItems) {}
 
     /**
    * @author       Kamal Sharma
    * @date         2019-01-02
    * @description  This method will do the recalculation of sharing with portal user when owner of account is changed.
    * @param        Map<Id, SObject> newItems, Map<Id, SObject> oldItems
    * @return       void
    */
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Set<Id> ownerChangedAccounts = new Set<Id>();
		Map<Id,Account> mapOfOldAccount = ((Map<Id,Account>) oldItems);
		for(Account account : ((Map<Id,Account>)newItems).values()){
			if(account.OwnerId != mapOfOldAccount.get(account.Id).OwnerId){
                ownerChangedAccounts.add(account.Id);
            }
		}
        //This method will do the recalculation of sharing with portal user for accounts provided.
		new NXX2_ShareRecordUtility().recalculateAccountSharing(ownerChangedAccounts);
    }
 
    public void AfterDelete(Map<Id, SObject> oldItems) {}
 
    public void AfterUndelete(Map<Id, SObject> oldItems) {}
}