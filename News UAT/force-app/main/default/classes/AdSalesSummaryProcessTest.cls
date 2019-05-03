/*---------------------------------------------------------
 * Author: David Dawson
 * Company: Bluewolf
 * Description: A unit test class to test the AdSales process (this process will cover the Opportunity (Pipeline) and the Sales Order (Actual) objects.)
 * History: Class Created.
            Opportunity Pipeline process test class completed.
 *
 * Update: 15/08/2016 - Peter Charalambous
 * Revenue Reporting R1.2 Solution
 * Description: Adsales process to test Revenue Reporting functionality
 *
 * Updated: 2017-05-17 Item-00276 louis.wang@bluewolf.com - updated test class to work with conditional mandatory Opportunity.Contact__c
 *
 * Updated: 2018-04-27 david.scullion@news.com.au - updated test class to allow for validation rules for contact email and revenue group required on an Opportunity.
 ---------------------------------------------------------*/

@isTest
private class AdSalesSummaryProcessTest {
    
    static testMethod void StagingObjectIntegrationTest() {
        
        TriggerSwitches__c ts = new TriggerSwitches__c(RevReporting__c = true, RevReportingActual__c = true);
        insert ts;
        
        Date todayMinusSix = system.Today() + 6;
        String CRON_EXP = '0 0 0 ' + String.valueOf(todayMinusSix.Day()) + ' ' + String.valueOf(todayMinusSix.Month()) + ' ? ' + String.valueOf(todayMinusSix.Year());
        
        SalesSummaryStaging__c sss = new SalesSummaryStaging__c(SiebelLogin__c = 'DDawson', EmployeeFirstName__c = 'David', EmployeeLastName__c = 'Dawson', FiscMonthId__c = '201603', FiscYear__c = 2016, TargetType__c = 'PORTFOLIO', TargetArea__c = 'PRINT', NRTargetAmount__c = 500000, TargetArea2__c = 'INDIVIDUAL', BookingRevenueType__c = 'PRINT', BookingRevenueAmount__c = 250000, DivisionId__c = '188', EmployeeRole__c = 'VIC - Sales Manager Metro 1', NRPublishedRevenue__c = 600000, NRCredits__c = -180000, NRDebits__c = 0, NRActualRevenue__c = 450000, PortfolioName__c = 'SALES MANAGER');

        //Begin testing the opportunity triggers
        Test.startTest();

        insert sss;
        
        //Schedule the test job
        String jobId = System.schedule('ScheduleApexClassTest',CRON_EXP,new SalesSummaryStagingCleanUpSCHED());
        
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];
     
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP,ct.CronExpression);
        
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered);
        
        //Stop testing the opportunity triggers
        Test.stopTest();
    }

    static testMethod void SalesOrderActualTest() {
        
        //need to ensure that we can access the custom metadata without the seealldata parameter
        List<FiscalCalendar__mdt> ncfcList = new List<FiscalCalendar__mdt>([SELECT Id, DT_ID__c, Date__c, FISC_MNTH_FIRST_DAY_DT__c, FISC_MNTH_LAST_DAY_DT__c, FISC_MNTH_NM__c FROM FiscalCalendar__mdt LIMIT 10]);
        System.assertEquals(10, ncfcList.size());

        TriggerSwitches__c ts = new TriggerSwitches__c(RevReporting__c = true, RevReportingActual__c = true);
        insert ts;

        SystemParameters__c sp = new SystemParameters__c(Description__c = 'This is the ID of user who is default sales rep (Integrator)', External_Id__c = 'Default Sales Rep', Name = 'Default Sales Rep', Value__c = '00590000002BFcD');
        insert sp;
        
        Account testAccount = new Account(Name = 'Test Account', No_Parent_Account__c = true,Revenue_Group__c = 'House');
        insert testAccount;

        Contact testContact = new Contact(FirstName = 'Test', LastName = 'Contact', No_Email__c = True);
        insert testContact;

        Sales_Order__c testSalesOrder = new Sales_Order__c(Status__c = 'Booking', Status_As_Of__c = system.Today(), Ad_Taker__c = UserInfo.getUserId(),Advertiser_Account__c = testAccount.Id, Placer_Account__c = testAccount.Id, Contact__c = testContact.Id);
        insert testSalesOrder;
        
        List<String> dateList = new List<String>();
        Integer i = 1;
        do{
           String xDate = '01/' + String.valueOf(i) + '/' + String.valueOf(system.Today().Year()); 
           dateList.add(xDate);
           i++;
        }while(i<13);
        
        List<Opportunity> opList = new List<Opportunity>();
        for(String d :dateList){
            Opportunity testOpportunity = new Opportunity(Competitor__c = 'Letterbox', 
                                                            OwnerCurrentRole__c = 'Test Role',
                                                            Name = 'Test Opportunity #1', 
                                                            Type = 'Core Activity', 
                                                            Campaign_Start_Date__c = system.Today(),
                                                            ForecastCategoryName = 'Pipeline', 
                                                            Description = 'This is just a test opportunity, nothing to see here. Move along please.', 
                                                            Opportunity_Type__c = 'Multi-Channel', 
                                                            AccountId = testAccount.Id, 
                                                            Amount = 5000, 
                                                            Classification__c = 'New Business   ', 
                                                            RevenueType__c = 'Print', 
                                                            StageName = 'Qualify Opportunity',
                                                            Contact__c = testContact.Id);
//            testOpportunity.CloseDate = date.parse(d);
                testOpportunity.CloseDate = system.Today();
            opList.add(testOpportunity);
        }
        insert opList;

        Product2 testProduct = new Product2(Name = 'Test Product', Family = 'Digital', ProductCode = 'PRO123456', IsActive = true);
        insert testProduct;

        Id pricebookId = Test.getStandardPricebookId();

        PriceBookEntry testPBE = new PriceBookEntry(Pricebook2Id = pricebookId, Product2Id = testProduct.Id, UnitPrice = 50, IsActive = true);
        insert testPBE;

        OpportunityLineItem opProduct = new OpportunityLineItem(OpportunityId = opList[0].Id, Sales_Order__c = testSalesOrder.Id, PriceBookEntryId = testPBE.Id, Quantity = 1, TotalPrice = 50);
        insert opProduct;

        Booking__c bookItem = new Booking__c(Ad_Taker__c = 'TestUserName', Status__c = 'Status Test', Sales_Order__c = testSalesOrder.Id, Sales_Rep__c = 'Peter');
        insert bookItem;

        /*Product2 prodTest = new Product2(Name = 'prod Test', Family = 'Digital', ProductCode = 'PRO182746', IsActive = true);
        insert prodTest;*/

        //Begin testing the opportunity triggers
        Test.startTest();

        //test a digital line item
        Booking_Line_Item__c bliItem = new Booking_Line_Item__c(Booking__c = bookItem.Id, Product__c = testProduct.Id, Ad_Type__c = 'Ad Test', Booked_Class__c = 'Test Booked Class', Run_Date__c = System.today(), Stop_On_Web_Date__c = System.today()+60);
        insert bliItem;

        //test a print line item
        Booking_Line_Item__c bliItemPrint = new Booking_Line_Item__c(Booking__c = bookItem.Id, Product__c = testProduct.Id, Ad_Type__c = 'Ad Test', Booked_Class__c = 'Test Booked Class', Run_Date__c = System.today());
        insert bliItemPrint;

        //ensure the created booking line item has a month id
        List<BookingLineItemRevenueDist__c> bliDistCheckList = new List<BookingLineItemRevenueDist__c>([SELECT Id, FiscalMonthId__c, SalesSummary__c FROM BookingLineItemRevenueDist__c WHERE BookingLineItem__c =:bliItem.Id]);
        System.assert(bliDistCheckList[0].FiscalMonthId__c != null, 'Fiscal Month is null on Booking Line Item Revenue Distributed record');
        System.assert(bliDistCheckList[0].SalesSummary__c != null, 'No Sales Summary record allocated to Booking Line Item Revenue Distributed record');

        //test to trigger Delete class.
        bliItem.Run_Date__c = system.Today() - 2;
        update bliItem;

        //ensure there is a sales summary record generated
        List<SalesSummary__c> ssList = new List<SalesSummary__c>([SELECT Id FROM SalesSummary__c WHERE Type__c = 'Actual']);
        System.assert(!ssList.isEmpty(), 'There are no Actual sales summary records');

        //test deleting the bli (rollup coverage)
        delete bliItem;

        //Stop testing the opportunity triggers
        Test.stopTest();
    }

}