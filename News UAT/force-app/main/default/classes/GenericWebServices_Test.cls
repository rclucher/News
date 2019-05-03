/**
 * GenericWebServices_Test
 *
 * @description Test class for GenericWebServices
 *
 * @author      Tim Fabros
 * @date        2015-06-26
 */
@isTest
private class GenericWebServices_Test {
    
    @isTest static void userHasEditAccess_Test() {
        // create test data
        User user = TestDataFactory.createUser('System Administrator', 'TestLastName', 'TestFirstName', null, false, false);
        insert user;

        // begin test
        Test.startTest();

        System.runAs(user)
        {
            Account account = TestDataFactory.createSingleAccount(null, null, null, null, null);
            insert account;

            Boolean expectedValue = false;
            expectedValue = GenericWebServices.userHasEditAccess(user.Id, account.Id);
            System.debug(expectedValue);
            // throw exception with null value
            expectedValue = GenericWebServices.userHasEditAccess('wrongId-!=@%asdf3234sdfges45rt4', 'wrongId-!=@%');
            System.debug(expectedValue);
        }
        
        Test.stopTest();
    }

    @isTest
    static void test_createCreativeForProductOrderId() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Status__c = 'Draft';
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Assigned_Social_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id,
            Status__c = 'Draft'
        );
        insert pOrd;

        Test.startTest();

        System.assertNotEquals(null, GenericWebServices.createCreativeForProductOrder(pOrd.Id, UserInfo.getUserId()));

        Test.stopTest();
    }

@isTest
    static void test_startOrchProcessFor() {
        Order__c order = TestDataSetupClass.createOrder(new Opportunity());
        order.Assigned_Campaign_Manager__c = UserInfo.getUserId();
        order.Status__c = 'Draft';
        insert order;

        Product_Order__c pOrd = new Product_Order__c(
            Assigned_Fulfilment_Owner__c = UserInfo.getUserId(),
            Order__c = order.Id
        );
        insert pOrd;

        CSPOFA__Orchestration_Process_Template__c template = new CSPOFA__Orchestration_Process_Template__c(
            Name = 'Campaign Setup'
        );
        insert template;

        CSPOFA__Orchestration_Process__c process = new CSPOFA__Orchestration_Process__c(
            Product_Order__c = pOrd.Id,
            CSPOFA__Orchestration_Process_Template__c = template.Id
        );
        insert process;

        CSPOFA__Orchestration_Step__c step = new CSPOFA__Orchestration_Step__c(
            New_Orch_Process__c = template.Name,
            CSPOFA__Orchestration_Process__c = process.Id
        );
        insert step;

        Test.startTest();

        GenericWebServices.startOrchProcessFor(pOrd.Id, 'Campaign Setup');

        Test.stopTest();
    }

    @isTest
    static void test_regenerateProductOrdersNoOrder() {
        Test.startTest();

        System.assertEquals('Cannot find Order.', GenericWebServices.regenerateProductOrders(null));

        Test.stopTest();
    }


    @isTest
    static void test_getCampaignState() {
        Campaign ca = new Campaign(Name='Test Campaign');
        ca.Status = 'Launched';
        
        Date todaysDate = Date.today();
        ca.StartDate = todaysDate;
        ca.EndDate = todaysDate.addMonths(1);
        ca.NEWS_Campaign_Type__c = 'Acquisition';
        insert ca;

        Campaign resCampaign = GenericWebServices.getCampaignState(ca.Id);
        System.assert(resCampaign.Status == 'Launched' );
        System.assert(resCampaign.IsActive != null);
    }

}