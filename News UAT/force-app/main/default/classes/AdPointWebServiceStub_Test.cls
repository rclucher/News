/**
 * Company: Salesforce.com
 * description:  This class contains unit tests for class AdPointWebserviceStub
 * 12/12/2013   Bohao Chen Created
 **/
@isTest
private class AdPointWebServiceStub_Test 
{
    static testMethod void adPointCreateAccountTest() 
    {
        // setup accounts
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // setup adpoint endpoint url in custom setting
        SystemParameters__c adpointEndPointUrl = new SystemParameters__c();
        adpointEndPointUrl.Value__c = 'https://webmethodsdev.newsdev.com.au/ws/news.crm.adapter.pub:adPointSyncWD';
        adpointEndPointUrl.Name = 'AdPointWS_Endpoint';
        adpointEndPointUrl.External_Id__c = 'AdPointWS_Endpoint';
        insert adpointEndPointUrl;
        
        Test.startTest();
        
        Test.setMock(WebServiceMock.class, new AdPointWebserviceAccountSyncMock());
        
        Account testAcct = accounts[0];
        
        AdPointWebserviceStub_Helper adPointHelper = new AdPointWebserviceStub_Helper();
        adPointHelper.createDigitalAccount(testAcct);
        
        Test.stopTest();
    } 
    
    static testMethod void adPointCreateContactTest() 
    {
        // setup accounts
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        insert accounts;
        
        // setup contacts
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
                        
        Test.setMock(WebServiceMock.class, new AdPointWebserviceContactSyncMock());
        
        Test.startTest();
        
        Contact testCon = contacts[0];
        
        AdPointWebserviceStub_Helper adPointHelper = new AdPointWebserviceStub_Helper();
        adPointHelper.createDigitalContact(testCon, accounts[0].Id);
        
        Test.stopTest();
    } 
    
    static testMethod void adPointCreateOrderTest() 
    {
        // setup accounts
        List<Account> accounts = TestDataFactory.createAccounts(2, false);
        insert accounts;
        
        // setup contacts
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        insert contacts;
        
        Sales_Order__c so = TestDataFactory.createSalesOrder('AdPoint');
        
        Test.setMock(WebServiceMock.class, new AdPointWebserviceOrderSyncMock());
        
        Test.startTest();
        
        AdPointWebserviceStub_Helper adPointHelper = new AdPointWebserviceStub_Helper();
        adPointHelper.createOrder(contacts[0], accounts[0], accounts[1], so);
        
        Test.stopTest();
    }
    
    static AdPointWebserviceStub.crmAdPointAccount mapAccount(Account testAcct)
    {
        AdPointWebserviceStub.crmAdPointAccount accountReq = new AdPointWebserviceStub.crmAdPointAccount();
        
        accountReq.Id = testAcct.Id;
        accountReq.Name = testAcct.Name;
        accountReq.Phone = testAcct.Phone;
        accountReq.AccountNumber = testAcct.AccountNumber;
        accountReq.OwnerId = testAcct.OwnerId;
        accountReq.BillingCity = testAcct.BillingCity;
        accountReq.BillingCountry = testAcct.BillingCountry;
        accountReq.BillingPostalCode = testAcct.BillingPostalCode;
        accountReq.BillingState = testAcct.BillingState;
        accountReq.BillingStreet = testAcct.BillingStreet;
        accountReq.ShippingCity = testAcct.ShippingCity;
        accountReq.ShippingCountry = testAcct.ShippingCountry;
        accountReq.ShippingPostalCode = testAcct.ShippingPostalCode;
        accountReq.ShippingState = testAcct.ShippingState;
        accountReq.ShippingStreet = testAcct.ShippingStreet;
        
        return accountReq;
    }
    
    static AdPointWebserviceStub.crmAdPointContact mapContact(Contact testCon)
    {
        AdPointWebserviceStub.crmAdPointContact contactReq = new AdPointWebserviceStub.crmAdPointContact();
        
        contactReq.Id = testCon.Id;
        contactReq.FirstName = testCon.FirstName;
        contactReq.LastName = testCon.LastName;
        contactReq.Email = testCon.Email;
        contactReq.MobilePhone = testCon.MobilePhone;
        contactReq.Phone = testCon.Phone;
        contactReq.Salutation = testCon.Salutation;
        contactReq.Title = testCon.Title;
        contactReq.AccountId = testCon.AccountId;

        return contactReq;
    }
    
    static AdPointWebserviceStub.crmAdPointOrder mapSalesOrder(Sales_Order__c testOrder)
    {
        AdPointWebserviceStub.crmAdPointOrder orderReq = new AdPointWebserviceStub.crmAdPointOrder();
        
        orderReq.Customer_ID = '2926';
        orderReq.PaymentCondition_ID = '1';
        orderReq.Contract_ID = '0';
        orderReq.Name = testOrder.Name;

        return orderReq;
    }
}