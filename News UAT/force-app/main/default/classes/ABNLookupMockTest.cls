/*---------------------------------------------------------
 * Author: Atul Gupta
 * Company: Bluewolf
 * Description: This is a mock class to test webservice calls made in Class ExternalAccountForm_Controller.
 * 					This class is referenced by ExternalAccountForm_Controller_Test Test Class
 * History:
 * 2015-12-16  Atul Gupta  Created
 // 2016-01-14 atul.gupta@bluewolfgroup.com
    // This class provides test coverage for
    //  - NONE
 ---------------------------------------------------------*/
@isTest
public class ABNLookupMockTest implements HttpCalloutMock {
		protected Integer code;
		protected String status;
		protected String bodyAsString;
		protected Map<String, String> responseHeaders;

		public ABNLookupMockTest(Integer code, String status, String body,
                                         Map<String, String> responseHeaders) {
			this.code = code;
			this.status = status;
			this.bodyAsString = body;
			this.responseHeaders = responseHeaders;
		}

	    public HTTPResponse respond(HTTPRequest req) {
	        HttpResponse resp = new HttpResponse();
			resp.setStatusCode(code);
			resp.setStatus(status);
			resp.setBody(bodyAsString);

			if (responseHeaders != null) {
				for (String key : responseHeaders.keySet()) {
					resp.setHeader(key, responseHeaders.get(key));
				}
			}
			return resp;
	    }
}