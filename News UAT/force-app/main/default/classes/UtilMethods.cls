public class UtilMethods {

    /**
     * Gets RecordTypeId for object and record type name
     *
     * @param String API Object Name.Record Type Name
     * @return Id
     * @example  'Product_order__c.Search Engine Marketing'
     * 
     * 
     *  History
     *  <Date>      <Authors Name>     <Brief Description of Change>
     *  20/10/2018  Rinaldo Clucher     Added Product_Configuration. ID when freating Product Orders.
     */
    /* record type section - start */

    public static Id getRecordTypeId(String recordTypeName)
    {
        return getRecordTypes().get(recordTypeName);
    }

    private static Map<String, Id> mRecordTypes;

    private static Map<String, Id> getRecordTypes()
    {
        if (mRecordTypes == null)
        {
            String key;
            String value;

            RecordType[]  rtlist = [ SELECT Id, Name, SObjectType FROM RecordType ];

            mRecordTypes = new Map<String, Id>();

            for (RecordType rt : rtlist)
            {
                key = rt.SObjectType + '.' + rt.Name;
                value = rt.Id;

                mRecordTypes.put(key, value );
            }
        }
        return mRecordTypes;
    }

    public static Map<Id, String> getSObjectTypes(string sObjectName)
    {
        Map<Id, String> rtList = new Map<Id, String>();
        Map<String, Id> allRTs = getRecordTypes();
        for(string key : allRTs.keySet())
        {
            if(key.startsWith(sObjectName))
                rtlist.put(allRTs.get(key), key.replace(sObjectName + '.',''));
        }
        return rtList;
    }
    /* record type section - end */

    public static Id createCreativeForProductOrderId (Id productOrderId, Id userId) {
        Product_Order__c po = [select id, name, New_Creative_Pushed_Count__c from product_order__c where id =: productOrderId];
        String creativeName = 'Creative for ' + po.name + date.today().format();
    
        Creative__c creativeRecord = new Creative__c (product_order__c = productOrderId, Creative_Owner__c = userId, name = creativeName);
        insert creativeRecord;
        
        if (po.New_Creative_Pushed_Count__c == null)
            po.New_Creative_Pushed_Count__c = 0;
        
        po.New_Creative_Pushed_Count__c++;
        po.Is_New_Creative_Button_Pushed__c = 'Clicked';
        
        update po;
        
        return creativeRecord.Id;
    }

    public static Set<String> findObjectNamesFromRecordIdPrefix (Set<Id> recordSetIds) {
        system.debug(recordSetIds);
        set<string>allObjectTypes = new set<string>();
        for (id recordid : recordSetIds) {
            system.debug(recordid.getSObjectType());
            system.debug(recordid.getSObjectType().getDescribe());
            system.debug(recordid.getSObjectType().getDescribe().getName());
             String sObjName = recordid.getSObjectType().getDescribe().getName();
             allObjectTypes.add(sObjName);
        }

        return allObjectTypes;
    }

    public static Map<id, string> mapRecordIdWithObjectName (Set<Id> recordSetIds) {
        system.debug(recordSetIds);
        map<id, string> recordidname = new map<id, string>();
        for (id recordid : recordSetIds) {
            if (recordId != null) {
            String sObjName = recordid.getSObjectType().getDescribe().getName();
            recordidname.put(recordId, sObjName);
            }
        }
        return recordidname;
    }

    public static string startOrchestratorProcessFor (Id recordId, String processName) {
        list<CSPOFA__Orchestration_Process__c> processlist = [select id from CSPOFA__Orchestration_Process__c where (Order__c =: recordId
         OR product_order__c =: recordId) and name = 'Container Tag Setup' and CSPOFA__Status__c!='Complete' AND CSPOFA__State__c!='TERMINATED'];
         system.debug(processlist);
        if (processlist != null && processlist.size() >0) {
            system.debug('here');
            return 'Container tag process is already running for this record.';
        }
        CS_OrchestratorUtil orchestratorUtil = new CS_OrchestratorUtil();
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
        // Expecting only one process for each Order, but in place if multiple
        Set<String> templateLabels = productMapping.GetOrchProcessesNamesForLabel(processName);
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();

        try {
            for (String label : templateLabels) {
                CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel (label);
                
                CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                        Name = 'Container Tag Setup', 
                                                                                                        Order__c = recordId);          
                processesToInsert.add(process); 
                new CS_OpportunityTriggerDelegate.insertOrchProcesses().execute(processesToInsert);
                break;
            }
            
            Order__c ord = [select Container_Tag_Pushed_Count__c
                            from Order__c where Id = :recordId];
                            
            if (ord.Container_Tag_Pushed_Count__c == null)
                ord.Container_Tag_Pushed_Count__c = 0;
                
            ord.Is_Container_Tag_Button_Pushed__c = 'Clicked';
            ord.Container_Tag_Pushed_Count__c++;
            
            update ord;  
        } catch (Exception e) {
            System.debug(e.getMessage());
            return 'There has been an error. Please contact your Salesforce administrator.';
        }
        return '';
    }
    
    public static String prepareDataToRegenerateProductOrder (Id orderId) {
        List<Order__c> orders = [select id, opportunity__c from Order__c where id =: orderId];

        if (!orders.isEmpty()) {
          
            Map<id, Order__c> oppWithOrderid = new Map<Id, Order__c>();
            oppWithOrderid.put(orders[0].opportunity__c, orders[0]);
            String result = DeleteProductOrdersFor (orders[0].Id);
            if (result.equals('')) {
                CreateProductOrders (oppWithOrderid, new Map<Id, csmso__Sales_Order__c>());
                return 'Success.';
            }
            else
                return result;
        }
        else
            return 'Cannot find Order.';
    }

    public static String startFulfilment (Id orderId) {
       String result = 'Success.';
       List<Product_Order__c> prodToUpdate=new List<Product_Order__c>() ;
       List<Product_Order__c> prodOrders = [SELECT Id, Status__c FROM Product_Order__c where Order__c =: orderId and Status__c='Draft'];
       if(prodOrders==null || prodOrders.size()==0)
          return 'No eligible products found for fulfilment.';
       for (Product_Order__c prodOrd : prodOrders)
        {
          prodOrd.Status__c = 'Fulfilment Started';
          prodToUpdate.add(prodOrd);
        }
        try
        {
            Order__c ord = [select Start_All_Fulfillment_Pushed_Count__c
                            from Order__c where Id = :orderId];
                            
            if (ord.Start_All_Fulfillment_Pushed_Count__c == null)
                ord.Start_All_Fulfillment_Pushed_Count__c = 0;
                
            ord.Start_All_Fulfillment_Pushed_Count__c++;
            
            update ord;          
            update prodToUpdate; 
        } catch (Exception e) {
            System.debug(e.getMessage());
            return 'There has been an error. Please contact your Salesforce administrator.';
        }
       return result;
    }

    public static String DeleteProductOrdersFor (Id orderId)
    {
        List<Product_Order__c> prodOrders = [SELECT Id, Status__c FROM Product_Order__c where Order__c =: orderId];
         for (Product_Order__c prodOrd : prodOrders) {  
            if (prodOrd.Status__c != 'Draft' && prodOrd.Status__c != 'Cancelled') {
                return 'At least one of your products has already started the fulfilment. Please ask your administrator for assistance.';
            }

        }
        delete prodOrders;
        return '';
    }

    public static void CreateProductOrders (Map<Id, Order__c> ordersForOpps, Map<Id, csmso__Sales_Order__c> salesOrderWithOppPar)
    {
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
        List<Product_Order__c> productOrders = new List<Product_Order__c>();
        boolean doNotCreateProdOrder=false;

        List<cscfga__Product_Configuration__c> productConfigList = [SELECT Id, Product_ID__c,
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c, cscfga__Description__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c FROM cscfga__Product_Configuration__c WHERE 
            cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c IN: ordersForOpps.keySet() AND
            (cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c ='Manually Approved' OR cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c ='Externally Approved')
            AND  Line_Item_Platform__c = 'Xtend' AND Bundle_Item__c = false ];//NR-508 added Bundle Item check
        Map<Id, List<cscfga__Product_Configuration__c>> oppWithPCs = new Map <Id, List<cscfga__Product_Configuration__c>>();
        List<Id> productIds = new List<Id>();
        Map<Id, Boolean> OppIdCallTracking = new Map<Id, Boolean>();
        if (!productConfigList.isEmpty()) {
            for (cscfga__Product_Configuration__c pc : productConfigList) {
                List<cscfga__Product_Configuration__c> PCs = oppWithPCs.get(pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c);
                if (PCs == null)
                    PCs = new List<cscfga__Product_Configuration__c>();
                PCs.add(pc);

                oppWithPCs.put (pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c, PCs);
                productIds.add (pc.Product_ID__c);

                OppIdCallTracking.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c, pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c);
            }

        //NXRIII-326 - I need to introduce Network__c field as additional condition to identify record type for PO 
        /*
        List<csmso__Product_Node__c> productNodes = new List<csmso__Product_Node__c>([Select id,Name,
            Product_Line__c, Product_Type__c, Do_Not_Create_Product_Order__c from csmso__Product_Node__c where 
            ID IN: productIds]);
        */
        List<csmso__Product_Node__c> productNodes = new List<csmso__Product_Node__c>([Select id,Name,
            Product_Line__c, Product_Type__c, Do_Not_Create_Product_Order__c, Network__c, Provider__c,Product_Groups_For_IO__c from csmso__Product_Node__c where
            ID IN: productIds]);
        //end of NXRIII-326 - DD

        Map<Id,sObject> products = new Map<Id, SObject>();

        products.putAll(productNodes);

        Map<Id, csmso__Sales_Order__c> salesOrderWithOpp;
        if (salesOrderWithOppPar == null || salesOrderWithOppPar.isEmpty()) {
            salesOrderWithOpp = new Map<Id, csmso__Sales_Order__c>();

            List<csmso__Sales_Order__c> salesOrders = [SELECT Id, Campaign_Name__c, Campaign_Start_Date__c, csmso__Opportunity__c, Campaign_End_Date__c, Campaign_End_Date2__c FROM csmso__Sales_Order__c
                                                    WHERE csmso__Opportunity__c IN: ordersForOpps.keySet() AND 
                                                    (csmso__Status__c ='Manually Approved' OR csmso__Status__c ='Externally Approved')];

            for (csmso__Sales_Order__c so : salesOrders)
                salesOrderWithOpp.put(so.csmso__Opportunity__c, so);
        }
        else {
            salesOrderWithOpp = salesOrderWithOppPar;
        }
        
        string idList = '';
        
        for (Id oppId : oppWithPCs.keySet()) {
            Set<String> allProductIdentifiers = new Set<String>();
            system.debug(salesOrderWithOpp);
            system.debug(oppWithPCs);
            for (cscfga__Product_Configuration__c pc : oppWithPCs.get(oppId)) {
                if(products.containsKey(pc.Product_ID__c)){
                    doNotCreateProdOrder=(boolean) products.get(pc.Product_ID__c).get('Do_Not_Create_Product_Order__c');
                    if(doNotCreateProdOrder){
                        system.debug('********There is no need to create a Product Order for the Product Node '+(String) products.get(pc.Product_ID__c).get('Name'));
                        continue;
                    }
                }
                
                // kw: apply 'singleton' pattern to improve performance
                String recordTypeLabel = getRecordTypeIdentifierForProduct (products.get(pc.Product_ID__c), productMapping);
                allProductIdentifiers.add(recordTypeLabel);
                Id recordType = UtilMethods.getRecordTypeId('Product_Order__c.'+recordTypeLabel);
                Product_Order__c newProduct;
                String status = (salesOrderWithOpp.get(oppId).Origin__c != null && salesOrderWithOpp.get(oppId).Origin__c != 'Salesforce') ? 'Live'
                                                                                                                                            : 'Draft';
                if (recordType != null)
                    newProduct = new Product_Order__c (   Order__c = ordersForOpps.get(oppId).Id, 
                                                            PC_Id__c = String.valueOf(pc.Id),
                                                            //Name = pc.cscfga__Description__c,
                                                            Status__c = status,
                                                            Product_Configuration__c = pc.id,     // Added Rinaldo
                                                            Type__c = 'New',
                                                            Product_Order_Start_Date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                            Product_Order_End_Date__c = salesOrderWithOpp.get(oppId).Campaign_End_Date2__c,
                                                            Product_Node__c = pc.Product_ID__c,
                                                            RecordTypeId = recordType,
                                                            Impressions_Factor__c = 1);
                else
                    newProduct = new Product_Order__c (   Order__c = ordersForOpps.get(oppId).Id,
                                                            PC_Id__c = String.valueOf(pc.Id),
                                                            //Name = pc.cscfga__Description__c,
                                                            Status__c = status,
                                                            Product_Configuration__c = pc.id,     // Added Rinaldo
                                                            Product_Order_Start_Date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                            Product_Order_End_Date__c = salesOrderWithOpp.get(oppId).Campaign_End_Date2__c,
                                                            Type__c = 'New',
                                                            Product_Node__c = pc.Product_ID__c,
                                                            Impressions_Factor__c = 1);

                System.debug(LoggingLevel.ERROR,'## Product Order : ' + newProduct);
                productOrders.add (newProduct);
            }

            system.debug(LoggingLevel.ERROR,'*******before insert productOrders 1 '+productOrders);

            // If Call Tracking checked on Sales Order, treat it like a normal product
            if (!allProductIdentifiers.contains('Call Tracking') && OppIdCallTracking.get(oppId)) {
                String recordTypeLabel = 'Call Tracking';
                Id recordType = UtilMethods.getRecordTypeId('Product_Order__c.'+recordTypeLabel);
                String status = (salesOrderWithOpp.get(oppId).Origin__c != null && salesOrderWithOpp.get(oppId).Origin__c != 'Salesforce') ? 'Live'
                                                                                                                                            : 'Draft';
                Product_Order__c newProduct = new Product_Order__c (   Order__c = ordersForOpps.get(oppId).Id, 
                                                            //Name = 'Call Tracking',
                                                            Status__c = status,
                                                            Type__c = 'New',
                                                            Product_Order_Start_Date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                            Product_Order_End_Date__c = salesOrderWithOpp.get(oppId).Campaign_End_Date2__c,
                                                            RecordTypeId = recordType,
                                                            Impressions_Factor__c = 1); 
                productOrders.add (newProduct); 
            }

        }
        try {
            system.debug(LoggingLevel.ERROR,'*******before insert productOrders 2 '+productOrders);
            insert productOrders;
            system.debug(LoggingLevel.ERROR,'*******after insert productOrders'+productOrders);
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', productOrders, 'Could not create product orders');
        }
    }
          
    }
    // TODO: upgrade removal, using sObject cast to support old and new prod def, set to Product Node for Upgrade
    public static String GetRecordTypeIdentifierForProduct(sObject product) {
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
        return getRecordTypeIdentifierForProduct(product);
    }

    // kw: added this method for better performance 
    public static String getRecordTypeIdentifierForProduct(sObject product, CS_ProductMappingMetadataUtil productMapping) {
        if(productMapping == null){
            productMapping = new CS_ProductMappingMetadataUtil();
        }

        String recordTypeIdentifier = (String) product.get('Product_Line__c');

        // PM CSP-TICKET FIX T-36418
        if (recordTypeIdentifier == 'Display' && product.get('Product_Type__c')=='Catch Up TV') {
            recordTypeIdentifier = 'Catch Up TV';
        }

        if (recordTypeIdentifier == 'Display' && product.get('Product_Type__c')=='Programmatic Audio') {
            recordTypeIdentifier = 'Programmatic Audio';
        }
		//NXRIII-337 new Product - Real Time Bidding CPC
        if (recordTypeIdentifier == 'Display' && product.get('Product_Groups_For_IO__c')=='Display CPC') {
            recordTypeIdentifier = 'Display CPC'; // maches label in Map_Orchestrator_Process__mdt
        }
        //NXRIII-364 - New Product - RTB Media Spend
        if (recordTypeIdentifier == 'Display' && product.get('Product_Groups_For_IO__c')=='Display Media Spend') {
            recordTypeIdentifier = 'RTB Display - Media Spend'; // maches label in Map_Orchestrator_Process__mdt
        }
        // PM CSP-TICKET FIX T-36418

        if (recordTypeIdentifier == 'Social' && product.get('Product_Type__c')=='Setup')
            recordTypeIdentifier = 'Social Setup';

        else if (recordTypeIdentifier == 'Search' && product.get('Product_Type__c')=='SEO')
            recordTypeIdentifier = 'SEO';

        else if (recordTypeIdentifier == 'Campaign Management' && product.get('Product_Type__c')=='Call Tracking')
            recordTypeIdentifier = 'Call Tracking';

        //NXRIII-303 new Product - Marketplace Feed
        if (recordTypeIdentifier=='Website' && product.get('Product_Type__c')=='Marketplace Feed')
            recordTypeIdentifier='Marketplace Feed';

        //NXRIII-305 new Product - Web Dev
        if (recordTypeIdentifier=='Website' && product.get('Product_Type__c')=='Web Dev')
            recordTypeIdentifier='Web Dev';
            
        //NXRIII-326 new Product - Real Estate product Brandme
        System.debug('***recordTypeIdentifier=' + recordTypeIdentifier);
        System.debug('***Product_Type__c=' + product.get('Product_Type__c'));
        System.debug('***Network__c=' + product.get('Network__c'));
        System.debug('***Provider__c=' + product.get('Provider__c'));

        if (recordTypeIdentifier=='Social' && product.get('Product_Type__c')=='Social Advertising' && product.get('Network__c')=='Content')
            recordTypeIdentifier='Content';

        if (recordTypeIdentifier=='Social' && product.get('Product_Type__c')=='Social Advertising' && product.get('Network__c')=='Facebook' && product.get('Provider__c')=='News Xtend - Real Estate')
            recordTypeIdentifier='Media Spend';

        /*if (recordTypeIdentifier=='Social' && product.get('Product_Type__c')=='Content')
            recordTypeIdentifier='Content';*/
        //end of NXRIII-326 - DD

        //NXRIII-328 replacement of Web Dev Product 
        if (recordTypeIdentifier=='Website' && product.get('Product_Type__c')=='Landing Pages')
            recordTypeIdentifier='Landing Pages';
        //end of NXRIII-328 - DD

        System.debug('***recordTypeIdentifier=' + recordTypeIdentifier);

        return productMapping.getRTForProductIdentifier(recordTypeIdentifier);
    }

    /**
     * Returns the list of all related fields to be used in dynamic SOQL
     *
     * @param so prefix.object api name (example Contact__r.Contact)
     * @return String csv list of all object fields
     */
    public static String getSobjectRelatedFields(String so) {
        String fieldString;
        List<string> objects = so.split(',');
        string prefix = objects[0];
        SObjectType sot = Schema.getGlobalDescribe().get(objects[1]);
        if (sot == null) {
            return null;
        }
        
        List<Schema.SObjectField> fields = sot.getDescribe().fields.getMap().values();

        fieldString = prefix + '.' + fields[0].getDescribe().LocalName;
        for (Integer i = 1; i < fields.size(); i++) {
            if (fields[i].getDescribe().LocalName != 'ContractId')
                fieldString += ','+prefix+'.' + fields[i].getDescribe().LocalName;
        }
        return fieldString;
    }

   /**
    * Run upgrade of Product attribute to use related Product Node and run configurator Upgrader
    *
    * @param scope List of Product Configurations with related Product attributes to update
    * @return Updated list of PCs with Product attribute set to Product Node reference
    * */
    public static List<cscfga__Product_Configuration__c> runProductAttrUpgrade(List<cscfga__Product_Configuration__c> scope ) {
        System.debug(scope);

        Set<Id> productRefIds = new Set<Id>();
        List<Exception_Record__c> exceptionList = new List<Exception_Record__c>();
        
        for (cscfga__Product_Configuration__c config : scope) {

            for (cscfga__Attribute__c att : config.cscfga__Attributes__r) {
                if (String.isNotBlank(att.cscfga__Value__c))
                    productRefIds.add(att.cscfga__Value__c);
            }
            System.debug(config.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c + ' -- ' +
                    config.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.Name);
        }

        Map<Id, News_Xtend_Product_Ref__c> productRefs = new Map<Id, News_Xtend_Product_Ref__c>(
        [
                SELECT Id,
                        Product_Node__c
                FROM News_Xtend_Product_Ref__c
                WHERE Id IN :productRefIds
        ]
        );

        List<cscfga__Attribute__c> attToUpdate = new List<cscfga__Attribute__c>();

        for (cscfga__Product_Configuration__c config : scope) {
            for (cscfga__Attribute__c att : config.cscfga__Attributes__r) {
                System.debug('***** att Id and val Id:'+att.Id +' Val:'+att.cscfga__Value__c);
                if (String.isNotBlank(att.cscfga__Value__c)) {
                    if (productRefs.containsKey(att.cscfga__Value__c)) {
                        att.cscfga__Value__c = productRefs.get(att.cscfga__Value__c).Product_Node__c;
                        attToUpdate.add(att);
                    } else {
                        Exception_Record__c er = new Exception_Record__c();
                        er.Failure_Reason__c = 'Missing News Extend Product ref - Id:'+att.cscfga__Value__c +':AttId:'+att.Id;

                        exceptionList.add(er);
                    }
                } else {
                    Exception_Record__c er1 = new Exception_Record__c();
                    er1.Failure_Reason__c = 'Product Id Missing - AttId:'+att.Id;

                    exceptionList.add(er1);
                }
            }
        }

        if(!exceptionList.isEmpty()){
            insert exceptionList;
        }

        update attToUpdate;

        cfgug1.ProductConfigurationUpgrader.upgradeConfigurations(new List<Id>(new Map<Id, cscfga__Product_Configuration__c>(scope).keySet()));
        
        Map<id, cscfga__Product_Configuration__c> mappc = new map<id, cscfga__Product_Configuration__c>(scope);
        
        list<cscfga__Product_Configuration__c> pcs = [select id, cscfga__configuration_status__c from 
                                                        cscfga__Product_Configuration__c where 
                                                        id IN: mappc.keySet()];

        //**IVANA UPDATE START** 
        for (cscfga__Product_Configuration__c pc : pcs) {
            pc.cscfga__configuration_status__c = 'Valid';
        }
        
        update pcs;
        //**IVANA UPDATE END**
        
        return pcs;
    }



    public static void CreateCSVsForDataImport(String dataImportSheet) 
    {
        set<ID> oppIDSetExc = new set<ID>();
        list<Document> docsExc = [select body from Document where Name = 'OpportunitiesToBeExcluded ProductionRun.csv'];
        if (!docsExc.isEmpty())
        {
            list<ID> oppIDListExc = (list<ID>)((list<Object>)docsExc[0].body.toString().split('\r\n'));
            oppIDSetExc.addAll(oppIDListExc);
        }

        Document doc = [select body from Document where Name = :dataImportSheet];
        list<String> masterSheetRecords = doc.body.toString().split('\r\n'); 
        
        set<ID> oppIds = new set<ID>();
        String oppForOrchProcess = '';
        map<Integer, Boolean> mapRowToValid = new map<Integer, Boolean>();
        
        for (integer i = 1; i < masterSheetRecords.size(); i++) 
        {
            String rec = masterSheetRecords[i];
            list<String> recFields = rec.split(',');
            
            if (String.isEmpty(recFields[1]) || !(recFields[1] instanceof ID) || oppIDSetExc.contains(ID.valueof(recFields[1]))) 
            {
                mapRowToValid.put(i, false);
                continue;
            }
            
            mapRowToValid.put(i, true);
            
            oppIds.add(recFields[1]);
            oppForOrchProcess += recFields[1] + '\r\n';
    }
    
    Map<ID, map<ID, list<Product_Order__c>>> mapOppToOrderToProductOrders = new map<ID, map<ID, list<Product_Order__c>>>();
    for (Product_Order__c po : [select Id, Order__c, Order__r.Opportunity__c, RecordType.Name
    from Product_Order__c where Order__r.Opportunity__c in :oppIds])
    {
        map<ID, list<Product_Order__c>> mapOrderToProductOrders = mapOppToOrderToProductOrders.get(po.Order__r.Opportunity__c);
        
        if (mapOrderToProductOrders == null)
            mapOrderToProductOrders = new map<ID, list<Product_Order__c>>();
            
        list<Product_Order__c> productOrders = mapOrderToProductOrders.get(po.Order__c);
        
        if (productOrders == null)
            productOrders = new list<Product_Order__c>();
            
        productOrders.add(po);
        
        mapOrderToProductOrders.put(po.Order__c, productOrders);
        mapOppToOrderToProductOrders.put(po.Order__r.Opportunity__c, mapOrderToProductOrders);
    }
    
    String orderCSV = 'Id,CPQ_Payment_Needed__c,Assigned_Campaign_Manager__c,Next_Campaign_Performance_Review_Date__c,Next_Customer_Report_Date__c,Next_Dashboard_Review_Date__c\r\n';
    String poCSV = 'Id,Assigned_Fulfilment_Owner__c,Next_Optimisation_Date__c,External_System_ID__c,Assigned_Social_Owner__c,Next_Social_Go_Live__c,Next_Social_Kick_Off__c\r\n';
    
    for (integer i = 1; i < masterSheetRecords.size(); i++)
    {
        String rec = masterSheetRecords[i];
        list<String> recFields = rec.split(',');
        
        if (mapRowToValid.get(i) == false) 
            continue;
     
        ID oppId = ID.valueOf(recFields[1]);
        String COAssignedCampaignManager = recFields[3];
        String CONextCampaignPerformanceReviewDate = recFields[4];
        String CONextCustomerReportDate = recFields[5];
        String CONextDashboardReviewDate = recFields[6];
        String COCPQPaymentNeeded = (!String.isEmpty(recFields[7]) && recFields[7] == 'Yes' ? 'false' : 'true');
        String SEMAssignedFulfilmentOwner = recFields[8];
        String SEMNextOptimisationDate = recFields[9];
        String SEMExternalSystemId = (!String.isEmpty(recFields[10]) ? recFields[10] : '');
        String RTBAssignedFulfilmentOwner = recFields[11];
        String RTBNextOptimisationDate = recFields[12];
        String SocialAssignedFulfilmentOwner = recFields[13];
        String SocialAssignedSocialOwner = recFields[14];
        String SocialNextOptimisationDate = recFields[15];
        String SocialNextSocialGoLive = recFields[16];
        String SocialNextSocialKickOff = recFields[17];
        
        map<ID, list<Product_Order__c>> mapOrderToProductOrders = mapOppToOrderToProductOrders.get(oppId);
        if (mapOrderToProductOrders == null) continue;
        
        for (ID orderId : mapOrderToProductOrders.keySet())
        {
            orderCSV += (ID.valueOf(orderId) + ',' + COCPQPaymentNeeded + ',' + COAssignedCampaignManager + ',' + CONextCampaignPerformanceReviewDate + ',' + CONextCustomerReportDate + ',' + CONextDashboardReviewDate + '\r\n');
            for (Product_Order__c po : mapOrderToProductOrders.get(orderId))
            {
                if (po.RecordType.Name == 'Search Engine Marketing')
                    poCSV += ID.valueOf(po.Id) + ',' + SEMAssignedFulfilmentOwner + ',' + SEMNextOptimisationDate + ',' + SEMExternalSystemId + ',,,\r\n';
                else if (po.RecordType.Name == 'Real Time Bidding')
                    poCSV += ID.valueOf(po.Id) + ',' + RTBAssignedFulfilmentOwner + ',' + RTBNextOptimisationDate + ',,,,\r\n';
                else if (po.RecordType.Name == 'Social')
                    poCSV += ID.valueOf(po.Id) + ',' + SocialAssignedFulfilmentOwner + ',' + SocialNextOptimisationDate + ',,' + SocialAssignedSocialOwner + ',' + SocialNextSocialGoLive + ',' + SocialNextSocialKickOff + '\r\n';
            }
        }
    }
    list<Document> documents = new list<Document>();
    Document doc1 = new Document();
    doc1.FolderId = [select Id from Folder where Name = 'Public Folder'].Id;
    doc1.Name = 'OppForOrchProcess ProductionRun.csv';
    doc1.ContentType = 'text/csv';
    doc1.Body = Blob.valueOf(oppForOrchProcess);
    documents.add(doc1);
    Document doc2 = new Document();
    doc2.FolderId = [select Id from Folder where Name = 'Public Folder'].Id;
    doc2.Name = 'CampaignOrderImport ProductionRun.csv';
    doc2.ContentType = 'text/csv';
    doc2.Body = Blob.valueOf(orderCSV );
    documents.add(doc2);
    Document doc3 = new Document();
    doc3.FolderId = [select Id from Folder where Name = 'Public Folder'].Id;
    doc3.Name = 'ProductOrderImport ProductionRun.csv';
    doc3.ContentType = 'text/csv';
    doc3.Body = Blob.valueOf(poCSV );
    documents.add(doc3);
    insert documents;
    }  
       
}