/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 */
@isTest
private class svc_GlobalViewPointWebServiceStub_Test {

    static testMethod void myUnitTest() 
    {
        Test.setMock(WebServiceMock.class, new svc_GvpWebServiceGenerateTokenMock());
        
        List<svc_GlobalViewPointWebServiceStub.tokenLoginParams> tokenLoginParams = new List<svc_GlobalViewPointWebServiceStub.tokenLoginParams>();
        
        // 9 token login params
        svc_GlobalViewPointWebServiceStub.tokenLoginParams tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'User Type';
        tokenLoginParam.value = 'Biller';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'Role';
        tokenLoginParam.value = 'News Credit/Advantage';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'User Context.Billing System Code';
        tokenLoginParam.value = 'NewsLTD';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'User Details.First Name';
        tokenLoginParam.value = 'Test first name';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'User Details.Last Name';
        tokenLoginParam.value = 'Test last name';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'User Name';
        tokenLoginParam.value = 'Test username';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'Filter.Apply Filter';
        tokenLoginParam.value = 'True';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'Filter.Account Number';
        tokenLoginParam.value = '12345678';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'Content Access.Account Number.Allow';
        tokenLoginParam.value = '12345678';
        tokenLoginParams.add(tokenLoginParam);


        svc_GlobalViewPointWebServiceStub.generateGVPTokenRequest2 tokenRequest2 = 
            new svc_GlobalViewPointWebServiceStub.generateGVPTokenRequest2();
        tokenRequest2.clientIdentifier = 'Salesforce';
        tokenRequest2.securityLevel = '';
        tokenRequest2.authenticationRealm = 'News Pty Ltd';
        tokenRequest2.tokenLoginParams = tokenLoginParams;
        
        
        svc_GlobalViewPointWebServiceStub.generateGVPTokenRequest tokenRequest = 
            new svc_GlobalViewPointWebServiceStub.generateGVPTokenRequest();
        tokenRequest.generateGVPTokenRequest = tokenRequest2;
        
        svc_GlobalViewPointWebServiceStub.news_adapter_gvp_provider_generateGVPToken_Port gvpWebService = 
            new svc_GlobalViewPointWebServiceStub.news_adapter_gvp_provider_generateGVPToken_Port();
        
        svc_GlobalViewPointWebServiceStub.generateGVPTokenResponse2 response2 = gvpWebService.generateGVPToken(tokenRequest);
        svc_GlobalViewPointWebServiceStub.generateGVPTokenResponse3 response3 = response2.generateGVPTokenResponse;
        
        system.debug('== response status=== ' + response3.status);
        system.debug('== erroMsg === ' + response3.errorMessage);
        
        //return response3.securityToken;
    }
}