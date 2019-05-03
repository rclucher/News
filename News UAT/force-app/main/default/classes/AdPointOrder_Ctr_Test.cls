/*
 * History:
 * 2015-11-25   Darshan G   Updated
 // 2015-11-25 darshan.gosar@bluewolfgroup.com 
        // This class provides test coverage for
        //  - AdPointOrder_Controller  100%
 */
@isTest
private class AdPointOrder_Ctr_Test 
{
    static testMethod void vfPageTest() 
    {
        List<SystemParameters__c> sysParams = new List<SystemParameters__c>();
        
        SystemParameters__c sysParam1 = new SystemParameters__c();
        sysParam1.Value__c = 'https://test.adpoint.news.newslimited.local';
        sysParam1.Description__c = 'domain URLfor AdPoint';
        sysParam1.Name = 'AdPoint_Url';
        sysParam1.External_Id__c = 'AdPoint_Url';
        sysParams.add(sysParam1);
        
        SystemParameters__c sysParam2 = new SystemParameters__c();
        sysParam2.Value__c = '005O0000000oq1q';
        sysParam2.Description__c = 'This is the ID of user who is default sales rep';
        sysParam2.Name = 'Default Sales Rep';
        sysParam2.External_Id__c = 'Default Sales Rep';
        sysParams.add(sysParam2);
        
        insert sysParams;
 
        Sales_Order__c so = TestDataFactory.createSalesOrder('AdPoint');
        Booking__c booking = TestDataFactory.createBooking(so);
        
        Test.startTest();
        
        PageReference pageRef = Page.AdPointOrder;
        pageRef.getParameters().put('s', 'true');
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardController ctr = new ApexPages.StandardController(booking);
        AdPointOrder_Controller adPointOrderCtr = new AdPointOrder_Controller(ctr);
        
        String adPointUrl = adPointOrderCtr.PageBaseURL;
        Boolean showFlag = adPointOrderCtr.showHeaderAndSidebar;
        
        system.assertEquals('https://test.adpoint.news.newslimited.local', adPointUrl);
        system.assert(showFlag);
        
         // SFE-766 2015-11-25 darshan.gosar@bluewolfgroup.com
            // Added to increase code coverage
        AdPointOrder_Controller adPointOrderCtrl = new AdPointOrder_Controller();
        adPointOrderCtrl.syncCalled = false;
        Test.stopTest();
    }
}