@isTest
public class AT_UpdateOpportunityStage_Test {
    
    @isTest(SeeAllData=true)
    public static void UnitTest01(){
        List<Id> OppIDs = new List<ID>();
        List<Opportunity> Opps = [Select ID from Opportunity where campaign_brief_form_completed__c = true and Approved_Sales_Order_Number__c != NULL and StageName NOT IN ('Closed Won','Closed Lost') LIMIT 2];
        for(Opportunity Opp: Opps) OppIDs.add(Opp.Id);
        AT_UpdateOpportunityStage atUOS = new AT_UpdateOpportunityStage(OppIDs);
        System.debug('Not Asserting Anything');
    }
    
}