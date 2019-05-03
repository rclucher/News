/*---------------------------------------------------------
 * Author: Alistair Borley
 * Company: CloudSense
 * Description: 
 * This class contains an action handler which is called by a button press on the CloudSense Sales Order screen
 * It performs the action of generating a PDF based on the information on the Sales Order.
 ---------------------------------------------------------*/

global without sharing class GenerateSalesOrderIO implements csmso.SalesOrderSupport.SalesOrderCustomAction{
    
    global String performAction(String salesOrderId) {
        
        System.debug('IGOR STUYVER: ' + salesOrderId);
        
        //Fix for NR-2180
        csmso__Sales_Order__c salesOrder = [select Id, Basket_Products__c, csmso__Status__c, Campaign_Start_Date__c, Margin_Flag__c, Campaign_Length__c from csmso__Sales_Order__c where Id = :salesOrderId];
        if (salesOrder.Campaign_Start_Date__c == null) {
            System.debug('Can not Generate IO without a Campaign Start Date');
            return '{"status":"error", "message":"Please enter Campaign Start Date before generating IO."}';
        }
        // T-26364 new code, added check for Campaign length
        if (salesOrder.Basket_Products__c.contains('News Xtend') &&
            ((((salesOrder.csmso__Status__c == 'Draft') || (salesOrder.csmso__Status__c == 'Externally Rejected') || (salesOrder.csmso__Status__c == 'Internally Rejected')) && ((salesOrder.Margin_Flag__c  == 'Margin TOO LOW'))) || 
                (salesOrder.csmso__Status__c == 'Draft' && salesOrder.Campaign_Length__c != null)))  {
            System.debug('Can not generate Insertion Order, Margin too low and/or Campaign length is less than 3 months and not approved:' + salesOrder.Margin_Flag__c );
            return '{"status":"error", "message":"Please obtain approval for Low margin or Seasonal campaign."}';// T-26364 2016-08-08 'lenght' to 'length'
        }
        
        //Fix ends here.
        
        Map<String, Object> inputMap = new Map<String, Object>();
        inputMap.put('recordId', salesOrderId);
        
        //csmso__Sales_Order__c salesOrder = Creator_DataPrep.prepInsertionOrder(inputMap, salesOrderId);
        
        salesOrder = Creator_DataPrep.prepInsertionOrder(inputMap, salesOrderId);
        csdg__Doc_Config__c dc = [SELECT 
                                    Id, Name,csdg__CustomerDocumentConfigId__c
                                    From csdg__Doc_Config__c
                                  WHERE csdg__CustomerDocumentConfigId__c = 'd3a37525-3660-42e5-bbac-592143ce7c05'
                                    LIMIT 1];
        
        //Set the ALternative to "DRAFT" if billing status is red
        if(salesOrder.csmso__Advertiser__r.Billing_Status__c == 'Red') {
            csdg.MetadataWrapper.alternativeNameStatic = 'DRAFT';
        }
        
        csdg.DocGenerationWrapper result = csdg.DocumentDataHandler.generate(dc.Id, salesOrderId, inputMap);
        
        String dt = Datetime.now().format('MM-dd-yyyy HH:mm:ss');
        //[[!AdvertizerNameTitle!]]-[[!OppNameTitle!]]-[[!SalesOrderNameTitle!]]-[[!NowTitle!]]
        //  but the title cannot be longer then 80 chars otherwise it will not fit in the approval
        String name = salesOrder.csmso__Advertiser__r.Name + '--' + salesOrder.Name + '-' + dt + '.pdf';
        //String name = result.response.metadata.targetName;
        //add the opp title but make sure the full name is no longer the 80chars
        Integer x = 80 - name.length();
        String oppName = salesOrder.csmso__Opportunity__r.Name;
        if(oppName.length() > x && x > 0) {
            oppName = oppName.right(x);
        }
        name = name.replace('--', '-' + oppName + '-');
        if(name.length() > 80) {
            name = name.right(80);
        }
        
        csmso__Upload_Approval__c ioa = new csmso__Upload_Approval__c();
        ioa.csmso__Sales_Order__c = salesOrderId;
        ioa.Name = name;
        insert ioa;

        Attachment a = new Attachment();
        a.name = ioa.Name;
        a.parentId = ioa.Id;
        a.Body = result.response.base64;
        a.contentType = 'application/pdf';
        insert a;
        
        return '{"status":"ok", "message":"Insertion Order successfully generated."}';
    }
    
}