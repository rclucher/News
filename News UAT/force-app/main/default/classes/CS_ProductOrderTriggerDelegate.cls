public with sharing class CS_ProductOrderTriggerDelegate extends CS_TriggerHandler.DelegateBase 
{
    static String SYSTEM_DURATION_COMMENT = 'System calculated.';
    public static  boolean firstRun = true;
    Map<Id, String> newInProgressPO;
    Map<Id, String> newInProgressPOType;
    CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
    Map<Id, String> rtIdandName = new Map<Id, String>();
    Map<Id, Id> prodOrdersToTriggerOrch;
    Map<Id, Id> prodOrdersReadyForLive;
    Map<Id, Id> prodOrdersStarted;
    Set<Id> newProductOrderIds;
    Map<Id, Map<Date, Date>> poChangedDates;
    list<id> setNextReviewDates;
    String dayOfRecurrency = System.Label.Social_Day_of_KickOff; 
    List<Id> ordersToTerminateProcesses;
    
    set<ID> changedCallTrackingIDs; // http://dashboard.news.com.au/browse/NXRIII-156, CS
    set<ID> changedGAUAIDs; // http://dashboard.news.com.au/browse/NXRIII-330, News
    map<ID, list<Product_Order__c>> mapOrderIdToPOs; // http://dashboard.news.com.au/browse/NXRIII-109, CS
    set<ID> fulfillmentStartedPOOrderIds;
    Set<Id> revisedPOIds;   // kw: Set of product ids for product orders revised after retraction
    Set<Id> amountRevisedPOIds;   // kw: Set of product ids for product orders revised after retraction
    
    public override void prepareBefore() 
    {
        mapOrderIdToPOs = new   map<ID, list<Product_Order__c>>(); //http://dashboard.news.com.au/browse/NXRIII-109, CS
    }

    public override void prepareAfter() 
    {
        newInProgressPO = new Map<Id, String>();
        newInProgressPOType = new Map<Id, String>();
        prodOrdersToTriggerOrch = new Map<Id, Id>();
        newProductOrderIds = new Set<Id>();
        prodOrdersReadyForLive = new Map<Id, Id>();
        prodOrdersStarted = new Map<Id, Id>();
        poChangedDates = new Map<Id, Map<Date, Date>>();
        MapProductOrderRTIdwithName();
        setNextReviewDates = new List<id>();
        changedCallTrackingIDs = new set<ID>(); // http://dashboard.news.com.au/browse/NXRIII-156, CS
        changedGAUAIDs = new set<ID>();// http://dashboard.news.com.au/browse/NXRIII-330, News
        fulfillmentStartedPOOrderIds = new set<ID>();
        ordersToTerminateProcesses = new List<Id>();
        revisedPOIds = new Set<Id>();   // kw: added for order amendment 
        amountRevisedPOIds = new Set<Id>() ;
    }

    public override void beforeInsert(sObject o) 
    {
        Product_Order__c po = (Product_Order__c)o;
        
        // http://dashboard.news.com.au/browse/NXRIII-109, CS //////
        list<Product_Order__c> pos = mapOrderIdToPOs.get(po.Order__c);
        if (pos == null)
            pos = new list<Product_Order__c>();
            
        pos.add(po);
            
        mapOrderIdToPOs.put(po.Order__c, pos); 
        
        system.debug('*****Product_Needs_To_Be_Reviewed__c '+po.Product_Needs_To_Be_Reviewed__c);

        if(po.Fulfillment_Type__c=='Display'|| po.Fulfillment_Type__c=='Social'){
            po.Product_Needs_To_Be_Reviewed__c=true;
        }
        ////////////////////////////////////////////////////////
    }

    public override void beforeUpdate(sObject old, sObject o) 
    {
        Product_Order__c newPO = (Product_Order__c) o;
        Product_Order__c oldPO = (Product_Order__c) old;  
        Date dt = Date.today();
        system.debug(newPO.Next_Social_Go_Live__c);
        system.debug(oldPO.Next_Social_Go_Live__c);
        system.debug(newPO.Next_Social_Go_Live__c != null && newPO.Next_Social_Go_Live__c != oldPO.Next_Social_Go_Live__c);
        if (newPO.Next_Social_Go_Live__c != null && newPO.Next_Social_Go_Live__c != oldPO.Next_Social_Go_Live__c ) {
            date tempDate = newPO.Next_Social_Go_Live__c.addMonths(-2);
            Integer day = Integer.valueOf(dayOfRecurrency);
            Integer month = tempDate.month();
            Integer year = tempDate.year();
            system.debug(o);
            o.put('Next_Social_Kick_Off__c', Date.newInstance(year, month, day));
        }
        
         if (newPO.Next_Social_Kick_Off__c != null && newPO.Next_Social_Kick_Off__c != oldPO.Next_Social_Kick_Off__c)
            newPO.One_Month_Before_Social_Kick_Off__c = newPO.Next_Social_Kick_Off__c.addMonths(-1);
        
        if (oldPO.status__c != null && !oldPO.status__c.contains('Pending') && newPO.status__c == 'Paused')
            newPO.Previous_Product_Order_Status__c = oldPO.status__c;
       
        if(newPO.Product_Order_Start_Date__c != null)
           dt = newPO.Product_Order_Start_Date__c;
        if (oldPO.status__c != 'Live' && newPO.status__c == 'Live')
             newPO.Next_Business_Date__c =  getNextBizDate(dt,System.Label.Number_Days_NextBizDate);  
        
        if(newPO.isNextBizDateRecalLanding__c!=null && newPO.isNextBizDateRecalLanding__c==true)
        {
            newPO.Next_Business_Date_Landing__c =  getNextBizDate(Date.today(),System.Label.Landing_Days_NextBizDate); 
            newPO.isNextBizDateRecalLanding__c = false;
        }    
        
        if (oldPO.Is_Creative_Required__c != 'No' && newPO.Is_Creative_Required__c == 'No')
            newPO.Is_New_Creative_Button_Pushed__c = 'Clicked';
    }

    public override void beforeDelete(sObject o) 
    {
        
    }

    public override void afterInsert(sObject o) 
    {
        Product_Order__c newPO = (Product_Order__c)o;
        if (newPO.PC_Id__c != null)
            newProductOrderIds.add(newPO.Id);
        if (newPO.Product_Order_Start_Date__c != null)
            poChangedDates.put (newPO.Id, new Map<Date, Date>{newPO.Product_Order_Start_Date__c => newPO.Product_Order_End_Date__c});
        
        // http://dashboard.news.com.au/browse/NXRIII-330, News
        if (    rtIdandName.get(newPO.RecordTypeId) == 'Call Tracking' && 
                newPO.GA_UA_ID__c != null)
            changedGAUAIDs.add(newPO.Id);
    
    }

    public override void afterUpdate(sObject old, sObject o)
    {
        Product_Order__c newPO = (Product_Order__c)o;
        Product_Order__c oldPO = (Product_Order__c)old;

        //if (Trigger.size > 0) {
        //    CSPOFA.Events.emit('update', Trigger.newMap.keySet());
        //}

        if (newPO.Status__c != 'Cancelled' && (newPO.status__c != null && newPO.status__c != oldPO.Status__c && newPO.Status__c == 'Live')
            || (newPO.Current_Optimisation_Date__c != null && newPO.Current_Optimisation_Date__c != oldPO.Current_Optimisation_Date__c))
            setNextReviewDates.add(newPO.id);

        if (newPO.Status__c != null && newPO.Status__c.equals('Fulfilment Started')
            && newPO.Status__c != oldPO.Status__c && oldPO.Status__c != 'Fulfilment Started' 
            && (oldPO.Status__c==null || oldPO.Status__c.equals('Draft') )) {
            string rtName = rtIdandName.get(newPO.RecordTypeId);
            newInProgressPO.put (newPO.Id,rtName);
            newInProgressPOType.put (newPO.Id, newPO.Type__c);
            prodOrdersStarted.put (newPO.Id, newPO.Order__c);
            fulfillmentStartedPOOrderIds.add(newPO.Order__c);
        }

        if (newPO.Status__c != null && newPO.Status__c.equals('Ready to go live') && newPO.Status__c != oldPO.Status__c)
            prodOrdersReadyForLive.put(newPO.Id, newPO.Order__c);

        if (newPO.Status__c != null && newPO.Status__c.contains('Pending') && newPO.Status__c != oldPO.Status__c)
            prodOrdersToTriggerOrch.put(newPo.Id, newPO.Order__c);
        //NX-1490 OA Sets PO to cancelled and needs to set the End Date
        if ( !(newPO.Status__c == 'Cancelled' && newPO.Type__c == 'Delete') &&
                (newPO.Product_Order_Start_Date__c != oldPO.Product_Order_Start_Date__c || newPO.Product_Order_End_Date__c != oldPO.Product_Order_End_Date__c)) {
            poChangedDates.put (newPO.Id, new Map<Date, Date>{newPO.Product_Order_Start_Date__c => newPO.Product_Order_End_Date__c});
        }
    
        system.debug('############ rtIdandName.get(newPO.RecordTypeId) ' + rtIdandName.get(newPO.RecordTypeId));

         // http://dashboard.news.com.au/browse/NXRIII-156, CS
        if (    rtIdandName.get(newPO.RecordTypeId) == 'Call Tracking' && 
                oldPO.Call_Tracking_Number__c != newPO.Call_Tracking_Number__c &&
                newPO.Call_Tracking_Number__c != null)
            changedCallTrackingIDs.add(newPO.Id);
        // http://dashboard.news.com.au/browse/NXRIII-330, News
        if (    rtIdandName.get(newPO.RecordTypeId) == 'Call Tracking' && 
                oldPO.GA_UA_ID__c != newPO.GA_UA_ID__c &&
                newPO.GA_UA_ID__c != null)
            changedGAUAIDs.add(newPO.Id);

        if (newPO.Status__c != null && newPO.Status__c != oldPO.Status__c && newPO.Status__c == 'Campaign Ended')
            ordersToTerminateProcesses.add(newPO.Id);

        if(newPO.Type__c != null && newPO.Type__c != oldPO.Type__c && ( newPO.Type__c == 'Upgrade' || newPO.Type__c == 'Downgrade' ) ){
            revisedPOIds.add(newPO.Id);
        }
        //NX-324-start
        if (newPO.Status__c != oldPO.Status__c)
        {
            CS_NotificationOnEvent.notificationObjectChangeEventWrapper tmpObjectNotification = new CS_NotificationOnEvent.notificationObjectChangeEventWrapper();
            tmpObjectNotification.objectType=CS_NotificationOnEvent.ObjectType.ProductOrder;
            tmpObjectNotification.FieldName='Status__c';
            tmpObjectNotification.FromValue=oldPO.Status__c;
            tmpObjectNotification.ToValue=newPO.Status__c;
            tmpObjectNotification.objectId=newPO.Id;

            CS_NotificationOnEvent.AddObjectChangeEvent(tmpObjectNotification);
        }
        //NX-324-end
     }

    public override void afterDelete(sObject o) 
    {
    }

    public override void afterUndelete(sObject o) 
    {
    }

    public override void finish() 
    {
        if (trigger.isAfter) {

            if (!setNextReviewDates.isEmpty())
                PopulateOptimisationReviewDates();

            if (!newInProgressPO.isEmpty() && firstRun)
                CreateSetupOrchProcessForProductOrders();
            if (!newProductOrderIds.isEmpty())
                PopulateFieldFromProductConfiguration(newProductOrderIds);
            if (!revisedPOIds.isEmpty())    // kw: added for order amendment 
                PopulateFieldFromProductConfigurationAfterRevision(revisedPOIds);
            if (!prodOrdersToTriggerOrch.isEmpty() && firstRun) {
                CreateAppropriateOrchProcesses();
            }
            if(!prodOrdersStarted.isEmpty()) {
                CheckOtherPOsAndUpdateCampaignToFulStarted();
            }
            if(!prodOrdersReadyForLive.isEmpty())
                CheckOtherPOsAndUpdateCampaignToFulReady();
            if (!poChangedDates.isEmpty())
                SetDurationType();
                
            // http://dashboard.news.com.au/browse/NXRIII-156, CS    
            if (!changedCallTrackingIDs.isEmpty())
                setCallTrackingNumberForSEMPOs();
            
            // http://dashboard.news.com.au/browse/NXRIII-330, News  
            if (!changedGAUAIDs.isEmpty())
                setGAUAIDForSEMPOs();
                         
            if (!fulfillmentStartedPOOrderIds.isEmpty())
                checkOtherPOsAndSetOrderFulFillmentStarted();
    
            if (!ordersToTerminateProcesses.isEmpty())
            {
                //TerminateOrderOnlyTasks(ordersToTerminateProcesses); //NX-249 - commented out by DD, this is not needed as terminating process will complete tasks
                CS_TaskBehaviour.ForceManualTaskClosure=true;
                TerminateRelatedProcesses(ordersToTerminateProcesses);
                CS_TaskBehaviour.ForceManualTaskClosure=false;
            }   

            //NX-324
            //if (CS_NotificationOnEvent.HasEvents())
            CS_NotificationOnEvent.SendNotificationEmails();
            //NX-324
                
        }
        else if (trigger.isBefore)
        {
            // http://dashboard.news.com.au/browse/NXRIII-109, CS
            if (!mapOrderIdToPOs.isEmpty())
                setAccountName();
        }
    }
    
    void checkOtherPOsAndSetOrderFulFillmentStarted()
    {
        list<Order__c> reqOrders = new list<Order__c>();
        
        for (Order__c ord : [select Id,
                             (select Id from Product_Orders__r where Status__c = 'Draft')
                             from Order__c where Id in :fulfillmentStartedPOOrderIds])
        {
            if (!ord.Product_Orders__r.isEmpty())
                continue;
                
            ord.Is_Start_All_Fulfilment_Button_Pushed__c = 'Clicked';
            reqOrders.add(ord); 
        }
        
        if (!reqOrders.isEmpty())
            update reqOrders;
    }
    
    // http://dashboard.news.com.au/browse/NXRIII-109, CS
    void setAccountName()
    {
        for (Order__c co : [select Id, Account__r.Name from Order__c where Id in :mapOrderIdToPOs.keySet()])
        {
            for (Product_Order__c po : mapOrderIdToPOs.get(co.Id))
                po.Account_Name__c = co.Account__r.Name;
        }       
    }
    
    // http://dashboard.news.com.au/browse/NXRIII-156, CS
    // Whenver a call tracking number is set/changed for a Call Tracking Product order, SEM product orders in the 
    // same campaign order will be updated with the same value in their Call tracking number field
    void setCallTrackingNumberForSEMPOs()
    {
        system.debug('########### changedCallTrackingIDs ' + changedCallTrackingIDs);
        
        map<ID, String> mapCOToCallTrackingNumber = new map<ID, String>();
        for (Product_Order__c ctPO : [select Id, Call_Tracking_Number__c, Order__c from Product_Order__c where Id in :changedCallTrackingIDs])
            mapCOToCallTrackingNumber.put(ctPO.Order__c, ctPO.Call_Tracking_Number__c);
            
        list<Product_Order__c> semPOs = [   select Id,Order__c from Product_Order__c 
                                            where Order__c in :mapCOToCallTrackingNumber.keySet()
                                            and RecordType.Name = 'Search Engine Marketing'];
            
        for (Product_Order__c semPO : semPOs)
            semPO.Call_Tracking_Number__c = mapCOToCallTrackingNumber.get(semPO.Order__c);
            
        update semPOs;
    }

    // http://dashboard.news.com.au/browse/NXRIII-330, News
    // Whenver a GA UA ID is set/changed for a Call Tracking Product order, SEM product orders in the 
    // same campaign order will be updated with the same value in their Call tracking number field
    void setGAUAIDForSEMPOs()
    {
        system.debug('########### changedGAUAIDs ' + changedGAUAIDs);
        map<ID, String> mapCOToCallTrackingNumber = new map<ID, String>();
        map<ID, String> mapCOToGAUAID = new map<ID, String>();
        for (Product_Order__c ctPO : [select Id, GA_UA_ID__c, Order__c from Product_Order__c where Id in :changedGAUAIDs])
            mapCOToGAUAID.put(ctPO.Order__c, ctPO.GA_UA_ID__c);
            
        list<Product_Order__c> semPOs = [   select Id,Order__c from Product_Order__c 
                                            where Order__c in :mapCOToGAUAID.keySet()
                                            and RecordType.Name = 'Search Engine Marketing'];
            
        for (Product_Order__c semPO : semPOs)
            semPO.GA_UA_ID__c = mapCOToGAUAID.get(semPO.Order__c);
            
        update semPOs;
    }    

    void PopulateOptimisationReviewDates()
    {
        List<Product_Order__c> prodorders = [select id,
                                        Product_Order_Start_Date__c, 
                                        Current_Optimisation_Date__c,
                                        Next_Optimisation_Date__c,
                                        Product_Order_Tier__c,
                                        Customer_Tier__c,
                                        RecordType.Name FROM Product_Order__c where id IN: setNextReviewDates];

        List<Product_Order_Tier_Frequency__mdt> productFreqs = [select id, masterlabel, Optimisation_Review__c,
        Team__c from Product_Order_Tier_Frequency__mdt];
        Map<string, map<string, Product_Order_Tier_Frequency__mdt>> tierWithFreq = 
            new map<string, map<string, Product_Order_Tier_Frequency__mdt>>();
        
        for (Product_Order_Tier_Frequency__mdt productFreq : productFreqs) {
            map<string, Product_Order_Tier_Frequency__mdt> temp = tierWithFreq.get(productFreq.team__c);
            if (temp == null){
                temp = new map<string, Product_Order_Tier_Frequency__mdt>();
            }
            temp.put(productFreq.masterlabel, productFreq);
            tierWithFreq.put(productFreq.team__c, temp);
        }

        for (Product_Order__c prodorder : prodorders) {
            string rtname = prodorder.recordtype.name;
            string team = '';
            if (rtName == 'Search Engine Marketing') {
                team = 'SEM';
            }
            /*Added by ND 19/04 to support new record types*/
            else if (rtName == 'Real Time Bidding' || rtname == 'Social' 
                     || rtName == 'Catch Up TV' || rtname == 'Programmatic Audio'
                    ) {
                team = 'RTB';
            }
            /*
            else {
                continue;
            }
            */
            if (team != '' && prodorder.Customer_Tier__c != null) {
            map<string, Product_Order_Tier_Frequency__mdt> prodFrequencyMap = tierWithFreq.get(team);
                system.debug('**IVANA PROD FREQ MAP ' + prodFrequencyMap);
            Product_Order_Tier_Frequency__mdt prodFrequency = prodFrequencyMap.get(prodorder.Customer_Tier__c);
            Date startdate;
                system.debug('**IVANA PROD prodFrequency: ' + prodFrequency);
                system.debug('**IVANA PROD prodorder.Customer_Tier__c: ' + prodorder.Customer_Tier__c);
                system.debug('**IVANA PROD team: ' + team);
                system.debug('**IVANA PROD tierWithFreq: ' + tierWithFreq);
                system.debug('**IVANA PROD prodorder: ' + prodorder);
                set<string> review = new set<string> (prodFrequency.Optimisation_Review__c.split(' '));
                system.debug(review);
                if (prodorder.Current_Optimisation_Date__c == null) {
                    startdate = prodorder.Product_Order_Start_Date__c;
                }
                else {
                    startdate = prodorder.Current_Optimisation_Date__c;
                }

                if (review.contains('month')) {

                    prodorder.Next_Optimisation_Date__c = 
                        startdate.addMonths(Integer.valueOf((new list<string>(review) )[0]));

                }
                else if (review.contains('week')) {
                    prodorder.Next_Optimisation_Date__c = 
                        startdate.addDays((Integer.valueOf((new list<string>(review) )[0])) * 7);
                }
                else if (review.contains('day')) {
                    prodorder.Next_Optimisation_Date__c = 
                        startdate.addDays(Integer.valueOf((new list<string>(review) )[0]));
                }
            }

            }

        update prodorders;
    }

    void SetDurationType ()
    {
        List<Product_Order__c> pos = [select id, Product_Order_Start_Date__c, Duration_months__c, Product_Order_End_Date__c, Duration_Type__c, Duration_Comment__c from Product_Order__c where id =: poChangedDates.keySet()];
        if (!pos.isEmpty()) {
            for (Product_Order__c po : pos) {
                Map<Date, Date> datesMap = poChangedDates.get(po.Id);
                Date startDate;
                for (date d : datesMap.keySet())
                    startDate = d;
                Date endDate = datesMap.get(startDate);

                if (endDate == null) {
                    po.Duration_Type__c = 'Standard';
                    po.Duration_Comment__c = '';
                    po.Duration_months__c = 12;
                    continue;
                }

                else {
                    Integer monthDiff = startDate.monthsBetween(endDate);
                    Date test = startDate.addMonths(monthDiff);
                    if (test == endDate && po.Duration_Type__c != 'Standard' && (po.Duration_Comment__c == SYSTEM_DURATION_COMMENT || po.Duration_Comment__c == null || po.Duration_Comment__c =='')) {
                        po.Duration_Type__c = 'Standard';
                        po.Duration_Comment__c = '';
                        po.Duration_months__c = monthDiff;
                    }
                    else {
                        po.Duration_Type__c = 'Non-standard';
                        po.Duration_Comment__c = SYSTEM_DURATION_COMMENT;
                        po.Duration_months__c = monthDiff;
                        if (startDate.day() < endDate.day())
                            po.Duration_months__c++;
                    }
                }
            }
            try {
            update pos;
            } catch(Exception ex)
            {
                ExLog.log(ex, 'config', pos, 'Could not update campaign duration.');
            }
        } 
    }

    void CheckOtherPOsAndUpdateCampaignToFulReady () 
    {
        List<Product_Order__c> productOrders = [select id, order__c, Status__c from Product_Order__c where order__c =: prodOrdersReadyForLive.values() 
                                                AND Status__c != 'Cancelled' AND Status__c != 'Live' AND  (NOT  (Status__c = 'Pending For Cancel' AND Type__c ='Delete') )]; // pm: added check for OA NX-1490
        Map<Id, Boolean> ordersToFulReady = new Map<Id, Boolean>();
        List<Id> orderIds = new List<Id>();
        if (!productOrders.isEmpty()) {
            for (Product_Order__c po : productOrders) {
                if (ordersToFulReady.get(po.Order__c) == null){
                    ordersToFulReady.put(po.Order__c, true);
                }
                if (po.Status__c != 'Ready to go live'){
                    ordersToFulReady.put(po.Order__c, false);
                }
            }
            for (Id orderId : ordersToFulReady.keySet()) {
                if(ordersToFulReady.get(orderId)){
                    orderIds.add(orderId);
                }
            }

            List<Order__c> ordersToBeUpdated = [select id, Status__c from order__c where id in: orderIds];
            for (Order__c order : ordersToBeUpdated){
                order.Status__c = 'Fulfilment Ready';
            }
            try {
                update ordersToBeUpdated;
            } catch(Exception ex)
            {
                ExLog.log(ex, 'config', ordersToBeUpdated, 'Could not update Order status');
            }
        }
    }

    void CheckOtherPOsAndUpdateCampaignToFulStarted () 
    {
        List<Product_Order__c> productOrders = [select id, order__c, Status__c from Product_Order__c where order__c =: prodOrdersStarted.values() AND Status__c != 'Cancelled'];
        Map<Id, Boolean> ordersToFulStarted = new Map<Id, Boolean>();
        system.debug(productOrders);
        List<Id> orderIds = new List<Id>();
        if (!productOrders.isEmpty())
            for (Product_Order__c po : productOrders) {
                if (ordersToFulStarted.get(po.Order__c) == null)
                    ordersToFulStarted.put(po.Order__c, true);
                if (po.Status__c == 'Draft')
                     ordersToFulStarted.put(po.Order__c, false);
                system.debug(ordersToFulStarted);
            }
            for (Id orderId : ordersToFulStarted.keySet()) {
                if(ordersToFulStarted.get(orderId))
                    orderIds.add(orderId);
            }
            system.debug(orderIds);

            List<Order__c> ordersToBeUpdated = [select id, Status__c from order__c where id in: orderIds];
            for (Order__c order : ordersToBeUpdated)
                order.Status__c = 'Fulfilment Started';
            try {
                update ordersToBeUpdated;
            } catch(Exception ex)
            {
                ExLog.log(ex, 'config', ordersToBeUpdated, 'Could not update order statuses');
            }
    }

    void CreateAppropriateOrchProcesses () 
    {
        List<Product_Order__c> poListNew = [select id, order__r.Status__c, Status__c, Type__c, RecordTypeId from Product_Order__c where id IN: prodOrdersToTriggerOrch.keySet()];
        CS_OrchestratorUtil orchestratorUtilNew = new CS_OrchestratorUtil();
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();

        for (Product_Order__c productOrder : poListNew) {

            if (productOrder.Order__r.Status__c == productOrder.Status__c)
                continue;

            try {
                String orchLabel = '';
                if (productOrder.Status__c == 'Pending For Pause') {
                    orchLabel = 'Product Pause';
                }
                else if (productOrder.Status__c == 'Pending For Cancel' && ( String.isBlank(productOrder.Type__c) || productOrder.Type__c != 'Delete')) { // additional check for OA
                    orchLabel = 'Product Cancel';
                }

                if (orchLabel == '') continue; 

                Set<String> templateLabels = productMapping.GetOrchProcessesNamesForLabel(orchLabel);

                for (String label : templateLabels) {
                    String orchName = rtIdandName.get(productOrder.RecordTypeId) + ' ' + orchLabel;
                    CSPOFA__Orchestration_Process_Template__c template = orchestratorUtilNew.GetProcessTemplateForLabel (label);
                
                    CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                        Name = orchName, 
                                                                                                        Product_Order__c = productOrder.Id);           
                    processesToInsert.add(process); 
                }
                firstRun = false;
            }  catch(Exception ex)
            {
                ExLog.log(ex, 'config', poListNew, 'Could not create orchestrator processes.');
            }
        }

        new CS_OpportunityTriggerDelegate.insertOrchProcesses().execute(processesToInsert);
    }

    void PopulateFieldFromProductConfiguration (Set<Id> poIds)     // kw: changed method signature to make it reusable
    {
        List<Product_Order__c> POs = [SELECT Id, RecordType.Name, Product_Order_Tier__c, PC_Id__c, Wholesale_Rate__c, Retail_Rate__c,
                Monthly_Impression_Goal__c, Wholesale_CPM__c, Retail_CPM__c,
                order__r.opportunity__c, order__r.sales_Order__c,order__r.sales_Order__r.csmso__Status__c,
                News_Xtend_Product_Ref__c,
                Product_Node__c
        FROM Product_Order__c
        WHERE Id IN: poIds];

        Set<Product_Order__c> posToUpdate = new Set<Product_Order__c>();

        Map<Id, Map<Id, Product_Order__c>> salesOrderIds = new Map<Id, Map<Id, Product_Order__c>>();
        for (Product_Order__c po : POs) {
            Id soId;
            if (po.order__r.sales_Order__r.csmso__Status__c == 'Killed') {
                csmso__Sales_Order__c so = [select id from csmso__Sales_Order__c
                where csmso__opportunity__c =:po.Order__r.opportunity__c AND
                (csmso__Status__c ='Manually Approved' OR csmso__Status__c ='Externally Approved')
                LIMIT 1];
                soId = so.Id;
            }
            else
                    soId = po.Order__r.sales_Order__c;

            Map<Id, Product_Order__c> polist = salesOrderIds.get(soId);
            if (polist == null)
                polist = new Map<Id, Product_Order__c>();
            polist.put(po.PC_Id__c, po);

            salesOrderIds.put(soId, polist);
        }

        List<cscfga__Attribute__c> attsList = [SELECT Id, Name , cscfga__Product_Configuration__c, cscfga__Value__c, cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__c
        FROM cscfga__Attribute__c WHERE cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__c
                IN :salesOrderIds.keySet() AND (Name = 'Total Cost' OR Name = 'Price' OR Name = 'Total Impressions' OR Name= 'Cost CPM' OR Name = 'CPM')
                AND  cscfga__Product_Configuration__r.Line_Item_Platform__c = 'Xtend'];//OPG: Xtend E2E Billing Trail - fixed PC select - 15/2/2018: removing to fix 79 and 81 issue: AND cscfga__Product_Configuration__r.cscfga__Parent_Configuration__c = null

        List<Product_Order_Tier_Ranges__c> tierRanges = Product_Order_Tier_Ranges__c.getall().values();
        map<string, list<Product_Order_Tier_Ranges__c>> recordtyperanges = new map<string, list<Product_Order_Tier_Ranges__c>>();

        for (Product_Order_Tier_Ranges__c tierRange: tierRanges) {
            string nametemp = tierRange.Record_Type_Name__c == null ? '':tierRange.Record_Type_Name__c;
            list<Product_Order_Tier_Ranges__c> rangesList= recordtyperanges.get(nametemp);
            if (rangesList == null )
                rangesList = new list<Product_Order_Tier_Ranges__c>();
            rangesList.add(tierRange);

            recordtyperanges.put(nametemp, rangesList);
        }
        system.debug(recordtyperanges);

        Map<Product_Order__c, List<cscfga__Attribute__c>> poWithAtts = new Map<Product_Order__c, List<cscfga__Attribute__c>>();
        Map<Id, Product_Order__c> poForSalesOrder;
        for (cscfga__Attribute__c att : attsList) {
            poForSalesOrder = salesOrderIds.get(att.cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__c);
            Product_Order__c po = poForSalesOrder.get(att.cscfga__Product_Configuration__c);
            if (po == null) continue;

            if (att.name == 'Total Cost' && att.cscfga__Value__c != null)
                po.Wholesale_Rate__c = Decimal.valueOf(att.cscfga__Value__c);

            else if (att.name == 'Price' && att.cscfga__Value__c != null) {
                po.Retail_Rate__c = Decimal.valueOf(att.cscfga__Value__c);
                list<Product_Order_Tier_Ranges__c> prodOrderRanges = recordtyperanges.get(po.recordtype.name) == null ?
                        recordtyperanges.get('') : recordtyperanges.get(po.recordtype.name);
                system.debug('prodOrderRanges =' + prodOrderRanges);  system.debug(att);
                if(prodOrderRanges != null){
                    for (Product_Order_Tier_Ranges__c tierRange: prodOrderRanges)
                    {
                        if ((po.Retail_Rate__c != 0) && (po.Retail_Rate__c >= tierRange.Lowerbound__c) && (po.Retail_Rate__c <= tierRange.Upperbound__c))
                        {
                            po.Product_Order_Tier__c = tierRange.Tier_level__c;
                        }
                    }
                }
                
            }
            else if (att.name == 'Total Impressions' && att.cscfga__Value__c != null)
                po.Monthly_Impression_Goal__c = Decimal.valueOf(att.cscfga__Value__c);
            else if (att.name == 'Cost CPM' && att.cscfga__Value__c != null)
                po.Wholesale_CPM__c = Decimal.valueOf(att.cscfga__Value__c);
            else if (att.name == 'CPM' && att.cscfga__Value__c != null)
                po.Retail_CPM__c = Decimal.valueOf(att.cscfga__Value__c);

            poForSalesOrder.put(att.cscfga__Product_Configuration__c, po);
        }

        try {
            update poForSalesOrder.values();
        }  catch(Exception ex)
        {
            ExLog.log(ex, 'config', poForSalesOrder.values(), 'Could not update product order calculations.');
        }
    }

    // kw: update po fields after po gets revised after retraction 
    public void PopulateFieldFromProductConfigurationAfterRevision (Set<Id> revisedPoIds)
    {
        PopulateFieldFromProductConfiguration(revisedPoIds);
    }

    public void MapProductOrderRTIdwithName ()
    {
        Schema.DescribeSObjectResult cfrSchema = Schema.SObjectType.Product_Order__c; 
        Map<String, Schema.RecordTypeInfo> ProdOrderRecordTypeInfo = cfrSchema.getRecordTypeInfosByName(); 

        for (String name : ProdOrderRecordTypeInfo.keySet()) {
            rtIdandName.put(ProdOrderRecordTypeInfo.get(name).getRecordTypeId(), Name);
        }
    }

    void CreateSetupOrchProcessForProductOrders () 
    {
        CS_OrchestratorUtil orchestratorUtil = new CS_OrchestratorUtil();
        system.debug(newInProgressPO);
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();
        Map<Id, List<String>> poToOrchProcesses = new Map<Id, List<String>>();
        for (Id poId : newInProgressPO.keySet())
        {
            if (newInProgressPOType.get(poId) == null || newInProgressPOType.get(poId) == '') {
                newInProgressPOType.put(poId, 'New');
            }
            Set<String> templateLabels = productMapping.getOrchProcessesNamesForLabelAndType(newInProgressPO.get(poId),
                                                                                    newInProgressPOType.get(poId));
            poToOrchProcesses.put(poId, new List<String>(templateLabels));
            system.debug(poId + ' ' + templateLabels);
        }

        try {
            for (Id poId : poToOrchProcesses.keySet()) {
                for (String processName : poToOrchProcesses.get(poId)) {
                    CSPOFA__Orchestration_Process_Template__c template = 
                        orchestratorUtil.GetProcessTemplateForLabel (processName);
                        system.debug(template);
                    CSPOFA__Orchestration_Process__c process =  
                        new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                        Name = processName + ' Setup', 
                                                                                                        Product_Order__c = poId);           
                    processesToInsert.add(process); 
                }
            }
            firstRun = false;

            new CS_OpportunityTriggerDelegate.insertOrchProcesses().execute(processesToInsert);
        }  catch(Exception ex)
            {
                ExLog.log(ex, 'config', processesToInsert, 'Could not insert orchestrator processes');
            }
    }

    Date getNextBizDate(Date givenDate, String strLabel)  
        {   
           Integer noOfDays = Integer.valueOf(strLabel); 
           if(noOfDays==null)
                noOfDays = 0;
           Date nextBizDt = givenDate; 
           List<Holiday> holList=[Select Name, ActivityDate From Holiday];  
           nextBizDt = nextBizDt.addDays(noOfDays);  
           while(!isWorkingDay(nextBizDt,holList)) 
           {
             nextBizDt = nextBizDt.addDays(1);
           }
           return nextBizDt;    
        }
    Boolean isWorkingDay(Date currentDate,List<Holiday> holidays)
        {   
            String strDay  = ((DateTime)currentDate).format('EEE');
            for(Holiday hDay:holidays)
            {      
                if(currentDate.isSameDay(hDay.ActivityDate)) 
                    return false; 
            }
            if(strDay.toUpperCase()=='SAT' || strDay.toUpperCase()=='SUN')
                return false;
            else 
                return true;
        }   

    void TerminateRelatedProcesses(List<Id> idListToTerminateProcesses) 
    {
        List<CSPOFA__Orchestration_Process__c> allPs = [SELECT Id FROM CSPOFA__Orchestration_Process__c 
                                                        WHERE CSPOFA__Status__c != 'Complete' AND Product_Order__c IN: idListToTerminateProcesses];

        for (CSPOFA__Orchestration_Process__c process : allPs) {
            process.CSPOFA__Status__c  = 'Complete';
            process.CSPOFA__State__c = 'TERMINATED';
        }                                  
        update allPs;
    }

    //NX-249 - commented out by DD, this is not needed as terminating process will complete tasks
    void TerminateOrderOnlyTasks(List<Id> idListToTerminateProcesses) 
    {
        system.debug('*** TerminateOrderOnlyTasks for Product Order');
        System.debug('***idListToTerminateProcesses=' + idListToTerminateProcesses);
        /*
        List<Task> tasks = [SELECT Id FROM Task WHERE Status NOT IN ('Completed','Done','Cancelled') 
            AND WhatId IN: idListToTerminateProcesses
            AND CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Do_Not_Kill__c=false];
        */

        List<Task> tasks = [SELECT Id FROM Task WHERE IsClosed=false AND WhatId IN: idListToTerminateProcesses
            AND CSPOFA__Orchestration_Step__c=null];
        
        for (Task task : tasks) {
            task.Status = 'Cancelled';
        }                                  
        update tasks;
    }
    

}