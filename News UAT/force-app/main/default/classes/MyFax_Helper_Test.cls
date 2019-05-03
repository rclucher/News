/*---------------------------------------------------------
 * This class contains unit tests for validating the behavior of Apex classes
 *
 * Author: Bluewolf
 * Company: Salesforce.com
 * description: Test class for MyFax_Helper
 * History:
 * 2015-12-08  Atul Gupta Updated
 // 2015-12-16 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - MyFax_Helper   85%
    //  - TaskManagement 100%
 */
@isTest
private class MyFax_Helper_Test 
{
	
    static testMethod void myUnitTest() {
		
		TestDataFactory.createFaxSystemParameters();
		
		List<Account> accList = TestDataFactory.createAccounts(5, false);
		List<Contact> conList = TestDataFactory.createContacts(5, accList[0]);
		try{
			MyFax_Helper helperClass = new MyFax_Helper();
			helperClass.sendFax();
		
			helperClass.sendFax(true, conList[0].Id, conList[0].Id);
		}catch(Exception ex){
			system.assertEquals(true, ex.getMessage().contains('it must be between 1 and 50'));
		}
    }
    
    static testMethod void testDocumentSize() {
		
		
		TestDataFactory.createFaxSystemParameters();
		
		List<Account> accList = TestDataFactory.createAccounts(5, false);
		insert accList;
		List<Contact> conList = TestDataFactory.createContacts(5, accList[0]);
		insert conList;
		List<Attachment> attList = new List<Attachment>();
    	
		Blob b = Blob.valueOf('Test Data test test test tste est test tses estesestse');
    	
    	Attachment attachment = new Attachment();
    	attachment.ParentId = conList[0].Id;
    	attachment.Name = 'Test_file.txt'; 
    	attachment.ContentType = 'text/plain';
    	attachment.Body = b;
    	attList.add(attachment);
    	insert attList;

		MyFax_Helper helperClass = new MyFax_Helper();
		List<Attachment> attachList = [Select id, body, bodylength, contenttype, parentid, name from Attachment];
		
		helperClass.addAttachment(attachList[0]);
		helperClass.addFaxRecipient('testName', '9876543212', '12345');
		
		Test.StartTest();
		Test.setMock(WebServiceMock.class, new wsMyfaxComMock());
		helperClass.sendFax(true, conList[0].Id, conList[0].Id, null);
		Test.stopTest();
    }
    
    static testMethod void testBinaryDocument() {
		
		
		TestDataFactory.createFaxSystemParameters();
		
		List<Account> accList = TestDataFactory.createAccounts(5, false);
		insert accList;
		List<Contact> conList = TestDataFactory.createContacts(5, accList[0]);
		insert conList;
		List<Attachment> attList = new List<Attachment>();
    	
		Blob b = Blob.valueOf('Test Data');
    	
    	Attachment attachment = new Attachment();
    	attachment.ParentId = conList[0].Id;
    	attachment.Name = 'Test_file1'; 
    	attachment.ContentType = 'application/vnd.ms-excel';
    	attachment.Body = b;
    	attList.add(attachment);
    	insert attList;

		MyFax_Helper helperClass = new MyFax_Helper();
		List<Attachment> attachList = [Select id, body, bodylength, contenttype, parentid, name from Attachment];
		
		helperClass.addAttachment(attachList[0]);
    }
    
    //Test addFile method for Attachment Id
    static testMethod void testAddFileMethodForAttachment() {
		
		TestDataFactory.createFaxSystemParameters();
		
		List<Account> accList = TestDataFactory.createAccounts(5, false);
		insert accList;
		List<Contact> conList = TestDataFactory.createContacts(5, accList[0]);
		insert conList;
		List<Attachment> attList = new List<Attachment>();
    	
		Blob b = Blob.valueOf('Test Data');
    	
    	Attachment attachment = new Attachment();
    	attachment.ParentId = conList[0].Id;
    	attachment.Name = 'Test_file1'; 
    	attachment.ContentType = 'text/plain';
    	attachment.Body = b;
    	attList.add(attachment);
    	insert attList;

		MyFax_Helper helperClass = new MyFax_Helper();
		List<Attachment> attachList = [Select id, body, bodylength, contenttype, parentid, name from Attachment];
		try{
			helperClass.addFile(attachList[0].Id);
		}catch(Exception ex){
			system.assertEquals(ex.getMessage().contains('Invalid Id, the file id must be a Attachment or a Document'), true);
		}
    }
    
