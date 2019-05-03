/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 *
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class RESTCyberAd_Test {

   static testMethod void salesOrderTest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');


        string reqURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/CyberAd/salesOrder/' + so.id;

        req.requestURI = reqURL;
        system.debug('### req.reqURL: ' + reqURL);

        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

         SalesOrderDetails_Helper.SalesOrderDetail result = RESTCyberAdSalesOrder.doGet();
         system.debug('### result.salesOrderID:' + result.salesOrderID);

         System.assert(result.salesOrderID == so.id);
   }


   static testMethod void salesOrderExistingBookingTest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        
        SystemParameters__c sp = new SystemParameters__c();
        sp.name='Default Sales Rep';
        sp.Value__c = UserInfo.getUserId();
        sp.External_Id__c = 'Default_Sales_Rep';
        insert sp;

        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        Booking__c b = TestDataFactory.createBooking(so);


        string reqURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/CyberAd/salesOrder/' + so.id +'-' + b.id;

        req.requestURI = reqURL;
        system.debug('### req.reqURL: ' + reqURL);

        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

         SalesOrderDetails_Helper.SalesOrderDetail result = RESTCyberAdSalesOrder.doGet();
         system.debug('### result.salesOrderID:' + result.salesOrderID);

         System.assert(result.salesOrderID == so.id);
         System.assert(result.bookingSFID == b.id);

   }


   static testMethod void salesOrderPostTest() {
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        SystemParameters__c sp = new SystemParameters__c();
        sp.name='Default Sales Rep';
        sp.Value__c = UserInfo.getUserId();
        sp.External_Id__c = 'Default_Sales_Rep';
        insert sp;

        Sales_Order__c so = TestDataFactory.createSalesOrder('Cyber');
        Booking__c b = TestDataFactory.createBooking(so);


        string reqURL = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/CyberAd/salesOrder/';

        req.requestURI = reqURL;
        system.debug('### req.reqURL: ' + reqURL);

        req.httpMethod = 'POST';

        RestContext.request = req;
        RestContext.response = res;



        blob blobBody = blob.valueOf('{"orderId" : "19", "salesOrder" : {"accountName":"","adType":"L","address":"","areaCode":null,"baName":"","baNumber":"",' +
                        '"baType":"","billingAccountID":"","bookedPoint":"VIC","bookingAccount":"AVFE010","bookingContact":"Jimmy Dummy","bookingDivision":"",'+
                        '"bookingID":"2183012","bookingNum":"","bookingprofile":"","bpType":"","campaignID":"","city":"","classificationCode":"Autorepair","contactID":"",' +
                        '"country":"","createdDate":"21/06/2013 11:20:00 AM","divisionName":"GAD","intgID":"","lastDate":"22/06/2013 12:00:00 AM","localNumber":null,' +
                        '"main":"","newsCaption":"ASDSA","newsDepth":"1.9","newsLines":"7","opportunityID":"","orderId":"","payerAccount":"","placerConId":"",' +
                        '"placerContact":"S2_1-1WTRC9W","placerFName":"","placerLName":"","postCode":null,"productID":"","publicationName":"GAT","runSchedule":"GAT:1x 22jun2013",' +
                        '"salesOrderID":"19","searchDate":null,"sourceSystem":"Cyber","startDate":"22/06/2013 12:00:00 AM","state":"","status":"Booking","totalCost":"52.22"},' +
                        ' "parameter" : {"salesOrderSFID":"'+ so.id +'"}}');

        req.requestBody = blobBody;


         string result = RESTCyberAdSalesOrder.createUpdateSalesOrderDetails();

   }



    static testMethod void salesOrderUsers() {

        list<User> users = TestDataFactory.createUsers(1, 'System Administrator', null, null, false);
        insert users;

        system.debug('### users :' + users);

        Map<id,list<CyberAd_User_Credential__c>> credentials = TestDataFactory.createCyberAdUserCredentials(3, users);
        list<CyberAd_User_Credential__c> tmpList = new list<CyberAd_User_Credential__c>();
        for(list<CyberAd_User_Credential__c> l : credentials.values())
        {
            tmpList.addAll(l);
        }

        insert tmpList;

        system.debug('### credentials :' + credentials);


        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/CyberAd/User?userID=' + users[0].id;
        req.httpMethod = 'GET';

        RestContext.request = req;
        RestContext.response = res;

        list<CyberAd_User_Credential__c> result = RESTCyberAdUser.getCyberAdLogin();
        system.debug('### result.size() :' + result.size());
        system.debug('### credentials.get(users[0].id).size() :' + credentials.get(users[0].id).size());


        req.requestURI = URL.getSalesforceBaseUrl().toExternalForm() + '/services/apexrest/CyberAd/User?userName=' + users[0].username;
        RestContext.request = req;
        RestContext.response = res;

        result = RESTCyberAdUser.getCyberAdLogin();
        system.debug('### result.size() :' + result.size());
        system.debug('### credentials.get(users[0].id).size() :' + credentials.get(users[0].id).size());

        //System.assert(result.size() == credentials.get(users[0].id).size());

    }
}