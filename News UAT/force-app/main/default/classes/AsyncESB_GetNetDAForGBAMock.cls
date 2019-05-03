@isTest
global class AsyncESB_GetNetDAForGBAMock implements WebServiceMock {

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

        AsyncESB_GetNetDAForGBAStub.getDAForGBAResponseFuture esbRespFuture = new AsyncESB_GetNetDAForGBAStub.getDAForGBAResponseFuture();
        response.put('response_x', esbRespFuture);
   }
}