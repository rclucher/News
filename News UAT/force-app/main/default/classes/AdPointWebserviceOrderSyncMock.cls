@isTest
global class AdPointWebserviceOrderSyncMock implements WebServiceMock {
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
       AdPointWebserviceStub.adPointCreateOrderResponse contactSyncResp = new AdPointWebserviceStub.adPointCreateOrderResponse();
       response.put('response_x', contactSyncResp);
   }
}