    //Test addFile method for Document Id
    static testMethod void testAddFileMethodForDocument() {
		
		TestDataFactory.createFaxSystemParameters();
		
		List<Account> accList = TestDataFactory.createAccounts(5, false);
		insert accList;
		List<Contact> conList = TestDataFactory.createContacts(5, accList[0]);
		insert conList;
		List<Attachment> attList = new List<Attachment>();
    	
		//Blob b = Blob.valueOf('Test Data');
    	
		Document doc = new Document();
		doc.FolderId = Userinfo.getuserId();
		doc.Body = Blob.valueOf('JSON string');
		doc.contenttype = 'application/vnd.ms-excel';
		doc.Name = 'Doc Name';
		insert doc;

		MyFax_Helper helperClass = new MyFax_Helper();
		List<Document> docList = [Select id, name, body, folderid from Document];
		
		helperClass.addFile(docList[0].Id);
		
		helperClass.getComment();
		helperClass.getCoverPageStatusAnswer();
		helperClass.getCoverPageStatusComment();
		helperClass.getCoverPageStatusComment();
		helperClass.getCoverPageStatusReview();
		helperClass.getCoverPageStatusUrgent();
    }
    
    //test for invalid email id in confirmation mail method
    static testMethod void testInvalidEmailId() {
		
		MyFax_helper_Test.createFaxSystemParam();
		
		List<Account> accList = TestDataFactory.createAccounts(5, false);
		insert accList;
		List<Contact> conList = TestDataFactory.createContacts(5, accList[0]);
		for(Contact con : conList){
			con.Fax = '9876543212';
		}
		insert conList;
		
		MyFax_Helper helperClass;
    	try{
			helperClass = new MyFax_Helper();
    	}catch(Exception ex){
    		system.assertEquals(ex.getMessage().contains('Invalid email address'), true);
    	}
    }
    
    //test for invalid email id in confirmation mail method
    static testMethod void testOtherMethods() {
		
		TestDataFactory.createFaxSystemParameters();
		
		MyFax_Helper helperClass = new MyFax_Helper();
    	
    	helperClass.setCoverPageStatusUrgent(true);
    	helperClass.setCoverPageStatusReview(true);
    	helperClass.setCoverPageStatusInformative(true);
    	Boolean coverpage = helperClass.getCoverPageStatusInformative();
    	helperClass.setCoverPageStatusComment(true);
    	helperClass.setCoverPageStatusAnswer(true);
    	helperClass.setComment('hello');
    	helperClass.setSubject('subject');
    	
    	
    }
    
    //Updated to include "Default Sales Rep" custom setting record
    public static void createFaxSystemParam()
    {
        List<SystemParameters__c> faxParams = new List<SystemParameters__c>();
        
        SystemParameters__c faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxDefaultCoverPageId';
        faxParam.Description__c = 'Fax Default Cover PageId';
        faxParam.External_Id__c = 'FaxDefaultCoverPageId';
        faxParam.Value__c = '4';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxDefaultFromText';
        faxParam.Description__c = 'The from text of the fax cover page';
        faxParam.External_Id__c = 'FaxDefaultFromText';
        faxParam.Value__c = 'NEWS CORP';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxSendConfirmationTo';
        faxParam.Description__c = 'Default email to receive fax confirmation';
        faxParam.External_Id__c = 'FaxSendConfirmationTo';
        faxParam.Value__c = 'test.com';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxDefaultPaperFormat';
        faxParam.Description__c = 'Fax default paper format. Valid values are "Letter", "Legal", "A4", "Default"';
        faxParam.External_Id__c = 'FaxDefaultPaperFormat';
        faxParam.Value__c = 'A4';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxDefaultResolution';
        faxParam.Description__c = 'Fax resolution. valid values are "204x98" or "204x196"';
        faxParam.External_Id__c = 'FaxDefaultResolution';
        faxParam.Value__c = '204x196';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxUserId';
        faxParam.Description__c = 'MyFax user id';
        faxParam.External_Id__c = 'FaxUserId';
        faxParam.Value__c = '5418797';
        faxParams.add(faxParam);
        
        faxParam = new SystemParameters__c();
        faxParam.Name = 'FaxUserPassword';
        faxParam.Description__c = 'Fax user password';
        faxParam.External_Id__c = 'FaxUserPassword';
        faxParam.Value__c = 'newsfaxt3st';
        faxParams.add(faxParam);
        
        
        insert faxParams;
    }
}