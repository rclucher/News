@RestResource(urlMapping='/CyberAd/salesOrder/*')
global without sharing class RESTCyberAdSalesOrder {


    //Get a SalesOrderDetails based on parameter passed
    @HttpGet
    global static SalesOrderDetails_Helper.SalesOrderDetail doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        SalesOrderDetails_Helper.SalesOrderDetail result = new SalesOrderDetails_Helper.SalesOrderDetail();


        system.debug('### req:' + req);

        //List of URL components
        list<string> params = req.requestURI.split('/');
        //The last item from the paramter list expect a sales_order__c ID
        //optonally a booking__c id separed by a dash '-'
        //booking is passed when oppening an existing booking
        String salesOrderAndBookingID = params[params.size()-1];

        //removes .xml from parameter
        salesOrderAndBookingID = salesOrderAndBookingID.replace('.xml', '');

        string salesOrderID;
        String bookingID;

        //sets variable with the passed ids
        if(salesOrderAndBookingID.indexOf('-')>0)
        {
            salesOrderID = salesOrderAndBookingID.split('-')[0];
            bookingID = salesOrderAndBookingID.split('-')[1];
        }
        else
        {
            salesOrderID = salesOrderAndBookingID;
        }

        System.debug('### params: ' + params);
        System.debug('### salesOrderID: ' + salesOrderID);
        System.debug('### bookingID: ' + bookingID);



        //Gets sales_order__c details
        Sales_Order__c salesOrder = getSalesOrderBySalesOrderID(salesOrderID);
        result.salesOrderSFID   =   salesOrderID;
        result.salesOrderID     =   salesOrder.Calc_External_Id__c;
        result.orderId          =   salesOrder.Calc_External_Id__c;
        result.divisionName     =   salesOrder.Booking_Division__c;
        result.payerAccount     =   salesOrder.Payer_Account__r.Name;
        result.placerContact    =   salesOrder.Contact__r.External_Id__c;
        result.placerFName      =   salesOrder.Contact__r.FirstName;
        result.placerLName      =   salesOrder.Contact__r.LastName;
        result.intgId           =   salesOrder.Calc_External_Id__c;
        result.main             =   salesOrder.Placer_Contact_Phone__c;
        result.localNumber      =   salesOrder.Placer_Contact_Phone__c;
        
        if(!salesOrder.Payer_Account__r.isPersonAccount)
        {
            result.address          =   salesOrder.Payer_Account__r.BillingStreet;
            result.postCode         =   salesOrder.Payer_Account__r.BillingPostalcode;
            result.state            =   salesOrder.Payer_Account__r.BillingState;
            result.country          =   salesOrder.Payer_Account__r.BillingCountry;
            if(salesOrder.Payer_Account__r.BillingCity!=null && salesOrder.Payer_Account__r.BillingCity.trim().length()>0)
                result.city         =   salesOrder.Payer_Account__r.BillingCity.toUpperCase();            
        }
        else
        {
            result.address          =   salesOrder.Payer_Account__r.PersonMailingStreet;
            result.postCode         =   salesOrder.Payer_Account__r.PersonMailingPostalCode;
            result.state            =   salesOrder.Payer_Account__r.PersonMailingState;
            result.country          =   salesOrder.Payer_Account__r.PersonMailingCountry;           
            if(salesOrder.Payer_Account__r.PersonMailingCity!=null && salesOrder.Payer_Account__r.PersonMailingCity.trim().length()>0)
                result.city         =   salesOrder.Payer_Account__r.PersonMailingCity.toUpperCase();            

        }
        //=='Established'?'Established':'Non Established'
        String billingAccountType = 'Non Established';

        if(     salesOrder.External_Account__r != null
            &&  salesOrder.External_Account__r.Account_Type__c != '' 
            &&  salesOrder.External_Account__r.Account_Type__c != 'Casual'
            &&  salesOrder.External_Account__r.Account_Type__c != 'Billing_Account'
            &&  salesOrder.External_Account__r.Account_Type__c != 'Private Party'
            &&  salesOrder.External_Account__r.Account_Type__c != 'Casual Business'
            &&  salesOrder.External_Account__r.Account_Type__c != 'Transient'
            &&  salesOrder.External_Account__r.Account_Type__c !='Non Established')
        {
            billingAccountType = 'Established';
        }            

        result.bAType           =   billingAccountType;
        result.bAName           =   salesOrder.Calc_External_Account_Name__c;
        result.bANumber         =   salesOrder.External_Account__r.Account_No__c;
        result.accountName      =   salesOrder.Calc_External_Account_Name__c;
        result.billingAccountId =   salesOrder.External_Account__r.External_Id__c;
        result.bookingprofile   =   result.bAName; //passing baName as bookingProfile is not being used in salesforce





        result.createdDate      =   formatDate(system.today());

        //if thre request includes a booking id
        if(bookingID!=null)
        {
            result.bookingSFID = bookingID;

            Booking__c booking = getBookingByBookingID(bookingID);
            if(booking.Third_Party_Created__c!=null)
            {
                result.createdDate      =   formatDate(Date.valueOf(booking.Third_Party_Created__c));
            }
            
            
            
            result.adType           =   booking.CyberAd_AdType__c;
            result.bookingId        =   booking.Name;
        }
        else
        {
            result.adType           =   'Billing';
        }



        result.divisionName = salesOrder.Booking_Division__c;//'GAD';
        result.bookingDivision = salesOrder.Booking_Division__c; //'GAD';
        //result.publicationName = 'GAT';

        // added by Tim Fabros 20 / 05 / 2014 - SFE-174 
        // Updated by Bohao Chen 28/05/2014
        // BEGIN: 

        // check if billing account and is a CyberAd
        // check if country is not Australia
        // check if not australian state/territory
        System.debug('@outside if statement: ' + result.country);
        System.debug('@outside if statement: ' + result.state);
        System.debug('@outside if statement: ' + result.postCode);
        System.debug('@outside if source system: ' + salesOrder.Source_System__c);

        String lowerCaseCountry = result.country.toLowerCase();
        String lowerCaseState = result.state.toLowerCase();

        if(salesOrder.Source_System__c == 'CyberAd' && 
            ((lowerCaseCountry != 'australia' && lowerCaseCountry != 'aus' && lowerCaseCountry != 'au') ||
                (lowerCaseState != 'nsw' && lowerCaseState != 'qld' && lowerCaseState != 'vic' && lowerCaseState != 'tas' && 
                    lowerCaseState != 'wa' && lowerCaseState != 'nt' && lowerCaseState != 'act' && lowerCaseState != 'sa'))) 
        {
            
            result.state = 'OTH';
            result.postCode = '9999';
            System.debug('@inside if statement: ' + result.state);
            System.debug('@inside if statement: ' + result.postCode);
        }
        // END:

        System.debug('### result: ' + result);
        return result;
    }



    @HttpPost
    global static string createUpdateSalesOrderDetails()
    {
        RestRequest req = RestContext.request;
        Blob body = req.requestBody;
        system.debug('### req.requestBody:' + req.requestBody);

        String bodySalesOrderDetail = body.toString();
        system.debug('### bodySalesOrderDetail:' + bodySalesOrderDetail);

        //add empty parameters {} if none was sent to CyberAd
        bodySalesOrderDetail = bodySalesOrderDetail.replace(' : \n}',' : {}\n}');

        SalesOrderDetails_Helper.SalesOrderWrapper jsonwrap = new SalesOrderDetails_Helper.SalesOrderWrapper();

        try
        {

            jsonwrap = (SalesOrderDetails_Helper.SalesOrderWrapper) JSON.deserialize(bodySalesOrderDetail, SalesOrderDetails_Helper.SalesOrderWrapper.class);
            system.debug('### jsonwrap:' + jsonwrap);
            jsonwrap.message = 'Post has been deserialized successfully' ;
            system.debug('### jsonwrap.salesOrder:' + jsonwrap.salesOrder);
            SalesOrderDetails_Helper.upsertSalesOrderDertails(jsonwrap);
        }
        catch(Exception ex)
        {
            jsonwrap.message = 'Post could not be deserialized \n' + ex.getMessage();
        }

        System.debug('### jsonwrap: ' + jsonwrap);

        return jsonwrap.message;
    }


    static private Sales_Order__c getSalesOrderBySalesOrderId(String soID)
    {
        system.debug('@ getSalesOrderBySalesOrderId(String soID)');
        Sales_Order__c so;

        try
        {   // added Source_System__c && External_Account__r.RecordTypeId. Addition made by Tim Fabros 20 / 05 / 2014 - SFE-174
            // BEGIN:
             so = [Select   Booking_Division__c,
                            Payer_Account__r.Name,
                            Contact__r.FirstName,
                            Contact__r.LastName,
                            Contact__r.External_Id__c,
                            Calc_External_Id__c,
                            Placer_Contact_Home__c,
                            Payer_Account__r.BillingStreet,
                            Payer_Account__r.BillingCity,
                            Payer_Account__r.BillingPostalcode,
                            Payer_Account__r.BillingState,
                            Payer_Account__r.BillingCountry,
                            Payer_Account__r.isPersonAccount,
                            Payer_Account__r.PersonMailingStreet,
                            Payer_Account__r.PersonMailingPostalCode,
                            Payer_Account__r.PersonMailingState,
                            Payer_Account__r.PersonMailingCountry, 
                            Payer_Account__r.PersonMailingCity,                             
                            External_Account__r.Account_Type__c,
                            Calc_External_Account_Name__c,
                            External_Account__r.Account_No__c,
                            External_Account__r.External_Id__c,
                            External_Account__r.RecordTypeId,
                            Placer_Contact_Phone__c, Source_System__c
                      From Sales_Order__c
                      Where id = :soID];
                      // END:
                      system.debug('### so:' + so);
        }
        catch(Exception ex)
        {
            System.debug('### Sales Orde do not exist in Salesforce with id: ' + soID);
        }
        return so;
    }


    static private Booking__c getBookingByBookingId(String bookingId)
    {
        system.debug('@ getBookingByBookingId(String bookingId)');
        Booking__c bk;
        try
        {
            bk = [Select Third_Party_Created__c,
                         Name,
                         CyberAd_AdType__c,
                         Booking_number__c
                    From Booking__c
                    Where id = :bookingId];
                    
                    
            system.debug('### bk:' + bk);
        }
        catch(Exception ex)
        {
            System.debug('### Booking do not exist in Salesforce with id: ' + bookingId);
        }
        return bk;
    }

    static private string  formatDate(date d)
    {
        string day = string.valueOf(d.day()).length()==2?string.valueOf(d.day()):'0'+d.day();
        string month = string.valueOf(d.month()).length()==2?string.valueOf(d.month()):'0'+d.month();
        return  day + '/' +  month + '/' + d.year();
    }


}