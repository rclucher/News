/*---------------------------------------------------------
 * Author: Bluewolf
 * Company: Salesforce.com
 * description: Test class for wsMyfaxCom
 * History:
 * 2015-12-02  Atul Gupta  Updated
  // 2016-01-15 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - wsMyfaxCom   91%
 --------------------------------------------------------*/
@isTest
private class wsMyfaxCom_Test 
{
	//SFE-766 2015-012-02 atul.gupta@bluewolfgroup.com - Updated test method to increase Code Coverage
    static testMethod void myUnitTest() 
    {
        // create users
        List<User> users = TestDataFactory.createUsers(1, 'News Direct Sales Inbound', null, null, false);
        insert users;
        
    	// create a sales order
    	Sales_Order__c so = TestDataFactory.createSalesOrder('AdPoint');
    	
        // create system parameters
        TestDataFactory.createFaxSystemParameters();
        
        // create a booking
    	Booking__c bk = TestDataFactory.createBooking(so);
        
        // create attachment
        List<Attachment> attachments = TestDataFactory.createAttachment(1, 'text', bk.Id);
        insert attachments;
        
    	Test.startTest();
        
        Test.setMock(WebServiceMock.class, new wsMyfaxComMock());
        
        MyFax_Helper myFax = new MyFax_Helper();
       
        myFax.addFaxRecipient('tester', '+61212345678', '12345');

        myFax.confirmationEmail('developers@bluewolf.com');

        myfax.setComment('this is test comment');
        
        myFax.addAttachment(attachments[0].Id);
           
        wsMyfaxCom.SendMyFaxResult_element faxResult = myfax.sendFax();
        
        faxResult = new wsMyfaxCom.SendMyFaxResult_element();
                
        wsMyfaxCom.MyFaxWSHeader resHeader = faxResult.Header;
        resHeader = new wsMyfaxCom.MyFaxWSHeader();
        
        Boolean flag = resHeader.ErrorFlag;
        String msgCode = resHeader.ReturnMessageCode;
        String msgTxt = resHeader.ReturnMessageText;
        
        Integer resNumOfFailed = faxResult.NumberOfFailed;
        Integer resNumOfSucc = faxResult.NumberOfSuccessful;
        
        wsMyfaxCom.ArrayOfSuccessfulFaxRecipient resSuccFaxRec = faxResult.SuccessfulFaxRecipientList;
        resSuccFaxRec = new wsMyfaxCom.ArrayOfSuccessfulFaxRecipient();
        List<wsMyfaxCom.SuccessfulFaxRecipient> succFaxRecs = resSuccFaxRec.SuccessfulFaxRecipient;
        
        wsMyfaxCom.SuccessfulFaxRecipient succFaxRec = new wsMyfaxCom.SuccessfulFaxRecipient();
        String billCode = succFaxRec.BillingCode;
        String name = succFaxRec.Name;
        DateTime ct = succFaxRec.CreatedAt;
        String faxNum = succFaxRec.FaxNumber;
        Integer transId = succFaxRec.TransactionID;
        
        
        wsMyfaxCom.ArrayOfFailedFaxRecipient resFailedFaxRec = faxResult.FailedFaxRecipientList;
        resFailedFaxRec = new wsMyfaxCom.ArrayOfFailedFaxRecipient();
        List<wsMyfaxCom.FailedFaxRecipient> failedFaxRecs = resFailedFaxRec.FailedFaxRecipient;
        
        wsMyfaxCom.FailedFaxRecipient failedFaxRec = new wsMyfaxCom.FailedFaxRecipient();
        String retCode = failedFaxRec.ReturnCode;
        
        Test.stopTest();
    }
	
	//SFE-766 2015-012-02 atul.gupta@bluewolfgroup.com - Updated test method to increase Code Coverage
	static testMethod void coverDataTypesTest(){
		
		new wsMyfaxCom.BinaryFaxDocument();
		
		new wsMyfaxCom.DownloadSentFaxesResult_element();
		
		new wsMyfaxCom.DownloadSentFaxesResponse_element();
		
		new wsMyfaxCom.SendSingleFaxRequest_element();
		
		new wsMyfaxCom.SendFaxBroadcastResult_element();
		
		new wsMyfaxCom.SendSingleFax_element();
		
		new wsMyfaxCom.SendFaxBroadcastResponse_element();
		
		new wsMyfaxCom.SentFaxes();

	}
}