@isTest
global class AdPointWebserviceAccountSyncMock implements WebServiceMock {
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
       AdPointWebserviceStub.adPointAccountSyncResponse accountSyncResp = new AdPointWebserviceStub.adPointAccountSyncResponse();
       response.put('response_x', accountSyncResp);
   }
}