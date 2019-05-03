global class CS_DataCreation implements Database.Batchable<sObject>,Database.Stateful {
    
    public class ImportData
    {
        
    }
    
    private static map<ID, User> allActiveUsers;
    public String query;
    //public List<id> oppIds;
    public User orchUser = [select id from User where name = 'Default Orchestrator']; 
    CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
    public list<id> ids = new list<id>();
    public list<id> accIds = new list<id>();
    public map<Id, list<String>> mapOppToStatus;
    public Map<Id, opportunity> closedOneOpps;
    
    
    private static map<Id, list<String>> mapOppToStatusStatic;
    
    private static void setImportStatusMessageStatic(ID oppID, String msg)
    {
        list<String> messages = mapOppToStatusStatic.get(oppID);
        if (messages == null)
            messages = new list<String>();
            
        messages.add(msg);
        mapOppToStatusStatic.put(oppID, messages);
    }    
    
    public static void validateDataSheet(String masterDataSheetName)
    {
        allActiveUsers = new map<ID, User>([select Id from User where IsActive = true]);
        
        mapOppToStatusStatic = new map<Id, list<String>>();
         
        Document doc = [select body from Document where Name = :masterDataSheetName];
         
        list<String> masterSheetRecords = doc.body.toString().split('\r\n');
         
        list<String> headerFields = masterSheetRecords[0].split(',');
         
        set<ID> oppIds = new set<ID>();
        set<ID> oppIdsToBeExcluded = new set<ID>();
         
        for (integer i = 1; i < masterSheetRecords.size(); i++) 
        {
            String rec = masterSheetRecords[i];
            System.debug('IGOR +++++++++++++++++ ' + rec);
            list<String> recFields = rec.split(',');
             
            if (String.isEmpty(recFields[1]) || !(recFields[1] instanceof ID))
            {
                setImportStatusMessageStatic('Row ' + String.valueOf(i + 1), 'Empty or invalid opportunity id for the data row. Data import process will reject this opportunity.');
                continue;
            }
            
            string strOppId = recFields[1];
            
            if (oppIds.contains(ID.valueOf(strOppId)))
                setImportStatusMessageStatic(recFields[1], 'Row with opportunity id ' + recFields[1] + ' is duplicated. Please remove the duplicate from data sheet.');           
            
            oppIds.add(recFields[1].trim());   
            
            if (recFields[0] != 'YES' && recFields[0] != 'Yes')
            {
                setImportStatusMessageStatic(strOppId, 'Not identified as a candidate for data import. Data import process will reject this opportunity.');
                oppIdsToBeExcluded.add(strOppId);
                
                continue;               
            }
            
            if (recFields[2] != 'YES' && recFields[2] != 'Yes')
            {
                setImportStatusMessageStatic(strOppId, 'Campaign is not live. Data import process will reject this opportunity.');
                oppIdsToBeExcluded.add(strOppId);
                
                continue;               
            }            
           
            isValidUser(recFields[3], strOppId, oppIdsToBeExcluded); 
            isValidDate(recFields[4], strOppId);
            isValidDate(recFields[5], strOppId);
            isValidDate(recFields[6], strOppId);
            isValidUser(recFields[8], strOppId, oppIdsToBeExcluded);
            isValidDate(recFields[9], strOppId);
            isValidUser(recFields[11], strOppId, oppIdsToBeExcluded);
            isValidDate(recFields[12], strOppId);
            isValidUser(recFields[13], strOppId, oppIdsToBeExcluded); 
            isValidUser(recFields[14], strOppId, oppIdsToBeExcluded);
            isValidDate(recFields[15], strOppId);
            isValidDate(recFields[16], strOppId); 
            isValidDate(recFields[17], strOppId);
       
         }  
        
        set<ID> oppIdsWithCancelledCO = new set<ID>();
        set<ID> oppIdsWithEndedCO = new set<ID>();
      
        //for (csmso__Sales_Order__c so : [select id, Campaign_End_Date2__c, csmso__Opportunity__c from csmso__Sales_Order__c
        //where csmso__Opportunity__c in: oppIds and Campaign_End_Date2__c <= :system.today()]) {
        //        oppIdsWithEndedCO.add(so.csmso__Opportunity__c);
        //}

        for (Payment__c payment : [select id, order__r.Opportunity__c, Status__c, End_Date__c FROM Payment__c where 
                                    order__r.Opportunity__c in: oppIds and (Status__c = 'Cancelled' or 
                                    End_Date__c <= :system.today())]) {
            oppIdsWithEndedCO.add (payment.order__r.Opportunity__c);
        }
            
        for (ID oppId : oppIdsWithEndedCO)
        {
            setImportStatusMessageStatic(oppId, 'Campaign order for this opportunity has been ended or it has been cancelled. Data import process will reject this opportunity.');
            oppIdsToBeExcluded.add(oppId);
        }
            
        set<ID> oppIdsWithOrchCO = new set<ID>();
        
        for (CSPOFA__Orchestration_Process__c op : [select Order__r.Opportunity__c from CSPOFA__Orchestration_Process__c 
                            where Order__r.Opportunity__c in :oppIds])
            oppIdsWithOrchCO.add(op.Order__r.Opportunity__c);   
            
        for (ID oppId : oppIdsWithOrchCO)   
        {
            setImportStatusMessageStatic(oppId, 'Campaign already went through orchestration process. Data import process will reject this opportunity.');
            oppIdsToBeExcluded.add(oppId);
        }
                
        
        String csvString = 'Opportunity ID,Status\r\n';
        
        for (Id oppId : mapOppToStatusStatic.keySet())
        {
            list<String> msgs = mapOppToStatusStatic.get(oppId);
            
            if (msgs != null)
            {
                for (integer i = 0; i < msgs.size(); i++)
                {
                    if (i == 0)
                        csvString += oppId;
                    else
                        csvString += '-';
                        
                    csvString += (',' + msgs[i] + '\r\n');
                }
            }
            
        }
        
        delete [select Id from Document where Name like 'DataSheetValidationReport%' or Name like 'OpportunitiesToBeExcluded%'];
        
        Document docValid = new Document();
            
        docValid.FolderId = [select Id from Folder where Name = 'Public Folder'].Id;
        docValid.Name = 'DataSheetValidationReport ProductionRun.csv';
        docValid.ContentType = 'text/csv';
        docValid.Body = Blob.valueOf(csvString);
            
        insert docValid;  
        
        string OpportunitiesToBeExcluded = '';
        
        for (ID oppId : oppIdsToBeExcluded)
            OpportunitiesToBeExcluded += oppId + '\r\n';
        
        if (OpportunitiesToBeExcluded != '')
        {
            Document docOppsExc = new Document();
                
            docOppsExc.FolderId = [select Id from Folder where Name = 'Public Folder'].Id;
            docOppsExc.Name = 'OpportunitiesToBeExcluded ProductionRun.csv';
            docOppsExc.ContentType = 'text/csv';
            docOppsExc.Body = Blob.valueOf(OpportunitiesToBeExcluded);
                
            insert docOppsExc;   
        }        
    }
    
    private static boolean isValidDate(String strDate, string strOppId)
    {
        try
        {
            if (String.isEmpty(strDate))
            {
                setImportStatusMessageStatic(strOppId, 'One of the date values is empty. We can not not proceed with orchestration process unless it will be fixed.');
                return false;
            }
                
            strDate = strDate.trim();
                
            Date dt = (Date)JSON.deserialize('"' + strDate + '"', Date.class);
            
            if (dt <= system.today())
            {
                setImportStatusMessageStatic(strOppId,  strDate + ' is today or past day. We can not not proceed with orchestration process unless it will be fixed.');
                return false;
            }
        }
        catch(Exception ex)
        {
            setImportStatusMessageStatic(strOppId,  'Date ' + strDate + ' is invalid. We can not not proceed with orchestration process unless it will be fixed.');
            return false;
        }
        
        return true;
    }
    
    private static boolean isValidUser(string strUser, string strOppId, set<ID> oppIdsToBeExcluded)
    {
        if (String.isEmpty(strUser))
        {
            setImportStatusMessageStatic(strOppId, 'One of the user values is empty. We can not not proceed with orchestration process unless it will be fixed.');
            oppIdsToBeExcluded.add(ID.valueOf(strOppId));
            
            return false;  
        }
            
        if (strUser instanceof ID && allActiveUsers.containsKey(ID.valueOf(strUser)))    
            return true;
        else
        {
            if (!allActiveUsers.containsKey(ID.valueOf(strUser)))
                setImportStatusMessageStatic(strOppId, 'User ' + strUser + ' is an inavlid or inactive user. We can not not proceed with orchestration process unless it will be fixed.');
            else
                setImportStatusMessageStatic(strOppId, strUser + ' is an invalid user id. We can not not proceed with orchestration process unless it will be fixed.');
            
            oppIdsToBeExcluded.add(ID.valueOf(strOppId)); 
            return false;
        }
    }
    
    global CS_DataCreation(String masterDataSheetName)
    {

    }

    global CS_DataCreation(List<Id> oppIds) {
        
        mapOppToStatus = new map<Id, list<String>>();

        ids.addAll(oppIds);
        query = 'select id, accountid, OwnerId, Industry_Code__c, contact__c,Amount, Owner_Division__c,Account.Name from opportunity where id in: ids';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope) {

        List<opportunity> oppList = (List<opportunity>)scope;

        closedOneOpps = new Map<Id, opportunity> (oppList);
        
        GetOrders (closedOneOpps);
    }
    
    global void finish(Database.BatchableContext BC) {
        
        String csvString = 'Opportunity ID,Status\r\n';
        
        for (Id oppId : mapOppToStatus.keySet())
        {
            list<String> msgs = mapOppToStatus.get(oppId);
            
            if (msgs == null || msgs.isEmpty())
                csvString += oppId +',Record not existing';
            else
            {
                for (integer i = 0; i < msgs.size(); i++)
                {
                    if (i == 0)
                        csvString += oppId;
                    else
                        csvString += '-';
                        
                    csvString += (',' + msgs[i] + '\r\n');
                }
            }
            
        }
            
        Document doc = new Document();
            
        doc.FolderId = [select Id from Folder where Name = 'Public Folder'].Id;
        doc.Name = 'DataImportStatus ProductionRun.csv';
        doc.ContentType = 'text/csv';
        doc.Body = Blob.valueOf(csvString);
            
        insert doc; 
        
        //for (id accId : accIds)
        //Database.executeBatch(new CS_BatchTierCalculation(accIds), 1);   
        
    }
    
    private void setImportStatusMessage(ID oppID, String msg)
    {
        list<String> messages = mapOppToStatus.get(oppID);
        if (messages == null)
            messages = new list<String>();
            
        messages.add(msg);
        mapOppToStatus.put(oppID, messages);
    }
    
    private void setHasApprovedSOFlag(set<ID> oppportunitiesWithSO, Map<Id, opportunity> closedOneOpps)
    {
        list<Opportunity> oppsWithSO = new list<Opportunity>();
        
        for (ID oppID : oppportunitiesWithSO)
        {
            Opportunity opp = closedOneOpps.get(oppID);
            opp.Has_an_Approved_SO__c = true;
    
            oppsWithSO.add(opp);
        }
        
        update oppsWithSO;
    }
    

    void GetOrders (Map<Id, opportunity> closedOneOpps) {
        
        
        Map<Id, Order__c> newOrderForOpp = new Map<Id, Order__c>();
        
        List<Order__c> existingOrders = [SELECT Id, Billing_Id__c, CPQ_Payment_Needed__c, Opportunity__c, Account__c, Account__r.Name FROM Order__c WHERE Opportunity__c IN: closedOneOpps.keySet()];
        Map<Id, id> orderExistForOpp = new Map<Id, id>();
        Map<Id, csmso__Sales_Order__c> salesOrderWithOpp = new Map<Id, csmso__Sales_Order__c>();
        
        set<ID> ordersWithOutBillingId = new set<ID>();

        if (!existingOrders.isEmpty()) {
             for (Order__c order : existingOrders) {
                string temp = String.valueOf(order.Opportunity__c).substring(0, 15);
                orderExistForOpp.put (id.valueOf(temp), order.id);
                accIds.add(order.Account__c);
                
                if (!order.CPQ_Payment_Needed__c && order.Billing_Id__c == null)
                    ordersWithOutBillingId.add(order.Id);
            }
        }

        List<csmso__Sales_Order__c> salesOrders = [SELECT Id, Campaign_Name__c, Campaign_Start_Date__c, Recurring_Price__c, csmso__Opportunity__c, csmso__Opportunity__r.Account.Name,
                                                csmso__Opportunity__r.account.tier__c, Campaign_End_Date__c, campaign_end_date2__c FROM csmso__Sales_Order__c
                                                WHERE csmso__Opportunity__c IN: closedOneOpps.keySet() AND (csmso__Status__c = 'Manually Approved' 
                                                OR csmso__Status__c = 'Externally Approved')];

        for (csmso__Sales_Order__c so : salesOrders) {
            salesOrderWithOpp.put(so.csmso__Opportunity__c, so);
        }
            
        setHasApprovedSOFlag(salesOrderWithOpp.keySet(), closedOneOpps);

        for (Id oppId : closedOneOpps.keySet()) {
            
            try {
            if (!salesOrderWithOpp.containsKey(oppId)) 
            {
                setImportStatusMessage(oppId, 'Manually or externally approved Sales order not existing for opportunity');
                continue;
            }
//added new field Industry_CodeCO__c while creation of the campaign order */
                Boolean evergreen = (salesOrderWithOpp.get(oppId).Campaign_End_Date2__c==null ? true : false);
                Order__c orderRec = new Order__c (id=orderExistForOpp.get(oppId)==null ? null : orderExistForOpp.get(oppId),
                                                  Opportunity__c = oppId,
                                                  Account__c = closedOneOpps.get(oppId).AccountId,
                                                  Account_Name__c = closedOneOpps.get(oppId).Account.Name,
                                                  Status__c = 'Campaign Live',
                                                  Sales_Order__c = salesOrderWithOpp.get(oppId).Id,
                                                  Proposed_Start_Date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                  Actual_start_date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                  Sales_Start_Date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                  End_Date__c = salesOrderWithOpp.get(oppId).Campaign_End_Date2__c,
                                                  Sales_Representative__c = closedOneOpps.get(oppId).OwnerId,
                                                  State__c = closedOneOpps.get(oppId).Owner_Division__c,
                                                  Customer_Contact__c = closedOneOpps.get(oppId).Contact__c,
                                                  Total_Amount_GST_Excl__c = closedOneOpps.get(oppId).Amount,
                                                  Industry_Code__c = closedOneOpps.get(oppId).Industry_Code__c,
                                                  Industry_CodeCO__c = closedOneOpps.get(oppId).Industry_Code__c,
                                                  Evergreen__c = evergreen,
                                                  Progress_Percentage__c = 100,
                                                  Overall_Status__c = 'Active'
                                                 );

                if (salesOrderWithOpp.get(oppId).csmso__Opportunity__r.account.tier__c != null) {
                    orderRec.Customer_tier__c = salesOrderWithOpp.get(oppId).csmso__Opportunity__r.account.tier__c;
                }
                else if (orderRec.Customer_tier__c == null || orderRec.Customer_tier__c == '') {
                    List<Customer_Tier_Ranges__c> tierRanges = Customer_Tier_Ranges__c.getall().values();
                    Decimal price = salesOrderWithOpp.get(oppId).Recurring_Price__c;
                    for (Customer_Tier_Ranges__c tierRange: tierRanges)
                    {
                        if ((price != null) && (price >= tierRange.Lowerbound__c) && (price <= tierRange.Upperbound__c)) {
                            orderRec.Customer_tier__c = tierRange.Name;
                        }
                    }
                }

                if (orderRec.Id == null) {
                    orderRec.Billing_Id__c = 'Data Import Billing Id';
                }
                else if (orderRec.Id != null && ordersWithOutBillingId.contains(orderRec.Id)) {
                    orderRec.CPQ_Payment_Needed__c = true;
                }
                // SHABU: Assign Duration Type ///////////////////////////////////////////////////////////
                orderRec.Duration_Type__c = 'Not Standard';
                
                if (orderRec.End_Date__c != null)
                {
                    Integer monthDiff = orderRec.Proposed_Start_Date__c.monthsBetween(orderRec.End_Date__c);
                    Date dateAfterMonths = orderRec.Proposed_Start_Date__c.addMonths(monthDiff);
                    
                    if (dateAfterMonths == orderRec.End_Date__c)
                        orderRec.Duration_Type__c = 'Standard';
                }
                else
                    orderRec.Duration_Type__c = 'Standard';
                ////////////////////////////////////////////////////////////////////////////////////////////
                if (orchUser != null) {
                    orderRec.Integration_User__c = orchUser.Id;
                    orderRec.OwnerId = orchUser.Id;
                }
                
                newOrderForOpp.put (oppId, orderRec);
            }
            catch (Exception ex)
            {
                setImportStatusMessage(oppId, 'Failed to create/update Campaign Order [' + ex.getMessage().replace(',', ';').replace('\n',';') + ' ' + ex.getStackTraceString().replace(',', ';').replace('\n',';') +']');
                return;
            }
            
        }
        try{
        if (!newOrderForOpp.values().isEmpty()) {
            list<id> ordersWithPOs = new list<id>();

            for (Order__c ord : newOrderForOpp.values()) {
                if (ord.id != null) {
                    ordersWithPOs.add(ord.id);    
                    system.debug('**ivana order id:' + ord);

                }
            }

            list<Product_Order__c> existingProdOrders = [select id from Product_Order__c where Order__c in: ordersWithPOs];
            system.debug('**ivana size '+ existingProdOrders.size() +' product orders:' + existingProdOrders );
            delete existingProdOrders;
            
            upsert newOrderForOpp.values();
            List<Exception_Record__c> exceptionList = new List<Exception_Record__c>();

            for (Order__c ord : newOrderForOpp.values()) {
                if (ord.Customer_tier__c == null || ord.Customer_tier__c == '') { 
                    Exception_Record__c er = new Exception_Record__c();
                    er.Failure_Reason__c = 'Missing customer tier on id: '+ord.id;

                    exceptionList.add(er);
                }
            }

            if (!exceptionList.isEmpty()) {
                insert exceptionList;
            }
            
            for (Id oppId : newOrderForOpp.keySet())
                setImportStatusMessage(oppId, 'Successfully created/updated Campaign Order');
           
            CreateProductOrders (newOrderForOpp, salesOrderWithOpp); 
        } }catch(Exception ex)
        {
            ExLog.log(ex, 'config', newOrderForOpp.values(), 'Could not create campaign orders');
             
             for (Id oppId : newOrderForOpp.keySet())
                setImportStatusMessage(oppId, 'Failed to create/update Campaign Order [' + ex.getMessage().replace(',', ';').replace('\n',';') + ' ' + ex.getStackTraceString().replace(',', ';').replace('\n',';') +']');
        }
        
    }

    public void CreateProductOrders (Map<Id, Order__c> ordersForOpps, Map<Id, csmso__Sales_Order__c> salesOrderWithOppPar)
    {
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
        List<Product_Order__c> productOrders = new List<Product_Order__c>();
        // SHABU: Added attributes Price and Total Cost in subquery for attributes
        List<cscfga__Product_Configuration__c> productConfigList = [SELECT (select Name,cscfga__value__c from cscfga__attributes__r where name in ('Price','Total Cost','Product')), Id, Product_ID__c, 
        cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c, cscfga__Description__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c FROM cscfga__Product_Configuration__c WHERE 
            cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c IN: ordersForOpps.keySet() AND cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c in ('Manually Approved','Externally Approved')];
        Map<Id, List<cscfga__Product_Configuration__c>> oppWithPCs = new Map <Id, List<cscfga__Product_Configuration__c>>();
        List<Id> productIds = new List<Id>();
        Map<Id, Boolean> OppIdCallTracking = new Map<Id, Boolean>();
        
        List<cscfga__Product_Configuration__c> productConfigListUpd = new List<cscfga__Product_Configuration__c>();

        if (!productConfigList.isEmpty()) {
            for (cscfga__Product_Configuration__c pc : productConfigList) {
                
                if (pc.Product_ID__c == null)
                {
                    for (cscfga__Attribute__c att : pc.cscfga__attributes__r)
                    {
                        if (att.Name == 'Product')
                        {
                            pc.Product_ID__c = att.cscfga__value__c;
                            productConfigListUpd.add(pc);
                            
                            break;
                        }
                    } 
                }    
                          
                List<cscfga__Product_Configuration__c> PCs = oppWithPCs.get(pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c);
                if (PCs == null)
                    PCs = new List<cscfga__Product_Configuration__c>();
                PCs.add(pc);

                oppWithPCs.put (pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c, PCs);
                system.debug(pc);
                productIds.add (pc.Product_ID__c);
                /*
                for (cscfga__attribute__c att : pc.cscfga__attributes__r) {
                    system.debug(att);
                    id temp = id.valueOf (att.cscfga__value__c);
                    system.debug(temp);
                    productIds.add (temp);
                    system.debug(productIds);
                }*/

                OppIdCallTracking.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__c, pc.cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c);
               
            }
            
            if (!productConfigListUpd.isEmpty())
                update productConfigListUpd;
                
            system.debug(productIds);
             
        Map<Id, csmso__Product_Node__c> products = new Map<Id, csmso__Product_Node__c>([Select id, Product_Line__c, Product_Type__c from csmso__Product_Node__c where 
            ID IN: productIds]);
            system.debug(loggingLevel.ERROR, '####### productIds ' + productIds);
            system.debug(loggingLevel.ERROR, '####### Original products ' + JSON.serializePretty(products));
        Map<Id, csmso__Sales_Order__c> salesOrderWithOpp;
        if (salesOrderWithOppPar == null || salesOrderWithOppPar.isEmpty()) {
            salesOrderWithOpp = new Map<Id, csmso__Sales_Order__c>(); 
                    system.debug(ordersForOpps);


            List<csmso__Sales_Order__c> salesOrders = [SELECT Id, Campaign_Name__c, Campaign_Start_Date__c, csmso__Opportunity__c, csmso__Opportunity__r.Account.Name,campaign_end_date2__c, Campaign_End_Date__c FROM csmso__Sales_Order__c
                                                    WHERE csmso__Opportunity__c IN: ordersForOpps.keySet() AND csmso__Status__c in ('Manually Approved','Externally Approved')];

            for (csmso__Sales_Order__c so : salesOrders)
                salesOrderWithOpp.put(so.csmso__Opportunity__c, so);
        }
        else {
            salesOrderWithOpp = salesOrderWithOppPar;
        }
        
        // SHABU ///////////////////////////////////////////////////////////////////////////////////////////////////////////
        // If there will be any product order related to any product configuration of an order, no new product order
        // will be created. Instead, the existing product order must be updated. The following code will fetch the 
        // id of an existing product order related to any product configuration for an order
        map<ID, map<String, ID>> mapOrderToPCToPOId = new  map<ID, map<String, ID>>();
        map<ID, ID> mapOrderToCallTracking = new map<ID, ID>();
/*        for (Product_Order__c exstPO : [select Id, Order__c, PC_Id__c, RecordType.Name 
                                        from Product_Order__c 
                                        where Order__c in :new Map<ID, Order__c>(ordersForOpps.values()).keySet()])
        {
            if (exstPO.PC_Id__c != null)
            {
                map<String, ID> mapPCToPOId = mapOrderToPCToPOId.get(exstPO.Order__c);
                if (mapPCToPOId == null)
                    mapPCToPOId = new map<String, ID>();
                    
                string truncPCID = exstPO.PC_Id__c.left(15);
                    
                mapPCToPOId.put(truncPCID, exstPO.Id);
                mapOrderToPCToPOId.put(exstPO.Order__c, mapPCToPOId); 
            }
            else if (exstPO.RecordType.Name == 'Call Tracking')
                mapOrderToCallTracking.put(exstPO.Order__c, exstPO.Id);
        }
        
       */
         
        /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        
        // SHABU: Fetch the record type and relared tier ranges from custom settings
        map<String, list<Product_Order_Tier_Ranges__c>> mapPORecTypeToTierRanges =  getProductTierRanges();
        
        set<ID> allCWOppIds = new set<ID>();
        allCWOppIds.addAll(closedOneOpps.keySet());
        
        set<ID> allOppWithPC = new set<ID>();
        allOppWithPC.addAll(oppWithPCs.keySet());
        
        allCWOppIds.removeAll(allOppWithPC);
        
        for (Id oppId : allCWOppIds)
            setImportStatusMessage(oppId, 'Unable to create Product Order as there is no related product configuration');
        
        set<ID> oppIds = new set<ID>();

        for (Id oppId : oppWithPCs.keySet()) {
            
            try {
            Set<String> allProductIdentifiers = new Set<String>();
            system.debug(salesOrderWithOpp);
            system.debug(oppWithPCs);
            
            for (cscfga__Product_Configuration__c pc : oppWithPCs.get(oppId)) {
                if (!products.containsKey(pc.Product_ID__c))
                {
                    setImportStatusMessage(oppId, 'Unable to create Product Order as the product ' + pc.Product_ID__c + ' is not existing');
                    continue;
                }
                
                oppIds.add(oppId);
                    
                // SHABU /////////////////////////////////////////////////////////////
                // Attribute map
                map<String, String> attributeMap = new map<String, String>();
                for (cscfga__Attribute__c att : pc.cscfga__attributes__r)
                    attributeMap.put(att.Name, att.cscfga__Value__c);
                //////////////////////////////////////////////////////////////////////
                system.debug(loggingLevel.ERROR, '####### pc.Product_ID__c ' + pc.Product_ID__c);  
                String recordTypeLabel = GetRecordTypeIdentifierForProduct (products.get(pc.Product_ID__c));
                allProductIdentifiers.add(recordTypeLabel);
                Id recordType = UtilMethods.getRecordTypeId('Product_Order__c.'+recordTypeLabel);
                               
                // SHABU: Store order id in a variable
                ID orderId = ordersForOpps.get(oppId).Id;
                string truncPCID = string.ValueOf(pc.Id).left(15);
                
                Product_Order__c newProduct;
                
                if (recordType != null)
                    newProduct = new Product_Order__c (   Order__c = orderId,//ordersForOpps.get(oppId).Id, 
                                                            PC_Id__c = String.valueOf(pc.Id),
                                                            //Name = pc.cscfga__Description__c,
                                                            Status__c = 'Live',
                                                            Account_Name__c = salesOrderWithOpp.get(oppId).csmso__Opportunity__r.Account.Name,
                                                            Product_Order_Start_Date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                            Product_Order_End_Date__c = salesOrderWithOpp.get(oppId).Campaign_End_Date2__c,
                                                            Product_Node__c = pc.Product_ID__c,
                                                            RecordTypeId = recordType,
                                                            Impressions_Factor__c = 1,
                                                            Progress_Percentage__c = 100);  
                else
                    newProduct = new Product_Order__c (   Order__c = orderId,//rdersForOpps.get(oppId).Id, 
                                                            PC_Id__c = String.valueOf(pc.Id),
                                                            //Name = pc.cscfga__Description__c,
                                                            Status__c = 'Live',
                                                            Product_Node__c = pc.Product_ID__c,
                                                            Impressions_Factor__c = 1,
                                                            Progress_Percentage__c = 100);  
                
                // SHABU ////////////////////////////////////////////////////////////////////////////////////////////////////  
                // Assign Id for existing order id     
                // Assign Retail rate
                 newProduct.Id = (mapOrderToPCToPOId.containsKey(orderId) && mapOrderToPCToPOId.get(orderId).containsKey(truncPCID)
                                                            ? mapOrderToPCToPOId.get(orderId).get(truncPCID)
                                                            : null);
                
                newProduct.Retail_Rate__c = !attributeMap.containsKey('Price') || attributeMap.get('Price') == null 
                                                ? 0 
                                                : Decimal.valueOf(attributeMap.get('Price'));
                
                // Assign product tier, only in case of existing po. For new po, trigger will
                // handle this
                if (newProduct.Id != null)                                                                      
                    setTier(newProduct, mapPORecTypeToTierRanges, newProduct.RecordTypeId);
                
                // For Product Order Social, assign social recurring status and wholesale rate
                if (recordTypeLabel == 'Social')
                {
                    newProduct.Social_Recurring_Status__c = 'Draft';
                    newProduct.Wholesale_Rate__c = !attributeMap.containsKey('Total Cost') || attributeMap.get('Total Cost') == null 
                                                ? 0 
                                                : Decimal.valueOf(attributeMap.get('Total Cost'));
                }
                /////////////////////////////////////////////////////////////////////////////////////////////////////////////
                                                            
                if (recordTypeLabel == 'Call Tracking' || recordTypeLabel == 'Landing Pages')
                    newProduct.Assigned_Fulfilment_Owner__c = ordersForOpps.get(oppId).Assigned_Campaign_Manager__c;

                productOrders.add (newProduct);
                setImportStatusMessage(oppId, 'Successfully set data to create/update Product Order for product ' + pc.Product_ID__c);
                
            }
 
            // If Call Tracking checked on Sales Order, treat it like a normal product
            if (!allProductIdentifiers.contains('Call Tracking') && OppIdCallTracking.get(oppId)) {
                String recordTypeLabel = 'Call Tracking';
                Id recordType = UtilMethods.getRecordTypeId('Product_Order__c.'+recordTypeLabel);
                Product_Order__c newProduct = new Product_Order__c (   Order__c = ordersForOpps.get(oppId).Id, 
                                                            //Name = 'Call Tracking',
                                                            Status__c = 'Live',
                                                            Product_Order_Start_Date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                            Product_Order_End_Date__c = salesOrderWithOpp.get(oppId).Campaign_End_Date2__c,
                                                            RecordTypeId = recordType,
                                                            Impressions_Factor__c = 1,
                                                            Progress_Percentage__c = 100,
                                                            Assigned_Fulfilment_Owner__c = ordersForOpps.get(oppId).Assigned_Campaign_Manager__c); 
                
                newProduct.Id = mapOrderToCallTracking.get(newProduct.Order__c);
                
                productOrders.add (newProduct); 
                 
                setImportStatusMessage(oppId, 'Successfully set data to create/update a Call Tracking Product Order');
            }
            
            }
            catch(Exception ex)
            {
                setImportStatusMessage(oppId, 'Failed to create/update product orders [' + ex.getMessage().replace(',', ';').replace('\n',';') + ' ' + ex.getStackTraceString().replace(',', ';').replace('\n',';') +']');
                return;
            }

        }
        
        
        try {
            //insert productOrders; 
            upsert productOrders;
            
            for (Id oppId : oppIds)
                setImportStatusMessage(oppId, 'Successfully created/updated valid product orders');
        }
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', productOrders, 'Could not create product orders');
            
             for (Id oppId : oppIds)
                setImportStatusMessage(oppId, 'Failed to create/update valid product orders [' + ex.getMessage().replace(',', ';').replace('\n',';') + ' ' + ex.getStackTraceString().replace(',', ';').replace('\n',';') +']');
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
    
    // SHABU ////////////////////////////////////////////////////////////
    // Method to fetch the tier ranges for the required record types
    private map<String, list<Product_Order_Tier_Ranges__c>> getProductTierRanges()
    {
        set<String> recordTypeNames = new set<String>();
        
        for (Product_Order_Tier_Ranges__c tierRange : Product_Order_Tier_Ranges__c.getall().values())
        {
            if (tierRange.Record_Type_Name__c == null) continue;
            recordTypeNames.add(tierRange.Record_Type_Name__c);
        }
        
        map<String, ID> mapRecNameToId = new map<String, ID>();
        for (RecordType recType : [select Id,Name from RecordType where Name in :recordTypeNames])
            mapRecNameToId.put(recType.Name, recType.Id);
            
        map<String, list<Product_Order_Tier_Ranges__c>> mapTierRanges = new map<String, list<Product_Order_Tier_Ranges__c>>();
        
        for (Product_Order_Tier_Ranges__c tierRange : Product_Order_Tier_Ranges__c.getall().values())
        {
            String recTypeId = tierRange.Record_Type_Name__c == null ? 'OTHER'
                                                                    : mapRecNameToId.get(tierRange.Record_Type_Name__c);
                                        
            list<Product_Order_Tier_Ranges__c> tierRanges = mapTierRanges.get(recTypeId);
            
            if (tierRanges == null)
                tierRanges = new list<Product_Order_Tier_Ranges__c>();
                
            tierRanges.add(tierRange);
            mapTierRanges.put(recTypeId, tierRanges);
        }
        
        return mapTierRanges;
    }
    
    // SHABU ////////////////////////////////////////////////////////////////
    // Method to set the product tier of specofied product order
    private void setTier(Product_Order__c po, map<String, list<Product_Order_Tier_Ranges__c>> mapTierRanges, String recordTypeID)
    {
        if (recordTypeID == null || !mapTierRanges.containsKey(recordTypeID))
            recordTypeID = 'OTHER';
        
        for (Product_Order_Tier_Ranges__c tierRange: mapTierRanges.get(recordTypeID))
        {
            if ((po.Retail_Rate__c != 0) && (po.Retail_Rate__c >= tierRange.Lowerbound__c) && (po.Retail_Rate__c <= tierRange.Upperbound__c))
            {
                po.Product_Order_Tier__c = tierRange.Tier_level__c;
                return;
            }
         
         }
    }

}