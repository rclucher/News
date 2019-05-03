@isTest
global class GeneraWebserviceLoginMock implements WebServiceMock {
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
       GeneraWebserviceLiteStub.LoginResponse_element respElement = new GeneraWebserviceLiteStub.LoginResponse_element();
       response.put('response_x', respElement);
   }
}