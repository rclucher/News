@isTest
global class AdPointWebserviceContactSyncMock implements WebServiceMock {
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
       AdPointWebserviceStub.adPointContactSyncResponse contactSyncResp = new AdPointWebserviceStub.adPointContactSyncResponse();
       response.put('response_x', contactSyncResp);
   }
}