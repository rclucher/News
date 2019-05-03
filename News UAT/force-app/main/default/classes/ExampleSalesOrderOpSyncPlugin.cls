global without sharing class ExampleSalesOrderOpSyncPlugin implements csmso.SalesOrderSupport.SalesOrderCustomAction{
    global String performAction(String salesOrderId){
        
        List<csmso__Sales_Order__c> soList=new List<csmso__Sales_Order__c>();
     
        csmso__Sales_Order__c salesOrder = [select Id, csmso__Opportunity__c, (select Id, cscfga__Basket_Status__c from csmso__Product_Baskets__r) from csmso__Sales_Order__c where Id = :salesOrderId];
                  Integer numOfInvalidConfig=[select count () from cscfga__Product_Configuration__c where cscfga__Configuration_Status__c !='Valid' and cscfga__Product_Basket__c=:salesOrder.csmso__Product_Baskets__r.get(0).Id];
        soList=[select id from csmso__Sales_Order__c where  csmso__Opportunity__c=:salesOrder.csmso__Opportunity__c and id!=:salesOrder.id];
        System.debug('**no.' + numOfInvalidConfig);
       
        if(numOfInvalidConfig<1) {
            syncBasketWithOpportunity(salesOrder.csmso__Product_Baskets__r.get(0).Id, salesOrder.csmso__Opportunity__c);       
            csmso__Sales_Order__c  SO= new csmso__Sales_Order__c (id=salesOrderId);
          
            for(csmso__Sales_Order__c s: soList){
                
            }
            soList.add(SO);
            update soList;
            return '{"status":"ok", "redirectURL":"/' + salesOrder.csmso__Opportunity__c + '", "message": "redirecting to opportunity ..."}';
        }
      
        return '{"status":"warning", "message":"There are invalid configurations, cannot synchronize this with the opportunity."}';          

    }

    global static void syncBasketWithOpportunity(Id basketId, Id opportunityId) {
        // Get the configs from the basket and attach to a new bundle.
        List<cscfga__Product_Configuration__c> configs = [select Id, Name from cscfga__Product_Configuration__c where cscfga__Product_Basket__c = :basketId];
    
        if (configs == null || configs.size() == 0){
        return;
        }
        System.debug('configs = '+configs);
    
        // create and then sync the bundle
        cscfga__Product_Bundle__c bundle = new cscfga__Product_Bundle__c(cscfga__Opportunity__c = opportunityId, name='tempBundleForSync with '+opportunityId);
        insert bundle;
    
        System.debug('bundle = ' + bundle);
        
        for (cscfga__Product_Configuration__c config : configs){
        config.cscfga__Product_Bundle__c = bundle.Id;
        }
        update configs;
        
        System.debug('bundle = ' + bundle);
        String bundleId = bundle.Id;
        System.debug('bundleId = ' + bundleId);
        Opportunity tempOpp = [select pricebook2Id from Opportunity where id=:opportunityId];
        System.debug(tempOpp);
    
        cscfga.ProductBundleController bundleController = new cscfga.ProductBundleController(bundleId);
    
        List<cscfga.LineItem> lineItems = bundleController.getAllLineItems();
    
        bundleController.doSyncWithOpportunity();
}
}