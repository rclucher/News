/**
 * Created by petar.mikic on 25/09/2017.
 */

global class CS_UpgradeOrdersPaymentsBatch implements Database.Batchable<sObject>
{
    private list<id> pliIds = new list<id>();
    private Map<Id, News_Xtend_Product_Ref__c> productsMap;
    global CS_UpgradeOrdersPaymentsBatch() {
        productsMap = new Map<Id, News_Xtend_Product_Ref__c>([SELECT Id, Product_Node__c FROM News_Xtend_Product_Ref__c WHERE Record_Type_Name__c = 'Product']);
    }
    
    global CS_UpgradeOrdersPaymentsBatch(List<id> ids) {
        pliIds = ids;
        productsMap = new Map<Id, News_Xtend_Product_Ref__c>([SELECT Id, Product_Node__c FROM News_Xtend_Product_Ref__c WHERE Record_Type_Name__c = 'Product']);
    }

    // prepare select of eligible payment schedules and then return all the related payment line items;
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        List<String> pliStatuses =  new List<String>{'Pending', 'In Progress', 'Scheduled'};
        
        if (pliIds.isEmpty()) {
            return Database.getQueryLocator(' SELECT Id, ' +
                                        '        News_Xtend_Product_Ref__c, ' +
                                        '        Product_ID__c, ' +
                                        '        News_Xtend_Product_Ref__r.Product_Node__c ' +
                                        ' FROM  Payment_Line_Item__c ' +
                                        ' WHERE Payment_Schedule__r.Status__c IN: pliStatuses ' +
                                        ' AND Product_Node__c = null ');
        }
        else  {
            return Database.getQueryLocator(' SELECT Id, ' +
                                        '        News_Xtend_Product_Ref__c, ' +
                                        '        Product_ID__c, ' +
                                        '        News_Xtend_Product_Ref__r.Product_Node__c ' +
                                        ' FROM  Payment_Line_Item__c ' +
                                        ' WHERE id IN: pliIds');
        }

    }
    

    global void execute(Database.BatchableContext BC, List<Payment_Line_Item__c> scope)
    {
         system.debug(scope);

        List<Payment_Line_Item__c> plItemsToUpdate = new  List<Payment_Line_Item__c>();

        News_Xtend_Product_Ref__c productRef = null;

        List<Exception_Record__c> exceptionList = new List<Exception_Record__c>();

        if ( scope.size() != 0 ) {

            System.debug(LoggingLevel.ERROR, '* * PaymentBatch * * > Updating ' + scope.size() + ' Payment Line Items ');

            for (Payment_Line_Item__c pli: scope) {
                
                productRef = productsMap.get(pli.Product_ID__c);

                // updating only Xtend Product refs that have a Product Node
                if (productRef != null && productRef.Product_Node__c != null ) {
                     
                    pli.Product_ID__c             = productRef.Product_Node__c;
                    pli.Product_Node__c           = productRef.Product_Node__c;
                    pli.News_Xtend_Product_Ref__c = productRef.Id;
                    system.debug('***** pli : '+pli);
                    system.debug('***** relatedProdNode : '+productRef);
                    plItemsToUpdate.add(pli);
                } else {

                    Exception_Record__c er = new Exception_Record__c();
                    er.Failure_Reason__c = 'Product_ID__c on PLI or Product_Node__c on Product ref is missing, Id:'+pli.Id;
                    //er.Record_Id__c = pli.Id;

                    exceptionList.add(er);
                }
            }

            
        }
        system.debug('***** plItemsToUpdate : '+plItemsToUpdate);

        if(!exceptionList.isEmpty()){
            insert exceptionList;
        }
        update plItemsToUpdate;

    }

    private void updateProductOrders(){
        // go through all related product orders
        List<Exception_Record__c> exceptionList = new List<Exception_Record__c>();

        List<Product_Order__c> productOrders        = [SELECT Id, News_Xtend_Product_Ref__c,
                News_Xtend_Product_Ref__r.Product_Node__c
        FROM Product_Order__c
        WHERE Product_Node__c = null];

        List<Product_Order__c> pOrdsToUpdate = new List<Product_Order__c>();
        String relatedProdNode;
        if (! productOrders.isEmpty() ) {
            System.debug(LoggingLevel.ERROR, '* * PaymentBatch * * > Updating ' + productOrders.size() + ' Product Orders ');

            for (Product_Order__c po: productOrders) {

                relatedProdNode = null;

                // updating only Xtend Product refs that have a Product Node
                if (po.News_Xtend_Product_Ref__c != null && po.News_Xtend_Product_Ref__r.Product_Node__c != null ) {

                    relatedProdNode = po.News_Xtend_Product_Ref__r.Product_Node__c;

                    po.Product_Node__c           = relatedProdNode;
                    //po.News_Xtend_Product_Ref__c = null;

                    pOrdsToUpdate.add(po);
                } else {

                    Exception_Record__c er = new Exception_Record__c();
                    er.Failure_Reason__c = 'News_Xtend_Product_Ref__c on Product Order or Product_Node__c on Product ref is missing Id:' +po.Id ;
                    //er.Record_Id__c = po.Id;

                    exceptionList.add(er);
                }
            }
        }

        if(!exceptionList.isEmpty()){
            insert exceptionList;
        }

        update pOrdsToUpdate;

    }
    global void finish(Database.BatchableContext BC)
    {
        updateProductOrders();
    }

}