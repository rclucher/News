/*---------------------------------------------------------
 * Author: Bohao Chen
 * Company: Salesforce.com
 * Description: This is for R-0523
 *              View Account Statement 
 *              Salesforce.com (Visualforce Button) -> Global Viewpoint (URL)
 * History:
 * 17/06/2013  Bohao Chen  Created
 * 03/07/2013  Bohao Chen  Updated
 ---------------------------------------------------------*/
global with sharing class GlobalViewPointGetToken
{
    webService static String getAccessToken(String acctNumber)
    {
        // get user informaiton
        String userFirstName = UserInfo.getFirstName();
        String userLastName = UserInfo.getLastName();
        String username = [Select u.Network_Username__c From User u Where u.Id =: UserInfo.getUserId() limit 1].Network_Username__c;
        
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
        tokenLoginParam.value = userFirstName;
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'User Details.Last Name';
        tokenLoginParam.value = userLastName;
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'User Name';
        tokenLoginParam.value = username;
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'Filter.Apply Filter';
        tokenLoginParam.value = 'True';
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'Filter.Account Number';
        tokenLoginParam.value = acctNumber;
        tokenLoginParams.add(tokenLoginParam);
        
        tokenLoginParam = new svc_GlobalViewPointWebServiceStub.tokenLoginParams();
        tokenLoginParam.key = 'Content Access.Account Number.Allow';
        tokenLoginParam.value = acctNumber;
        tokenLoginParams.add(tokenLoginParam);

        svc_GlobalViewPointWebServiceStub.generateGVPTokenRequest2 tokenRequest2 = 
            new svc_GlobalViewPointWebServiceStub.generateGVPTokenRequest2();
        tokenRequest2.clientIdentifier = 'Salesforce';
        tokenRequest2.securityLevel = '';
        tokenRequest2.authenticationRealm = 'News Ltd';
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
        
        // send error email to notify administrator if retrieving access token failed
        if(response3.status != 'SUCCESS')
        {
            String subject = 'Couldn\'t retrieve access token for Global Viewpoint';
            String[] toAddresses = new String[] {'shared_salesforce@news.com.au'};
            String msg = 'There is an error on retrieving access token for JDE account ' 
                       + acctNumber 
                       + ' for user ' 
                       + UserInfo.getName() + ' in org:' + userinfo.getOrganizationId() + '.<br />' 
                       + response3.errorMessage;
            
            Global_Helper.sendMessageToUsers(subject, msg, toAddresses, 'html');
        }
        
        return response3.securityToken;
    }
}