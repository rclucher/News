/**
* @author           Kevin Wu
* @date             2018-10-01
* @className        CS_RetractSalesOrderServiceHelper
* @testClassName    CS_RetractSalesOrderServiceTest
                    CS_RetractSalesOrderServiceHelperTest
* @description      Service helper class for sales order retraction
*/
public without sharing class CS_RetractSalesOrderServiceHelper {


    /**
    * @name         : updateOpportunityPostRetraction
    * @description  : update fields on opportunity post retraction
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Id oppyId
    * @return       : Opportunity
    *
    * revision 1    : Petar Mikic - Updated on 19th of Feb 2019 to include campaignActive flag, and set Opp dates
    */
    public static Opportunity updateOpportunityPostRetraction(Id oppyId, Boolean campaignActive){
        Opportunity oppy = new Opportunity();
        oppy.Id = oppyId;
        oppy.StageName = 'Confirmed/Awaiting Bookings';
        oppy.Has_an_Approved_SO__c = false;
        oppy.Approved_Sales_Order_Number__c = null;
        oppy.Campaign_Brief_Form_Completed__c = false;

        //PetarM OA update dates on Opp when Active campaign
        if (campaignActive) {
            oppy.CloseDate          = Date.today().addDays(10);
            oppy.Retraction_Date__c = Date.today();
        }

        update oppy;
        return oppy;
    }

    /**
    * @name         : updateSalesOrderPostRetraction
    * @description  : update fields on sales order post retraction
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : csmso__Sales_Order__c so, Boolean campaignActive
    * @return       : csmso__Sales_Order__c
    */
    public static csmso__Sales_Order__c updateSalesOrderPostRetraction(csmso__Sales_Order__c so, Boolean campaignActive){
        // indicate if the retraction is inside an existing retraction 
        Boolean inRetration = (so.Retraction_On__c == 'Active Campaign');

        csmso__Sales_Order__c salesOrder = new csmso__Sales_Order__c();

        Order__c campaignOrder = (!so.Orders__r.isEmpty()) ? so.Orders__r : null; // to check for order on inactivecampaign

        salesOrder.Id = so.Id;
        if(campaignActive){
            salesOrder.csmso__Status__c ='Retracted';
            salesOrder.Retraction_On__c = 'Active Campaign';
            salesOrder.Retracted_Date__c = System.today();

            if(!inRetration){
                salesOrder.Previous_Campaign_Start_Date__c  = so.Campaign_Start_Date__c;
                salesOrder.Previous_Campaign_End_Date__c    = so.Campaign_End_Date__c;
                salesOrder.Previous_Opp_CW_Date__c          = campaignOrder.Opportunity_Closed_Won_Date__c; //NX-1534, in this context Order.Opportunity_Closed_Won_Date__c was retrieved before OPP closedates updates
                salesOrder.Notes__c                 = null;
                salesOrder.Retraction_Cache_Data__c = CS_ReinstateSalesOrderService.backUpData(salesOrder);
            }

        }else{
            salesOrder.csmso__Status__c ='Draft';
            salesOrder.Retraction_On__c = ( campaignOrder != null)?  'Inactive Campaign' : ''; // only set this if retraction happened post order creation
            salesOrder.Notes__c = null;
        }

        salesOrder.Campaign_Start_Date__c   = null; // OA CR: NX-1567, common for Live and non Live
        salesOrder.Campaign_Length__c       = null;

        update salesOrder;
        return salesOrder;
    }

    /**
    * @name         : deleteOneOffProduct
    * @description  : delete one-off product(s) that have been fulfilled post retration
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : csmso__Sales_Order__c so
    * @return       : n/a
    */
    public static void deleteOneOffProduct(csmso__Sales_Order__c so){
        if(String.isBlank(so.Retraction_Cache_Data__c)) return;
        String cachedData = CS_ReinstateSalesOrderServiceHelper.getAttachmentContent(so.Retraction_Cache_Data__c);
        Map<String, List<SObject>> cacheDataMap = (Map<String, List<SObject>>)JSON.deserialize(cachedData, Map<String, List<SObject>>.class);

        //restore attributes
        List<cscfga__Attribute__c> attrList = (List<cscfga__Attribute__c>)cacheDataMap.get('attr');

        List<cscfga__Product_Configuration__c> pcDeleteList = new List<cscfga__Product_Configuration__c>();
        for(cscfga__Attribute__c attr: attrList){
            if (attr.Name != null && attr.cscfga__Value__c != null && attr.Name == 'Payment Type' && attr.cscfga__Value__c == 'One Off') {
                cscfga__Product_Configuration__c pc = new cscfga__Product_Configuration__c( Id = attr.cscfga__Product_Configuration__c);
                pcDeleteList.add(pc);
            }
        }
        delete pcDeleteList;
    }

    /**
    * @name         : createAdditionalPaymentSchedule
    * @description  : create payment schedules records
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Order__c order, Payment__c payRec
    * @return       : PaymentScheduleWrapper
    */
    public static PaymentScheduleWrapper createAdditionalPaymentSchedule(Order__c order, Payment__c payRec){
        PaymentScheduleWrapper psWrapper;
        Payment_Schedule__c payRecSch;

        Date actualStartDate = order.Actual_Start_Date__c;
        Date previousActualStartDate = order.Previous_Actual_Start_Date__c;
        Integer previousActualStartDateDay = previousActualStartDate.day();

        Date startDateThisPS = date.newInstance(actualStartDate.year(), actualStartDate.month(), previousActualStartDateDay);
        if(startDateThisPS > actualStartDate){
            startDateThisPS = startDateThisPS.addMonths(-1);
        }
        Date endDateThisPS = startDateThisPS.addMonths(1);
        Date billingDate = endDateThisPS.toStartOfMonth().addDays(-1);
        system.debug('***** actualStartDate=' + actualStartDate);
        system.debug('***** previousActualStartDate=' + previousActualStartDate);
        system.debug('***** startDateThisPS=' + startDateThisPS);
        system.debug('***** endDateThisPS=' + endDateThisPS);
        system.debug('***** billingDate=' + billingDate);


        if(order.Actual_Start_Date__c != null && order.Actual_Start_Date__c >= billingDate){
            payRecSch = new Payment_Schedule__c();

            Datetime dateTimeStarttemp = order.Actual_Start_Date__c;
            Date dateStartTemp = Date.newInstance(dateTimeStarttemp.year(),dateTimeStarttemp.month(),dateTimeStarttemp.day());
            String campStartDate =dateStartTemp.format();

            Date dateEndTemp = endDateThisPS;
            String campEndDate =dateEndTemp.format();

            payRecSch.Name = 'Payment Schedule - '+campStartDate+' - '+ campEndDate;
            payRecSch.Schedule_End_Date__c = date.parse(campEndDate);
            payRecSch.Status__c = 'Pending';
            payRecSch.Schedule_Start_Date__c = date.parse(campStartDate);
            payRecSch.Payment__c = payRec.id;

            psWrapper = new PaymentScheduleWrapper(payRecSch, true, true);
        }else if(order.Actual_Start_Date__c != null && order.Actual_Start_Date__c < billingDate){
            payRecSch = new Payment_Schedule__c();

            Date dateStartTemp = startDateThisPS;
            String campStartDate =dateStartTemp.format();

            Datetime dateTimeEndtemp = order.Actual_Start_Date__c;
            Date dateEndTemp = Date.newInstance(dateTimeEndtemp.year(),dateTimeEndtemp.month(),dateTimeEndtemp.day());
            String campEndDate =dateEndTemp.format();

            payRecSch.Name = 'Payment Schedule - '+campStartDate+' - '+ campEndDate;
            payRecSch.Schedule_End_Date__c = date.parse(campEndDate);
            payRecSch.Status__c = 'Pending';
            payRecSch.Schedule_Start_Date__c = date.parse(campStartDate);
            payRecSch.Payment__c = payRec.id;

            psWrapper = new PaymentScheduleWrapper(payRecSch, false, true);
        }

        return psWrapper;
    }

    /**
    * @name         : createCallTrackingProductOrder
    * @description  : create a product order for call tracking
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Order__c co, Id callTrackingRTId
    * @return       : Product_Order__c
    */
    public static Product_Order__c createCallTrackingProductOrder(Order__c co, Id callTrackingRTId){
        Product_Order__c callTrackingPo = new Product_Order__c();
        callTrackingPo.Order__c = co.Id;
        callTrackingPo.Status__c = 'Draft';
        callTrackingPo.Type__c = 'New';
        callTrackingPo.Product_Order_Start_Date__c = co.Sales_Order__r.Campaign_Start_Date__c;
        callTrackingPo.Product_Order_End_Date__c = co.Sales_Order__r.Campaign_End_Date2__c;
        callTrackingPo.RecordTypeId = callTrackingRTId;
        callTrackingPo.Impressions_Factor__c = 1;

        return callTrackingPo;
    }

    /**
    * @name         : getPoRecordTypeId
    * @description  : retrieve the record type Id of product order 
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : SObject productNode, CS_ProductMappingMetadataUtil productMapping
    * @return       : Id
    */
    public static Id getPoRecordTypeId(SObject productNode, CS_ProductMappingMetadataUtil productMapping){
        String recordTypeLabel = UtilMethods.getRecordTypeIdentifierForProduct (productNode, productMapping);
        Id recordTypeId = UtilMethods.getRecordTypeId('Product_Order__c.'+recordTypeLabel);
        return recordTypeId;
    }

    /**
    * @name         : createNewProductOrder
    * @description  : create product order records for newly added product 
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Order__c co, cscfga__Product_Configuration__c pc, Id poRecordTypeId
    * @return       : Product_Order__c
    */
    public static Product_Order__c createNewProductOrder(Order__c co, cscfga__Product_Configuration__c pc, Id poRecordTypeId){
        Product_Order__c newProduct = new Product_Order__c();
        newProduct.Order__c 		= co.Id;
        newProduct.PC_Id__c 		= String.valueOf(pc.Id);
        newProduct.Product_Configuration__c =  pc.Id;
        newProduct.Status__c 		= 'Draft';
        newProduct.Type__c 			= 'New';
        newProduct.Product_Node__c 	= pc.Product_ID__c;
        newProduct.Impressions_Factor__c 		= 1;
        if(poRecordTypeId != null){
            newProduct.Product_Order_Start_Date__c 	= co.Sales_Order__r.Campaign_Start_Date__c;
            newProduct.Product_Order_End_Date__c 	= co.Sales_Order__r.Campaign_End_Date2__c;
            newProduct.RecordTypeId 				= poRecordTypeId;
        }

        return newProduct;
    }

    /**
    * @name         : createPaymentSchedules
    * @description  : create payment schedule records
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : Order__c orderRec, Payment__c payRec
    * @return       : List<PaymentScheduleWrapper>
    */
    public static List<PaymentScheduleWrapper> createPaymentSchedules(Order__c orderRec, Payment__c payRec){
        List<PaymentScheduleWrapper> psWrapList = new List<PaymentScheduleWrapper>();
        if(payRec==null){
            return psWrapList;
        }

        if(orderRec.End_Date__c != null && payRec.Order__r.Sales_Order__r.Campaign_Length__c!= null){
            for(Integer i = 0; i < payRec.Order__r.Sales_Order__r.Campaign_Length__c; i++){
                Payment_Schedule__c payRecSch = new Payment_Schedule__c();

                Datetime dateTimeStarttemp = orderRec.actual_start_date__c.addMonths(i);
                Date dateStartTemp = Date.newInstance(dateTimeStarttemp.year(),dateTimeStarttemp.month(),dateTimeStarttemp.day());
                String campStartDate =dateStartTemp.format();

                Datetime dateTimeEndtemp = orderRec.actual_start_date__c.addMonths(i+1);
                Date dateEndTemp = Date.newInstance(dateTimeEndtemp.year(),dateTimeEndtemp.month(),dateTimeEndtemp.day());
                String campEndDate =dateEndTemp.format();

                payRecSch.Name = 'Payment Schedule - '+campStartDate+' - '+ campEndDate;
                payRecSch.Schedule_End_Date__c = date.parse(campEndDate);
                payRecSch.Status__c = 'Pending';
                payRecSch.Schedule_Start_Date__c = date.parse(campStartDate);
                payRecSch.Payment__c = payRec.id;

                psWrapList.add(new PaymentScheduleWrapper(payRecSch));
            }

        }
        //T-29839 15/2/17 NF Start
        else if ((orderRec.End_Date__c == null) && (orderRec.Sales_Order__r.Recurring_Price__c == 0 )){
            Payment_Schedule__c payRecSch = new Payment_Schedule__c();

            Datetime dateTimeStarttemp = orderRec.actual_start_date__c.addMonths(0);
            Date dateStartTemp = Date.newInstance(dateTimeStarttemp.year(),dateTimeStarttemp.month(),dateTimeStarttemp.day());
            String campStartDate =dateStartTemp.format();

            Datetime dateTimeEndtemp = orderRec.actual_start_date__c.addMonths(1);
            Date dateEndTemp = Date.newInstance(dateTimeEndtemp.year(),dateTimeEndtemp.month(),dateTimeEndtemp.day());
            String campEndDate =dateEndTemp.format();

            payRecSch.Name = 'Payment Schedule - '+campStartDate+' - '+ campEndDate;
            payRecSch.Schedule_End_Date__c = date.parse(campEndDate);
            payRecSch.Status__c = 'Pending';
            payRecSch.Schedule_Start_Date__c = date.parse(campStartDate);
            payRecSch.Payment__c = payRec.id;

            psWrapList.add(new PaymentScheduleWrapper(payRecSch));

        }
        //T-29839 15/2/2017 NF End
        else{
            Integer paymentScheduleTime = Order_PaymentSchedulerController.paymentScheduleTime != null ? Order_PaymentSchedulerController.paymentScheduleTime : 36;
            for(Integer i = 0; i < paymentScheduleTime; i++){ // T-28932
                Payment_Schedule__c payRecSch = new Payment_Schedule__c();
                Datetime dateTimetemp = orderRec.actual_start_date__c.addMonths(i);
                Date dateTemp = Date.newInstance(dateTimetemp.year(),dateTimetemp.month(),dateTimetemp.day());
                String campStartDate =dateTemp.format();

                Datetime dateTimeEndtemp = orderRec.actual_start_date__c.addMonths(i+1);
                Date dateEndTemp = Date.newInstance(dateTimeEndtemp.year(),dateTimeEndtemp.month(),dateTimeEndtemp.day());
                String campEndDate =dateEndTemp.format();

                payRecSch.Name = 'Payment Schedule - '+campStartDate+' - '+ campEndDate;
                payRecSch.Schedule_Start_Date__c = date.parse(campStartDate);
                payRecSch.Schedule_End_Date__c = date.parse(campEndDate);
                payRecSch.Status__c = 'Pending';
                payRecSch.Payment__c = payRec.id;
                //payRecSchedules.add(payRecSch);
                psWrapList.add(new PaymentScheduleWrapper(payRecSch));
            }
        }

        PaymentScheduleWrapper additionalPsWrap = createAdditionalPaymentSchedule(orderRec, payRec);
        if(additionalPsWrap !=null){
            psWrapList.add(additionalPsWrap);
        }
        return psWrapList;
    }

    /**
    * @name         : createPaymentLineItem
    * @description  : create payment line items
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : csmso__Sales_Order__c salesOrder, List<PaymentScheduleWrapper> psWrapList
    * @return       : List<Payment_Line_Item__c>
    */
    public static List<Payment_Line_Item__c> createPaymentLineItem(csmso__Sales_Order__c salesOrder, List<PaymentScheduleWrapper> psWrapList){

        List<Payment_Line_Item__c> payLineItems = new List<Payment_Line_Item__c>();
        cscfga__Product_Basket__c prodBasket = Order_PaymentSchedulerController.prodBasketList(salesOrder);
        List<cscfga__Product_Configuration__c> prodConfigs = Order_PaymentSchedulerController.prodConfigList(prodBasket.Id);
        if(prodConfigs != null && prodConfigs.size()>0){
            Payment_Schedule__c firstPS;
            for (PaymentScheduleWrapper psWrap :  psWrapList) {
                if (firstPS == null) {
                    firstPS = psWrap.paymentSchedule;
                }
                if (firstPS.Schedule_Start_Date__c > psWrap.paymentSchedule.Schedule_Start_Date__c && !psWrap.partialAmount) {
                    firstPS = psWrap.paymentSchedule;
                }
            }

            for(PaymentScheduleWrapper schWrap : psWrapList ) {
                Payment_Schedule__c sch = schWrap.paymentSchedule;
                for(cscfga__Product_Configuration__c prodConf : prodConfigs) {
                    Boolean oneOffProduct = false;

                    Payment_Line_Item__c payLineItem = new Payment_Line_Item__c();

                    for (cscfga__Attribute__c atr : prodConf.cscfga__Attributes__r) {
                        if (atr.Name == 'Product') {
                            payLineItem.Product_Node__c = atr.cscfga__Value__c;
                        }

                        if (atr.Name == 'Product Name') {
                            payLineItem.Product_Name__c = atr.cscfga__Value__c;
                        } else if (atr.Name == 'Quantity') {
                            payLineItem.Quantity__c = decimal.valueOf(atr.cscfga__Value__c);
                        } else if (atr.Name == 'Price') {
                            Decimal price;
                            if(schWrap.partialAmount){
                                Integer deltaDay = sch.Schedule_Start_Date__c.daysBetween(sch.Schedule_End_Date__c);

                                price = decimal.valueOf(deltaDay)/30 * decimal.valueOf(atr.cscfga__Value__c);
                            }else{
                                price = decimal.valueOf(atr.cscfga__Value__c);
                            }

                            if(schWrap.isRefund){
                                price = price * -1;
                            }

                            payLineItem.Price__c = price;
                            payLineItem.List_Price__c = decimal.valueOf(atr.cscfga__Value__c);
                        } else if (atr.Name == 'Payment Type') {
                            if (atr.cscfga__Value__c == 'One Off')
                                oneOffProduct = true;

                            payLineItem.Payment_Type__c = atr.cscfga__Value__c;
                        }
                    }

                    if (oneOffProduct && sch.Id == firstPS.Id) {
                        payLineItem.Payment_Schedule__c = sch.id;
                        payLineItem.Name = payLineItem.Product_Name__c;
                        payLineItem.Type__c = 'Normal';
                        payLineItem.Basic_Price__c = prodConf.Basic_Price__c;
                        payLineItem.Discount__c = prodConf.Discount__c;
                        payLineItem.Product_ID__c = prodConf.Product_ID__c;
                        payLineItem.Quantity__c =  prodConf.Quantity__c;
                        payLineItem.Site_Section__c = prodConf.Site_Section__c;
                        payLineItem.Site_Section_Group__c = prodConf.Site_Section_Group__c;
                        payLineItem.Configuration_ID__c = prodConf.id;
                        payLineItem.Network__c = prodConf.Network__c;
                        payLineItem.Cost_Model__c = prodConf.Cost_Model__c;
                        payLineItems.add(payLineItem);
                    } else if (!oneOffProduct) {
                        payLineItem.Payment_Schedule__c = sch.id;
                        payLineItem.Name = payLineItem.Product_Name__c;
                        payLineItem.Type__c = 'Normal';
                        payLineItem.Basic_Price__c = prodConf.Basic_Price__c;
                        payLineItem.Discount__c = prodConf.Discount__c;
                        payLineItem.Product_ID__c = prodConf.Product_ID__c;
                        payLineItem.Quantity__c =  prodConf.Quantity__c;
                        payLineItem.Recurring__c = true;
                        payLineItem.Site_Section__c = prodConf.Site_Section__c;
                        payLineItem.Site_Section_Group__c = prodConf.Site_Section_Group__c;
                        payLineItem.Configuration_ID__c = prodConf.id;
                        payLineItem.Network__c = prodConf.Network__c;
                        payLineItem.Cost_Model__c = prodConf.Cost_Model__c;
                        payLineItems.add(payLineItem);
                    }

                }
            }

        }
        return payLineItems;
    }

    /**
    * @name         : checkRetractSOPermission
    * @description  : check if the user has permission for retracting sales order
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String groupName, Id userId
    * @return       : Boolean
    */
    public static Boolean checkRetractSOPermission(String groupName, Id userId){
        Boolean hasPermission = false;

        List<GroupMember> members = [Select Id, UserOrGroupId
        From GroupMember
        Where Group.DeveloperName =: groupName
        And UserOrGroupId =:userId];

        if(!members.isEmpty()){
            hasPermission = true;
        }

        return hasPermission;
    }

    /**
    * @name         : createTaskForCampaignRetracted
    * @description  : create a task for campaign order post retraction
    * @createdby    : Kevin Wu - 2018-10-01
    * @param        : String userId, String orderId, String subject, String taskDesc
    * @return       : n/a
    */
    public static void createTaskForCampaignRetracted(String userId, String orderId, String subject, String taskDesc){
        Task t = new Task();
        t.OwnerId   = userId;
        t.Subject   = subject;
        t.Description = taskDesc;
        t.Priority  = 'High';
        t.WhatId    = orderId;

        // PetarM NX-1378
        t.RecordTypeId  = Task.SObjectType.getDescribe().getRecordTypeInfosByName().get('To-Do').getRecordTypeId();
        t.Type          = 'To Do';
        t.Status        = 'Not Started';
        t.ActivityDate  = Date.today();

        insert t;
    }

    /**
    * @name         : PaymentScheduleWrapper
    * @description  : a wrapper class for payment schedule records
    * @createdby    : Kevin Wu - 2018-10-01
    */
    public class PaymentScheduleWrapper{
        public Payment_Schedule__c paymentSchedule;
        public Boolean isRefund;
        public Boolean partialAmount;
        public PaymentScheduleWrapper(Payment_Schedule__c ps){
            this.paymentSchedule = ps;
            this.isRefund = false;
            this.partialAmount = false;
        }

        public PaymentScheduleWrapper(Payment_Schedule__c ps, Boolean isRefund, Boolean partialAmount){
            this.paymentSchedule = ps;
            this.isRefund = isRefund;
            this.partialAmount = partialAmount;
        }
    }


    /**
    * @name         : terminateExistingOrchProcess
    * @description  : terminates the existing process when SO is retracted before fulfilment.
    *
    */

    public static void terminateExistingOrchProcesses(Id orderId) {


        List<CSPOFA__Orchestration_Process__c> allPs = [SELECT Id FROM CSPOFA__Orchestration_Process__c
        WHERE CSPOFA__Status__c != 'Complete' AND Order__c =: orderId];

        for (CSPOFA__Orchestration_Process__c process : allPs) {
            process.CSPOFA__Status__c  = 'Complete';
            process.CSPOFA__State__c = 'TERMINATED';
        }

        update allPs;

    }

}