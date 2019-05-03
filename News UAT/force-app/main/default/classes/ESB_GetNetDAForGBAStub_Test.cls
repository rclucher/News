/*---------------------------------------------------------
author: Allanah Mae
Company: Salesforce.com
description: Test for ESB_GetNetDAForGBAStub and AsyncESB_GetNetDAForGBAStub
History:
07-03-2017  Allanah Mae  Created
---------------------------------------------------------*/
@isTest
private class ESB_GetNetDAForGBAStub_Test {
	
	@testSetup static void setupTestData(){
		SystemParameters__c esbEndpoint = new SystemParameters__c();
		esbEndpoint.Name = 'ESB GetNetDAForGBA Endpoint';
		esbEndpoint.Value__c = 'testURL';
		esbEndpoint.External_Id__c = 'testId';
		insert esbEndpoint;
    }

    static testMethod void ESB_GetNetDAForGBATest() {
    	ESB_GetNetDAForGBAMock esbMock = new ESB_GetNetDAForGBAMock();
        esbMock.success = true;
        Test.setMock(WebServiceMock.class, esbMock);

        ESB_GetDAForGBA_Helper esb = new ESB_GetDAForGBA_Helper();
        Test.startTest();

        ESB_GetNetDAForGBAStub.getDAForGBAResponse resp = esb.getNetDA('TestGBA');
        System.assertEquals('SUCCESS', resp.Response);
		System.assertEquals('JDE123456', resp.DA);

        Test.stopTest();
    }

    static testMethod void AsyncESB_GetNetDAForGBATest() {
    	AsyncESB_GetNetDAForGBAMock esbMock = new AsyncESB_GetNetDAForGBAMock();
        Test.setMock(WebServiceMock.class, esbMock);

        AsyncESB_GetNetDAForGBAStub.Asyncnews_adapter_xref_wsdl_getDAForGBA_Port asyncGetNetDAForGBAWebservice = new AsyncESB_GetNetDAForGBAStub.Asyncnews_adapter_xref_wsdl_getDAForGBA_Port();

        Test.startTest();

        AsyncESB_GetNetDAForGBAStub.getDAForGBAResponseFuture resp = asyncGetNetDAForGBAWebservice.beginGetDAForGBA(new Continuation(40), 'gba', 'nmbsDivision');
        ESB_GetNetDAForGBAStub.getDAForGBAResponse esbResp = resp.getValue();
        System.debug(esbResp);
        Test.stopTest();
    }
}