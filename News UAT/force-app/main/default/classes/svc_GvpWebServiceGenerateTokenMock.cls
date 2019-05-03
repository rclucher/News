@isTest
global class svc_GvpWebServiceGenerateTokenMock implements WebServiceMock {
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
   	    svc_GlobalViewPointWebServiceStub.generateGVPTokenResponse3 generateGVPTokenResponse = new svc_GlobalViewPointWebServiceStub.generateGVPTokenResponse3();
   	    generateGVPTokenResponse.status = 'SUCCESS';
        generateGVPTokenResponse.securityToken = 'IJHKLJKLJLKLKJKLJLKJLKJLKNMNKJHJKHYIUY';
        generateGVPTokenResponse.errorMessage = null;
        
   	    svc_GlobalViewPointWebServiceStub.generateGVPTokenResponse2 generateGVPTokenResponse1 = new svc_GlobalViewPointWebServiceStub.generateGVPTokenResponse2(); 
   	    generateGVPTokenResponse1.generateGVPTokenResponse = generateGVPTokenResponse;
   	    
        svc_GlobalViewPointWebServiceStub.generateGVPTokenResponse respElement = new svc_GlobalViewPointWebServiceStub.generateGVPTokenResponse();
        respElement.generateGVPTokenResponse = generateGVPTokenResponse1;
        
        response.put('response_x', respElement);
   }
}