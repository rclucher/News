global class CS_ResetOrchestratorPriority implements Database.Batchable<sObject> {
	
	String query;
	
	global CS_ResetOrchestratorPriority() {

		query = 'SELECT Id, Name, Order__c, Product_Order__c, Creative__c, CSPOFA__Status__c, CSPOFA__Priority__c FROM CSPOFA__Orchestration_Process__c WHERE CSPOFA__Priority__c = \'3 - High\'';
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {

   		List<CSPOFA__Orchestration_Process__c> orchList = (List<CSPOFA__Orchestration_Process__c>)scope;
   		Set<Id> campaignIds = new Set<Id>();
   		Set<Id> productOrderIds = new Set<Id>();
   		Set<Id> creativeIds = new Set<Id>();
   		for(CSPOFA__Orchestration_Process__c item : orchList){
   			item.CSPOFA__Priority__c = '2 - Normal';

   			if(item.Order__c != null){
   				campaignIds.add(item.Order__c);
   			} else if (item.Product_Order__c != null){
   				productOrderIds.add(item.Product_Order__c);
   			} else if (item.Product_Order__c != null){
   				creativeIds.add(item.Creative__c);
   			}
   		}

   		List<Order__c> orderList = [SELECT Id, Name, Orchestrator_Priority__c FROM Order__c WHERE Id in :campaignIds];
   		List<Product_Order__c> poList = [SELECT Id, Name, Orchestrator_Priority__c FROM Product_Order__c WHERE Id in :productOrderIds];
   		List<Creative__c> creativeList = [SELECT Id, Name, Orchestrator_Priority__c FROM Creative__c WHERE Id in :creativeIds];


   		for(Order__c item : orderList){
   			item.Orchestrator_Priority__c = false;
   		}

   		for(Product_Order__c item : poList){
   			item.Orchestrator_Priority__c = false;
   		}

   		for(Creative__c item : creativeList){
   			item.Orchestrator_Priority__c = false;
   		}

   		if(!orchList.isEmpty()){
   			update orchList;
   		}
   		if(!orderList.isEmpty()){
   			update orderList;
   		}
   		if(!poList.isEmpty()){
   			update poList;
   		}
   		if(!creativeList.isEmpty()){
   			update creativeList;
   		}
	
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}