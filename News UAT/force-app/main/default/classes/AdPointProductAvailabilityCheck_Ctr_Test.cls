@isTest
private class AdPointProductAvailabilityCheck_Ctr_Test 
{
    static testMethod void vfPageTest() 
    {
    	SystemParameters__c sysParam = new SystemParameters__c();
    	sysParam.Value__c = 'https://test.adpoint.news.newslimited.local';
    	sysParam.Description__c = 'domain URLfor AdPoint';
    	sysParam.Name = 'AdPoint_Url';
    	sysParam.External_Id__c = 'AdPoint_Url';
    	insert sysParam;
 
        Test.startTest();
    	
        PageReference pageRef = Page.AdPointProductAvailabilityCheck;
        pageRef.getParameters().put('s', 'true');
        Test.setCurrentPage(pageRef);
        
        AdPointProductAvailabilityCheck_Ctr adPointProductCheckCtr = new AdPointProductAvailabilityCheck_Ctr();
        
        String adPointUrl = adPointProductCheckCtr.adPointUrl;
        Boolean showFlag = adPointProductCheckCtr.showHeaderAndSidebar;
        
        system.assertEquals('https://test.adpoint.news.newslimited.local', adPointUrl);
        system.assert(showFlag);
        
        Test.stopTest();
    }
}