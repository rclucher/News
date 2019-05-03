/**********************************************************************************************
    Name          : Order_PaymentSchedulerController 
    Created By    : Malvika Sharma
    Created Date  : Aug 10 2016
    Description   : Class to create Order, Payment, Payment Schedule and Payment Line Item records
                    for SO having status as 'Externally Approved' or 'Manual Approval' onclick of 
                    Schedule Payments button on opportunity
    -------
    History                                                            
    -------                                                            
    VERSION     AUTHOR              DATE           DETAIL                   
    ------      ------              -----          -------                
    1.1         Malvika Sharma      10-08-2016     Created   
    **********************************************************************************************/
    global class Order_PaymentSchedulerController 
    {
        public static Order__c orderRec = new Order__c();
        public static Payment__c payRec = new Payment__c();
        public static Payment_Line_Item__c payLineitm = new Payment_Line_Item__c();
        public static List<Payment_Schedule__c> payRecSchedules = new List<Payment_Schedule__c>();
        public static List<cscfga__Product_Configuration__c> prodConfigs = new List<cscfga__Product_Configuration__c>();
        global static String[] attrName = new String[]{'Product', 'Product Name', 'Quantity', 'Price', 'Cost Model', 'Payment Type'};
        public static List<Payment_Line_Item__c> payLineItems = new List<Payment_Line_Item__c>();
        public static cscfga__Product_Basket__c  productBas;
        public static INTEGER paymentScheduleTime = 36; // T-28932
        public List<Payment_Line_Item__c> paymentLineItemList{get;set;}
        public List<Payment_Schedule__c> paymentScheduleList{get;set;}
        public Map<string,List<Payment_Line_Item__c>> paymentLineMap{get;set;}
        public integer newLineItemPrice{get;set;}
        public Map<string,Boolean> showErrorMessageMap{get;set;}
        @TestVisible private decimal lineItemVaue;
        public Map<string,Decimal> priceMap{get;set;}
        public Map<id,Decimal> currentpriceMap{get;set;}
        public string copyPricingVal{get;set;}
        public boolean showcopyPricingButton{get;set;}
        @TestVisible private ApexPages.StandardController ctrl;
        @TestVisible private Set<Integer> paymentLineCount = new Set<Integer>();
        /* Standard Controller method */ 
        public Order_PaymentSchedulerController(ApexPages.StandardController controller) {
            showcopyPricingButton = true;
            ctrl = controller;
            newLineItemPrice =0;        
            priceMap = new Map<string,Decimal>();
            showErrorMessageMap = new Map<string,Boolean>();
            payRec = (Payment__c)controller.getRecord();
            integer currentMonth = Date.Today().Month();
            paymentScheduleList = [Select id, Name,Amount__c,Payment__c from Payment_Schedule__c where Payment__c=:payRec.id and Status__c='Pending'];
            paymentLineItemList = [select id,Name,Price__c,Payment_Schedule__c from Payment_Line_Item__c where Payment_Schedule__c IN : paymentScheduleList ];
            
            paymentLineMap = new Map<string,List<Payment_Line_Item__c>>();
            currentpriceMap = new Map<id,Decimal>();
            
            for(Payment_Schedule__c paymentschRec : [select id,Name,(select Name,Price__c from Payment_Line_Items__r) from Payment_Schedule__c where Payment__c=:payRec.id  and Status__c='Pending']){
               lineItemVaue = 0;
               Payment_Line_Item__c[] paymentItemRecList= paymentschRec.Payment_Line_Items__r;
               paymentLineMap.put(paymentschRec.ID,paymentItemRecList);
               paymentLineCount.add(paymentItemRecList.size());
               System.debug('paymentLineMap'+paymentLineMap); 
               for(Payment_Line_Item__c paymentLineSum : paymentItemRecList){
                   lineItemVaue = lineItemVaue + paymentLineSum.Price__c;
                   paymentLineSum.Price__c = paymentLineSum.Price__c.setScale(2);
                   currentpriceMap.put(paymentLineSum.id,paymentLineSum.Price__c);
               }
               priceMap.put(paymentschRec.ID,lineItemVaue);
               showErrorMessageMap.put(paymentschRec.ID,false);
            }
            system.debug('paymentLineCount-->'+paymentLineCount);
            if(paymentLineCount.size()>1){
                system.debug('paymentLineCount1-->'+paymentLineCount);
                   showcopyPricingButton = false;
            }
        }
        
        /*Method to calculate Price */
        public void paymentPriceCalculation(){
            for(Payment_Schedule__c payscheRec : paymentScheduleList){
                lineItemVaue = 0;
                list<Payment_Line_Item__c> paymentCalculation = paymentLineMap.get(payscheRec.id);            
                for(Payment_Line_Item__c paymentLineSum : paymentCalculation){
                    paymentLineSum.Price__c = paymentLineSum.Price__c;
                    lineItemVaue = lineItemVaue + paymentLineSum.Price__c;
                }
                priceMap.put(payscheRec.ID,lineItemVaue);
                if(payscheRec.Amount__c.setScale(2) !=lineItemVaue ){
                    showErrorMessageMap.put(payscheRec.id,true);
                }else{
                    showErrorMessageMap.put(payscheRec.id,false);
                }
            }
        }
        
        /*Method to copy Price */
        public void copyPricingValue(){   
        System.debug('INpaymentLineMap'+paymentLineMap);    
        System.debug('copyPricingVal'+copyPricingVal);   
            List<Payment_Line_Item__c> valueCopyFrom = paymentLineMap.get(copyPricingVal);
            Map<integer,Decimal> pricingValueToCopy = new Map<integer,Decimal>();
            Integer increment = 1;
            System.debug('valueCopyFrom'+valueCopyFrom);
            if(payLineitm.Type__c!= 'Credit'){
                for(Payment_Line_Item__c paymentLineSum : valueCopyFrom){            
                    pricingValueToCopy.put(increment,paymentLineSum.Price__c);
                    increment++;
                }        
                for(Payment_Schedule__c payscheRec : paymentScheduleList){
                    lineItemVaue = 0;
                    increment = 1;
                    list<Payment_Line_Item__c> paymentCalculation = paymentLineMap.get(payscheRec.id); 
                    List<Payment_Line_Item__c> listItemListRec = new List<Payment_Line_Item__c>();           
                    for(Payment_Line_Item__c paymentLineSum : paymentCalculation){
                        paymentLineSum.Price__c = pricingValueToCopy.get(increment);
                        system.debug('paymentLineSum.Price__c-->'+paymentLineSum.Price__c);
                        listItemListRec.add(paymentLineSum);
                        
                        lineItemVaue = lineItemVaue + paymentLineSum.Price__c;
                        increment++;
                    }
                    paymentLineMap.put(payscheRec.id,listItemListRec);
                    priceMap.put(payscheRec.ID,lineItemVaue);
                    if(payscheRec.Amount__c!=lineItemVaue ){
                        showErrorMessageMap.put(payscheRec.id,true);
                    }else{
                        showErrorMessageMap.put(payscheRec.id,false);
                    }
                }
            }else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Copy functionality is unavailable as there is an Credit adjustment in the Payment'));
            }
        }
        
        /*Method to save line items*/
        public PageReference savelineItem(){
            List<Payment_Line_Item__c> paymentLineItemToSave = new List<Payment_Line_Item__c>();
            Boolean isErrorOccured = false;
            for(Payment_Schedule__c payscheRec : paymentScheduleList){
                lineItemVaue = 0;
                list<Payment_Line_Item__c> paymentCalculation = paymentLineMap.get(payscheRec.id);
                
                for(Payment_Line_Item__c paymentLineSum : paymentCalculation){
                    paymentLineItemToSave.add(paymentLineSum);
                    lineItemVaue = lineItemVaue + paymentLineSum.Price__c;
                }
                System.debug('IGOR +++++++++++++++++++ payscheRec: ' + payscheRec);
                System.debug('IGOR +++++++++++++++++++ lineItemVaue: ' + lineItemVaue);
                if(payscheRec.Amount__c.setScale(2) !=lineItemVaue ){
                    showErrorMessageMap.put(payscheRec.id,true);
                    isErrorOccured = true;
                }else{
                    showErrorMessageMap.put(payscheRec.id,false);
                }            
            }
            if(isErrorOccured){
                return null;
            }else{
                update paymentLineItemToSave;
            }
            PageReference paymentiew= new ApexPages.StandardController(payRec).view();
            paymentiew.setRedirect(true);
            return paymentiew;
        }
        
        /* webService method linked to on-click javascript */
        webService static String updateOrder_Payment(Id oppId) {
            Opportunity opp = new Opportunity();
            List<Opportunity> oppList = new list<Opportunity> ([select OpportunityGroup__c, Account.AdPoint_ID__c, Payer_Account__r.AdPoint_ID__c, TM1_Publication__c, JDE_Publication_Code__c from Opportunity where id =:oppId]);
            //**Commented for field type switch Start (take off Campaign_End_Date2__c field from query)
            List<csmso__Sales_Order__c> salesOrders = [Select id,Name,csmso__Status__c,csmso__Advertiser__c,Recurring_Price__c, Campaign_Start_Date__c,
            Campaign_End_Date2__c,Campaign_Length__c,Total_GST_inclusive__c,csmso__Total_Price__c,GST__c,csmso__Booking_Contact__r.Name 
            from csmso__Sales_Order__c WHERE csmso__Opportunity__c =:oppId and (csmso__Status__c = 'externally approved'
                        or csmso__Status__c = 'manually approved')];
            //**Commented for field type switch End
            if (salesOrders.size() > 1) {
                return 'More than one manually or externally approved Sales Order.';
            }
            else if (salesOrders.size() < 1){
                    return 'There needs to be an approved Sales Order in order to Schedule Payments.';
                }
            
            try {
                /* never delete Campaign Orders - NXIII-314
                List<Order__c> ordersToDelete = [
                    select id 
                    from Order__c
                    where Opportunity__c = :oppId AND Status__c != 'Fulfilment Ready'
                ];
                */
                /*
				List<Payment_Schedule__c> psToDelete = [
                    select Id, Status__c
                    from Payment_Schedule__c
                    where Payment__r.Order__r.Opportunity__c = :oppId
                ];
				*/
                List<Payment__c> pToDelete = [
                    select Id
                    from Payment__c
                    where Order__r.Opportunity__c = :oppId
                ];
				/*
                List<Payment_Line_Item__c> pliToDelete = [
                    select Id
                    from Payment_Line_Item__c
                    where Payment_Schedule__r.Payment__r.Order__r.Opportunity__c = :oppId
                ];
				*/
				/*
               for (Payment_Schedule__c ps : psToDelete) {
                    if (ps.Status__c != 'Pending' && ps.Status__c != 'Cancelled') {
                        return 'Campaign already started. Cannot reschedule payments.';
                    }
                }
				*/
				/*
                if (!pliToDelete.isEmpty()) {
                    delete pliToDelete;
                }
                if (!psToDelete.isEmpty()) {
                    delete psToDelete;
                }
				*/
                if (!pToDelete.isEmpty()) {
                    delete pToDelete;
                }
                //if (!ordersToDelete.isEmpty()) {
                //    delete ordersToDelete;
                //}
                if (oppId !=null && salesOrders.size()>0){
                    getOrder(oppId, salesOrders[0]);
                    createPayment(salesOrders[0],oppList[0]);
                    createPaymentSchedule(salesOrders[0]);
                    createPaymentLineItem(salesOrders[0]);  
                    if (orderRec.Account__c != null)
                        Database.executeBatch(new CS_BatchTierCalculation(orderRec.Account__c));        
                }
				//NX-324-start
				CS_NotificationOnEvent.notificationButtonEventWrapper ButtonEvent = new CS_NotificationOnEvent.notificationButtonEventWrapper();
				ButtonEvent.objectType=CS_NotificationOnEvent.ObjectType.Opportunity;
				ButtonEvent.ButtonName='Schedule_Payments';
				//ButtonEvent.Message='Button Opportunity.Schedule_Payments has been clicked';
				ButtonEvent.objectId=oppId;
				CS_NotificationOnEvent.AddButtonEvent(ButtonEvent);
				CS_NotificationOnEvent.SendNotificationEmails();
                //NX-324-end
				return ('Successful!');
            } catch(Exception e) {
                return e.getMessage();
            }
        }
        
        
        /* Method to create Order */
        public static void getOrder(Id oppId, csmso__Sales_Order__c salesOrder) { 
            list<order__c> orders = [SELECT Id, Name, Account__c, Opportunity__c,Proposed_Start_Date__c, actual_start_date__c, End_Date__c,Schedule_Payments_Pushed_Count__c FROM Order__c WHERE Opportunity__c = :oppId];
            if (!orders.isEmpty())
                orderRec = orders[0];
            else  {
                orderRec = new Order__c(Opportunity__c = oppId, Proposed_Start_Date__c = salesOrder.Campaign_Start_Date__c, 
                    actual_start_date__c = salesOrder.Campaign_Start_Date__c, End_Date__c = salesOrder.Campaign_End_Date2__c, Account__c = salesOrder.csmso__Advertiser__c);
              }
              
            if (orderRec.Schedule_Payments_Pushed_Count__c == null)    
                orderRec.Schedule_Payments_Pushed_Count__c = 0;
                
            orderRec.Is_Schedule_Payments_Button_Pushed__c = 'Clicked';
            orderRec.Schedule_Payments_Pushed_Count__c++;
                              
            upsert orderRec;
        }

        webService static string checkActualStartDate(Id oppId)
        {
            string result = 'Actual Start Date is not set on Campaign Order';
            order__c tmpOrder;
			            
            list<order__c> orders = [SELECT Id, Actual_Start_Date__c, Status__c FROM Order__c 
                WHERE Opportunity__c = :oppId];
            
            if (!orders.isEmpty())
            {
                tmpOrder = orders[0];
                if (tmpOrder.Status__c=='Paused' || tmpOrder.Status__c=='Cancelled' || 
                    tmpOrder.Status__c=='Pending For Pause' || 
                    tmpOrder.Status__c=='Pending For Cancel' || 
                    tmpOrder.Status__c=='Campaign Ended')
                {
                    result = 'You can not create payments when Campaign Order Status is ' + tmpOrder.Status__c;
                } 
                else if (tmpOrder.Actual_Start_Date__c!=null)
                    result='true';          
            }
            else
            {
                list<Opportunity> lstOpportunity = [select Id from Opportunity where Id=:oppId and IsClosed=false];

                if (lstOpportunity.size()>0)
                {
                    result ='You can not create Payment Schedule on open Opportunity';
                }
            }

			if (result=='true')
			{
				List<Payment__c> lstPayment = [select Id from Payment__c where Order__r.Opportunity__c=: oppId];
				if (lstPayment.size()>0) result = 'Campaign already started. Cannot reschedule payments';
			}


			/*
			if (result=='true')
			{
				List<Payment_Schedule__c> lstPS = [select Id from Payment_Schedule__c 
					where Status__c!='Pending' and Payment__r.Order__r.Opportunity__c=: oppId];

				if (lstPS.size()>0) result = 'Campaign already started. Cannot reschedule payments';
			}
			*/


            return result;
        }
        
        /* Method to create Payment */
        public static void createPayment(csmso__Sales_Order__c salesOrder, Opportunity opplst){
            /*commented temporarily by DD
			Decimal maximumMinimumEvergreenCancellationPeriod=0;
            Boolean updateMinimumEvergreenCancellationPeriod=false;   
            */
			payRec.Name = 'Payment - '+salesOrder.Name;
            //**Commented for field type switch Start (take off if else condition)
            if(salesOrder.Campaign_End_Date2__c == null){
                payRec.Status__c = 'Pending';
            }
            //**Commented for field type switch End
            else{
                payRec.Status__c = 'In Progress';
            }
            /*commented temporarily by DD
			List<Product_Order__c> productOrderList=[SELECT Product_Node__r.Minimum_Evergreen_Cancellation_Period__c FROM Product_Order__c WHERE Order__c=:orderRec.id];
            for(Product_Order__c prodOrder:productOrderList){
                if(prodOrder.Product_Node__r.Minimum_Evergreen_Cancellation_Period__c!=null){
                    if(prodOrder.Product_Node__r.Minimum_Evergreen_Cancellation_Period__c>=maximumMinimumEvergreenCancellationPeriod){
                        maximumMinimumEvergreenCancellationPeriod=prodOrder.Product_Node__r.Minimum_Evergreen_Cancellation_Period__c;
                        updateMinimumEvergreenCancellationPeriod=true;
                    }
                }
            }
            if(updateMinimumEvergreenCancellationPeriod){
                payRec.Minimum_Evergreen_Cancellation_Period__c=maximumMinimumEvergreenCancellationPeriod;
            }
			*/
            payRec.Start_Date__c = orderRec.actual_start_date__c;
            //**Commented for field type switch Start (take off if else condition)
            payRec.End_Date__c = orderRec.End_Date__c;
            //payRec.Amount__c = salesOrder.Total_GST_inclusive__c;
            payRec.Order__c = orderRec.Id;
            payRec.Advertiser_Account_Adpoint_ID__c = opplst.Account.AdPoint_ID__c;
            payRec.Payer_Account_Adpoint_ID__c = opplst.Payer_Account__r.AdPoint_ID__c;
            payRec.JDE_Publication_Code__c = opplst.JDE_Publication_Code__c;
            payRec.TM1_Publication__c = opplst.TM1_Publication__c;
            payRec.Primary_Contact_on_SO__c = salesOrder.csmso__Booking_Contact__r.Name;
            /*
            if(salesOrder.Campaign_Length__c!= null){ 
            payRec.Cancellation_Reason__c = 'Seasonal campaign with pre-defined end date';        
            }
            else{
            payRec.Cancellation_Reason__c ='';
            }
            */
            if (payRec.End_Date__c==null) 
				payRec.Cancellation_Reason__c ='';
			else
				payRec.Cancellation_Reason__c ='Seasonal campaign with pre-defined end date';
            
			insert payRec;
        }
        
         /* Method to create Payment Schedules as per the campaign length */
        public static void createPaymentSchedule(csmso__Sales_Order__c salesOrder){ 
        //**Commented for field type switch Start (take off if else condition)  
        if(orderRec.End_Date__c != null){     
                for(Integer i = 0; i < salesOrder.Campaign_Length__c; i++){
                    Payment_Schedule__c payRecSch = new Payment_Schedule__c();
                    
                    Datetime dateTimeStarttemp = orderRec.actual_start_date__c.addMonths(i);
                    Date dateStartTemp = Date.newInstance(dateTimeStarttemp.year(),dateTimeStarttemp.month(),dateTimeStarttemp.day());
                    String campStartDate =dateStartTemp.format();
                    
                    Datetime dateTimeEndtemp = orderRec.actual_start_date__c.addMonths(i+1);
                    Date dateEndTemp = Date.newInstance(dateTimeEndtemp.year(),dateTimeEndtemp.month(),dateTimeEndtemp.day());
                    String campEndDate =dateEndTemp.format();
                    
                    payRecSch.Name = 'Payment Schedule - '+campStartDate+' - '+ campEndDate;
                    //payRecSch.PaymentSchDate__c = salesOrder.Campaign_Start_Date__c.addMonths(i);
                    payRecSch.Schedule_End_Date__c = date.parse(campEndDate);
                    payRecSch.Status__c = 'Pending';
                    //payRecSch.Payment_Date__c= salesOrder.Campaign_Start_Date__c; 
                    payRecSch.Schedule_Start_Date__c = date.parse(campStartDate);
                    payRecSch.Payment__c = payRec.id;
                    
                    payRecSchedules.add(payRecSch);
                }
                       
                insert payRecSchedules;
        }    
        //T-29839 15/2/17 NF Start
        else if ((orderRec.End_Date__c == null) && (salesOrder.Recurring_Price__c == 0 )){
            
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
                    
                    payRecSchedules.add(payRecSch);
                    
                    insert payRecSchedules;
            
            }   
         //T-29839 15/2/2017 NF End 
    
        else
            //**Commented for field type switch End
        {
            for(Integer i = 0; i < paymentScheduleTime; i++){ // T-28932
                    Payment_Schedule__c payRecSch = new Payment_Schedule__c();
                    Datetime dateTimetemp = orderRec.actual_start_date__c.addMonths(i);
                    Date dateTemp = Date.newInstance(dateTimetemp.year(),dateTimetemp.month(),dateTimetemp.day());
                    String campStartDate =dateTemp.format();
                    
                    Datetime dateTimeEndtemp = orderRec.actual_start_date__c.addMonths(i+1);
                    Date dateEndTemp = Date.newInstance(dateTimeEndtemp.year(),dateTimeEndtemp.month(),dateTimeEndtemp.day());
                    String campEndDate =dateEndTemp.format();
                    
                    payRecSch.Name = 'Payment Schedule - '+campStartDate+' - '+ campEndDate;
                    //payRecSch.PaymentSchDate__c = salesOrder.Campaign_Start_Date__c.addMonths(i);
                    payRecSch.Schedule_Start_Date__c = date.parse(campStartDate);
                    payRecSch.Schedule_End_Date__c = date.parse(campEndDate);
                    payRecSch.Status__c = 'Pending';
                    //payRecSch.Payment_Date__c= salesOrder.Campaign_Start_Date__c; 
                    payRecSch.Payment__c = payRec.id;
                    payRecSchedules.add(payRecSch);
                }
                       
                insert payRecSchedules;
            }
        }
        
        /* Method to get product basket */
        global static cscfga__Product_Basket__c ProdBasketList(csmso__Sales_Order__c salesOrder){        
            productBas = [Select Id, Name , csmso__Sales_Order__c from cscfga__Product_Basket__c where csmso__Sales_Order__c =: salesOrder.Id];
            return productBas;
        }
        
        /* Method to get product config */
        global static list<cscfga__Product_Configuration__c > ProdConfigList(Id prodBasketId){
            list<cscfga__Product_Configuration__c> allProdConfig = new list<cscfga__Product_Configuration__c>();
            allProdConfig= [SELECT Id, Name, cscfga__Description__c,  cscfga__Product_Basket__r.csmso__Sales_Order__r.Name,Basic_Price__c,Discount__c,
            Product_ID__c,Quantity__c,Site_Section__c,Site_Section_Group__c,Network__c,Cost_Model__c,
            (Select  Name, cscfga__Value__c, cscfga__Attribute_Definition__r.Name, cscfga__Product_Configuration__r.Name 
            FROM cscfga__Attributes__r 
            where cscfga__Attribute_Definition__r.Name IN : attrName ORDER BY cscfga__Attribute_Definition__r.Name DESC NULLS LAST ) 
            FROM cscfga__Product_Configuration__c WHERE cscfga__Product_Basket__c=:prodBasketId
            AND  Line_Item_Platform__c = 'Xtend' ];//OPG: Xtend E2E Billing Trail - fixed PC select];
            return allProdConfig;
        }
        
        /* Method to create Payment Line Items */
        public static void createPaymentLineItem(csmso__Sales_Order__c salesOrder){
            cscfga__Product_Basket__c prodBasket = new cscfga__Product_Basket__c();
            prodBasket = ProdBasketList(salesOrder);        
            prodConfigs = ProdConfigList(prodBasket.Id);
            if(prodConfigs != null && prodConfigs.size()>0){
            Payment_Schedule__c firstPS;
            for (Payment_Schedule__c sch :  payRecSchedules) {
                if (firstPS == null) {
                    firstPS = sch;
                }
                if (firstPS.Schedule_Start_Date__c > sch.Schedule_Start_Date__c) {
                    firstPS = sch;
                }
            }

            for(Payment_Schedule__c sch : payRecSchedules ) {
                for(cscfga__Product_Configuration__c prodConf : prodConfigs) {
                    Boolean oneOffProduct = false;
                    //system.debug('KK - starting line item creation');
                    //system.debug('prodConf.cscfga__Attributes__r'+prodConf.cscfga__Attributes__r);
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
                            payLineItem.Price__c = decimal.valueOf(atr.cscfga__Value__c);
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
                insert payLineItems;
            }
        }
    }