@isTest
global class GeneraWebserviceLogoutMock implements WebServiceMock {
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
       GeneraWebserviceLiteStub.LogoutResponse_element respElement = new GeneraWebserviceLiteStub.LogoutResponse_element();
       response.put('response_x', respElement);
   }
}