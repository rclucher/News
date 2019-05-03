trigger CS_AllOptimisiationLogTrigger on Optimisation_Log__c (
	before insert, 
	before update) {

	No_Triggers__c notriggers = No_Triggers__c.getInstance(UserInfo.getUserId());
	if (!notriggers.Flag__c) {
		
		if (Trigger.isBefore) {
			if(Trigger.isUpdate || Trigger.isInsert){
				for(Optimisation_Log__c item : Trigger.new){
					System.debug('***** CS_AllOptimisiationLogTrigger item:' + item);
					if(item.Product_Order__c != null){
						System.debug('***** CS_AllOptimisiationLogTrigger Campaign_Order_of_PO__c:' + item.Campaign_Order_of_PO__c);
						item.Campaign_Order__c = item.Campaign_Order_of_PO__c;
					}
				}
			}
	    	//call your handler.before method
	    
		}
	}
}