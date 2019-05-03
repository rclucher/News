/**
 * Used to process all Order Requests in real-time or in scheduled mode.
 * Scheduled mode processes those requests that failed real time processing
 * due to validation or concurrency issues (for instance Account object was locked by another process).
 * Scheduled mode processes all Ecommerce Order Request records that are:
 * - Created not more than 24h ago
 * - Older than 1h (to ensure we do not compete with order request creation integration or real-time processing)
 * - Not already processed (Observer_Processing_Done__c = false)
 */
global class APIPostRuleExecution implements Queueable, Database.Batchable<SObject> {
    
    global APIPostRuleExecution (List<Id> bIds) {
        this.basketIds = bIds;
    }
    
    public List<cscfga__Product_Basket__c> allBaskets;
    public List<Id> basketIds;
    public Map<Id, csmso__Sales_Order__c> oppIdsalesOrder;
    public Map<Id, Opportunity> opportunityMap;

    private final Map<String, String> DATA4_CHARACTER = new Map<String, String> {
        '0' => '8', '1' => '9', '2' => 'a', '3' => 'b',
        '4' => '8', '5' => '9', '6' => 'a', '7' => 'b',
        '8' => '8', '9' => '9', 'a' => 'a', 'b' => 'b',
        'c' => '8', 'd' => '9', 'e' => 'a', 'f' => 'b'
    };
    public void execute(QueueableContext context) {
        Init(basketIds);
    }
    
    public String generateGuid() {
        Blob b = Crypto.generateAesKey(128);
        String h = EncodingUtil.convertToHex(b).toLowerCase();
        return (
            h.substring(0, 8)
            + '-' + h.substring(8, 12)
            + '-4' + h.substring(13, 16)
            + '-' + DATA4_CHARACTER.get(h.substring(16, 17)) + h.substring(17, 20)
            + '-' + h.substring(20)
            );
    }
    
    global void Init(List<Id> basketIds) {
        Savepoint sp = Database.setSavepoint();
        try {
            system.debug(basketIds);
            allBaskets = [  SELECT  Id,
                                    Campaign_Start_Date__c,
                                    Campaign_Name__c,
                                    Name,
                                    OwnerId,
                                    Booking_Contact__c,
                                    cscfga__Opportunity__c,
                                    cscfga__Total_Price__c,
                                    Sales_Rep_Identifier__c,
                                    Contact_Identifier__c,
                                    cscfga__Products_In_Basket__c,
                                    cscfga__Products_Id_Qty_In_Basket__c,
                                    (SELECT Id, Name, csb2c__Account__c, Observer_Processing_Done__c, csb2c__Error_Information__c, Processing_Error_Message__c FROM csb2c__Inbound_Ecommerce_Order_Requests1__r)
                            FROM    cscfga__Product_Basket__c
                            WHERE   Id IN: basketIds];

            if (allBaskets.isEmpty()) {
                throw new SObjectException('No valid baskets');
            }
            ValidateBasketData();

            List<Opportunity> newOpportunities = CreateOpportunities();
            
            CreateAndQuerySalesOrders();
            List<Id> productBasketIds = CreateBasketSession();
                    
            CheckProductData(productBasketIds);
            CloseWinOpps(newOpportunities);
            SchedulePayments();
            RemoveErrorMessage(); 
        }
        catch (SObjectException e) {
            
        }
        catch (Exception e) {
            Database.rollback(sp);
            List<csb2c__Inbound_Ecommerce_Order_Request__c> errorOrderRequests = new List<csb2c__Inbound_Ecommerce_Order_Request__c>();
            for (cscfga__Product_Basket__c basket : allBaskets) {
                String msg = e.getMessage();
                msg += e.getStackTraceString();
                //adjust msg to field length
                basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Processing_Error_Message__c = msg.left(255);
                errorOrderRequests.add(basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0]);
            }
            update errorOrderRequests;
        }
    }
    
    void CloseWinOpps (List<Opportunity> newOpportunities) {
    	News_TriggerHelper.OpportunityManagement_Before_Update_Executing = false;
    	News_TriggerHelper.OpportunityManagement_After_Update_Executing = false;
    	for (Opportunity singleOpp : newOpportunities) {
    		singleOpp.StageName = 'Closed Won';
    		singleOpp.Reason_Won_Lost__c = 'Alternative Media';
    		singleOpp.Has_an_Approved_SO__c = true;
    	}
    	update newOpportunities;
    	if (!Test.isRunningTest()) {
    	    AddChatterPost();
    	}
    }
    
    void mentionTextPost(Id oppId, Id oppOwnerId, Id userId, String campaignName) { 
		ConnectApi.MessageBodyInput messageInput = new ConnectApi.MessageBodyInput();
	   	messageInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
	   	
	   	ConnectApi.MentionSegmentInput mentionSegment = new ConnectApi.MentionSegmentInput();
	   	mentionSegment.id = oppOwnerId;
	   	messageInput.messageSegments.add(mentionSegment);
	
	   	ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
	   	textSegment.text = ' New Campaign Track Opportunity ' + campaignName + ' is now live.';
	   	messageInput.messageSegments.add(textSegment);
	
	   	ConnectApi.FeedItemInput input = new ConnectApi.FeedItemInput();
	   	input.subjectId = oppId;
	   	input.body = messageInput;
	   	
	   	ConnectApi.ChatterFeeds.postFeedElement(null, input);
	}
    
    void AddChatterPost() {
    	Id userId = UserInfo.getUserId();
    	for (csmso__Sales_Order__c so : oppIdsalesOrder.values()) {
    		mentionTextPost(so.csmso__Opportunity__c, so.OwnerId, userId, so.Campaign_Name__c);
    	}	
    }
    
    void RemoveErrorMessage() {
        List<csb2c__Inbound_Ecommerce_Order_Request__c> errorOrderRequests = new List<csb2c__Inbound_Ecommerce_Order_Request__c>();
        for (cscfga__Product_Basket__c basket : allBaskets) {
            basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Processing_Error_Message__c= '';
            basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Observer_Processing_Done__c= true;
            
            errorOrderRequests.add(basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0]);
            
        }
        update errorOrderRequests;
    }

    void CheckProductData(List<Id> productBasketIds) {
        List<cscfga__Product_Configuration__c> allProductConfigs = [    SELECT  Id, 
                                                                                Name, 
                                                                                Product_ID__c,
                                                                                Platform__c,
                                                                                cscfga__Configuration_Status__c, 
                                                                                Product_Quantity__c,
                                                                                Total_Invoice__c,
                                                                                Provider_Name__c,
                                                                                Product_Line_Name__c,
                                                                                Product_Type_Name__c,
                                                                                Network__c,
                                                                                Product_Name__c, 
                                                                                (SELECT Id, Name, cscfga__Value__c FROM cscfga__Attributes__r) 
                                                                        FROM    cscfga__Product_Configuration__c 
                                                                        WHERE   cscfga__Product_Basket__c IN :productBasketIds];
        List<cscfga__Attribute__c> pcAttrs = new List<cscfga__Attribute__c>();
        for (cscfga__Product_Configuration__c pc : allProductConfigs) {
            pc.cscfga__Configuration_Status__c = 'Valid';
            pc.cscfga__Key__c = generateGuid();
            pc.Platform__c = 'Xtend';
            pc.Product_Quantity__c = 1;
            for (cscfga__Attribute__c att: pc.cscfga__Attributes__r) {
                if (att.Name == 'Product') {
                    pc.Product_ID__c = att.cscfga__Value__c;
                }
                else if (att.Name == 'Price') {
                    pc.Total_Invoice__c = Decimal.valueOf(att.cscfga__Value__c);
                }
                else if (att.Name == 'Provider Name') {
                    pc.Provider_Name__c = att.cscfga__Value__c;
                }
                else if (att.Name == 'Product Line Name') {
                    pc.Product_Line_Name__c = att.cscfga__Value__c;
                }
                else if (att.Name == 'Network Name') {
                    pc.Network__c = att.cscfga__Value__c;
                }
                else if (att.Name == 'Product Name') {
                    pc.Product_Name__c = att.cscfga__Value__c;
                }
                pcAttrs.add(new cscfga__Attribute__c(Id = att.id, cscfga__Key__c = generateGuid()));
            }
        }
        update pcAttrs;
        update allProductConfigs;
    }

    List<Id> CreateBasketSession () {
        List<Id> pBIds = new List<Id>();
        for (cscfga__Product_Basket__c pb : allBaskets) {
            pb.csmso__Sales_Order__c = oppIdsalesOrder.get(pb.cscfga__Opportunity__c).Id;
            cscfga.SessionManager.SessionInfo sessionInfo = cscfga.SessionManager.getOrCreateSession
                    (oppIdsalesOrder.get(pb.cscfga__Opportunity__c).Id, 'Session for Sales Order \'' + oppIdsalesOrder.get(pb.cscfga__Opportunity__c).Name + '\'' );
            pb.cscfga__user_session__c = sessionInfo.userSession.id;
            pBIds.add(pb.Id);
        }
        update allBaskets;
        return pBIds;
    }

    void CreateAndQuerySalesOrders() {
        List<csmso__Sales_Order__c> newSalesOrders = new List<csmso__Sales_Order__c>();

        for (cscfga__Product_Basket__c basket : allBaskets) {
            csmso__Sales_Order__c so = new csmso__Sales_Order__c (
                csmso__Advertiser__c = basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].csb2c__Account__c,
                //csmso__Booking_Contact__c = basket.Booking_Contact__c,
                csmso__Status__c = 'Manually Approved',
                csmso__Opportunity__c = basket.cscfga__Opportunity__c,
                Basket_Products__c = basket.cscfga__Products_In_Basket__c,
                Campaign_Start_Date__c = basket.Campaign_Start_Date__c,
                Campaign_Length__c = 1,
                Platform_Set__c = 'Xtend',
                Campaign_Name__c = basket.Campaign_Name__c,
                Origin__c = 'Campaign Track',
                OwnerId = basket.OwnerId,
                csmso__Total_Price__c = basket.cscfga__Total_Price__c,
                Total_Duration_Price__c = basket.cscfga__Total_Price__c 
                );
            newSalesOrders.add(so);
        }
        insert newSalesOrders;

        List<csmso__Sales_Order__c> salesOrdersList = [ SELECT  Id,
                                                                Name,
                                                                csmso__Advertiser__c,
                                                                csmso__Booking_Contact__c,
                                                                csmso__Status__c,
                                                                csmso__Opportunity__c,
                                                                Campaign_Start_Date__c,
                                                                Campaign_Length__c,
                                                                Campaign_Name__c,
                                                                Origin__c,
                                                                OwnerId,
                                                                Recurring_Price__c,
                                                                Campaign_End_Date2__c,
                                                                csmso__Total_Price__c,
                                                                csmso__Booking_Contact__r.Name
                                                        FROM    csmso__Sales_Order__c
                                                        WHERE   csmso__Opportunity__c IN: opportunityMap.keySet()];
        system.debug('observer' + salesOrdersList);
        oppIdsalesOrder = new Map<Id, csmso__Sales_Order__c>();
        for (csmso__Sales_Order__c salesOrder : salesOrdersList) {
            oppIdsalesOrder.put(salesOrder.csmso__Opportunity__c, salesOrder);
        }
    }

    void ValidateBasketData () {
        List<csb2c__Inbound_Ecommerce_Order_Request__c> errorOrderRequests = new List<csb2c__Inbound_Ecommerce_Order_Request__c>();
        Map<Id, String> salesRepIdentifierForBasket = new Map<Id, String>();
        Map<Id, String> contactIdentifierForBasket = new Map<Id, String>();
                
        for (Integer i = 0; i< allBaskets.size(); i++) {
            cscfga__Product_Basket__c basket = allBaskets[i];
            system.debug(basket);
            if (basket.Campaign_Name__c == null 
                || basket.Campaign_Start_Date__c == null 
                || basket.cscfga__Products_Id_Qty_In_Basket__c == null
                || basket.Sales_Rep_Identifier__c == null) {
                String errorMsg = '';
                if (basket.Campaign_Name__c == null) {
                    errorMsg += 'Campaign name';
                }
                if (basket.Campaign_Start_Date__c == null) {
                    if (errorMsg!='') {
                        errorMsg += ', ';
                    }
                    errorMsg += 'Campaign start date';
                }
                if (basket.cscfga__Products_Id_Qty_In_Basket__c == null) {
                    if (errorMsg!='') {
                            errorMsg += ', ';
                    }
                    errorMsg += 'Products in the basket';
                }
                if (basket.Sales_Rep_Identifier__c == null) {
                    if (errorMsg!='') {
                        errorMsg += ', ';
                    }
                    errorMsg += 'Sales representative identifier';
                }
                
                basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Processing_Error_Message__c= 'Following information is missing: '+errorMsg;
                errorOrderRequests.add(basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0]);
                allBaskets.remove(i);
                system.debug(errorMsg);
                continue;
            }
                    
            salesRepIdentifierForBasket.put(basket.Id, basket.Sales_Rep_Identifier__c);
            if (String.isNotBlank(basket.Contact_Identifier__c)) {
            	contactIdentifierForBasket.put(basket.Id, basket.Contact_Identifier__c);
            }
        }
                
        List<User> users = [SELECT  Id,
                                    Email 
                            FROM    User 
                            WHERE   Email IN: salesRepIdentifierForBasket.values()];

        Map<String, Id> usersMap = new Map<String, Id>();
        for (User singleUser : users) {
            usersMap.put(singleUser.Email, singleUser.Id);
        }
        Map<String, Id> contactMap;
        if (!contactIdentifierForBasket.isEmpty()) {
	        List<Contact> contacts = [  SELECT  Id,
	                                            AdPoint_Id__c 
	                                    FROM    Contact 
	                                    WHERE   AdPoint_Id__c IN: contactIdentifierForBasket.values()];
	        contactMap = new Map<String, Id>();
	        for (Contact singleContact : contacts) {
	            contactMap.put(singleContact.AdPoint_Id__c, singleContact.Id);
	        }
        }

        for (Integer i = 0; i< allBaskets.size(); i++) {
            String errorMsg = '';
            Date todayDate = Date.today();
            cscfga__Product_Basket__c basket = allBaskets[i];
            if (usersMap.get(basket.Sales_Rep_Identifier__c)== null ) {
                errorMsg += 'No user for email '+ basket.Sales_Rep_Identifier__c;
                
                if (basket.Campaign_Start_Date__c < todayDate ) {
                    if (errorMsg!='') {
                        errorMsg += ', ';
                    }
                    errorMsg += 'Campaign Start Date needs to be later than today ('+basket.Campaign_Start_Date__c+')';
                }
                if (basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Processing_Error_Message__c== null) {
                    basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Processing_Error_Message__c = '';
                }
                basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Processing_Error_Message__c += 'Following information is in incorrect format: '+errorMsg;
                //make sure resulting error msg isn't longer than the field length
                basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Processing_Error_Message__c = basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].Processing_Error_Message__c.left(255);
                errorOrderRequests.add(basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0]);
                allBaskets.remove(i);
                system.debug(errorMsg);
                continue;
            }
            else {
                basket.OwnerId = usersMap.get(basket.Sales_Rep_Identifier__c);
                if (contactMap != null && contactMap.containsKey(basket.Contact_Identifier__c)) {
                    basket.Booking_Contact__c = contactMap.get(basket.Contact_Identifier__c);
                }
            }           
        }

        if (!errorOrderRequests.isEmpty()) {
            update errorOrderRequests;
            system.debug (errorOrderRequests);
        }               
    }

    void SchedulePayments() {
        for (csmso__Sales_Order__c salesOrder : oppIdsalesOrder.values()) {
            Order_PaymentSchedulerController.getOrder(salesOrder.csmso__Opportunity__c, salesOrder);
            System.debug('**** CT-Payment - Opp -- ' + opportunityMap.get(salesOrder.csmso__Opportunity__c));
            Order_PaymentSchedulerController.createPayment(salesOrder, opportunityMap.get(salesOrder.csmso__Opportunity__c));
            Order_PaymentSchedulerController.createPaymentSchedule(salesOrder);
            Order_PaymentSchedulerController.createPaymentLineItem(salesOrder);
        }
    }

    List<Opportunity> CreateOpportunities () {
        opportunityMap = new Map<Id, Opportunity>();
        List<Opportunity> tempOppList =     new List<Opportunity>();
        Map<String, Decimal> basketPrice =  new Map<String, Decimal>();
        Map<Id, Opportunity> basketIdToOpp =   new Map<Id, Opportunity>();     
        String OppCampName = '';
        
        for (cscfga__Product_Basket__c basket : allBaskets) {
            OppCampName = basket.Campaign_Name__c.replace(',',' '); //validation rule for xtend doesn't allow comma in a name
            Opportunity newOpp = new Opportunity (
                AccountId = basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].csb2c__Account__c,
                Payer_Account__c = basket.csb2c__Inbound_Ecommerce_Order_Requests1__r[0].csb2c__Account__c,
                Description = 'Campaign Track Opportunity ' + basket.Campaign_Name__c,
                Name = ('Xtend - ' + OppCampName).left(120),
                Probability = 100,
                StageName = 'Discover Needs',
                CloseDate = Date.today(),
                OpportunityGroup__c = 'NewsXtend',
                Classification__c='Existing Business',
                Competitor__c='Other',
                RecordTypeId = UtilMethods.getRecordTypeId('Opportunity.Real Estate'),
                OwnerId = basket.OwnerId);
            
            tempOppList.add(newOpp);
            basketPrice.put(newOpp.Name, basket.cscfga__Total_Price__c);
            //Id will be populated after insert
            basketIdToOpp.put(basket.Id, newOpp);
        }

        insert tempOppList;

        Product2 xtendProduct = [SELECT Id, 
                                        Name 
                                FROM    Product2 
                                WHERE   Name = 'Digital - NewsXtend' 
                                LIMIT 1];
        PricebookEntry xtendProdEntry = [   SELECT  Id, 
                                                    Name 
                                            FROM    PricebookEntry 
                                            WHERE   Name = 'Digital - NewsXtend' 
                                            LIMIT 1];

        List<OpportunityLineItem> allOLIs = new List<OpportunityLineItem>();
        for (Opportunity singleOpp : tempOppList) {
            OpportunityLineItem oli = new OpportunityLineItem (
                Product2Id = xtendProduct.Id, 
                PricebookEntryId = xtendProdEntry.Id,
                TotalPrice = basketPrice.get(singleOpp.Name), 
                OpportunityId = singleOpp.Id, 
                Quantity = 1);
            
            allOLIs.add(oli);
        }
        insert allOLIs;

        for (cscfga__Product_Basket__c basket : allBaskets) {
            basket.cscfga__Opportunity__c = basketIdToOpp.get(basket.Id).Id;
        }
        update allBaskets;
        //populate opportunityMap with fresh Opp data as downstream process uses fields that we did not set
        opportunityMap = new Map<Id, Opportunity>([SELECT Id, AccountId, Payer_Account__c, Description, Name, Probability, StageName, CloseDate,
                                                    OpportunityGroup__c, Classification__c, Competitor__c, RecordTypeId, OwnerId, Account.AdPoint_ID__c,
                                                    Payer_Account__r.AdPoint_ID__c, TM1_Publication__c, JDE_Publication_Code__c
                                                FROM Opportunity
                                                WHERE Id IN :tempOppList]);
        return opportunityMap.values();
    }

	//Batchable interface implementation methods
	/**
	 * Prepare context, query all Order requests that we need to process.
	 */
	global Database.QueryLocator start(Database.BatchableContext batchableContext) {
		//start is earlist datetime for today
		Datetime startDateTime = Datetime.now().addHours(-24);
		//end is 60 minutes ago so we don't overlap with real-time processing
		Datetime endDateTime = Datetime.now().addHours(-1);
		return Database.getQueryLocator([SELECT Id, csb2c__Product_Basket__c
										FROM csb2c__Inbound_Ecommerce_Order_Request__c
										WHERE Observer_Processing_Done__c = false AND csb2c__Product_Basket__c != null
											AND CreatedDate >= : startDateTime AND CreatedDate <= : endDateTime]);
	}

	/**
	 * Processing order requests by extracting basket Id and calling class
	 * that is used for real-time processing.
	 */
	global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
		List<Id> basketIds = new List<Id>();
		for (csb2c__Inbound_Ecommerce_Order_Request__c eOrderReq : (List<csb2c__Inbound_Ecommerce_Order_Request__c>)scope) {
			basketIds.add(eOrderReq.csb2c__Product_Basket__c);
		}
		if (!basketIds.isEmpty()) {
			APIPostRuleExecution apiPRE = new APIPostRuleExecution(basketIds);
			//execute right away
			apiPRE.execute(null);
		}
	}

	global void finish(Database.BatchableContext BC){
		//Not used for now
	}
}