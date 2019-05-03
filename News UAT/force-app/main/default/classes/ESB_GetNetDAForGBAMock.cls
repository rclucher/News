@isTest
global class ESB_GetNetDAForGBAMock implements WebServiceMock {
    public boolean success { get {return success == null ? true : success;} set;}
    public static Integer TEST_CALLOUT_INDEX = 0;

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

        ESB_GetNetDAForGBAStub.getDAForGBAResponse esbResp = new ESB_GetNetDAForGBAStub.getDAForGBAResponse();

        if (TEST_CALLOUT_INDEX == 0) {
            System.debug('success: ' + success);
            if (success) {
                esbResp.Response = 'SUCCESS';
                esbResp.DA = 'JDE123456';
            }
            else if (!success) {
                esbResp.Response = 'DA doesn\'t exist in GBA/BA table';
            }

            System.debug('esbResp.DA: ' + esbResp.DA);
            response.put('response_x', esbResp);
        }
        else if (TEST_CALLOUT_INDEX == 1) {
            GeneraWebserviceLiteStub.LoginResponse_element loginResp = new GeneraWebserviceLiteStub.LoginResponse_element();
            response.put('response_x', loginResp);
        }
        else if (TEST_CALLOUT_INDEX == 2) {
            GeneraWebserviceLiteStub.SetAccountFieldResponse_element setAccountFieldResp = new GeneraWebserviceLiteStub.SetAccountFieldResponse_element();
            response.put('response_x', setAccountFieldResp);
        }
        else if (TEST_CALLOUT_INDEX == 3) {
            GeneraWebserviceLiteStub.SetAccountFieldResponse_element setAccountFieldResp = new GeneraWebserviceLiteStub.SetAccountFieldResponse_element();
            response.put('response_x', setAccountFieldResp);
        }
        else if (TEST_CALLOUT_INDEX == 4) {
            GeneraWebserviceLiteStub.SaveAccountResponse_element saveAccountResp = new GeneraWebserviceLiteStub.SaveAccountResponse_element();
            response.put('response_x', saveAccountResp);
        }
        else if (TEST_CALLOUT_INDEX == 5) {
            GeneraWebserviceLiteStub.LogoutResponse_element logoutResp = new GeneraWebserviceLiteStub.LogoutResponse_element();
            response.put('response_x', logoutResp);
        }
        else if (TEST_CALLOUT_INDEX == 6) {
            esbResp.Response = 'Some other failure';
            response.put('response_x', esbResp);
        }
        else if (TEST_CALLOUT_INDEX == 7) {
            //do nothing
        }
        else {
            response.put('response_x', esbResp);
        }
        
        TEST_CALLOUT_INDEX++;
   }
}