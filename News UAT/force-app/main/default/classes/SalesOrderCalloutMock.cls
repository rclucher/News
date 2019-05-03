@isTest
global class SalesOrderCalloutMock implements WebServiceMock{    
    global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
       GBALookupService.agencyClientDAResponse respElement = new GBALookupService.agencyClientDAResponse();
               respElement.DA = '7010';
               respElement.status = 'success';
               respElement.errorMessage = 'errmsg';    
       GBALookupService.checkAndCreateAgencyClientDAResponse resp = new GBALookupService.checkAndCreateAgencyClientDAResponse();
               resp.agencyClientDAResponse = respElement;
       response.put('response_x',resp); 
   }
}