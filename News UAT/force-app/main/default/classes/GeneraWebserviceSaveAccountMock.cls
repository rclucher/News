@isTest
global class GeneraWebserviceSaveAccountMock implements WebServiceMock {
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType)
   {
       GeneraWebserviceLiteStub.SaveAccountResponse_element respElement = new GeneraWebserviceLiteStub.SaveAccountResponse_element();
       
       //list<GeneraWebserviceLiteStub.Refund> refunds = new list<GeneraWebserviceLiteStub.Refund>();
       GeneraWebserviceLiteStub.Refund refund = new GeneraWebserviceLiteStub.Refund();
       refund.Amount = 10.2;
       refund.CardNumberHash = '4111111111111';
       refund.CardType = 'Visa';
       refund.ID = 1234567890;
       refund.Message ='My message';
       refund.TransID = 'T123456';
       
       respElement.Refund = new list<GeneraWebserviceLiteStub.Refund>();
       respElement.Refund.add(refund);
       
       response.put('response_x', respElement);
   }
}