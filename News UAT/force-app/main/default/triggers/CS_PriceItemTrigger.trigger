trigger CS_PriceItemTrigger on cspmb__Price_Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
	if (notriggers == null || !notriggers.Flag__c) {
		CS_TriggerHandler.execute(new CS_PriceItemTriggerDelegate());
	}
}