@IsTest
public class CreateMarketingCloudQuoteTaxEmailsTest {
    public static Booking__c booking;
    public static Messaging.InboundEmail email;
    public static Messaging.InboundEnvelope env;
    public static void setup(){
        User u = TestDataFactory.createUser('System Administrator', 'testLast', 'testFirst', null, false, false);
        insert u;
        TestDataFactory.createFaxSystemParameters();
        
        List<Booking_Oppty_Status_Map__c> bookingOpptyStatusMap = new List<Booking_Oppty_Status_Map__c>();
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Reservation', OpptyStatus__c='Reservation'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Cancelled', OpptyStatus__c='Closed Lost', OpptyReason__c = 'Withdrawn'));
        bookingOpptyStatusMap.add(new Booking_Oppty_Status_Map__c(Name='Active', OpptyStatus__c='Closed Won', OpptyReason__c = 'Masthead Reputation'));
        insert bookingOpptyStatusMap;
        // create account
        List<Account> accounts = TestDataFactory.createAccounts(1, false);
        for (Account a : accounts)
        {
            a.OwnerId = u.Id;
        }
        insert accounts;
        
        // create contact
        List<Contact> contacts = TestDataFactory.createContacts(1, accounts[0]);
        for (Contact c : contacts)
        {
            c.OwnerId = u.Id;
        }
        insert contacts;
        
        // create 10 products
        List<Product2> products = TestDataFactory.createProducts(2);
        
        // create pricebooks
        List<Pricebook2> pricebooks = TestDataFactory.createCustomPricebookData();
        List<PricebookEntry> pricebookEntries = TestDataFactory.createPricebookEntryData(pricebooks[0], products);
        Id stdPricebookId = Test.getStandardPricebookId();
        
        // create 2 sales orders
        List<Sales_Order__c> salesOrders = TestDataFactory.createSalesOrders(1, accounts[0], accounts[0], accounts[0], contacts[0], null);
        List<Sales_Order__c> salesOrders1 = new List<Sales_Order__c>();
        for (Sales_Order__c so : salesOrders)
        {
            so.OwnerId = u.Id;
            salesOrders1.add(so);
        }
        insert salesOrders1;
        Sales_Order__c so = salesOrders1[0];
        booking = new booking__c();
        booking.Name = 'xre124';
        booking.Sales_Order__c = so.Id;
        booking.Booking_Number__c = 'xre124';
        booking.External_Id__c = 'xre124';
        booking.Advertiser_Account__c = so.Advertiser_Account__c;
        system.debug('booking '+booking);
        insert booking;
        
        // Create a new email and envelope object
        email  = new Messaging.InboundEmail();
        env = new Messaging.InboundEnvelope();
        email.plainTextBody = 'This should become a note';
        email.fromAddress ='test@test.com';
        email.subject = 'Your NewsAdds -- Tax Invoice - '+booking.External_Id__c;
        String contactEmail = 'jsmith@salesforce.com';
        email.ccAddresses = new String[] {'Jon Smith <' + contactEmail + '>'};
            }
    @isTest
    public static void deleteOldOrder_Payment(){
        setup();
        CreateMarketingCloudQuoteTaxEmails emailHandler = new CreateMarketingCloudQuoteTaxEmails();
        Test.startTest();
        Messaging.InboundEmailResult result = emailHandler.handleInboundEmail(email, env);
        Test.stopTest();
        List<EmailMessage> messagesCreated = [Select Id from EmailMessage where relatedtoid=:booking.id];
        System.assertEquals(1, messagesCreated.size(), 'An EmailMessage should have been created from the inbound email ');
    } 
}