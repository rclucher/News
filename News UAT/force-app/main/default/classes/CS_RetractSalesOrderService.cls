/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_RetractSalesOrderService
* @testClassName    CS_RetractSalesOrderServiceTest
* @description      Service class for sales order retraction
*/
public without sharing class  CS_RetractSalesOrderService {
	final static String ERROR_MESSAGE_NO_CAMP = 'Sales Order cannot be retracted for one of the following reasons:   1. Sales Order is not Manually Approved OR  2. Associated Campaign is not Live yet. Please Clone Opportunity to make edits';
	final static String ERROR_MESSAGE_CANT_RETRACT = 'Sales Order cannot be retracted';
    final static String CAMPAIGN_NOT_RETRACTABLE = 'It is not possible to retract the sales order due to the campaign status.';
    final static String CAMPAIGN_IN_FULFILLMENT = 'You cannot retract this Sales Order because this Campaign is In-SetUp.';
    final static String ERROR_MESSAGE_SO_RETRACT_FAIL = 'Error occured. Failed to retract Sales Order.';
	final static String SUCCESS_MESSAGE_SO_RETRACT = 'Sales Order retracted.';
    final static String USER_NO_PERMISSION = 'You cannot retract this Sales Order. Please contact your Campaign Co-Ordinator.';
    final static String DBL_RETRACT_ON_LIVE_CO = 'You cannot retract this Sales Order again. The previous Live campaign was retracted and currently in revision.';


    /**
    * @name         : retract
    * @description  : retract a sales order
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String salesOrderId
    * @return       : String
    */
	public static String retract(String salesOrderId){
		Order__c order;
        csmso__Sales_Order__c salesOrder;

        List<csmso__Sales_Order__c> soList = [Select csmso__Status__c, Id, Campaign_Start_Date__c, Campaign_End_Date__c, csmso__Opportunity__c, 
                                                csmso__Opportunity__r.StageName, Retraction_On__c, 
                                                (Select Id, Assigned_Campaign_Manager__c, Overall_Status__c, Status__c, Opportunity_Closed_Won_Date__c From Orders__r)
                                            From csmso__Sales_Order__c
                                            Where   Id = :salesOrderId
                                                    AND Origin__c != 'Campaign Track'
                                                    AND (csmso__Status__c = 'Manually Approved' 
                                                    OR csmso__Status__c = 'Externally Approved')  Limit 1];

        if(soList.isEmpty()){
            throw new RetractSalesOrderException(ERROR_MESSAGE_CANT_RETRACT);
        }else{
            salesOrder = soList.get(0);
            if(!salesOrder.Orders__r.isEmpty()){
                order = salesOrder.Orders__r;
            }
        }

        Boolean campaignActive = false;
        if(order != null){


            if( order.Overall_Status__c == 'Active'         &&
                    (order.Status__c == 'Campaign Live' || order.Status__c == 'Paused' || order.Status__c == 'Pending For Cancel' || order.Status__c == 'Pending For Pause')){
                campaignActive = true;

            }
            // campaign in-SetUp
            // not including returned to sales as that is a BAU process
            else if(order.Status__c == 'Draft' || order.Status__c == 'Ready for Review'  || order.Status__c == 'In Progress'){
                campaignActive = salesOrder.Retraction_On__c == 'Active Campaign' ? true : false;

                //no double retract on live campaign, CR as part of NX-1499
                if (campaignActive) {
                    throw new RetractSalesOrderException(DBL_RETRACT_ON_LIVE_CO);
                }

                if(!validateUser()){
                    throw new RetractSalesOrderException(USER_NO_PERMISSION);
                }

                Id userId = order.Assigned_Campaign_Manager__c != null ? order.Assigned_Campaign_Manager__c : UserInfo.getUserId();

                String taskSubject = Label.OA_Halt_Live_Campaign_Task_Subject; //PetarM NX-1378 'Halt any further campaign processing';
                String taskSummary = Label.OA_Halt_Live_Campaign_Task_Summary; //PetarM NX-1378  'Sales Order Undergoing Retraction. Please halt any further processing.';
                CS_RetractSalesOrderServiceHelper.createTaskForCampaignRetracted(userId, order.Id, taskSubject, taskSummary);
                

                

            }else if(order.Status__c == 'Fulfilment Started' || order.Status__c == 'Fulfilment Ready'){
                throw new RetractSalesOrderException(CAMPAIGN_IN_FULFILLMENT);

            }else if(order.Status__c == 'Paused' || order.Status__c == 'Cancelled' || order.Status__c == 'Rejected' || order.Status__c == 'Campaign Ended'){
                throw new RetractSalesOrderException(CAMPAIGN_NOT_RETRACTABLE);

            }else{
                throw new RetractSalesOrderException(ERROR_MESSAGE_CANT_RETRACT);
            }
        }

        handleRetraction(salesOrder, campaignActive);

		return SUCCESS_MESSAGE_SO_RETRACT;
	}

    /**
    * @name         : handleRetraction
    * @description  : handle retraction by updating sales order and opportunity
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : csmso__Sales_Order__c salesOrder, Boolean campaignActive
    * @return       : n/a
    */
    public static void handleRetraction(csmso__Sales_Order__c salesOrder, Boolean campaignActive){
        // update fields on opportunity
        CS_RetractSalesOrderServiceHelper.updateOpportunityPostRetraction(salesOrder.csmso__Opportunity__c, campaignActive);

        // update fields on so
        csmso__Sales_Order__c updatedSO = CS_RetractSalesOrderServiceHelper.updateSalesOrderPostRetraction(salesOrder, campaignActive);
        
        // remove one off products if the retraction is on live campaign
        if(campaignActive && salesOrder.Retraction_On__c != 'Active Campaign' ){
            CS_RetractSalesOrderServiceHelper.deleteOneOffProduct(updatedSO);
        }

        //NX-1504 archived products
        Map<id,cscfga__Product_Configuration__c> catalogItemPcMap = buildCatalogToProductConfigurationMap(updatedSO, null);

        if ( updatedLineItemsArchivedFlag(catalogItemPcMap) ) {
            updatedSO.csmso__Status__c = 'Retraction Blocked';
            update updatedSO;

        }

    }

    /**
    * @name         : validateUser
    * @description  : validate if the user has permission to retract sales order
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : n/a
    * @return       : Boolean
    */
    public static Boolean validateUser(){
        return CS_RetractSalesOrderServiceHelper.checkRetractSOPermission('News_Xtend_Retract_SO_Group', UserInfo.getUserId());
    }


    /**
    * @name         : updatePaymentSchedules
    * @description  : update payment records including payment, payment schedules and payment line itmes
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Map<Id, Order__c> ordersMa
    * @return       : n/a
    */
    public static void updatePaymentSchedules(Map<Id, Order__c> ordersMap){
        List<Payment__c> payments = [SELECT Id, Order__c, Order__r.End_Date__c, Order__r.Sales_Order__c, Start_Date__c, End_Date__c, 
                                            Order__r.Actual_Start_Date__c, Order__r.Sales_Order__r.Campaign_Length__c, Order__r.Evergreen__c
                                     FROM Payment__c
                                     WHERE Order__c IN: ordersMap.keySet()];
        if(payments.isEmpty()){
            return;
        }

        Map<String, Payment__c> coPaymentMap = new Map<String,Payment__c>();
        for(Payment__c p: payments){
            p.Sales_Order__c = p.Order__r.Sales_Order__c;
            p.Previous_Start_Date__c = p.Start_Date__c;
            p.Previous_End_Date__c = p.End_Date__c;
            p.Revision_Date__c = System.today();
            p.Status__c = 'Revised';
            p.Start_Date__c = p.Order__r.Actual_Start_Date__c;

            if (p.Order__r.Evergreen__c) {
                p.End_Date__c = null;
                //included clearing of the fields on the payment as part of NX-1619 (reverted part of PaymentTriggerDelegate, only trigger code remained for NX-1508
                p.Cancellation_Reason__c ='';
                p.Minimum_Evergreen_Cancellation_Date__c = null;
                p.Cancelled_Date__c = null;
                p.Cancellation_Reason_Notes__c = null;
                p.End_Date__c = null;

            } else {
                p.End_Date__c = p.Order__r.End_Date__c;
                //p.Cancellation_Reason__c ='Seasonal campaign with pre-defined end date'; // this was original see NX-1509/NX-1508 but is a Prod issue to be fixed by BAU

            }

            coPaymentMap.put(p.Order__c, p);
        }
        update payments;

        // delete all the pending payment schedule records
        List<Payment_Schedule__c> oldPsList = [SELECT  Id, Payment__c, Status__c, 
                                                     (SELECT Id FROM Payment_Line_Items__r)
                                            FROM    Payment_Schedule__c
                                            WHERE   Status__c = 'Pending' 
                                            AND     Payment__r.Order__c IN: ordersMap.keySet()];
        if(!oldPsList.isEmpty()){
            delete oldPsList;
        }

        List<Payment_Schedule__c> newPsList = new List<Payment_Schedule__c>();  // all the ps to insert
        Map<Payment__c, List<CS_RetractSalesOrderServiceHelper.PaymentScheduleWrapper>> psPaymentMap 
                = new Map<Payment__c, List<CS_RetractSalesOrderServiceHelper.PaymentScheduleWrapper>>();  // key: payment record, value: list of ps
        for(Order__c order: ordersMap.values()){
            List<CS_RetractSalesOrderServiceHelper.PaymentScheduleWrapper> psWrapList 
                = CS_RetractSalesOrderServiceHelper.createPaymentSchedules(order, coPaymentMap.get(order.Id) );
            for(CS_RetractSalesOrderServiceHelper.PaymentScheduleWrapper psWrap: psWrapList){
                newPsList.add(psWrap.paymentSchedule);
            }

            //newPsList.addAll(psList);

            Payment__c payment = coPaymentMap.get(order.Id);
            psPaymentMap.put(payment, psWrapList);
        }

        if(!newPsList.isEmpty()){
            insert newPsList;
        }
 
        List<Payment_Line_Item__c> allPaymentLines = new List<Payment_Line_Item__c>();
        for(Payment__c payment: psPaymentMap.keySet()){
             List<CS_RetractSalesOrderServiceHelper.PaymentScheduleWrapper> psWrapList = psPaymentMap.get(payment);

            csmso__Sales_Order__c salesOrder = new csmso__Sales_Order__c();
            salesOrder.Id = payment.Order__r.Sales_Order__c;
            List<Payment_Line_Item__c> paymentLines = CS_RetractSalesOrderServiceHelper.createPaymentLineItem(salesOrder, psWrapList);
            allPaymentLines.addAll(paymentLines);
        }

        if(!allPaymentLines.isEmpty()){
            insert allPaymentLines;
        }

    }

    /**
    * @name         : updateProductOrdersForRestractedOrders
    * @description  : update product orders after changed values get  populated onto campaign order
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Set<Id> orderIds, Boolean campaignActive
    * @return       : n/a
    */
	public static void updateProductOrdersForRestractedOrders(Set<Id> orderIds, Boolean campaignActive){
		Map<ID, Order__c> orders = new Map<ID, Order__c>([SELECT Id, Sales_Order__c, Sales_Order__r.Campaign_Start_Date__c, Sales_Order__r.Campaign_End_Date2__c, Sales_Order__r.Call_Tracking__c,
                                                                    Sales_Order__r.Previous_Campaign_Start_Date__c, Sales_Order__r.Previous_Campaign_End_Date__c
															FROM Order__c 
															WHERE Id IN: orderIds]);

		List<Product_Order__c> allExistingPOs = [SELECT 	Id, Order__c, Order__r.Sales_Order__c, Order__r.Sales_Order__r.GST_Tax__c, PC_Id__c, Product_Order_Start_Date__c, Product_Order_End_Date__c,
                                                            Product_Node__c, Retail_Rate__c , RecordTypeId, RecordType.DeveloperName, Product_Node__r.Product_Type__c,
                                                            Product_Configuration__r.One_Off_Price__c,Type__c
												FROM		Product_Order__c
												WHERE		Order__c  IN: orderIds
                                                ORDER BY  RecordType.Name DESC]; //added sort by record type name to ensure call tracking is on bottom (at least bellow SEM)

		// get existing product orders (that have not been updated)
		// key: sales order id
		// value: a list of product orders
		Map<Id, List<Product_Order__c>> allExistingPOsBySo = new Map<Id, List<Product_Order__c>>();
		for(Product_Order__c po: allExistingPOs){
			List<Product_Order__c> poList;
			if(allExistingPOsBySo.containsKey(po.Order__r.Sales_Order__c)){
				poList = allExistingPOsBySo.get(po.Order__r.Sales_Order__c);
			}else{
				poList = new List<Product_Order__c>();
			}

			poList.add(po);
			allExistingPOsBySo.put(po.Order__r.Sales_Order__c, poList);
		}



		// group all the CO by SO 
		Map<Id, Order__c> allExistingCOsBySo = new Map<Id, Order__c>();
		for(Order__c order: orders.values()){
			allExistingCOsBySo.put(order.Sales_Order__c, order);
		}

		Map<ID, cscfga__Product_Configuration__c> productConfigs
												= new Map<ID, cscfga__Product_Configuration__c>([SELECT Id, Product_ID__c, cscfga__Product_Basket__r.csmso__Sales_Order__c, Total_Invoice__c
									        		FROM cscfga__Product_Configuration__c 
									        		WHERE cscfga__Product_Basket__r.csmso__Sales_Order__c IN: allExistingCOsBySo.keySet() 
									            	AND  Line_Item_Platform__c = 'Xtend']);
		// get all product configurations (new)
		// key: sales order id
		// value: the list of product configurations
		Map<Id, List<cscfga__Product_Configuration__c>> allPcBySo = new Map<Id, List<cscfga__Product_Configuration__c>>();
	    // set of product nodes Id
		Set<Id> pnIds = new Set<Id>();
		// iterate all the product configuration records
        for(cscfga__Product_Configuration__c pc: productConfigs.values()){
        	List<cscfga__Product_Configuration__c> pcList 
        		= allPcBySo.containsKey(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c) 
				? allPcBySo.get(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c)
				: new List<cscfga__Product_Configuration__c>();

			pcList.add(pc);
			pnIds.add(pc.Product_ID__c);
			allPcBySo.put(pc.cscfga__Product_Basket__r.csmso__Sales_Order__c, pcList);
        }

        // list of all the product nodes 
	    Map<Id,sObject> pnList = new Map<Id, SObject>();
	    List<csmso__Product_Node__c> productNodes = [SELECT Id, Product_Line__c, Product_Type__c, Provider__c,
                                                            Network__c, Product_Groups_For_IO__c,
                                                            Do_Not_Create_Product_Order__c
	    											FROM 	csmso__Product_Node__c 
	    											WHERE Id IN: pnIds];
	    pnList.putAll(productNodes);


        // all the product orders that need to be updated
        List<Product_Order__c> poListUpsert = new List<Product_Order__c>();

        // the list of product orders that need to be deleted (for inactive campaign scenario, decided byt the flag passed in)
        List<Product_Order__c> poListDelete = new List<Product_Order__c>();

        // the list of product orders to refresh once they get revised (inactive campaign scenario)
        Set<Id> poIdsRefresh = new Set<Id>();

        // this is used to get the record type of the new po 
        CS_ProductMappingMetadataUtil productMapping = new CS_ProductMappingMetadataUtil();

        // store all the order ids that needs updating for the renewal scenario
        Set<Id> updateOrderIdsForRenewal = new Set<Id>();

        Id callTrackingRTId = UtilMethods.getRecordTypeId('Product_Order__c.Call Tracking');
        Id SEMRecordTypeID = Product_Order__c.getSObjectType().getDescribe().getRecordTypeInfosByName().get('Search Engine Marketing').getRecordTypeId();

        // handle all the sales order one by one
        for(Id soId: allExistingCOsBySo.keySet()){
        	List<Product_Order__c> oldPoList = allExistingPOsBySo.get(soId);
        	List<cscfga__Product_Configuration__c> newPcList = allPcBySo.get(soId);
        	Set<String> oldPcIds = new Set<String>();
            Order__c co = allExistingCOsBySo.get(soId);
            
            Boolean callTrackPoExist = false;   // indicate whether a call tracking po exists
            Boolean isSoRenewed = true;   // indicate whether it is a renew scenario
            List<Product_Order__c> poListUpsertTemp = new List<Product_Order__c>();
            Boolean callTrackingRequired = co.Sales_Order__r.Call_Tracking__c;  // indicate whether a call tracking po is required to create
            Boolean isCallTrackingPO = false;
            Boolean isCallTrackingFromLineItem = false;
            Boolean hasSEMBeenDeleted = false;

            // iterate all the original product orders to decide the type of the change
        	for(Product_Order__c po: oldPoList){
        		oldPcIds.add(po.PC_Id__c);

                if(campaignActive){
                    po.Previous_Product_Order_Start_Date__c = po.Product_Order_Start_Date__c;
                    po.Previous_Product_Order_End_Date__c   = po.Product_Order_End_Date__c;
                    po.Reset_QA_Items__c					= 'Yes'; // being introduced to be handled during QA Checklist creation.
                }

                // handle removed pc
                isCallTrackingPO = (po.RecordTypeId == callTrackingRTId);
                iscallTrackingFromLineItem = (isCallTrackingPo && !String.isEmpty(po.PC_Id__c)); //differentiate call tracking line from a checkbox created PO

        		if( ! productConfigs.containsKey(po.PC_Id__c) && !isCallTrackingPO) { // po doesn't exist in new pc list, skipping call tracking

                        if (po.RecordTypeId == SEMRecordTypeID) {
                            hasSEMBeenDeleted = true;
                        }

                        if ( campaignActive ){

                            if(po.Product_Configuration__r.One_Off_Price__c > 0 ){ // NX-1480
                                po.Type__c = 'Unchanged (Fulfilled)';  // if it is a one-off product

                            } else {

                                po.Status__c    = 'Draft';
                                po.Type__c      = 'Delete';



                                isSoRenewed = false; // Deletion of a non one off product shouldn't be a Renewal
                            }

                            poListUpsertTemp.add(po);
                        }
                        else {
                            poListDelete.add(po);
                        }
                        
                        continue;


        		}

                // handling call tracking
                if ( isCallTrackingPO ) {
                    callTrackPoExist = true;
                    if(campaignActive) {   // NX-1491 PM added check for active Campaigns

                            po.Type__c = 'Unchanged (Fulfilled)';

                    } else {

                        po.Status__c    = 'Draft';

                        //NX-1613 will delete CAll Tracking only if SEM deleted in setup and call tracking no longer required
                        if (hasSEMBeenDeleted && !callTrackingRequired) {
                            //po.Type__c      = 'Delete';
                            poListDelete.add(po);
                            continue;
                        }
                    }
                    poListUpsertTemp.add(po);
                    continue;
                }

                // do this only for campaign that ever went live
                if(campaignActive){
                    // get the current pc to decide the type of the change
                    cscfga__Product_Configuration__c newPc = productConfigs.get(po.PC_Id__c);

                    if(newPc != null && po.RecordTypeId != callTrackingRTId){
                        Decimal newPcInvoiceAmount = newPc.Total_Invoice__c;
                        Decimal oldPoInvoiceAmount = po.Retail_Rate__c;

                        Boolean updatedExistingProductOrder =  false;


                        //po.Delta_Amount_GST_Exclusive__c = newPcInvoiceAmount - oldPoInvoiceAmount;
                        //po.Delta_Amount_GST_Inclusive__c = po.Delta_Amount_GST_Exclusive__c * (1+ po.Order__r.Sales_Order__r.GST_Tax__c/100);
                        //po.Delta_Duration__c = '';

                        // check if it is an upgrade here
                        if(newPcInvoiceAmount > oldPoInvoiceAmount){
                            po.Type__c      = 'Upgrade';
                            updatedExistingProductOrder = true;
                        }
                        // check if it is a downgrade here
                        else if(newPcInvoiceAmount < oldPoInvoiceAmount){
                            po.Type__c      = 'Downgrade';
                            updatedExistingProductOrder = true;
                        }

                        if ( updatedExistingProductOrder ) {
                            //ensure product node update
                            if ( po.Product_Node__c != newPc.Product_ID__c ) {
                                po.Product_Node__c = newPc.Product_ID__c;
                            }

                            po.Status__c    = 'Draft';
                            po.Assigned_Fulfilment_Owner_For_QA__c = null;
                            poListUpsertTemp.add(po);
                            isSoRenewed = false;
                            continue;

                        }
                    }

                    // check if it is a renewal here
                    system.debug('co.Sales_Order__r.Previous_Campaign_End_Date__c='+co.Sales_Order__r.Previous_Campaign_End_Date__c);
                    system.debug('co.Sales_Order__r.Campaign_End_Date2__c='+co.Sales_Order__r.Campaign_End_Date2__c);

                    // seasonal --> seasonal, old end date > new end date
                    if(co.Sales_Order__r.Previous_Campaign_End_Date__c != null && co.Sales_Order__r.Campaign_End_Date2__c != null && co.Sales_Order__r.Campaign_End_Date2__c < co.Sales_Order__r.Previous_Campaign_End_Date__c){
                        isSoRenewed = false;
                    }

                    // seasonal --> seasonal, old end date == new end date, invalid scenario
                    if(co.Sales_Order__r.Previous_Campaign_End_Date__c != null && co.Sales_Order__r.Campaign_End_Date2__c != null && co.Sales_Order__r.Campaign_End_Date2__c == co.Sales_Order__r.Previous_Campaign_End_Date__c){
                        isSoRenewed = false;
                    }
                    
                    // seasonal --> seasonal, old end date < new end date
                    if(co.Sales_Order__r.Previous_Campaign_End_Date__c != null && co.Sales_Order__r.Campaign_End_Date2__c != null && co.Sales_Order__r.Previous_Campaign_End_Date__c < co.Sales_Order__r.Campaign_End_Date2__c){
                        // this is a valid renewal, do nothing
                    }

                    // seasonal --> evergreen
                    if(co.Sales_Order__r.Previous_Campaign_End_Date__c != null && co.Sales_Order__r.Campaign_End_Date2__c == null){
                        // this is a valid renewal, do nothing
                    }

                    // evergreen --> evergreen
                    if(co.Sales_Order__r.Previous_Campaign_End_Date__c == null && co.Sales_Order__r.Campaign_End_Date2__c == null){
                        isSoRenewed = false;
                    }

                    // evergreen --> seasonal, invalid scenario, technically this is a cancellation
                    if(co.Sales_Order__r.Previous_Campaign_End_Date__c == null && co.Sales_Order__r.Campaign_End_Date2__c != null){
                        isSoRenewed = false;
                    }
                    system.debug('isSoRenewed='+isSoRenewed);
                    
                    // update the type to be unchanged
                    po.Status__c    = 'Draft';
                    po.Type__c      = 'Unchanged';
                    poListUpsertTemp.add(po);
                }else{
                    poIdsRefresh.add(po.Id);
                }
        		
        	}

        	// iterate the list of new pc to identify the new pc
        	for(cscfga__Product_Configuration__c pc: newPcList){
                Boolean stopProdOrderCreation =  (Boolean) pnList.get(pc.Product_ID__c).get('Do_Not_Create_Product_Order__c'); //NX-1615

        		if(!oldPcIds.contains(pc.Id) && !stopProdOrderCreation){

        			// create a new po here
        			Id poRecordTypeId = CS_RetractSalesOrderServiceHelper.getPoRecordTypeId(pnList.get(pc.Product_ID__c), productMapping);
        			Product_Order__c newPO = CS_RetractSalesOrderServiceHelper.createNewProductOrder(co, pc, poRecordTypeId);
        			poListUpsertTemp.add(newPO);
                    isSoRenewed = false;
        		}
        	}

            if(callTrackingRequired && !callTrackPoExist){
                Product_Order__c callTrackingPo = CS_RetractSalesOrderServiceHelper.createCallTrackingProductOrder(co, callTrackingRTId);
                poListUpsertTemp.add(callTrackingPo);
                isSoRenewed = false;
            }

            if(!poListUpsertTemp.isEmpty()){
                if(isSoRenewed && campaignActive){
                    
                    for(Product_Order__c po: poListUpsertTemp ) {
                        //
                        isCallTrackingPO = (po.RecordTypeId == callTrackingRTId);

                        if( isCallTrackingPO || po.Product_Configuration__r.One_Off_Price__c > 0 ) {
                            po.Type__c = 'Unchanged (Fulfilled)'; // one offs on Renewal should remain Unchanged
                            continue;
                        }

                        po.Type__c = 'Renew';
                    }
                }
                poListUpsert.addAll(poListUpsertTemp);
            }

        }


        if(!poListUpsert.isEmpty()){
            CS_CampaignRetractionHelper.emptyProductOrderFields(poListUpsert);
        	upsert poListUpsert;
        }

        if(!poListDelete.isEmpty()){
            delete poListDelete;
        }

        if(!poIdsRefresh.isEmpty()){
            CS_ProductOrderTriggerDelegate td = new CS_ProductOrderTriggerDelegate();
            td.populateFieldFromProductConfigurationAfterRevision(poIdsRefresh);
        }

        //if(!updateOrderIdsForRenewal.isEmpty()){
        //    List<Order__c> ordersUpdateForRenewal = new  List<Order__c>();
        //    for(Id orderId: updateOrderIdsForRenewal){
        //        Order__c order = new Order__c();
        //        order.Id = orderId;
        //        order.Change_Category__c = 'Renewal';
        //        order.Related_Order__c = orderId;
        //        order.Change_Comment__c = 'This campaign order is under renewal.';
        //        ordersUpdateForRenewal.add(order);
        //    }
        //    update ordersUpdateForRenewal;
        //}

	}



    /**
     *
     * @author      : Petar Mikic
     * @date        : 2019/04/08
     * @description : Used to update flag on each line item if any item is archived
     * @param pcList
     */
    public static Boolean updatedLineItemsArchivedFlag(Map<Id,cscfga__Product_Configuration__c> catalogueIdsToPCMap) {

        List<csmso__Product_Node__c> product_nodes = [SELECT Id, Is_Active__c
                                                      FROM csmso__Product_Node__c
                                                      WHERE Id IN: catalogueIdsToPCMap.keySet() AND Is_Active__c = false];
        // exit if no archived product nodes
        if ( product_nodes.isEmpty() ) {
            return false;
        }

//        Boolean trueWhenNotTesting = true;
          List<cscfga__Product_Configuration__c> pcsToUpdate = new List<cscfga__Product_Configuration__c>();
//
//        if(catalogueIdsToPCMap.keySet().contains(null)){
//            trueWhenNotTesting = false;
//        }

        for (csmso__Product_Node__c pn: product_nodes) {

            cscfga__Product_Configuration__c tempPC = catalogueIdsToPCMap.get(pn.Id);
            tempPC.IsArchived_Catalogue_Item__c = true;

            pcsToUpdate.add(tempPC);
        }

        update pcsToUpdate;

        return true;
    }


    public static Map<Id, cscfga__Product_Configuration__c> buildCatalogToProductConfigurationMap(csmso__Sales_Order__c so, List<cscfga__Product_Configuration__c> pcList) {
        Map<Id,cscfga__Product_Configuration__c> catalogueIdsToPCMap = new Map<Id, cscfga__Product_Configuration__c>();

        if (pcList == null) {
             pcList = [SELECT Id, Product_ID__c
                       FROM   cscfga__Product_Configuration__c
                       WHERE  cscfga__Product_Basket__r.csmso__Sales_Order__c =: so.Id];
        }

        for (cscfga__Product_Configuration__c pc: pcList) {
            catalogueIdsToPCMap.put(pc.Product_ID__c,pc);
        }

        return catalogueIdsToPCMap;
    }



	public class RetractSalesOrderException extends Exception {}
}