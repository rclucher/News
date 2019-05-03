global class CS_CreateOrchProcessForImport  implements Database.Batchable<sObject>,Database.Stateful {
    

    
    public String query;

    public User orchUser = [select id from User where name = 'Default Orchestrator']; 
    //CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
    public list<id> ids = new list<id>();

    public Map<Id, opportunity> closedOneOpps;

    global CS_CreateOrchProcessForImport (List<Id> oppIds) {
        
        map<Id, list<String>> mapOppToStatus = new map<Id, list<String>>();

        ids.addAll(oppIds);
        query = 'select id, accountid, OwnerId, Industry_Code__c, contact__c,Amount, Owner_Division__c,Account.Name from opportunity where id in: ids';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        List<opportunity> oppList = (List<opportunity>)scope;

        closedOneOpps = new Map<Id, opportunity> (oppList);
        
        CreateOrchProcessForCampaignOdrers(closedOneOpps);
    }
    
    global void finish(Database.BatchableContext BC) {
        
        
    }
    
 

    void CreateOrchProcessForCampaignOdrers (Map<Id, opportunity> closedOneOpps) {
        
         
        List<Order__c> existingOrders = [SELECT Id, Billing_Id__c, CPQ_Payment_Needed__c, Opportunity__c, Account__c, Account__r.Name FROM Order__c WHERE Opportunity__c IN: closedOneOpps.keySet()];
 
        try{
             
            CreateCampaignRecurringOrchProcessForOrders(existingOrders);
            CreateOrchProcessForProductOdrers(closedOneOpps.keySet()); 

        }catch(Exception ex)
        {
            ExLog.log(ex, 'config', existingOrders, 'Could not create campaign orders');
         }
        
    }

    void CreateCampaignRecurringOrchProcessForOrders (List<Order__c> orders) 
    {
        list<Id> oppIds = new list<Id>();
        for (Order__c ord : orders)
            oppIds.add(ord.Opportunity__c);
        
        set<ID> orderWithOrchProcess = new set<ID>();
        List<CSPOFA__Orchestration_Process__c> OrchProcesses = [select Id,Order__c from CSPOFA__Orchestration_Process__c where Order__c in :new map<ID, Order__c>(orders).keySet()];
        for (CSPOFA__Orchestration_Process__c op : OrchProcesses)
        	orderWithOrchProcess.add(op.Order__c);
        
        //if(!OrchProcesses.isEmpty()){delete OrchProcesses;}  
        
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
        CS_OrchestratorUtil orchestratorUtil = new CS_OrchestratorUtil();

        // Expecting only one process for each Order, but in place if multiple
        Set<String> templateLabels = productMapping.GetOrchProcessesNamesForLabel('Campaign Setup Recurring');
        system.debug(loggingLevel.ERROR, '####### templateLabels ' + templateLabels);
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();

        try {
            for (String label : templateLabels) {
                CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel(label);
                
                
                for (Order__c order : orders) {
                	if (orderWithOrchProcess.contains(order.Id))
                		continue;
                		
                    CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                        Name = 'Campaign Setup Recurring', 
                                                                                                        Order__c = order.Id);           
                    processesToInsert.add(process); 
                }

                new CS_OpportunityTriggerDelegate.insertOrchProcesses().execute(processesToInsert);
            }
        } 
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', orders, 'Orchestrator processes were not created for these campaigns');
            
        }
    }

    public void CreateOrchProcessForProductOdrers (set<ID> oppIds)
    {
         List<cscfga__Product_Configuration__c> productConfigList = [SELECT (select Name,cscfga__value__c from cscfga__attributes__r where name in ('Price','Total Cost','Product')), Id, Product_ID__c, 
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c, cscfga__Description__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c FROM cscfga__Product_Configuration__c WHERE 
            cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c IN: oppIds AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c in ('Manually Approved','Externally Approved')];
         List<Id> productIds = new List<Id>();

        if (!productConfigList.isEmpty()) {
            for (cscfga__Product_Configuration__c pc : productConfigList) {
                  productIds.add (pc.Product_ID__c);
             }
            
             system.debug(productIds);
             
        Map<Id, csmso__Product_Node__c> products = new Map<Id, csmso__Product_Node__c>([Select id, Product_Line__c, Product_Type__c from csmso__Product_Node__c where 
            ID IN: productIds]);
            //system.debug(loggingLevel.ERROR, '####### productIds ' + productIds);
            system.debug(loggingLevel.ERROR, '####### Original products ' + JSON.serializePretty(products));
         
        List<Product_Order__c> productOrders = [select Id,Product_Node__c from Product_Order__c
                                            where Order__r.Opportunity__c in :oppIds and
                                            RecordType.Name in ('Social','Search Engine Marketing','Real Time Bidding')];
        
        try {
             CreateProductRecurringOrchProcess(productOrders, products); 
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', productOrders, 'Could not create product orders');
        }
    }
          
    }
    

    public static String GetRecordTypeIdentifierForProduct(csmso__Product_Node__c product) {
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
        
        
        String recordTypeIdentifier = product.Product_Line__c;
        
       

        if (recordTypeIdentifier == 'Social' && product.Product_Type__c=='Setup')
            recordTypeIdentifier = 'Social Setup';

        else if (recordTypeIdentifier == 'Search' && product.Product_Type__c=='SEO')
            recordTypeIdentifier = 'SEO';

        else if (recordTypeIdentifier == 'Campaign Management' && product.Product_Type__c=='Call Tracking')
            recordTypeIdentifier = 'Call Tracking';

        return productMapping.GetRTForProductIdentifier(recordTypeIdentifier);
    }

     void CreateProductRecurringOrchProcess (List<Product_Order__c> prodorders, Map<Id, csmso__Product_Node__c> products ) 
    {
    	set<ID> prodorderWithOrchProcess = new set<ID>();
    	list<CSPOFA__Orchestration_Process__c> OrchProcesses = [select Id,Product_Order__c from CSPOFA__Orchestration_Process__c where Product_Order__c in :new map<ID, Product_Order__c>(prodorders).keySet()];
    	for (CSPOFA__Orchestration_Process__c op : OrchProcesses)
        	prodorderWithOrchProcess.add(op.Product_Order__c);
        //delete [select Id from CSPOFA__Orchestration_Process__c where Product_Order__c in :new map<ID, Product_Order__c>(prodorders).keySet()];
        
        CS_OrchestratorUtil orchestratorUtil = new CS_OrchestratorUtil();
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();

        Map<id, list<string>> prodWIthTemNames = new Map<id, list<string>>();

        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();

        for (Product_Order__c prodOrd : prodorders) {
        	if (prodorderWithOrchProcess.contains(prodOrd.Id))
        		continue;
        		
            if (prodOrd.Product_Node__c != null && products.get(prodOrd.Product_Node__c) != null) {
                String recordTypeLabel = GetRecordTypeIdentifierForProduct (products.get(prodOrd.Product_Node__c));
                 system.debug(loggingLevel.ERROR, '####### recordTypeLabel ' + recordTypeLabel);
                system.debug(recordTypeLabel);
                if (recordTypeLabel == 'Social') {
                    List<string> temIdens = new list<string>{'Real Time Bidding Recurring', 'Social Recurring'}; 
                    for (String label : temIdens) {
                        List<String> templateLabels = new list<string>(productMapping.GetOrchProcessesNamesForLabel(label));

                        CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel (templateLabels.get(0));
                        
                        CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                                Name = template.name, 
                                                                                                                Product_Order__c = prodOrd.Id);           
                        processesToInsert.add(process);  
                        system.debug(process);                   
                    }
                }
                else if (recordTypeLabel == 'Search Engine Marketing') {
                    list<string> temIdens = new list<string>{'Search Engine Marketing Recurring'};
                    for (String label : temIdens) {
                        List<String> templateLabels = new list<string>(productMapping.GetOrchProcessesNamesForLabel(label));
                        
                         system.debug(loggingLevel.ERROR, '####### templateLabels ' + templateLabels);

                        CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel (templateLabels.get(0));
                        
                        CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                                Name = template.name, 
                                                                                                                Product_Order__c = prodOrd.Id);           
                        processesToInsert.add(process); 
                        system.debug(process);                     
                    }
                }
                else if (recordTypeLabel == 'Real Time Bidding') {
                    list<string> temIdens = new list<string>{'Real Time Bidding Recurring'};
                    for (String label : temIdens) {
                        List<String> templateLabels = new list<string>(productMapping.GetOrchProcessesNamesForLabel(label));

                        CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel (templateLabels.get(0));
                        
                        CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                                Name = template.name, 
                                                                                                                Product_Order__c = prodOrd.Id);           
                        processesToInsert.add(process);   
                        system.debug(process);                   
                    }
                }
            }
        }

        try {
            new CS_OpportunityTriggerDelegate.insertOrchProcesses().execute(processesToInsert);
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', prodorders, 'Orchestrator processes were not created for these prodOrd');
         } 
    }
 
}