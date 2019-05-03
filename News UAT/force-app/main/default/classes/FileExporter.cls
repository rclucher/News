/*
* - billing file 
*
*/
public class FileExporter{


	/**
	 * publish billing file to ESB
	 * @param billingFileId
	 * @return String
	 */
	public static String pushFileToOut(Id billingFileId) {

		String res='';
		
		List<Attachment> attList = [
			select id , name, Body 
			from attachment 
			where ParentId = :billingFileId
			order by createddate desc
		];
		
		if (!attList.isEmpty()) {
			Blob csvFile = attList[0].Body;
			String bodyEncoded = EncodingUtil.base64Encode(csvfile);
			system.debug('before call' + attList[0].Id);
			res = doHttpCall('POST', csvfile);
			system.debug('after call---' + res);
			return res;
		}

		return 'Error - Please generate Billing File';

	}

	/**
	 * Performs http callout
	 * @param method
	 * @param data
	 * @return String
	 */
    @TestVisible
	private static String doHttpCall(String method, Blob data) {
		Billing_File_ESB_Integration__c integrationSettings = Billing_File_ESB_Integration__c.getInstance(UserInfo.getUserId());
		System.debug('Data : ' + UserInfo.getUserId());
        System.debug('Data1 : ' + integrationSettings);
		if (integrationSettings != null) {
			String endpoint = integrationSettings.Endpoint__c;
			String username = integrationSettings.Username__c;
			String password = integrationSettings.Password__c;
			
			Blob headerValue = Blob.valueOf(username + ':' + password);
			
			HttpRequest req = new HttpRequest();
            System.debug('endpoint :' +endpoint);
			req.setEndpoint(endpoint);
			req.setMethod(method);
			req.setBodyAsBlob(data);
			req.setHeader('Content-Type','application/octet-stream');
			req.setTimeout(120000);
			
			String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue); 
			
			system.debug(authorizationHeader);
			req.setHeader('Authorization', authorizationHeader);
			
			Http http = new Http();
			HTTPResponse res = http.send(req);    
			System.debug(res.getBody() +'   '  + res.getStatusCode());
			
			if(res.getStatusCode()!= 200 ){//||  res.getStatusCode()!= 201
				return 'FAIL#' + res.getBody();
			}
			return res.getBody();
		}
		return null;
	}
    
    
    public static void testWebM(){
    
        HttpRequest req = new HttpRequest();
        req.setEndpoint('http://webmethodsdev.newsdev.com.au/ws/news.integration.xtend.cloudsense.agencyClient.wsdl.checkAndCreateAgencyClientDA/news_integration_xtend_cloudsense_agencyClient_wsdl_checkAndCreateAgencyClientDA_Port');
        req.setMethod('POST');
        req.setHeader('SOAPAction' ,'checkAndCreateAgencyClientDA');
        String RequestSAmple = '<?xml version="1.0"?>'+
'<Customer_ID>9963</Customer_ID>'+
'<PaymentCondition_ID>1</PaymentCondition_ID>'+
'<Contract_ID>0</Contract_ID>'+
'<Agency_ID/>'+
'<Contact_ID>52260</Contact_ID>'+
'<Ref_num_2>a1g900000021j1v</Ref_num_2>'+
'<Name>SO8626005</Name>'+
'<InvoiceTo>Customer</InvoiceTo>'+
'<Segment>Retail</Segment>'+
'<AccountManager_ID>2522</AccountManager_ID>'+
'<SellingTeam_ID/>'+
'<BookingAccountManagerNetworkLogin>ComitoS</BookingAccountManagerNetworkLogin>'+
'<AdPointOrder_ID/>'+
'<Placer_Contact_Email_c>daman.foy@kdvsport.com</Placer_Contact_Email_c>'+
'<datasan__Account_ABN__c/>'+
'<Customer_Books_Direct__c>Yes</Customer_Books_Direct__c>'+
'<AccountName>KDV Sport Pty Ltd</AccountName>';
        
        req.setBody(RequestSAmple);
        req.setHeader('Content-Type','application/xml');
        req.setTimeout(120000);
        
        //CloudsenseESB/esbdev@123
        String username = 'CloudsenseESB';
        String password = 'esbdev@123';
        Blob headerValue = Blob.valueOf(username + ':' + password);
        
        
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue); 
        
        system.debug(authorizationHeader);
        req.setHeader('Authorization', authorizationHeader);
        
        Http http = new Http();
        HTTPResponse res = http.send(req);    
        System.debug(res.getBody() +'   '  + res.getStatusCode());
        
        
    
    }

}