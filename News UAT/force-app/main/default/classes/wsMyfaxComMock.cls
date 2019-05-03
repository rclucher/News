@isTest
global class wsMyfaxComMock implements WebServiceMock {
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
       wsMyfaxCom.SendMyFaxResponse_element sendFaxResponse = new wsMyfaxCom.SendMyFaxResponse_element();
       response.put('response_x', sendFaxResponse);
   }
}