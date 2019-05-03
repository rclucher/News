public class CS_OpportunityTriggerDelegate extends CS_TriggerHandler.DelegateBase {
    public Map<Id, Opportunity> newlyClosedOneOpps;
    Map<Id, Opportunity> newlyClosedLostOpps;//NX-220
    List<Id> ordersToTerminateIdList;//NX-220
    CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();
    Map<Id, csmso__Sales_Order__c> salesOrderWithOpp;
    List<User> orchUsers;
    User orchUser;
    Set<string> states;
    //List<businesshours> bhs =[SELECT id FROM BusinessHours where IsDefault = true];
    List<businesshours> bhs;
    List<History_Tracking__c> historyTrackingList;

    public override void prepareBefore() {}
    public override void prepareAfter() {
        newlyClosedOneOpps = new Map<Id, Opportunity>();
        newlyClosedLostOpps = new Map<Id, Opportunity>();
        ordersToTerminateIdList=new List<Id>();
        historyTrackingList = new List<History_Tracking__c>();
        orchUsers = CS_Cache.defaultOrchestratorUser;
        if (!orchUsers.isEmpty())   
            orchUser = orchUsers[0];

    // NX R3 - after completion of staged go-live, this section can be removed
    // START
        SetSelectiveOrchestrator();
    // NX R3 - after completion of staged go-live, this section can be removed
    // END
    }

    // NX R3 - after completion of staged go-live, this section can be removed
    // START
    void SetSelectiveOrchestrator() 
    {
        Selective_Orchestrator_Fulfilment__mdt selective = [SELECT id, Selective__c, State_List__c
            FROM Selective_Orchestrator_Fulfilment__mdt WHERE MasterLabel ='Default' LIMIT 1];

        if (selective != null && selective.selective__c) {
            states = new Set<String>();
            if (selective.state_list__c != null && selective.state_list__c.contains(',')) {
                list<string> listStates = selective.state_list__c.split(',');
                states.addAll(listStates);
            }
            else {
                if (selective.state_list__c != null && !selective.state_list__c.equals(''))
                    states.add(selective.state_list__c);
            }
        }
    }
    // NX R3 - after completion of staged go-live, this section can be removed
    // END

    public override void beforeInsert(sObject o) {}
    public override void beforeUpdate(sObject old, sObject o) {}
    public override void beforeDelete(sObject o) {}

    public override void afterInsert(sObject o) {}
    public override void afterUpdate(sObject old, sObject o) {
        Opportunity newOpp = (Opportunity) o;
        Opportunity oldOpp = (Opportunity) old;

       
        /*if (newOpp.OpportunityGroup__c != null && newOpp.OpportunityGroup__c.equals('NewsXtend')
            && newOpp.StageName.equals('Closed Won') && !oldOpp.StageName.equals('Closed Won') )
            newlyClosedOneOpps.put (newOpp.Id, newOpp);
            
        */
       
        // 15/02/2018 MC: Removed logic for Opportunity Platform (Create CO if there is any Xtand product in SO)
        if (newOpp.StageName.equals('Closed Won') && !oldOpp.StageName.equals('Closed Won')){
            List<csmso__Sales_Order__c> soList = [SELECT Id, Name, Origin__c, Platform_Set__c, csmso__Status__c FROM csmso__Sales_Order__c WHERE csmso__Status__c in ('Manually Approved','Externally Approved') And csmso__Opportunity__c = :newOpp.ID];
            List<Order__c> existingReturnedToSalesCampaignOrderList=[SELECT Id FROM Order__c WHERE Opportunity__c=:newOpp.ID AND Status__c='Returned To Sales' AND Draft_Review_Passed__c !='No'];//NX-220 // expanded to ignore OA  orders NX-1486
            
            if(!soList.isEmpty()){
                csmso__Sales_Order__c so = soList.get(0);
                if(so.Platform_Set__c != null && so.Platform_Set__c.contains('Xtend')){
                    newlyClosedOneOpps.put(newOpp.Id, newOpp);

                    if ( String.isEmpty(so.Origin__c) || so.Origin__c == 'Salesforce') {
                        //kw: order amendment - history tracking
                        History_Tracking__c historyTracking = CS_HistoryTrackingService.createHistoryTracking('Sales Order', so.Id, 'Opportunity Closed/Won', false, true);
                        historyTrackingList.add(historyTracking);

                    }
                }

            }
            if(!existingReturnedToSalesCampaignOrderList.isEmpty()){//NX-220
                for(Order__c campaignOrder:existingReturnedToSalesCampaignOrderList){
                    ordersToTerminateIdList.add(campaignOrder.id);
                }
                newlyClosedOneOpps.put(newOpp.Id, newOpp);
            }
        }else if(newOpp.StageName.equals('Closed Lost') && !oldOpp.StageName.equals('Closed Lost')){//NX-220
            List<Order__c> existingReturnedToSalesCampaignOrderList=[SELECT Id FROM Order__c WHERE Opportunity__c=:newOpp.ID AND Status__c='Returned To Sales' AND Draft_Review_Passed__c !='No'];//NX-220 // expanded to ignore OA  orders NX-1486
            if(!existingReturnedToSalesCampaignOrderList.isEmpty()){
                for(Order__c campaignOrder:existingReturnedToSalesCampaignOrderList){
                    ordersToTerminateIdList.add(campaignOrder.id);
                }
                newlyClosedLostOpps.put(newOpp.Id, newOpp);
            }
        }

    }
    public override void afterDelete(sObject o) {}

    public override void finish() {
        if (trigger.isAfter) {
            if (!newlyClosedOneOpps.isEmpty()) {
                CreateResetOrders ();

                if ( ! historyTrackingList.isEmpty() ) {
                    CS_HistoryTrackingService.enqueueHistorySnapshotCreation(historyTrackingList);
                }
            }
            if (!newlyClosedLostOpps.isEmpty())//NX-220
                RejectOrders ();
            if(!ordersToTerminateIdList.isEmpty()){//NX-220
                TerminateProductOrders(ordersToTerminateIdList);
            }
        }
    }

    public without sharing class insertOrchProcesses {
        public void execute(List<CSPOFA__Orchestration_Process__c> procList) {
            insert procList;        
        }
    }
    
    void RejectOrders(){//NX-220
        List<Order__c> rejectCampaignOrders =new List<Order__c>();
        List<Order__c> existingOrders = [SELECT Id, Opportunity__c, Proposed_Start_Date__c,Status__c,Draft_Review_Passed__c FROM Order__c WHERE Opportunity__c IN: newlyClosedLostOpps.keySet()];

        for(Order__c item : existingOrders){
            if(item.Status__c=='Returned To Sales' && item.Draft_Review_Passed__c!='No'){//NX-220
                item.Status__c='Rejected';
                rejectCampaignOrders.add(item);
            }
        }
        
        if(!rejectCampaignOrders.isEmpty()){
            update rejectCampaignOrders;
        }
    }

    public void CreateResetOrders () {
        Map<Id, Order__c> newOrderForOpp = new Map<Id, Order__c>();
        
        List<Order__c> existingOrders = [SELECT Id, Actual_Start_Date__c, Assigned_Campaign_Manager__c, Draft_Review_Passed__c , End_Date__c,  
                                                Opportunity__c, Opportunity__r.Amount,Status__c, Proposed_Start_Date__c, 
                                                Sales_Order__r.Retracted_Date__c, Sales_Order__r.Retraction_On__c, Sales_Order__r.Campaign_End_Date2__c , Sales_Order__r.Campaign_Start_Date__c, 
                                                Sales_Start_Date__c
                                        FROM Order__c 
                                        WHERE Opportunity__c IN: newlyClosedOneOpps.keySet()];
        Map<Id, Boolean> orderExistForOpp = new Map<Id, Boolean>();
        List<Order__c> startnewCampaignSetupOrchProcess =new List<Order__c>();
        List<Order__c> startInactiveSetupOrchProcess =new List<Order__c>(); //NX-1379
        salesOrderWithOpp = new Map<Id, csmso__Sales_Order__c>();

        Map<Id,csmso__Sales_Order__c> salesOrders = new Map<Id,csmso__Sales_Order__c>([SELECT Id, Origin__c, Campaign_Name__c, Campaign_Start_Date__c, csmso__Opportunity__c, csmso__Opportunity__r.account.tier__c, 
                                                        Recurring_Price__c, Campaign_End_Date__c, Campaign_End_Date2__c, Previous_Campaign_Start_Date__c, Previous_Campaign_End_Date__c, Retraction_On__c
                                                FROM csmso__Sales_Order__c
                                                WHERE csmso__Opportunity__c IN: newlyClosedOneOpps.keySet() 
                                                        AND (csmso__Status__c = 'Manually Approved' 
                                                        OR csmso__Status__c = 'Externally Approved')]);

        //MC 20/02/2018 - NXRIII-244
        // PM 13/03/2019 - NX-1477 (need same logic for proposed start date in Order trigger, moved code to separate method);
        Date proposedDate = getCalculatedProposedStartDate();

        Set<Id> nonliveOrderRetractedList = new Set<Id>();
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();
        CS_OrchestratorUtil orchestratorUtil = new CS_OrchestratorUtil();
        if (!existingOrders.isEmpty()) {
            List<Id> orderIds = new List<Id>();
            for (Order__c order : existingOrders) {
                orderIds.add(order.Id);
            }
            List<CSPOFA__Orchestration_Process__c> existingProcesses = [SELECT      Id, Order__c 
                                                                        FROM        CSPOFA__Orchestration_Process__c
                                                                        WHERE       Order__c IN: orderIds
                                                                        AND         Name = 'Campaign Retraction'
                                                                        AND         (CSPOFA__Status__c = 'In Progress' OR CSPOFA__Status__c = 'Initializing')];
            Map<Id, Boolean> existingRetractedProcesses = new Map<Id, Boolean>();                                                                  
            for (CSPOFA__Orchestration_Process__c process : existingProcesses) {
                existingRetractedProcesses.put(process.Order__c, true);
            } 
            String setupNotesFlag = '';

            for (Order__c order : existingOrders) {
                //GenericHelper_Dummy.ChatterPost(new Opportunity(Id=order.Opportunity__c),'C/W Happened with an exisitng Campaign Order ' + order.Id);
                orderExistForOpp.put (order.Opportunity__c, true);
                system.debug('**** order='+order);
                // for order amendment

                if(order.Sales_Order__r.Retracted_Date__c != null ) {

                    order.Status__c='Draft'; // udpated
                    order.Overall_status__c='In-Revision';
                    order.Accept_Retraction_Change__c = false;
                    order.Draft_Review_Passed__c=null;
                    
                    if (existingRetractedProcesses.get(order.id) == null || !existingRetractedProcesses.get(order.id)) {
                        Set<String> templateLabels = productMapping.GetOrchProcessesNamesForLabel('Campaign Retraction');
                        if(!templateLabels.isEmpty()){
                            CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel (
                                new List<String>(templateLabels)[0]);
                            if (template != null) {
                                CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                                    Name = 'Campaign Retraction', 
                                                                                                                    Order__c = order.Id);           
                                processesToInsert.add(process); 
                            }
                        }
                    }   
                    continue;
                }


                // Fix for BAU NXRIII-346 which might fail since Setup_Notes__c is required on Proposed_StartDate change
                setupNotesFlag= ( proposedDate != order.Proposed_Start_Date__c ) ? 'ToDo': '';
                //Fix for BAU NXRIII-346 end
                order.Proposed_Start_Date__c = proposedDate;

                if(order.Status__c=='Returned To Sales' && order.Draft_Review_Passed__c!='No' && order.Sales_Order__r.Retracted_Date__c == null){//NX-220
                    order.Setup_Notes__c = (setupNotesFlag == 'ToDo')
                                            ?
                                            'Returned To Sales process changed the Proposed Start Date to ' + proposedDate.format()
                                            :
                                            '';
                    order.Status__c='Draft';
                    order.Assigned_Campaign_Manager__c=null;
                    order.Draft_Review_Passed__c=null;
                    order.QA_Check_Approved__c=null;
                    order.Setup_Completed__c=false;
                    order.Actual_Start_Date__c=null;
                    order.Monthly_Dashboard_Review_Date_Int__c=null;
                    order.Weekly_Internal_Campaign_Review_Date_Int__c=null;
                    order.Is_Schedule_Payments_Button_Pushed__c=null;
                    order.Is_Start_All_Fulfilment_Button_Pushed__c=null;
                    order.Is_Container_Tag_Button_Pushed__c=null;
                    startnewCampaignSetupOrchProcess.add(order);
                }

                // kw: update campaign order after retraction (inactive campaign)
                if(order.Sales_Order__r.Retraction_On__c != null) {
                    if(order.Sales_Order__r.Retraction_On__c == 'Inactive Campaign'){
                        order.Setup_Notes__c = (setupNotesFlag== 'ToDo')
                                ?
                                'Updated Inactive Campaign changed the Proposed Start Date to ' + proposedDate.format()
                                :
                                '';
                        order.Status__c='Draft';
                        //GenericHelper_Dummy.ChatterPost(order, 'Updated Inactive Campaign to Draft post C/W. Notes:' + Order.Setup_Notes__c);
                        nonliveOrderRetractedList.add(order.Id);
                        startInactiveSetupOrchProcess.add(order);
                    }
                }
            }

            if (!processesToInsert.isEmpty()) {
                insert processesToInsert;
            }
        }

        for (csmso__Sales_Order__c so : salesOrders.values())
            salesOrderWithOpp.put(so.csmso__Opportunity__c, so);
        List<Order__c> selectedOrchOrders = new list<Order__c>();
        for (Id oppId : newlyClosedOneOpps.keySet()) {
            if (!orderExistForOpp.containsKey(oppId) && salesOrderWithOpp.containsKey(oppId)) {
                Decimal recPrice = salesOrderWithOpp.get(oppId).Recurring_Price__c;
                string tier = GetTierLevel (recPrice);
                if (recPrice == 0 || tier == '') {
                    tier = salesOrderWithOpp.get(oppId).csmso__Opportunity__r.account.tier__c;
                    if (tier == null || tier == '')
                        tier = 'Tier 3';
                }

                String campaignName = (salesOrderWithOpp.get(oppId) != null && salesOrderWithOpp.get(oppId).Campaign_Name__c !=  null && salesOrderWithOpp.get(oppId).Campaign_Name__c != '') ? salesOrderWithOpp.get(oppId).Campaign_Name__c : 'Order for '+ newlyClosedOneOpps.get(oppId).Name;
                //Boolean evergreen = (salesOrderWithOpp.get(oppId).Campaign_End_Date__c==null ? true : false);
                Boolean evergreen = (salesOrderWithOpp.get(oppId).Campaign_End_Date2__c==null ? true : false);
                String status = (salesOrderWithOpp.get(oppId).Origin__c != null && salesOrderWithOpp.get(oppId).Origin__c != 'Salesforce') ? 'Campaign Live'
                                                                                                                                            : 'Draft';
                Date actualStartDate = (salesOrderWithOpp.get(oppId).Origin__c == null || salesOrderWithOpp.get(oppId).Origin__c == '' || salesOrderWithOpp.get(oppId).Origin__c == 'Salesforce')   
                                        ? null
                                        : salesOrderWithOpp.get(oppId).Campaign_Start_Date__c;
                 system.debug(actualStartDate);
                  //added new field Industry_CodeCO__c while creation of the campaign order */
                Order__c orderRec = new Order__c (
                                                  Opportunity__c = oppId,
                                                  Account__c = newlyClosedOneOpps.get(oppId).AccountId,
                                                  Status__c = status,
                                                  Sales_Order__c = salesOrderWithOpp.get(oppId).Id,
                                                  Proposed_Start_Date__c = proposedDate, //salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                  Sales_Start_Date__c = salesOrderWithOpp.get(oppId).Campaign_Start_Date__c,
                                                  //End_Date__c = salesOrderWithOpp.get(oppId).Campaign_End_Date__c,
                                                  End_Date__c = salesOrderWithOpp.get(oppId).Campaign_End_Date2__c,
                                                  Sales_Representative__c = newlyClosedOneOpps.get(oppId).OwnerId,
                                                  State__c = newlyClosedOneOpps.get(oppId).Owner_Division__c,
                                                  Customer_Contact__c = newlyClosedOneOpps.get(oppId).Contact__c,
                                                  Total_Amount_GST_Excl__c = newlyClosedOneOpps.get(oppId).Amount,
                                                  Industry_Code__c = newlyClosedOneOpps.get(oppId).Industry_Code__c,
                                                  Industry_CodeCO__c = newlyClosedOneOpps.get(oppId).Industry_Code__c,
                                                  Evergreen__c = evergreen,
                                                  actual_start_date__c = actualStartDate,
                                                  Customer_Tier__c = tier);
                if (orchUser != null) {
                    orderRec.Integration_User__c = orchUser.Id;
                    orderRec.OwnerId = orchUser.Id;
                }
                system.debug ('** ivana **'  + orderRec);

                newOrderForOpp.put (oppId, orderRec);
                /*
                if (states != null && orderRec.state__c != null ) {
                    string orderState = orderRec.state__c.trim();
                    if (!states.isEmpty() && states.contains(orderState)) {
                        selectedOrchOrders.add(orderRec);
                    }
                }
                else if (orderRec.state__c == null && states != null && !states.isEmpty())
                    selectedOrchOrders.addAll(newOrderForOpp.values());
                else if (states == null)
                    selectedOrchOrders.addAll(newOrderForOpp.values());
                    */
                    if (salesOrderWithOpp.get(oppId).Origin__c == null || salesOrderWithOpp.get(oppId).Origin__c == '' || salesOrderWithOpp.get(oppId).Origin__c == 'Salesforce') {
                    selectedOrchOrders.add(orderRec);
                }     
                system.debug (selectedOrchOrders);
            }
        }
        try {
            if (!newOrderForOpp.values().isEmpty()) {
                insert newOrderForOpp.values();
                system.debug ('** ivana **'  + newOrderForOpp.values());
                CreateCampaignSetupOrchProcessForOrders (selectedOrchOrders);
                UtilMethods.CreateProductOrders (newOrderForOpp, salesOrderWithOpp);
            } 

             if (!existingOrders.isEmpty()) {//NX-220
                update existingOrders;
                if(!startnewCampaignSetupOrchProcess.isEmpty()){
                    CreateCampaignSetupOrchProcessForOrders(startnewCampaignSetupOrchProcess);
                }
                
                // update product orders for retracted campaign orders (non-live)
                if(!nonliveOrderRetractedList.isEmpty()){
                    //terminate processes for old CO/PO's
                    terminateInactiveCampaignOrchProcesses(nonliveOrderRetractedList);

                    Boolean campaignLive = false;
                    CS_RetractSalesOrderService.updateProductOrdersForRestractedOrders(nonliveOrderRetractedList, campaignLive);

                    if( !startInactiveSetupOrchProcess.isEmpty() ) {
                        CreateCampaignSetupOrchProcessForOrders(startInactiveSetupOrchProcess);
                    }
                }
             }
        } catch(Exception ex) {
            ExLog.log(ex, 'config', newOrderForOpp.values(), 'Could not create campaign orders');
        }
        
    }

    private String GetTierLevel (Decimal price) {
        List<Customer_Tier_Ranges__c> tierRanges = Customer_Tier_Ranges__c.getall().values();
        for (Customer_Tier_Ranges__c tierRange: tierRanges)
        {                           
            if ((price != null) && (price >= tierRange.Lowerbound__c) && (price <= tierRange.Upperbound__c)) {
                return tierRange.Name;
            }
        }
        return '';
    }

    void CreateCampaignSetupOrchProcessForOrders (List<Order__c> orders) 
    {
        CS_OrchestratorUtil orchestratorUtil = new CS_OrchestratorUtil();

        // Expecting only one process for each Order, but in place if multiple
        Set<String> templateLabels = productMapping.GetOrchProcessesNamesForLabel('Campaign Setup');
        List<CSPOFA__Orchestration_Process__c> processesToInsert = new List<CSPOFA__Orchestration_Process__c>();

        try {
            for (String label : templateLabels) {
                CSPOFA__Orchestration_Process_Template__c template = orchestratorUtil.GetProcessTemplateForLabel (label);
                
                for (Order__c order : orders) {
                    CSPOFA__Orchestration_Process__c process =  new CSPOFA__Orchestration_Process__c (  CSPOFA__Orchestration_Process_Template__c = template.Id, 
                                                                                                        Name = 'Campaign Setup', 
                                                                                                        Order__c = order.Id);           
                    processesToInsert.add(process); 
                }

                new insertOrchProcesses().execute(processesToInsert);
            }
        } 
        catch(Exception ex)
        {
            ExLog.log(ex, 'config', orders, 'Orchestrator processes were not created for these campaigns');
        }
    }
    
    void TerminateProductOrders(List<Id> campaignOrderIdList){//NX-220
        List<Id> idListToTerminateProcesses=new List<Id>();
        List<Product_Order__c> productOrderList =[SELECT Id,additional_comment_for_social_setup__c,additional_comment__c,approved_by_client__c,assigned_fulfilment_owner_for_qa__c,
                                                    assigned_fulfilment_owner__c,briefing_form_not_valid_for_social_setup__c,briefing_form_not_valid__c,briefing_form_valid_for_social_setup__c,
                                                    briefing_form_valid__c,current_optimisation_date__c,current_social_go_live__c,current_social_kick_off__c,isNextBizDateRecalLanding__c,is_content_plan_sufficient__c,
                                                    is_creative_required__c,peer_review_passed__c,post_go_live_review__c,qa_check_passed__c,social_content_plan_approved__c,social_recurring_status__c,status__c
                                                    FROM Product_Order__c 
                                                    WHERE Order__c IN: campaignOrderIdList];

        for(Product_Order__c prodOrder:productOrderList){
            prodOrder.additional_comment_for_social_setup__c='';
            prodOrder.additional_comment__c='';
            prodOrder.approved_by_client__c=null;
            prodOrder.assigned_fulfilment_owner_for_qa__c=null;
            prodOrder.assigned_fulfilment_owner__c=null;
            prodOrder.briefing_form_not_valid_for_social_setup__c=null;
            prodOrder.briefing_form_not_valid__c=null;
            prodOrder.briefing_form_valid_for_social_setup__c=null;
            prodOrder.briefing_form_valid__c=null;
            prodOrder.current_optimisation_date__c=null;
            prodOrder.current_social_go_live__c=null;
            prodOrder.current_social_kick_off__c=null;
            prodOrder.isNextBizDateRecalLanding__c=false;
            prodOrder.is_content_plan_sufficient__c=null;
            prodOrder.is_creative_required__c=null;
            prodOrder.peer_review_passed__c=null;
            prodOrder.post_go_live_review__c=null;
            prodOrder.qa_check_passed__c=null;
            prodOrder.social_content_plan_approved__c=false;
            prodOrder.social_recurring_status__c=null;
            prodOrder.status__c='Draft';

            idListToTerminateProcesses.add(prodOrder.id);
        }

        if(!idListToTerminateProcesses.isEmpty()){
            TerminateRelatedProcesses(idListToTerminateProcesses);
            //TerminateOrderOnlyTasks(idListToTerminateProcesses);
            update productOrderList;
        }
    }

    void TerminateRelatedProcesses(List<Id> idListToTerminateProcesses){ //NX-220
        List<CSPOFA__Orchestration_Process__c> allPs = [SELECT Id FROM CSPOFA__Orchestration_Process__c 
                                                        WHERE CSPOFA__Status__c != 'Complete' AND Product_Order__c IN: idListToTerminateProcesses];

        for (CSPOFA__Orchestration_Process__c process : allPs) {
            process.CSPOFA__Status__c  = 'Complete';
            process.CSPOFA__State__c = 'TERMINATED';
        }                                  
        update allPs;
    }
    
    void TerminateOrderOnlyTasks(List<Id> idListToTerminateProcesses){ //NX-220
        List<Task> tasks = [SELECT Id FROM Task WHERE Status NOT IN ('Completed','Done','Cancelled') 
            AND WhatId IN: idListToTerminateProcesses
            AND CSPOFA__Orchestration_Step__r.CSPOFA__Orchestration_Step_Template__r.Do_Not_Kill__c=false];

        for (Task task : tasks) {
            task.Status = 'Cancelled';
        }                                  
        update tasks;
    }
    // pm: Moved  proposedDate calculation to static method for NX-1477
    public static Date getCalculatedProposedStartDate() {

        Date proposedDate;

        String proposedStartDate = System.Label.Proposed_Start_Date;

        List<businesshours> bhs = CS_Cache.defaultBusinessHours;

        if (!bhs.isEmpty()) {
            businesshours bh = bhs.get(0);
            Long milSecs;
            milSecs = (Long) (Integer.valueOf(proposedStartDate)*8*60*60*1000);
            Datetime targetDateTime = BusinessHours.add(bh.Id, Date.today(), milSecs);
            date d = Date.newInstance(targetDateTime.year(), targetDateTime.month(), targetDateTime.day());
            proposedDate = d;
        } else {
            proposedDate = Date.today().addDays(Integer.valueOf(proposedStartDate));
        }

        return proposedDate;
    }

    // pm: Method used to terminate all processeses * after C/W * on retracted inactive campaign (NX-1379)
    void terminateInactiveCampaignOrchProcesses(Set<Id> coIds) {
        List<Product_Order__c> prodOrders = [SELECT Id FROM Product_Order__c WHERE Order__c IN: coIds];

        List<CSPOFA__Orchestration_Process__c> allPs = [SELECT Id FROM CSPOFA__Orchestration_Process__c
        WHERE CSPOFA__Status__c != 'Complete' AND (Product_Order__c IN: prodOrders OR Order__c IN:coIds ) ];

        for (CSPOFA__Orchestration_Process__c process : allPs) {
            process.CSPOFA__Status__c  = 'Complete';
            process.CSPOFA__State__c = 'TERMINATED';
        }
        update allPs;

    }

}