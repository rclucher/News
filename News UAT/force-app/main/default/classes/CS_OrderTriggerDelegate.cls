public with sharing class CS_OrderTriggerDelegate extends CS_TriggerHandler.DelegateBase 
{
    public static  boolean firstRun = true;
    CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil(); 
    Map<Id, Order__c> newPausedOrders;
    Map<Id, Order__c> newLiveOrders;
    Map<Id, Order__c> retractedNewLiveOrders;  // new live co that was retracted before
    Map<Id, Order__c> newCancelOrders;
    List<Order__c> ordersToTriggerOrch;
    Map<Id, Date> newStartDateOnOrders;
    Map<Id, Date> newActStartDateOnOrders;
    Map<Id, Date> newEndDateOnOrders;
    Map<Id, Id> cmAssigned;
    Map<order__c, String> orderUpdatedStatus;
    map<id, Order__c> oppsUpdatedProgress;
    map<id, order__c> setupCallOrders;
    list<id> setNextReviewDates;
    list<id> setNextDashReviewDates;
    list<id> setNextPerfReviewDates;
    list<id> setNextReportReviewDates;
    String daysbeforeDashReview = System.Label.Days_before_Dashboard_Review;
    List<businesshours> bhs;
    Map<Id, Order__c> ordersCancelled;
    Map<Id, Order__c> ordersPaused;
    Map<Id, Order__c> ordersEnded;
    Map<Id, Order__c> ordersRetracted;  // order amendment: camoaigns that are in revision post so retraction
    Map<Id, Order__c> acceptChangeToOrder;  // order amendment: campaign manager has accepeted changes from so retraction
    List<Id> ordersToTerminateProcesses;
    List<Id> returnedToSalesOrdersToTerminateProcessesIdList;//NX-220
    List<Order__c> returnedToSalesOrdersToTerminateProcesses;//NX-220
    List<Id> productOrdersToCancelTasks;//NX-220
    List<Id> returnedToSalesOpportunityIdList;//NX-220
    List<History_Tracking__c> historyTrackingList;

    map<ID, list<Order__c>> mapAccountToCOs; // http://dashboard.news.com.au/browse/NXRIII-109, CS
	string strChatterComments; //NXRIII-346
    public override void prepareBefore() 
    {
        orderUpdatedStatus = new Map<Order__c, String>();
        mapAccountToCOs = new map<ID, list<Order__c>>(); // http://dashboard.news.com.au/browse/NXRIII-109, CS
        acceptChangeToOrder = new Map<Id, Order__c>();

        if(bhs == null){
            bhs = CS_Cache.defaultBusinessHours;
        }
    }

    public override void prepareAfter() 
    {
        newPausedOrders = new Map<Id, Order__c>();
        newLiveOrders = new Map<Id, Order__c>();
        retractedNewLiveOrders  = new Map<Id, Order__c>();
        historyTrackingList = new List<History_Tracking__c>();
        newCancelOrders = new Map<Id, Order__c>();
        ordersToTriggerOrch = new List<Order__c>();
        newStartDateOnOrders = new Map<Id, Date>();
        newActStartDateOnOrders = new Map<Id, Date>();
        newEndDateOnOrders = new Map<Id, Date>();
        cmAssigned = new Map<Id, Id>();
        oppsUpdatedProgress = new Map<Id, Order__c>();
        setupCallOrders = new Map<id, order__c>();
        setNextReviewDates = new List<id>();
        setNextReportReviewDates = new List<id>();
        setNextPerfReviewDates = new List<id>();
        setNextDashReviewDates = new List<id>();
        ordersPaused = new map<id, order__c>();
        ordersCancelled = new map<id, order__c>();
        ordersEnded = new Map<Id, Order__c>();
        ordersRetracted = new Map<Id, Order__c>();
        ordersToTerminateProcesses = new List<Id>();
        returnedToSalesOrdersToTerminateProcessesIdList = new List<Id>();//NX-220
        returnedToSalesOrdersToTerminateProcesses=new List<Order__c>();//NX-220
        productOrdersToCancelTasks = new List<Id>();//NX-220
        returnedToSalesOpportunityIdList = new List<Id>();//NX-220

        if(bhs == null){
            bhs = CS_Cache.defaultBusinessHours;
        }
    }

    public override void beforeInsert(sObject o) 
    {
        Order__c newOrder = (Order__c)o;
        orderUpdatedStatus.put(newOrder, newOrder.status__c);
        
        // http://dashboard.news.com.au/browse/NXRIII-109, CS //////////////// 
        if (newOrder.Account__c != null)
        {
            list<Order__c> cos = mapAccountToCOs.get(newOrder.Account__c); 
            if (cos == null)
                cos = new list<Order__c>();
                
            cos.add(newOrder);
                
            mapAccountToCOs.put(newOrder.Account__c, cos);   
        } 
        ////////////////////////////////////////////////////////////////////// 
        
          
    }

    public override void beforeUpdate(sObject old, sObject o) 
    {
        Order__c oldOrder = (Order__c)Old;
        Order__c newOrder = (Order__c)o;
        Date dt = Date.today();
        if (newOrder.Next_Dashboard_Review_Date__c != null && newOrder.Next_Dashboard_Review_Date__c != oldOrder.Next_Dashboard_Review_Date__c) {
            if (!bhs.isEmpty()) {
                businesshours bh = bhs.get(0);
                Long milSecs;
                milSecs = (Long) (Integer.valueOf(daysbeforeDashReview)*-8*60*60*1000);
                Datetime targetDateTime = BusinessHours.add(bh.Id, newOrder.Next_Dashboard_Review_Date__c, milSecs);
                date d = Date.newInstance(targetDateTime.year(), targetDateTime.month(), targetDateTime.day());
                newOrder.Next_Dashboard_Internal_Review_Date__c = d;
            }
            else {
                newOrder.Next_Dashboard_Internal_Review_Date__c = newOrder.Next_Dashboard_Review_Date__c-3;
            }
        }
        if (newOrder.Status__c != oldOrder.Status__c)
            orderUpdatedStatus.put(newOrder, newOrder.status__c);

        // kw: order amendment
        // if change has been accepeted, update co 
        if (newOrder.Accept_Retraction_Change__c != oldOrder.Accept_Retraction_Change__c && newOrder.Accept_Retraction_Change__c ){
            acceptChangeToOrder.put(newOrder.Id, newOrder);
        }

        if (newOrder.Cancellation_Date__c != oldOrder.Cancellation_Date__c)
            newOrder.End_Date__c = newOrder.Cancellation_Date__c;

        if((newOrder.isNextBizDateRecal__c!=null && newOrder.isNextBizDateRecal__c==true) ||
            (oldOrder.Actual_Start_Date__c != newOrder.Actual_Start_Date__c && newOrder.Actual_Start_Date__c != null))
        {
            // http://dashboard.news.com.au/browse/NXRIII-154
            if (oldOrder.Actual_Start_Date__c != newOrder.Actual_Start_Date__c && newOrder.Actual_Start_Date__c != null)
                dt = newOrder.Actual_Start_Date__c;
                
            newOrder.Next_Business_Date__c =  getNextBizDate(dt, System.Label.Order_Days_NextBizDate); 
            newOrder.isNextBizDateRecal__c = false;
        }
        
        if (oldOrder.Proposed_Start_Date__c != null && oldOrder.Proposed_Start_Date__c != newOrder.Proposed_Start_Date__c && oldOrder.End_Date__c != null)
        {
                Integer monthDifference = oldOrder.Proposed_Start_Date__c.monthsBetween(oldOrder.End_Date__c);
                newOrder.End_Date__c = newOrder.Proposed_Start_Date__c.addMonths(monthDifference);// T-33686 CSP 2017-10-04
        }       

    }

    public override void beforeDelete(sObject o) 
    {}

    public override void afterInsert(sObject o) 
    {}

    public override void afterUpdate(sObject oOld, sObject oNew)
    {
        Order__c oldOrder = (Order__c)oOld;
        Order__c newOrder = (Order__c)oNew;

        if (Trigger.size > 0) {
            CSPOFA.Events.emit('update', Trigger.newMap.keySet());
        }
        // Author: KW 
        // update campaign order lineitems (product orders) if the campaign order's been retracted
        if(oldOrder.Revision_Date__c != newOrder.Revision_Date__c && newOrder.Revision_Date__c != null){
            ordersRetracted.put(newOrder.id, newOrder);
        }
        if (newOrder.Pause_Start_Date__c != oldOrder.Pause_Start_Date__c)
            ordersPaused.put(newOrder.id, newOrder);
        if (newOrder.Cancellation_Date__c != oldOrder.Cancellation_Date__c)
            ordersCancelled.put(newOrder.id, newOrder);

        if (newOrder.Actual_Start_Date__c != null && newOrder.Actual_Start_Date__c != oldOrder.Actual_Start_Date__c)
            setNextReviewDates.add(newOrder.id);

        if (newOrder.Current_Campaign_Performance_Review_Date__c != null && newOrder.Current_Campaign_Performance_Review_Date__c != oldOrder.Current_Campaign_Performance_Review_Date__c)
        {
            setNextPerfReviewDates.add(newOrder.id);
                        system.debug(loggingLevel.ERROR, '####### setNextPerfReviewDates ' + setNextPerfReviewDates);
        }

        
        if (newOrder.Current_Dashboard_Review_Date__c != null && newOrder.Current_Dashboard_Review_Date__c != oldOrder.Current_Dashboard_Review_Date__c)
            setNextDashReviewDates.add(newOrder.id);

        
        if (newOrder.Current_Customer_Report_Date__c != null && newOrder.Current_Customer_Report_Date__c != oldOrder.Current_Customer_Report_Date__c)
            setNextReportReviewDates.add(newOrder.id); 

        if (newOrder.Setup_Call_Schedule__c != oldOrder.Setup_Call_Schedule__c)
            setupCallOrders.put (newOrder.id, newOrder);

        if (newOrder.Progress_Percentage__c != oldOrder.Progress_Percentage__c || newOrder.Status__c != oldOrder.Status__c)
            oppsUpdatedProgress.put(newOrder.Opportunity__c, newOrder);

        if (newOrder.Status__c != null && newOrder.Status__c.contains('Pause') && newOrder.Status__c != oldOrder.Status__c)
            newPausedOrders.put (newOrder.Id, newOrder);

        if (newOrder.Status__c == 'Campaign Ended' && newOrder.Status__c != oldOrder.Status__c)
            ordersEnded.put(newOrder.Id, newOrder);

        if (newOrder.Assigned_Campaign_Manager__c != null && newOrder.Assigned_Campaign_Manager__c != oldOrder.Assigned_Campaign_Manager__c)
            cmAssigned.put (newOrder.Id, newOrder.Assigned_Campaign_Manager__c);

        if (newOrder.Status__c != null && newOrder.Status__c == 'Campaign Live' && newOrder.Status__c != oldOrder.Status__c){
            system.debug('**** campaign go-live ');
            system.debug('**** newOrder='+newOrder);
            // kw: order amendment 
            if(newOrder.Previous_Sales_Order_Start_Date__c == null){    // the co was not retracted 
                newLiveOrders.put (newOrder.Id, newOrder);
            }
            else{   // the co was previously retracted 
                retractedNewLiveOrders.put(newOrder.Id, newOrder);
            }
            if ( String.isEmpty(newOrder.Origin__c) || newOrder.Origin__c == 'Salesforce') {
                //kw: order amendment - history tracking
                History_Tracking__c historyTracking = CS_HistoryTrackingService.createHistoryTracking('Sales Order', newOrder.Sales_Order__c, 'Campaign Live', false, true);
                historyTrackingList.add(historyTracking);

            }

        }

        if (newOrder.Status__c != null && oldOrder.Status__c == 'Paused' && newOrder.Status__c != oldOrder.Status__c)
            newLiveOrders.put (newOrder.Id, newOrder);

        if (newOrder.Status__c != null && newOrder.Status__c.contains('Cancel') && newOrder.Status__c != oldOrder.Status__c)
            newCancelOrders.put (newOrder.Id, newOrder);

        if (newOrder.Status__c != null && newOrder.Status__c.contains('Pending') && newOrder.Status__c != oldOrder.Status__c) {
            ordersToTriggerOrch.add(newOrder);
        }
        if (newOrder.End_Date__c != oldOrder.End_Date__c) {
            newEndDateOnOrders.put (newOrder.Id, newOrder.End_Date__c);
        }
        if (newOrder.Cancellation_Date__c != oldOrder.Cancellation_Date__c) {
            newEndDateOnOrders.put (newOrder.Id, newOrder.Cancellation_Date__c);
        }




        if (newOrder.Proposed_Start_Date__c != oldOrder.Proposed_Start_Date__c) {
            newStartDateOnOrders.put (newOrder.Id, newOrder.Proposed_Start_Date__c);

            // no end date updates of evergreen
            if ( !newOrder.Evergreen__c) {

                if(!(oldOrder.Proposed_Start_Date__c == null || newOrder.Proposed_Start_Date__c == null || oldOrder.End_Date__c == null)) {
                    Integer monthDifference = oldOrder.Proposed_Start_Date__c.monthsBetween(oldOrder.End_Date__c);
                    //Date tempDate = calculateNewEndDate(newOrder.Proposed_Start_Date__c,newOrder.End_Date__c,oldOrder.Proposed_Start_Date__c);// T-33686 CSP 2017-10-04
                    newEndDateOnOrders.put (newOrder.Id, newOrder.Proposed_Start_Date__c.addMonths(monthDifference));// T-33686 CSP 2017-10-04
                }
                //NXRIII-346 start
                // post the catter  Setup risk notes when proposed start date is changed
                if(newOrder.Setup_Notes__c !=null && oldOrder.Proposed_Start_Date__c != null && newOrder.Proposed_Start_Date__c != null && newOrder.Proposed_Start_Date__c > system.today()){
                    strChatterComments = stringCompare(oldOrder.Setup_Notes__c,newOrder.Setup_Notes__c);
                    list<order__c> newOrderList = new list<order__c>();
                    newOrderList.add(newOrder);
                    if(strChatterComments!=null && newOrder.Setup_Notes__c!=oldOrder.Setup_Notes__c){
                        PostToChatter(newOrderList,'Setup_Notes__c' );
                    }

                }
            }

            //NXRIII-346 End
        }
        else if (newOrder.Actual_Start_Date__c != oldOrder.Actual_Start_Date__c && newOrder.Status__c!='Draft' && newOrder.Actual_Start_Date__c != null) {//NX-220
            newActStartDateOnOrders.put (newOrder.Id, newOrder.Actual_Start_Date__c);
            newStartDateOnOrders.put (newOrder.Id, newOrder.Actual_Start_Date__c);
        }else if(newOrder.Sales_Start_Date__c != oldOrder.Sales_Start_Date__c && newOrder.Sales_Start_Date__c != null){
            newStartDateOnOrders.put (newOrder.Id, newOrder.Sales_Start_Date__c);
        }   


        if (newOrder.Status__c != null && newOrder.Status__c != oldOrder.Status__c && newOrder.Status__c == 'Campaign Ended')
            ordersToTerminateProcesses.add(newOrder.Id);
        if (newOrder.Status__c != null && newOrder.Status__c != oldOrder.Status__c && newOrder.Status__c == 'Returned To Sales' && newOrder.Draft_Review_Passed__c!='No'){//NX-220
            returnedToSalesOrdersToTerminateProcesses.add(newOrder);
            returnedToSalesOrdersToTerminateProcessesIdList.add(newOrder.Id);
            returnedToSalesOpportunityIdList.add(newOrder.Opportunity__c);
        }

        //NX-324-start
        if (newOrder.Status__c != null && newOrder.Status__c != oldOrder.Status__c)
        {
            CS_NotificationOnEvent.notificationObjectChangeEventWrapper tmpObjectNotification = new CS_NotificationOnEvent.notificationObjectChangeEventWrapper();
            tmpObjectNotification.objectType=CS_NotificationOnEvent.ObjectType.CampaignOrder;
            tmpObjectNotification.FieldName='Status__c';
            tmpObjectNotification.FromValue=oldOrder.Status__c;
            tmpObjectNotification.ToValue=newOrder.Status__c;
            tmpObjectNotification.objectId=newOrder.Id;
            tmpObjectNotification.Message='';

            CS_NotificationOnEvent.AddObjectChangeEvent(tmpObjectNotification);
        }
        //NX-324-end
    }

    public override void afterDelete(sObject o) 
    {}

    public override void afterUndelete(sObject o) 
    {}

    public override void finish() 
    {
        if (trigger.isBefore)
        {
            if(!acceptChangeToOrder.isEmpty()){
                populateRetractionChange();

            }

            if(!orderUpdatedStatus.isEmpty())
                SetOverallStatus();
            
            // http://dashboard.news.com.au/browse/NXRIII-109, CS  
            if (!mapAccountToCOs.isEmpty())
                SetAccountName();              
        }

        if (trigger.isAfter) 
        {
            if (!ordersCancelled.isEmpty())
                PopulateCancelDetailsOnPOs();
            if (!ordersPaused.isEmpty())
                PopulatePauseDetailsOnPOs();
            if (!setNextReviewDates.isEmpty())
                PopulateOptimisationReviewDates();
            if (!setNextReportReviewDates.isEmpty())
                PopulateOptimisationReportReviewDates();
            if (!setNextDashReviewDates.isEmpty())
                PopulateOptimisationDashboardReviewDates();
            if (!setNextPerfReviewDates.isEmpty())
                PopulateOptimisationPerformanceReviewDates();

            if (!oppsUpdatedProgress.isEmpty())
                UpdateOpporunityOnProgress();

            if (!newPausedOrders.isEmpty())
                UpdateProductOrders(newPausedOrders);

            if (!newLiveOrders.isEmpty())
                UpdateProductOrders(newLiveOrders);

            // kw: order amendment
            // modify existing payment schedules
            if (!retractedNewLiveOrders.isEmpty()){
                // update all product orders 
                UpdateProductOrders(retractedNewLiveOrders);
                // trigger payment schedule update from there
                CS_RetractSalesOrderService.updatePaymentSchedules(retractedNewLiveOrders);

                //NX-1618,
                List<csmso__Sales_Order__c> salesOrders = new List<csmso__Sales_Order__c>();

                for(Order__c o: retractedNewLiveOrders.values()) {
                    csmso__Sales_Order__c so = new csmso__Sales_Order__c(id = o.Sales_Order__c);

                    CS_ReinstateSalesOrderService.clearSalesOrderRetractionFields(so);
                    salesOrders.add(so);
                }

                update salesOrders;
            }

            if ( !historyTrackingList.isEmpty() ) {
                    CS_HistoryTrackingService.enqueueHistorySnapshotCreation(historyTrackingList);
            }

            if (!newCancelOrders.isEmpty())
                UpdateProductOrders(newCancelOrders);

            if(!ordersEnded.isEmpty()){
                UpdateProductOrders(ordersEnded);
            }

            // order amendment: update product orders for retracted campaign orders
            if(!ordersRetracted.isEmpty()){
                updateProductOrdersForRestractedOrders(ordersRetracted);
            }

            if (!ordersToTriggerOrch.isEmpty() && firstRun)
                CreateAppropriateOrchProcesses();

            if (!newStartDateOnOrders.isEmpty())
                UpdateStartDates();
                
            if (!newActStartDateOnOrders.isEmpty())    
                UpdatePONextDates();
                
            if (!newEndDateOnOrders.isEmpty())
                UpdateEndDates();
                UpdateCaseEndDates();

            if (!ordersToTerminateProcesses.isEmpty())
            {
                 TerminateOrderOnlyTasks(ordersToTerminateProcesses); //NX-249 - commented out by DD, this is not needed as termination of the process will terminate tasks
                 CS_TaskBehaviour.ForceManualTaskClosure=true;
                 TerminateRelatedProcesses(ordersToTerminateProcesses);
                 CS_TaskBehaviour.ForceManualTaskClosure=false;
                 
            }
            
            if (!returnedToSalesOrdersToTerminateProcesses.isEmpty())//NX-220
            {
                List<Product_Order__c> listProductOrdersToCancel=[SELECT Id FROM Product_Order__c WHERE Order__c IN: returnedToSalesOrdersToTerminateProcessesIdList];

                TerminateRelatedProcesses(returnedToSalesOrdersToTerminateProcessesIdList);
                //TerminateOrderOnlyTasks(returnedToSalesOrdersToTerminateProcessesIdList); //this is not needed as termination of the process will terminate tasks

                if(!Test.isRunningTest()) 
                    //PostToChatter();
                    PostToChatter(returnedToSalesOrdersToTerminateProcesses,'Notes_for_Failure__c');
                
                UpdateReturnedToSalesOrderOpportunity();
                
                for(Product_Order__c prodOrder:listProductOrdersToCancel){
                    productOrdersToCancelTasks.add(prodOrder.id);
                }
                if(!productOrdersToCancelTasks.isEmpty()){ 
                    TerminateOrderOnlyTasks(productOrdersToCancelTasks); 
                }
            }
        
            //NX-324
            //if (CS_NotificationOnEvent.HasEvents())
            CS_NotificationOnEvent.SendNotificationEmails();
            //NX-324
        }
    }

    void PopulateCancelDetailsOnPOs() 
    {
        list<Product_Order__c> allPOs = [select id,
                                                Pause_Start_Date__c,
                                                Campaign_Restart_Date__c,
                                                Reason_For_Pause__c,
                                                Order__c,
                                                Cancellation_Date__c,
                                                Cancellation_Reason__c FROM Product_Order__c where status__c != 'Cancelled' AND 
                                                order__c IN: ordersCancelled.keySet()];
        Map<id, List<Product_Order__c>> ordersWithPOs = new map<id, List<Product_Order__c>>();
        list<Product_Order__c> posToUpdate = new list<Product_Order__c>();
        
        for (Product_Order__c po : allPOs) {
            list<Product_Order__c> pos = ordersWithPOs.get(po.Order__c);
            if (pos == null)
                pos = new list<Product_Order__c>();
            pos.add(po);
            ordersWithPOs.put(po.Order__c, pos);
        }                                  
        for (id orderid : ordersWithPOs.keySet()) {
            list<Product_Order__c> pos = ordersWithPOs.get(orderid);
            for (Product_Order__c po : pos) {
                order__c order = ordersCancelled.get(po.Order__c);
                po.Cancellation_Date__c = order.Cancellation_Date__c;
                po.Cancellation_Reason__c = order.Cancellation_Reason__c;
                posToUpdate.add(po);
            }
        } 
        update posToUpdate;
    }

    void populateRetractionChange(){
        List<Order__c> orders = [Select Id, Actual_Start_Date__c,
                                        Sales_Order__r.Campaign_Start_Date__c, Sales_Order__r.Campaign_End_Date2__c,
                                        Opportunity__r.Amount, Sales_Order__r.Retracted_Date__c, 
                                        Sales_Order__r.Previous_Campaign_Start_Date__c, Sales_Order__r.Previous_Campaign_End_Date__c,
                                        Sales_Order__r.Previous_Opp_CW_Date__c, Setup_Notes__c,Proposed_Start_Date__c
                                    From Order__c
                                    Where Id In: acceptChangeToOrder.keySet()];

        //NX-1477 Setup Notes validation issue fix
        String setupNotesPlaceHolder  = '\n {0} : Order Amendment accepted,  Proposed Start Date Auto Updated [From {1} to {2}].';
        List<String> messageParams = new List<String>();
        Date proposedDate  = CS_OpportunityTriggerDelegate.getCalculatedProposedStartDate();



        for(Order__c orderDB: orders){
            Order__c order = acceptChangeToOrder.get(orderDB.Id);

            messageParams.clear();
            messageParams.add(Date.today().format());
            messageParams.add(orderDB.Proposed_Start_Date__c.format()); // old proposed start date
            messageParams.add(proposedDate.format());


            order.Sales_Start_Date__c                   = orderDB.Sales_Order__r.Campaign_Start_Date__c;
            order.End_Date__c                           = orderDB.Sales_Order__r.Campaign_End_Date2__c;
            order.Total_Amount_GST_Excl__c              = orderDB.Opportunity__r.Amount;
            order.Evergreen__c                          = orderDB.Sales_Order__r.Campaign_End_Date2__c==null ? true : false;

            //NX-1477
            order.Proposed_Start_Date__c                = proposedDate;
            order.Setup_Notes__c                        = String.format(setupNotesPlaceHolder,messageParams);
            //NX-1477

            order.Revision_Date__c                      = System.today();
            order.Previous_Actual_Start_Date__c         = orderDB.Actual_Start_Date__c;
            order.Previous_Sales_Order_Start_Date__c    = orderDB.Sales_Order__r.Previous_Campaign_Start_Date__c;
            order.Previous_End_Date__c                  = orderDB.Sales_Order__r.Previous_Campaign_End_Date__c;
            order.Previous_Opp_CW_Date__c               = orderDB.Sales_Order__r.Previous_Opp_CW_Date__c; //pm: OA CR in NX-1534
            order.Actual_Start_Date__c                  = null;
            order.Is_Start_All_Fulfilment_Button_Pushed__c = null;
            order.Assigned_Campaign_Manager_For_QA__c   = null;
            order.Reset_QA_Items__c						= 'Yes'; //added to reset the QA Items entries related to QA Checklist.
            // OA PM: Related to NX-1401 START Need to clear field when CO is retracted as Live
            // updateProductOrdersForRestractedOrders passes campaignLIve as true for ordersRetracted
            order.QA_Check_Approved__c = null;
            // OA PM: Related to NX-1401 END
        }

    }

    void PopulatePauseDetailsOnPOs() 
    {
        list<Product_Order__c> allPOs = [select id,
                                                Pause_Start_Date__c,
                                                Campaign_Restart_Date__c,
                                                Reason_For_Pause__c,
                                                Order__c,
                                                Cancellation_Date__c,
                                                Cancellation_Reason__c FROM Product_Order__c where status__c != 'Paused' AND
                                                order__c IN: ordersPaused.keySet()];
        Map<id, List<Product_Order__c>> ordersWithPOs = new map<id, List<Product_Order__c>>();
        list<Product_Order__c> posToUpdate = new list<Product_Order__c>();
        
        for (Product_Order__c po : allPOs) {
            list<Product_Order__c> pos = ordersWithPOs.get(po.Order__c);
            if (pos == null)
                pos = new list<Product_Order__c>();
            pos.add(po);
            ordersWithPOs.put(po.Order__c, pos);
        }                                  
        for (id orderid : ordersWithPOs.keySet()) {
            list<Product_Order__c> pos = ordersWithPOs.get(orderid);
            for (Product_Order__c po : pos) {
                order__c order = ordersPaused.get(po.Order__c);
                po.Pause_Start_Date__c = order.Pause_Start_Date__c;
                po.Reason_For_Pause__c = order.Reason_For_Pause__c;
                po.Campaign_Restart_Date__c = order.Campaign_Restart_Date__c;
                posToUpdate.add(po);
            }
        } 
        update posToUpdate;
    }

    void PopulateOptimisationDashboardReviewDates()
    {
        //List<businesshours> bhs =[SELECT id FROM BusinessHours where IsDefault = true];
        List<Order__c> orders = [select id,
                                        Actual_Start_Date__c, 
                                        Customer_Tier__c,
                                        Current_Campaign_Performance_Review_Date__c,
                                        Current_Dashboard_Review_Date__c,
                                        Current_Customer_Report_Date__c,
                                        Next_Campaign_Performance_Review_Date__c,
                                        Next_Dashboard_Review_Date__c,
                                        Next_Dashboard_Internal_Review_Date__c,
                                        Next_Customer_Report_Date__c FROM Order__c where id IN: setNextDashReviewDates];

        List<Campaign_Tier_Frequency__mdt> campaignFreqs = [select id, masterlabel, Dashboard_Review_Frequency__c,
            Performance_Review_Frequency__c, Report_Review__c from Campaign_Tier_Frequency__mdt];
        Map<string, Campaign_Tier_Frequency__mdt> tierWithFreq = new map<string, Campaign_Tier_Frequency__mdt>();
        
        for (Campaign_Tier_Frequency__mdt camTierFreq : campaignFreqs) {
            tierWithFreq.put(camTierFreq.masterlabel, camTierFreq);
        }

        for (order__c order : orders) {
            Campaign_Tier_Frequency__mdt camFrequency = tierWithFreq.get(order.Customer_Tier__c);
            if (camFrequency != null) {
                Date startdate;
                system.debug(order);

                    set<string> dashReview = new set<string>(camFrequency.Dashboard_Review_Frequency__c.split(' '));
                    system.debug(dashReview);
                    if (order.Current_Dashboard_Review_Date__c == null)
                        startdate = order.Actual_Start_Date__c;
                    else
                        startdate = order.Current_Dashboard_Review_Date__c;

                    if (dashReview.contains('month')) {
                        order.Next_Dashboard_Review_Date__c = 
                            startdate.addMonths(Integer.valueOf((new list<string>(dashReview) )[0]));
                            system.debug(order.Next_Dashboard_Review_Date__c);
                    }
                    else if (dashReview.contains('week')) {
                        order.Next_Dashboard_Review_Date__c = 
                            startdate.addDays((Integer.valueOf((new list<string>(dashReview) )[0])) * 7);
                    }
                    else if (dashReview.contains('day')) {
                        order.Next_Dashboard_Review_Date__c = 
                            startdate.addDays(Integer.valueOf((new list<string>(dashReview) )[0]));
                    }
                    if (order.Next_Dashboard_Review_Date__c != null) {
                        if (!bhs.isEmpty()) {
                            businesshours bh = bhs.get(0);
                            Long milSecs;
                            milSecs = (Long) (Integer.valueOf(daysbeforeDashReview)*-8*60*60*1000);
                            Datetime targetDateTime = BusinessHours.add(bh.Id, order.Next_Dashboard_Review_Date__c, milSecs);
                            date d = Date.newInstance(targetDateTime.year(), targetDateTime.month(), targetDateTime.day());
                            order.Next_Dashboard_Internal_Review_Date__c = d;
                        }
                        else {
                            order.Next_Dashboard_Internal_Review_Date__c = order.Next_Dashboard_Review_Date__c-3;
                        }
                    }
                }
        }


        update orders;
    }
    void PopulateOptimisationPerformanceReviewDates()
    {
        //List<businesshours> bhs =[SELECT id FROM BusinessHours where IsDefault = true];
        List<Order__c> orders = [select id,
                                        Actual_Start_Date__c, 
                                        Customer_Tier__c,
                                        Current_Campaign_Performance_Review_Date__c,
                                        Current_Dashboard_Review_Date__c,
                                        Current_Customer_Report_Date__c,
                                        Next_Campaign_Performance_Review_Date__c,
                                        Next_Dashboard_Review_Date__c,
                                        Next_Dashboard_Internal_Review_Date__c,
                                        Next_Customer_Report_Date__c FROM Order__c where id IN: setNextPerfReviewDates];
                                        
        system.debug(loggingLevel.ERROR, '####### orders before: ' + orders);                                

        List<Campaign_Tier_Frequency__mdt> campaignFreqs = [select id, masterlabel, Dashboard_Review_Frequency__c,
            Performance_Review_Frequency__c, Report_Review__c from Campaign_Tier_Frequency__mdt];
        Map<string, Campaign_Tier_Frequency__mdt> tierWithFreq = new map<string, Campaign_Tier_Frequency__mdt>();
        
        for (Campaign_Tier_Frequency__mdt camTierFreq : campaignFreqs) {
            tierWithFreq.put(camTierFreq.masterlabel, camTierFreq);
        }
        
        system.debug(loggingLevel.ERROR, '####### tierWithFreq: ' + tierWithFreq);  

        for (order__c order : orders) {
            Campaign_Tier_Frequency__mdt camFrequency = tierWithFreq.get(order.Customer_Tier__c);
             system.debug(loggingLevel.ERROR, '####### camFrequency: ' + camFrequency); 
            if (camFrequency != null) {
                Date startdate;
                system.debug(order);

                    set<string> perfReview = new set<string> (camFrequency.Performance_Review_Frequency__c.split(' '));
                    system.debug(loggingLevel.ERROR, '####### perfReview: ' + perfReview); 
                    system.debug(perfReview);
                    system.debug(loggingLevel.ERROR, '####### order.Current_Campaign_Performance_Review_Date__c: ' + order.Current_Campaign_Performance_Review_Date__c); 
                    if (order.Current_Campaign_Performance_Review_Date__c == null)
                        startdate = order.Actual_Start_Date__c;
                    else
                        startdate = order.Current_Campaign_Performance_Review_Date__c;

                    if (perfReview.contains('month')) {

                        order.Next_Campaign_Performance_Review_Date__c = 
                            startdate.addMonths(Integer.valueOf((new list<string>(perfReview) )[0]));
                        system.debug(order.Next_Campaign_Performance_Review_Date__c);
                    }
                    else if (perfReview.contains('week')) {
                        order.Next_Campaign_Performance_Review_Date__c = 
                            startdate.addDays((Integer.valueOf((new list<string>(perfReview) )[0])) * 7);
                    }
                    else if (perfReview.contains('day')) {
                        order.Next_Campaign_Performance_Review_Date__c = 
                            startdate.addDays(Integer.valueOf((new list<string>(perfReview) )[0]));
                    }
                    
                    system.debug(loggingLevel.ERROR, '####### order.Next_Campaign_Performance_Review_Date__c: ' + order.Next_Campaign_Performance_Review_Date__c); 
                }
        }

        system.debug(loggingLevel.ERROR, '####### orders ' + orders);
        update orders;
    }

    void PopulateOptimisationReportReviewDates()
    {
        //List<businesshours> bhs =[SELECT id FROM BusinessHours where IsDefault = true];
        List<Order__c> orders = [select id,
                                        Actual_Start_Date__c, 
                                        Customer_Tier__c,
                                        Current_Campaign_Performance_Review_Date__c,
                                        Current_Dashboard_Review_Date__c,
                                        Current_Customer_Report_Date__c,
                                        Next_Campaign_Performance_Review_Date__c,
                                        Next_Dashboard_Review_Date__c,
                                        Next_Dashboard_Internal_Review_Date__c,
                                        Next_Customer_Report_Date__c FROM Order__c where id IN: setNextReportReviewDates];

        List<Campaign_Tier_Frequency__mdt> campaignFreqs = [select id, masterlabel, Dashboard_Review_Frequency__c,
            Performance_Review_Frequency__c, Report_Review__c from Campaign_Tier_Frequency__mdt];
        Map<string, Campaign_Tier_Frequency__mdt> tierWithFreq = new map<string, Campaign_Tier_Frequency__mdt>();
        
        for (Campaign_Tier_Frequency__mdt camTierFreq : campaignFreqs) {
            tierWithFreq.put(camTierFreq.masterlabel, camTierFreq);
        }

        for (order__c order : orders) {
            Campaign_Tier_Frequency__mdt camFrequency = tierWithFreq.get(order.Customer_Tier__c);
            if (camFrequency != null) {
                Date startdate;
                system.debug(order);

                    set<string> reportReview = new set<string>(camFrequency.Report_Review__c.split(' '));
                    system.debug(reportReview);
                    if (order.Current_Customer_Report_Date__c == null)
                        startdate = order.Actual_Start_Date__c;
                    else
                        startdate = order.Current_Customer_Report_Date__c;
                    if (reportReview.contains('month')) {
                        order.Next_Customer_Report_Date__c = 
                            startdate.addMonths(Integer.valueOf((new list<string>(reportReview) )[0]));
                            system.debug(order.Next_Customer_Report_Date__c);
                    }
                    else if (reportReview.contains('week')) {
                        order.Next_Customer_Report_Date__c = 
                            startdate.addDays((Integer.valueOf((new list<string>(reportReview) )[0])) * 7);
                    }
                    else if (reportReview.contains('day')) {
                        order.Next_Customer_Report_Date__c = 
                            startdate.addDays(Integer.valueOf((new list<string>(reportReview) )[0]));
                    }
                }
        }


        update orders;
    }

    void PopulateOptimisationReviewDates()
    {
        //List<businesshours> bhs =[SELECT id FROM BusinessHours where IsDefault = true];
        List<Order__c> orders = [select id,
                                        Actual_Start_Date__c, 
                                        Customer_Tier__c,
                                        Current_Campaign_Performance_Review_Date__c,
                                        Current_Dashboard_Review_Date__c,
                                        Current_Customer_Report_Date__c,
                                        Next_Campaign_Performance_Review_Date__c,
                                        Next_Dashboard_Review_Date__c,
                                        Next_Dashboard_Internal_Review_Date__c,
                                        Next_Customer_Report_Date__c FROM Order__c where id IN: setNextReviewDates];

        List<Campaign_Tier_Frequency__mdt> campaignFreqs = [select id, masterlabel, Dashboard_Review_Frequency__c,
            Performance_Review_Frequency__c, Report_Review__c from Campaign_Tier_Frequency__mdt];
        Map<string, Campaign_Tier_Frequency__mdt> tierWithFreq = new map<string, Campaign_Tier_Frequency__mdt>();
        
        for (Campaign_Tier_Frequency__mdt camTierFreq : campaignFreqs) {
            tierWithFreq.put(camTierFreq.masterlabel, camTierFreq);
        }

        for (order__c order : orders) {
            Campaign_Tier_Frequency__mdt camFrequency = tierWithFreq.get(order.Customer_Tier__c);
            if (camFrequency != null) {
                Date startdate;
                system.debug(order);

                    set<string> perfReview = new set<string> (camFrequency.Performance_Review_Frequency__c.split(' '));
                    system.debug(perfReview);
                    if (order.Current_Campaign_Performance_Review_Date__c == null)
                        startdate = order.Actual_Start_Date__c;
                    else
                        startdate = order.Current_Campaign_Performance_Review_Date__c;

                    if (perfReview.contains('month')) {

                        order.Next_Campaign_Performance_Review_Date__c = 
                            startdate.addMonths(Integer.valueOf((new list<string>(perfReview) )[0]));
                        system.debug(order.Next_Campaign_Performance_Review_Date__c);
                    }
                    else if (perfReview.contains('week')) {
                        order.Next_Campaign_Performance_Review_Date__c = 
                            startdate.addDays((Integer.valueOf((new list<string>(perfReview) )[0])) * 7);
                    }
                    else if (perfReview.contains('day')) {
                        order.Next_Campaign_Performance_Review_Date__c = 
                            startdate.addDays(Integer.valueOf((new list<string>(perfReview) )[0]));
                    }

                    set<string> dashReview = new set<string>(camFrequency.Dashboard_Review_Frequency__c.split(' '));
                    system.debug(dashReview);
                    if (order.Current_Dashboard_Review_Date__c == null)
                        startdate = order.Actual_Start_Date__c;
                    else
                        startdate = order.Current_Dashboard_Review_Date__c;

                    if (dashReview.contains('month')) {
                        order.Next_Dashboard_Review_Date__c = 
                            startdate.addMonths(Integer.valueOf((new list<string>(dashReview) )[0]));
                            system.debug(order.Next_Dashboard_Review_Date__c);
                    }
                    else if (dashReview.contains('week')) {
                        order.Next_Dashboard_Review_Date__c = 
                            startdate.addDays((Integer.valueOf((new list<string>(dashReview) )[0])) * 7);
                    }
                    else if (dashReview.contains('day')) {
                        order.Next_Dashboard_Review_Date__c = 
                            startdate.addDays(Integer.valueOf((new list<string>(dashReview) )[0]));
                    }
                    if (order.Next_Dashboard_Review_Date__c != null) {
                        if (!bhs.isEmpty()) {
                            businesshours bh = bhs.get(0);
                            Long milSecs;
                            milSecs = (Long) (Integer.valueOf(daysbeforeDashReview)*-8*60*60*1000);
                            Datetime targetDateTime = BusinessHours.add(bh.Id, order.Next_Dashboard_Review_Date__c, milSecs);
                            date d = Date.newInstance(targetDateTime.year(), targetDateTime.month(), targetDateTime.day());
                            order.Next_Dashboard_Internal_Review_Date__c = d;
                        }
                        else {
                            order.Next_Dashboard_Internal_Review_Date__c = order.Next_Dashboard_Review_Date__c-3;
                        }
                    }

                    set<string> reportReview = new set<string>(camFrequency.Report_Review__c.split(' '));
                    system.debug(reportReview);
                    if (order.Current_Customer_Report_Date__c == null)
                        startdate = order.Actual_Start_Date__c;
                    else
                        startdate = order.Current_Customer_Report_Date__c;
                    if (reportReview.contains('month')) {
                        order.Next_Customer_Report_Date__c = 
                            startdate.addMonths(Integer.valueOf((new list<string>(reportReview) )[0]));
                            system.debug(order.Next_Customer_Report_Date__c);
                    }
                    else if (reportReview.contains('week')) {
                        order.Next_Customer_Report_Date__c = 
                            startdate.addDays((Integer.valueOf((new list<string>(reportReview) )[0])) * 7);
                    }
                    else if (reportReview.contains('day')) {
                        order.Next_Customer_Report_Date__c = 
                            startdate.addDays(Integer.valueOf((new list<string>(reportReview) )[0]));
                    }
                }
        }


        update orders;
    }


    void UpdateOpporunityOnProgress()
    {
        List<Opportunity> opps = [select id, Campaign_Progress__c, Campaign_Status__c from Opportunity where id IN: oppsUpdatedProgress.keySet() ];

        for (Opportunity opp : opps){
            opp.Campaign_Progress__c = oppsUpdatedProgress.get(opp.Id).Progress_Percentage__c;
            opp.Campaign_Status__c = oppsUpdatedProgress.get(opp.Id).Status__c;
        }

        update opps;
    }
    
    // http://dashboard.news.com.au/browse/NXRIII-109, CS
    void SetAccountName()
    {
        for (Account acc : [select Id, Name from Account where Id in :mapAccountToCOs.keySet()])
        {
            for (Order__c o : mapAccountToCOs.get(acc.Id))
                o.Account_Name__c = acc.Name;
        }       
    }

    void SetOverallStatus()
    {
        try {
            List<Campaign_Status__mdt> statusInforMetadata = [select id, MasterLabel, Overall_Status__c from Campaign_Status__mdt where MasterLabel IN: orderUpdatedStatus.values()];

            //PM_cs: NX-1487 start
            Set<Id> soIds = new Set<Id>();
            for (order__c campaign : orderUpdatedStatus.keySet()) {
                soIds.add(campaign.Sales_Order__c);
            }
            soIds.remove(null); //removing any null values if CO doesn't have an SO for some reason

            List<String> asActiveStatuses   = new List<String>{'Campaign Live', 'Paused','Pending For Cancel','Pending For Pause'};
            List<String> asInactiveStatuses = new List<String>{'Cancelled', 'Campaign Ended','Rejected'};
            List<string> dontTouchStatuses  = new List<String>();
            dontTouchStatuses.addAll(asActiveStatuses);
            dontTouchStatuses.addAll(asActiveStatuses);

            Map<Id,csmso__Sales_Order__c> salesOrderMap = new Map<Id, csmso__Sales_Order__c>([SELECT Id, Retracted_Date__c from csmso__Sales_Order__c WHERE ID IN: soIds]);

            Map<String, String> statusInfoMap = new Map<String, String>();
            for (Campaign_Status__mdt cstatusmetadata : statusInforMetadata)
                statusInfoMap.put(cstatusmetadata.masterlabel, cstatusmetadata.overall_status__c);

            for (order__c campaign : orderUpdatedStatus.keySet()) {
                String orderUpdatedStatus = orderUpdatedStatus.get(campaign);
                String overallStatus;

                if (salesOrderMap.get(campaign.Sales_Order__c).Retracted_Date__c != null && ! dontTouchStatuses.contains(orderUpdatedStatus) ) {
                    overallStatus = 'In-Revision';
                }
                else{
                    overallStatus = statusInfoMap.get(orderUpdatedStatus);
                }


                campaign.overall_status__c = overallStatus;
            }
        } catch(Exception ex)
        {
            ExLog.log(ex, 'config', new list<order__c>(orderUpdatedStatus.keySet()), 'Did not update overall status.');
        }
    }

    void UpdateEndDates() 
    {
        List<Product_Order__c> productOrders = [select id, order__c, order__r.Sales_Order__r.Retracted_Date__c, Product_Order_End_Date__c, Product_Order_Start_Date__c from Product_Order__c where Order__c IN: 
                                        newEndDateOnOrders.keySet()];
        if (!productOrders.isEmpty()) {
            for (Product_Order__c po : productOrders){
                po.Product_Order_End_Date__c = newEndDateOnOrders.get(po.Order__c);
            }
            update productOrders;
        }
    }

    //CSP T-33686 (4.10.2017)
    void UpdateCaseEndDates() 
    {
        List<Order__c> orders = [select id, End_Date__c from Order__c where Id IN: 
                                        newEndDateOnOrders.keySet()];
        if (!orders.isEmpty()) {
            for (Order__c o : orders)
                o.End_Date__c = newEndDateOnOrders.get(o.Id);
            update orders;
        }
    }
    //end CSP T-33686(4.10.2017)

    void UpdateStartDates() 
    {
        List<Product_Order__c> productOrders = [select id, order__c, order__r.Sales_Order__r.Retracted_Date__c, Product_Order_Start_Date__c, Product_Order_End_Date__c from Product_Order__c where Order__c IN: newStartDateOnOrders.keySet()];
        if (!productOrders.isEmpty()) {
            for (Product_Order__c po : productOrders){
                po.Product_Order_Start_Date__c = newStartDateOnOrders.get(po.Order__c);
            }
            update productOrders;
        }
    }
    
    void UpdatePONextDates() 
    {
        List<Product_Order__c> productOrders = [select id, order__c, Product_Order_Start_Date__c from Product_Order__c where Order__c IN: newActStartDateOnOrders.keySet()];
        if (!productOrders.isEmpty()) {
            for (Product_Order__c po : productOrders)
                po.Next_Business_Date__c = getNextBizDate(newActStartDateOnOrders.get(po.Order__c), System.Label.Number_Days_NextBizDate);  
                 
            update productOrders;
        }
    }    

    // KW: update product orders for orders retracted
    void updateProductOrdersForRestractedOrders(Map<Id, Order__c> orders){
        Boolean campaignLive = true;
        CS_RetractSalesOrderService.updateProductOrdersForRestractedOrders(orders.keySet(), campaignLive);                                           
    }

    void UpdateProductOrders(Map<Id, Order__c> orders)
    {
        List<Product_Order__c> productOrders = [select id, order__c, status__c, Type__c, Previous_Product_Order_Status__c from Product_Order__c where order__c in: orders.keySet()
                                                    AND status__c != 'Cancelled' AND Type__c != 'Unchanged (Fulfilled)'];

        Set<Id> goLiveCancelProdOrders = new Set<Id>();

        if (!productOrders.isEmpty()) {
            for (Product_Order__c po : productOrders) {

                if ( ( newLiveOrders.containsKey(po.Order__c)|| retractedNewLiveOrders.containsKey(po.Order__c) )
                        && (po.Status__c == 'Pending For Cancel' && po.Type__c == 'Delete') ) {
                    //NX-1490
                    po.Status__c = 'Cancellation Ready';
                    goLiveCancelProdOrders.add(po.Id);
                    continue;
                }

                if (newPausedOrders.get(po.Order__c) != null)
                    po.Status__c = newPausedOrders.get(po.Order__c).status__c;
                else if (newLiveOrders.get(po.Order__c) != null && po.Previous_Product_Order_Status__c != null)
                    po.Status__c = po.Previous_Product_Order_Status__c;
                else if (newLiveOrders.get(po.Order__c) != null && po.Previous_Product_Order_Status__c == null)
                    po.Status__c = 'Live';
                else if (newCancelOrders.get(po.Order__c) != null)
                    po.Status__c = newCancelOrders.get(po.Order__c).status__c;
                else if (ordersEnded.get(po.Order__c) != null){
                    po.Status__c = ordersEnded.get(po.Order__c).status__c;
                }else if (retractedNewLiveOrders.get(po.Order__c) != null && po.Previous_Product_Order_Status__c == null){
                    po.Status__c = 'Live';
                }
            }

            update productOrders;

            if (goLiveCancelProdOrders.size() > 0 ) {
                CSPOFA.Events.emit('update',goLiveCancelProdOrders);
            }
        }   
    }

    void CreateAppropriateOrchProcesses () 
    {
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();
        CS_OrchestratorUtil orchestratorUtil = new CS_OrchestratorUtil();

        for (Order__c order : ordersToTriggerOrch) {
            try {
                String orchLabel = '';
                if (order.Status__c == 'Pending For Pause')
                    orchLabel = 'Campaign Pause';
                else if (order.Status__c == 'Pending For Cancel')
                    orchLabel = 'Campaign Cancel';

                Set<String> templateLabels = productMapping.GetOrchProcessesNamesForLabel(orchLabel);

                for (String label : templateLabels) {
                    CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel (label);
                
                    CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                        Name = orchLabel, 
                                                                                                        Order__c = order.Id);           
                    processesToInsert.add(process); 
                    system.debug(processesToInsert);
                }
                firstRun = false;

            } catch (Exception e) {
                System.debug(e.getMessage());
            }
        }

        new CS_OpportunityTriggerDelegate.insertOrchProcesses().execute(processesToInsert);
    }
    
    Date getNextBizDate(Date givenDate, String custLabel)  
        {   
           Integer noOfDays = Integer.valueOf(custLabel); 
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
    // T-33686 CSP 2017-10-04
    
    @TestVisible static Date calculateNewEndDate( Date startDate, Date endDate, Date newStartDate)
        {
            Date newEndDate = Date.today();
            Integer numberOfDays = Date.daysInMonth(newStartDate.year(), newStartDate.month());
            Date lastDayOfTheMonth = Date.newInstance(newStartDate.year(), newStartDate.month(), (numberOfDays));
            Integer monthDifference = startDate.monthsBetween(endDate);
            newEndDate = Date.newInstance(newStartDate.year(), newStartDate.month(),1);
            newEndDate = newEndDate.addMonths(monthDifference);

            if(newEndDate.month()==2 && math.mod(newEndDate.year(),4)==0 && (newStartDate.day() == 29 || newStartDate.day() == 30 || newStartDate.day() == 31)){
                newEndDate = Date.newInstance(newStartDate.year(), newStartDate.month(),1);
                newEndDate = newEndDate.addMonths(monthDifference);
                numberOfDays = Date.daysInMonth(newEndDate.year(), newEndDate.month());
                newEndDate = newEndDate.addDays(numberOfDays-1);
            }
            else if(newEndDate.month()==2 && math.mod(newEndDate.year(),4)!=0 && (newStartDate.day() == 28 || newStartDate.day() == 29 || newStartDate.day() == 30 || newStartDate.day() == 31))
            {
                newEndDate = Date.newInstance(newStartDate.year(), newStartDate.month(),1);
                newEndDate = newEndDate.addMonths(monthDifference);
                numberOfDays = Date.daysInMonth(newEndDate.year(), newEndDate.month());
                newEndDate = newEndDate.addDays(numberOfDays-1);
            }else{
                newEndDate = newStartDate.addMonths(monthDifference);
            }
            Return newEndDate;
        }
    // T-33686 CSP 2017-10-04


    void TerminateRelatedProcesses(List<Id> idListToTerminateProcesses) 
    {
        List<CSPOFA__Orchestration_Process__c> allPs = [SELECT Id FROM CSPOFA__Orchestration_Process__c 
                                                        WHERE CSPOFA__Status__c != 'Complete' AND order__c IN: idListToTerminateProcesses];

        for (CSPOFA__Orchestration_Process__c process : allPs) {
            process.CSPOFA__Status__c  = 'Complete';
            process.CSPOFA__State__c = 'TERMINATED';
        }                                  
        update allPs;
    }

    //NX-249 - commented out by DD, this is not needed as terminating process will complete tasks
    void TerminateOrderOnlyTasks(List<Id> idListToTerminateProcesses) 
    {
        List<Task> tasks = [SELECT Id FROM Task WHERE IsClosed=false
            AND WhatId IN: idListToTerminateProcesses
            AND CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Do_Not_Kill__c=false];

        for (Task task : tasks) {
            task.Status = 'Cancelled';
        }                                  
        update tasks;
    }
    
    
    void UpdateReturnedToSalesOrderOpportunity(){//NX-220
        List<Opportunity> opportunityList=[SELECT StageName,Reason_Won_Lost__c FROM Opportunity WHERE Id IN:returnedToSalesOpportunityIdList];

        for(Opportunity opp:opportunityList){
            opp.StageName='Confirmed/Awaiting Bookings';
            opp.Reason_Won_Lost__c='';
        }
        if(!opportunityList.isEmpty())
            update opportunityList;
    }

    //Generalized this method to resue for any chatter post
    Public void PostToChatter(list<Order__c> chatterOrderList, string fieldToPost ){
    //void PostToChatter(){//NX-220
        ConnectApi.FeedItemInput feedItemInput;
        ConnectApi.MentionSegmentInput mentionSegmentInput;
        ConnectApi.MessageBodyInput messageBodyInput;
        ConnectApi.TextSegmentInput textSegmentInput;

        //for(Order__c campaignOrder:returnedToSalesOrdersToTerminateProcesses){
        for(Order__c campaignOrder:chatterOrderList){

            feedItemInput = new ConnectApi.FeedItemInput();
            mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            messageBodyInput = new ConnectApi.MessageBodyInput();
            textSegmentInput = new ConnectApi.TextSegmentInput();
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();


            mentionSegmentInput.id = campaignOrder.Sales_Representative__c;
            messageBodyInput.messageSegments.add(mentionSegmentInput);

            //textSegmentInput.text ='\n'+System.Label.Return_To_Sales_Chatter_Post_in_Opportunity_Content; NXRIII-346
            //NXRIII-346 Begin
            if(fieldToPost=='Notes_for_Failure__c'){
                //textSegmentInput.text ='\n'+System.Label.Return_To_Sales_Chatter_Post_in_Opportunity_Content;
                textSegmentInput.text ='\n'+System.Label.Return_To_Sales_Chatter_Post_in_Opportunity_Content+ '\n'+'Failure Notes: ' +campaignOrder.Notes_for_Failure__c;
            }else if(fieldToPost == 'Setup_Notes__c'){
                textSegmentInput.text ='\n'+ strChatterComments;

            }
            //NXRIII-346 End

            messageBodyInput.messageSegments.add(textSegmentInput);

            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            feedItemInput.subjectId = campaignOrder.Opportunity__c;

            ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
        }
    }

    /**
  * ───────────────────────────────────────────────────────────────────────────────────────────────┐
  * This method will compare the two strings and remove the common part of the string.
  * ────────────────────────────────────────────────────────────────────────────────────────────────
  * Date           NAME             DESCRIPTION
  * 08/02/2019 - Ashfaq Mohammed -  //NXRIII-346
  * ───────────────────────────────────────────────────────────────────────────────────────────────┘
  */

    Public string stringCompare(string str1 , string str2){
        string str3;
        if(str1==null && str2!=null){
            str3 = str2;
        }
        else if(str1!=null && str2!=null){
            str3 = str2.remove(str1);
        }
        return str3.trim();

    }


}