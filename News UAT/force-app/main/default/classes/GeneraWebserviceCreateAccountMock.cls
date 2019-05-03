@isTest
global class GeneraWebserviceCreateAccountMock implements WebServiceMock {
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
       GeneraWebserviceLiteStub.CreateAccountResponse_element respElement = new GeneraWebserviceLiteStub.CreateAccountResponse_element();
        respElement.CreateAccountResult = 'T1980508';
       response.put('response_x', respElement);
   }
}