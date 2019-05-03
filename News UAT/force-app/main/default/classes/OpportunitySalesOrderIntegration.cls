public with sharing class OpportunitySalesOrderIntegration {
    Opportunity opp;
    
    public OpportunitySalesOrderIntegration(ApexPages.StandardController c) {
        opp = (Opportunity) c.getRecord();
    }

    public PageReference generateSalesOrder() {
        // Assume for now that we are dealing only with Agency opps - need to upgrade this method for direct etc
        //List<Sales_Order__c> sos = [select Id from Sales_Order__c where Opportunity__c = :opp.Id];
        csmso__Sales_Order__c so;
        Id advertiser = opp.AccountId;

        //if (sos.size() ==0) {
            so = new csmso__Sales_Order__c(
                csmso__Advertiser__c = advertiser,
                csmso__Opportunity__c = opp.Id,
                csmso__Status__c = 'Draft'
                //Brand__c = opp.Brand__c,
                //Budget__c = opp.Budget__c
            );
            insert so;
            csmso__Sales_Order__c thisSO = [select id, name from csmso__Sales_Order__c where id =: so.id];
            cscfga.SessionManager.SessionInfo sessionInfo = cscfga.SessionManager.getOrCreateSession(so.Id, 'Session for Sales Order \'' + thisSO.Name + '\'' );       
            

            cscfga__Product_Basket__c basket = new cscfga__Product_Basket__c(csmso__Sales_Order__c = so.Id,cscfga__User_Session__c=sessionInfo.userSession.id,Name='Basket for Session: '+sessionInfo.userSession.id);
            insert basket;
        /*} else {
            so = sos.get(0);
        }*/
        return new PageReference('/'+so.Id);
    }
}