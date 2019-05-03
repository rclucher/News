/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 * 2017-06-28 Item-00323 louis.wang@bluewolf.com - added new test method for new functionality
 *
 *      This class provides test coverage for
 *          - emailAttachmentReassigner.trigger     100%
 *          - AttachmentTrigger_Helper              97%
 */
@isTest
private class emailAttachmentReassignerTest 
{
    static testmethod void attachmentTester() 
    {
        Case c = new Case();
        insert c;
        
        EmailMessage em = new EmailMessage();
        em.parentId = c.id;
        em.MessageDate = Date.today();
        em.FromAddress = 'test@from.com';
        em.ToAddress = 'test@to.com';
        em.Subject = 'test subject';
        em.TextBody = 'heres a text body.';
        insert em;
                
    
        Attachment a = new Attachment();
        a.name = 'test attachment';
        a.body = blob.valueof('attachment body');
        a.parentid = em.id;
        insert a;   
        
        List<Attachment> attachments = [Select Id From Attachment Where parentId = :c.id];
        
        System.assert(attachments.size() == 1, 'Wrong number of attachments (( ' + attachments.size() );
    }

    static testmethod void createDocumentTest()
    {
        // 2017-06-28 Item-00323 louis.wang@bluewolf.com 
        //      Create an Attachment under CyberSell Booking. Observe that a Document record is created.

        // create users
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
                
        // set default sales rep
        // treat last user in the list as default sales rep
        SystemParameters__c salesRep = new SystemParameters__c(Name = 'Default Sales Rep', Value__c = users[0].Id, External_Id__c = '1234');
        insert salesRep;
       
        // create booking
        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber$ell');
        List<Booking__c> bookings = TestDataFactory.createBookings(1, so);
        insert bookings;

        Test.startTest();

        // create attachment
        List<Attachment> attachments = TestDataFactory.createAttachment(1, 'text', bookings[0].Id);
        insert attachments;
        Test.stopTest();

        // observe 1 Document record is created
        List<Document> docList = [SELECT Id, FolderId, Name FROM Document];
        system.assertEquals(docList.size(), 1);
    }   

    static testmethod void createDocumentTest_Negative()
    {
        // 2017-06-28 Item-00323 louis.wang@bluewolf.com 
        //      Create an Attachment under AdPoint Booking. Observe that no Document record is created.

        // create a sales order
        Sales_Order__c so = TestDataFactory.createSalesOrder('AdPoint');
        
        // create system parameters
        TestDataFactory.createFaxSystemParameters();
        
        // create a booking
        Booking__c bk = TestDataFactory.createBooking(so);
        

        Test.startTest();

        // create attachment
        List<Attachment> attachments = TestDataFactory.createAttachment(1, 'text', bk.Id);
        insert attachments;
        Test.stopTest();

        List<Document> docList = [SELECT Id, FolderId, Name FROM Document];
        system.assertEquals(docList.size(), 0);
    }
}