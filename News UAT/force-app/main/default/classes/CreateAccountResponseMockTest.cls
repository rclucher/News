/*---------------------------------------------------------
 * Author: Atul Gupta
 * Company: Bluewolf
 * Description: This is a mock class to test webservice calls made in Class ExternalAccountForm_Controller.
 * 					This class is referenced by ExternalAccountForm_Controller_Test Test Class
 * History:
 * 2016-01-15  Atul Gupta  Created
 // 2016-01-14 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - NONE
 ---------------------------------------------------------*/
@isTest
global class CreateAccountResponseMockTest implements WebServiceMock {
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
       GeneraWebserviceLiteStub.CreateAccountResponse_element createAccResponse = new GeneraWebserviceLiteStub.CreateAccountResponse_element();
       response.put('response_x', createAccResponse);
   }
}