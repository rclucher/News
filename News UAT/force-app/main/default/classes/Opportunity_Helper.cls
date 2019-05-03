public with sharing class Opportunity_Helper 
{
    public static Map<String, Opportunity> createOpportunitFromSalesOrder(Map<Id, Sales_Order__c> salesOrderById)
    {
        Map<String, Opportunity> opportunityBySalesOrderId = new Map<String, Opportunity>();
        
        system.debug('@ createOpportunitFromSalesOrder()');
        List<Opportunity> opportunities = new List<Opportunity>();

        for(String salesOrderId : salesOrderById.keySet())
        {
            Sales_Order__c so = salesOrderById.get(salesOrderId);
            Opportunity opportunity = new Opportunity();
            
            if(so.Source_System__c == 'OSCA' || so.Source_System__c == 'CampaignTrack') // added by Tim Fabros 18 / 07 / 2014 - SFE added CampaignTrack to logic
            {
                opportunity.Opportunity_Type__c = 'Self Service'; ///???
                opportunity.Payer_Account__c = so.Payer_Account__r.id;
                opportunity.AccountId = so.Advertiser_Account__r.id;
                opportunity.recordTypeId = getRecordTypeIdByName(opportunity.Opportunity_Type__c, 'Opportunity');
                opportunity.name = 'OSCA - ' + so.Advertiser_Account__r.Name + ' - ' + system.today().year() + system.today().month() + system.today().day();
                opportunity.type = 'Non-Core Activity';
                opportunity.Revenue_Group__c = so.Advertiser_Account__r.Revenue_Group__c;
                opportunity.Industry_Code__c = so.Advertiser_Account__r.Industry_Code__c;
                opportunity.Description = salesOrderId; // sales order id in description is to find opportunity based on sales order id
                opportunity.StageName = 'Closed Won';
                opportunity.CloseDate = Date.today();
                //ND 10/04 set amount to avoid validation on closed won opportunity
                opportunity.Amount = 0;
                opportunity.CloseDate = Date.today();
            }

            // added by Tim Fabros 18 / 07 / 2014 - SFE
            // added logic for campaign track to
            // change the opportunity type and name
            // BEGIN:
            if(so.Source_System__c == 'CampaignTrack')
            {
                opportunity.Opportunity_Type__c = 'Walk-In';
                opportunity.name = 'CampaignTrack - ' + so.Advertiser_Account__r.Name + ' - ' + system.today().year() + system.today().month() + system.today().day();
            }
            // END:
            
            if(opportunity.Opportunity_Type__c == 'Self Service')
            {
                opportunity.StageName = 'Closed Won'; 
                opportunity.Probability = 100;
                opportunity.Reason_Won_Lost__c = 'Other';
                opportunity.CloseDate = system.today();
                opportunity.Campaign_Start_Date__c = system.today();
            }

            // 2017-05-22 Item-00282 louis.wang@bluewolf.com - Opportunity created by SalesOrder trigger will skip the conditional mandatory Contact validation rule.
            opportunity.BypassContactValidation__c = true;
            
            opportunityBySalesOrderId.put(salesOrderId, opportunity);
        }
        
		try{
        	insert opportunityBySalesOrderId.values();
		}
        catch(Exception ex)
        {
            system.assert(false, ex.getMessage());
            ExLog.log(ex, 'config', opportunityBySalesOrderId.values(), 'SFE-824 Investigation');
        }
         
        system.debug('====BC: opportunityBySalesOrderId=== ' + opportunityBySalesOrderId);
        
        return opportunityBySalesOrderId;
    }
    
    private static Map<String, Map<String, RecordType>> bySobjectAndRecordTypeName
    {
        get{ return bySobjectAndRecordTypeName = bySobjectAndRecordTypeName == null ? new Map<String, Map<String, RecordType>>() : bySobjectAndRecordTypeName; }
        set;
    }
    
    private static String getRecordTypeIdByName(String recordTypeName, String sObjectType)
    {
        String recordTypeId;
        Id rtId = null; 
        if(recordTypeName != null && sObjectType != null && (!bySobjectAndRecordTypeName.containsKey(sObjectType) || !bySobjectAndRecordTypeName.get(sObjectType).containsKey(recordTypeName)))
        {
            getRecordObjectMap (sObjectType);
        }

        if(bySobjectAndRecordTypeName.get(sObjectType).containsKey(recordTypeName))
        {   
            rtId = bySobjectAndRecordTypeName.get(sObjectType).get(recordTypeName).Id;
        }

        return rtId;
    }
    
    private static void getRecordObjectMap (String s)
    {
        Map<String,RecordType> rtObj = new Map<String,RecordType>();      

        for(RecordType rt : [Select r.Id, r.Name From RecordType r where r.SobjectType =: s])
        {
            rtObj.put(rt.name, rt);
        }

        if(rtObj.size()>0)
        {
            bySobjectAndRecordTypeName.put(s, rtObj);
        }

    }
    // updated by Bohao Chen on 6/6/2014 for JIRA SFE-498
    // Begin
    public static void populateCaseWithOpportunityId(Map<Id, List<Id>> opportunityIdsByCaseId)
    {
        if(opportunityIdsByCaseId != null && !opportunityIdsByCaseId.isEmpty())
        {
            List<Case> cases = new List<Case>();
            for(Case c : [Select Id, Opportunity__c, RecordType.Name From Case Where Id IN: opportunityIdsByCaseId.keySet()])
            {
                if(c.RecordType.Name == 'Referral')
                {
                    c.Opportunity__c = opportunityIdsByCaseId.get(c.Id)[0];
                    cases.add(c);                    
                }
            }
            try{
            	update cases;
            }
            catch(Exception ex)
	        {
	            ExLog.log(ex, 'config', cases, 'SFE-824 Investigation');
	        }
        }
    }
    // End
    
    //REVENUE REPORTING 
    public static Void rollupTriggerOpportunityLineItem(Set<Id> opIds){
        List<OpportunityLineItem> oliList = new List<OpportunityLineItem>([SELECT Id, RollupTrigger__c FROM OpportunityLineItem WHERE OpportunityId IN :opIds]);
    	for(OpportunityLineItem oli :oliList){
            oli.RollupTrigger__c = true;
        }
        try{
        	update oliList;
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', oliList, 'SFE-824 Investigation');
        }
    }
	////END REVENUE REPORTING
    
 //   /**
 //   * @description  creates a case if the related account has not been credit checked
 //   *               (before insert)
 //   *
 //   * @date         2017-10-20
 //   * @author       Tim Fabros
 //   **/
 //   public static void createCreditCheckCase(List<Opportunity> newOpptys) {

 //       Set<Id> recordTypeIds = new Set<Id>();
 //       recordTypeIds.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('SME').getRecordTypeId());
 //       recordTypeIds.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('KAC').getRecordTypeId());
 //       recordTypeIds.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('IMA').getRecordTypeId());
        
 //       Set<Id> accountIds = new Set<Id>();

 //       for (Opportunity newOpp : newOpptys) {
 //           if (recordTypeIds.contains(newOpp.RecordtypeId) && newOpp.StageName == 'Discover Needs') {

 //               accountIds.add(newOpp.AccountId);
 //           }
 //       }

 //       if (accountIds.isEmpty()) { return; }

 //       List<Account> accounts = [SELECT Id FROM Account WHERE Id IN :accountIds AND Has_Credit_Checked__c = false];

 //       Group financeQueue = [SELECT Id FROM Group WHERE Name = 'Finance' AND Type = 'Queue'];

 //       List<Case> creditCases = new List<Case>();

 //       for (Account account : accounts) {

 //           account.Credit_Status__c = 'Pending';

 //           Case creditCase = new Case();

 //           creditCase.AccountId = account.Id;
 //           creditCase.RecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Credit Check').getRecordTypeId();
 //           creditCase.OwnerId = financeQueue.Id;

 //           creditCases.add(creditCase);
 //       }

 //       System.debug(LoggingLevel.ERROR, '@creditCases: ' + creditCases);

 //       if (creditCases.isEmpty()) { return; }
            
 //       insert creditCases;
 //       update accounts;

 //   }
}