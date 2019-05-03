@isTest
private class CS_LightningTransitionTest {
    
    @testSetup static void setup() {
        // Set up test data
        Account sAccount = TestDataSetupClass.createAccount();
        insert sAccount;
        
        Contact sContact = TestDataSetupClass.createContact(sAccount);
        insert sContact;
        
        Opportunity sOpportunity = TestDataSetupClass.createOpportunity(sAccount, sContact);
        insert sOpportunity;
        
        Order__c sOrder = TestDataSetupClass.createOrder(sOpportunity);
        insert sOrder;
        
        Product_Order__c sProductOrder = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = sOrder.Id,
            Status__c = 'In Progress');
        insert sProductOrder;
		
		Payment__c sPayment = new Payment__c(
			Name = 'Test Payment',
			Order__c = sOrder.Id);
		insert sPayment;
    }
    
    
    @isTest
    static void testStartPOFulfilment() {
        Product_Order__c sProductOrder = [SELECT ID From Product_Order__c LIMIT 1];
        
        //test start fulfilment PO
        Boolean startFulfilmentResult = Start_Fulfilment_Product_Order.updateOrder(String.valueOf(sProductOrder.Id));
    }
    
    
    
    @isTest
    static void testPauseProductOrder() {
        Product_Order__c sProductOrder = [SELECT ID From Product_Order__c LIMIT 1];
        
        Boolean result = Pause_Product_Order_modalbox.updateOrder(String.valueOf(sProductOrder.Id));
    }
    
    @isTest
    static void testStartCancel_Product_Order_modalbox() {
        Product_Order__c sProductOrder = [SELECT ID From Product_Order__c LIMIT 1];
        
        Boolean result = Cancel_Product_Order_modalbox.updateOrder(String.valueOf(sProductOrder.Id));
    }

    
    @isTest
    static void testPause_Campaign_modalbox() {
        Order__c sOrder = [SELECT ID From Order__c LIMIT 1];
        
        Boolean result = Pause_Campaign_modalbox.updateOrder(String.valueOf(sOrder.Id));
    }
    @isTest
    static void testReturn_Campaign_to_Sales_ctrl() {
        Order__c sOrder = [SELECT ID From Order__c LIMIT 1];
        
        Boolean result = Return_Campaign_to_Sales_ctrl.updateOrder(String.valueOf(sOrder.Id));
        string strResult = Return_Campaign_to_Sales_ctrl.initClass(String.valueOf(sOrder.Id)); 
    }    
    @isTest
    static void testCancel_Order_modalbox() {
        //Order__c sOrder = [SELECT ID From Order__c LIMIT 1];
		Payment__c sPayment = [SELECT ID FROM Payment__c LIMIT 1];
        
        Boolean result = Cancel_Order_modalbox.updateOrder(String.valueOf(sPayment.Id));
    }
    
    
    @isTest
    static void testStart_Fulfilment() {
        Order__c sOrder = [SELECT ID From Order__c LIMIT 1];
        
        String result = Start_Fulfilment.Start_Fulfilment_mtd(String.valueOf(sOrder.Id));
    }
    

    
    @isTest
    static void testSchedule_payment_ctrl() {
        Opportunity sOpportunity = [SELECT ID From Opportunity LIMIT 1];
        
        String result = Schedule_payment_ctrl.schedulePayment(sOpportunity.Id);
    }
    
    @isTest
    static void testPriorityextension() {
        
        Order__c sOrder = [SELECT ID From Order__c LIMIT 1];
        Product_Order__c sProductOrder = [SELECT ID From Product_Order__c LIMIT 1];
        Opportunity sOpportunity = [SELECT ID From Opportunity LIMIT 1];
        
        
        Test.starttest();
        ApexPages.StandardController ctrl = new ApexPages.StandardController(sOrder);
        CS_CampaignPriorityExtension priority = new CS_CampaignPriorityExtension(ctrl);
        
        
        ApexPages.StandardController ctrlr = new ApexPages.StandardController(sProductOrder);
        CS_CampaignPriorityExtension prioritys = new CS_CampaignPriorityExtension(ctrlr);
        
        
        
        prioritys.executePriorityLogic('2 - Normal');
        prioritys.executePriorityLogic('3 - High');
        priority.executePriorityLogic('2 - Normal');
        priority.executePriorityLogic('3 - High');
        priority.executeHighPriorityLogic();
        priority.executeNormalPriorityLogic();
        
        Test.stoptest();
        
        
    } 
    
    @isTest
    static void testrecreate_tag() {
        
        Order__c sOrder = [SELECT ID From Order__c LIMIT 1];
        
        
        Test.starttest();
        
        ApexPages.StandardController controller = new ApexPages.StandardController(sOrder);
        recreate_tag rtag = new recreate_tag(controller);
        rtag.executeRecreateLogic();
        
        Test.stoptest();
    }
    @isTest
    static void TestCS_CampaignBriefFormExtension() {
        
        Order__c sOrder = [SELECT ID From Order__c LIMIT 1];
        
        Test.starttest();
        
        ApexPages.StandardController controller = new ApexPages.StandardController(sOrder);
        CS_CampaignBriefFormExtension rtag = new CS_CampaignBriefFormExtension(controller);
        rtag.creatOrViewBriefForm();
        
        Test.stoptest();
    }
}