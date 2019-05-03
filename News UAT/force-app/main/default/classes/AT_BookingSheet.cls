/**
* @description  Controller for Sales Order Booking Sheet
*
* @author       Pratyush Chalasani (Ativa)
* @date         2018-02-01

* @updated by   LBK
* @date         2018.03.12
* @description  New fields mapped. Refer https://docs.google.com/document/d/1NnIfzymuMjUOjel-9FGeN9cMMzRzZXlGW6Qa85COgN4/edit?disco=AAAABtFpm0s&ts=5aa1fb73 for more details.
                Fixed the page crash occurred when Booking Contact (csmso__Booking_Contact__c) is blank.

* @updated by  Mohsin Ali
* @date         2018-09-04
* Jira: NR-865
* @description	Added New Field: Planner_Account__r.Name in the select statement
* @date         2018-10-24
* Jira: NR-1633 & NR-987 & NR-1764 & NR-1632
* @description	Added New Fields: Proposed_Discount__c, Proposed_Discount_Amount__c, Print_Caption__c

* @date         2018-10-25
* Jira: NR-1632 & NR-1764
* @description	Added New Field: Print_Placement_Notes__c

* @date         2019-01-25
* Jira: NR-21
* @description	Cahnged digital target field: Digital_Targeting_Selection__c


**/
public class AT_BookingSheet {
    Id recordID;
    
    public csmso__Sales_Order__c SOrder {get; private set;}
    
    public String address {get; private set;}
    
    public Opportunity Opp {get; private set;}
    
    public Account Acc {get; private set;}
    
    public Contact BkCnt {get; private set;}
    
    // This might not actually be used directly on the booking sheet,
    // but is used to link to the product configuration records.
    public cscfga__Product_Basket__c Basket {get; private set;}
    
    public Boolean hasXtend   {get; private set;}
    public Boolean hasDigital {get; private set;}
    public Boolean hasPrint   {get; private set;}
    
    public String AccountNumbers {get; private set;}
    public Datetime createdDate {get;set;}
    // Top level Product Configuration record
    public cscfga__Product_Configuration__c Bundle {get; private set;}
    
    // Product Configuration records for individual products in a bundle
    public List<cscfga__Product_Configuration__c> Xtends {get; private set;}
    public List<cscfga__Product_Configuration__c> Prints {get; private set;}
    public List<cscfga__Product_Configuration__c> Digitals {get; private set;}
    
    public Boolean Bespoke {get; private set;}
    
    public AT_BookingSheet(ApexPages.StandardController controller) {
        recordID = controller.getId();
        
        Bespoke = false;
        
        loadData();
    }
    
    public void loadData() {
        SOrder = [SELECT
                        Id,
                        Name,
                        csmso__Advertiser__c,
                        csmso__Booking_Contact__c,
                        //csmso__Booking_Contact__r.Phone,
                        //csmso__Booking_Contact__r.Email,
                        csmso__Opportunity__c,
                        csmso__Creative_Contact__c,
                        csmso__From__c,
                        csmso__To__c,
                        Owner.Name,
                        Owner.Email,
                        Owner.Phone,
                        //Owner.MobilePhone, //Not accessible because of a known issue in the platform. Looking for a work around -LBK
                        CreatedDate,
                        Booking_Contact_For_Digital__r.Name,
                        Booking_Contact_For_Digital__r.Email,
                        Booking_Contact_For_Digital__r.Phone,
                        Booking_Contact_For_Digital__r.MobilePhone,
                        Booking_Contact_For_Print__r.Name,
                        Booking_Contact_For_Print__r.Email,
                        Booking_Contact_For_Print__r.Phone,
                        Booking_Contact_For_Print__r.MobilePhone,
                        //Added by LBK
                        Total_Duration_Price__c,
                        Total_Duration_GST__c,
                        Total_Duration_Price_GST_Inclusive__c,
                        Payment_Method__c
                      FROM csmso__Sales_Order__c WHERE Id = :recordID];

        createdDate = adjust(SOrder.CreatedDate);
        if(SOrder.csmso__Advertiser__c != null){
            Acc = [SELECT
                        Id,
                        Name,
                        Industry_Code__r.Name,
                        AccountNumber,
                        BillingStreet,
                        BillingCity,
                        BillingState,
                        BillingPostalCode,
                        Website,
                        AdPoint_Id__c
                   FROM Account WHERE Id = :SOrder.csmso__Advertiser__c];
            
            List<External_Account__c> externalAccounts = [SELECT Id FROM External_Account__c WHERE Customer_Account__c = :Acc.Id];
        }
        else{
            Acc = new Account();
        }
        
        
        if(SOrder.csmso__Booking_Contact__c != null){
            BkCnt = [SELECT
                        Id,
                        Name,
                        Phone,
                        MobilePhone,
                        Email
                   FROM Contact WHERE Id = :SOrder.csmso__Booking_Contact__c];
        }
        else{
            BkCnt = new Contact(); //This section (else part) is added to handle the page crash error if the csmso__Booking_Contact__c is blank in the Sales Order.
        }
        
        if(SOrder.csmso__Opportunity__c != null){
            Opp = [SELECT
                        Id,
                        AccountId,
                        Name,
                        Revenue_Group__c,
                        Payer_Account__c,
                        Industry_Code__c,
                        Industry_Code__r.Name,
                        Payer_Account__r.Name,
                        Payer_Account__r.Phone,
                        Planner_Account__r.Name
                   FROM Opportunity WHERE Id = :SOrder.csmso__Opportunity__c];
        }
        else{
            Opp = new Opportunity();
        }
        List<String> accountNumberList = new List<String>();
        
        for (External_Account__c exAcc: [SELECT
                                                Account_No__c,
                                                Customer_Account__c,
                                                Payer_Account__c
                                             FROM External_Account__c
                                             WHERE
                                                (Customer_Account__c = :Acc.Id) AND
                                                (Status__c = 'Active') AND
                                                (RecordType.DeveloperName = 'Booking_Account')]) {

            //If (opportunity payer account (Payer_Account__c) is null) or (opportunity payer account (Payer_Account__c)  = opportunity Account Name) then
            if ((Opp.Payer_Account__c == null) || (Opp.Payer_Account__c == Opp.AccountId)) {
                System.debug('no payer');
                
                //find booking system accounts where account type = booking account and booking system account payer account = booking system account Customer Account and status = Active.
                // (type and status are already filtered in the SOQL query)
                if (exAcc.Payer_Account__c == exAcc.Customer_Account__c) accountNumberList.add(exAcc.Account_No__c);
            } else {
                System.debug('has payer');
                //If opportunity payer account (Payer_Account__c) is not null and  (opportunity payer account (Payer_Account__c)  <> opportunity Account Name) then
                
                //find booking system accounts where account type = booking account and booking system account payer account  = opportunity payer account and status = Active
                // (type and status are already filtered in the SOQL query)
                if (exAcc.Payer_Account__c == Opp.Payer_Account__c) accountNumberList.add(exAcc.Account_No__c);
            }
        }       
        
        AccountNumbers = String.join(accountNumberList, ', ');
        
        address = Acc.BillingStreet + ' ' +
                  Acc.BillingCity + ', ' +
                  Acc.BillingState + ' ' +
                  Acc.BillingPostalCode;
        
        Basket = new cscfga__Product_Basket__c();
        
        List<cscfga__Product_Basket__c> baskets = [SELECT Id, cscfga__Total_Price__c FROM cscfga__Product_Basket__c WHERE csmso__Sales_Order__c = :SOrder.Id];
        
        if (baskets.size() > 0) Basket = baskets[0];
        
        Bundle = new cscfga__Product_Configuration__c();
        
        Xtends   = new List<cscfga__Product_Configuration__c>();
        Prints   = new List<cscfga__Product_Configuration__c>();
        Digitals = new List<cscfga__Product_Configuration__c>();
        
        if (!baskets.isEmpty()) {
            List<cscfga__Product_Configuration__c> configs =
                [SELECT
                    Id,
                    Name,
                    cscfga__Parent_Configuration__c,
                    Bundle_Name__c,
                    Platform__c,
                    Digital_Ad_Product__c,
                    Duration__c,
                    Publication__c,
                    Section__c,
                    Material_Type__c,
                    Material_Changes__c,
                    Ad_Size__c,
                    Selected_Dates__c,
                    Order_Name_Prefix__c,
                    Position__c,
                    Ad_Size_Rate_Card__c,
                    Discount_Notes__c,
                    Material_Instructions__c,
                    Price_Per_Impression__c,
                    cscfga__Total_Price__c,
                    Site_Section_Group__c,
                    Impressions_Quantity__c,
                    Digital_Insertion_Unit_Type__c,
                    Digital_Device_Type__c,
                    Client_Outcome__c,
                    Product_Line_Name__c,
                    Total_Xtend_Price__c,
                    SF_Primary_Campaign_Source__c,
                    Booking_Notes__c,
                    Print_Start_Date__c,
                    Cycle__c,
                    Campaign_Holiday_Start_Date__c,
                    Campaign_Holiday_End_Date__c,
                    Total_Print_Price__c,
                    Total_Digital_Price__c,
                    Base_Bundle_Price__c,
                    Total_Bundle_Price__c,
                    State__c,
                    Bespoke_Digital_Description__c,
                    Digital_Online_Advertising_Type__c,
                    Digital_Quantity__c,
                    Subsection__c,
                    Bundle_Details__c,
                    Owner.Name,
                    Owner.Email,
                    Owner.Phone,
                    //Added By LBK
                    Line_Item_Duration_Price__c,
                    Duration_Months__c,
                    Total_Digital_Duration_Quantity__c,
                    Total_Bundle_Price_GST_Inclusive__c,
                    Booking_Instructions__c,
                    // NR-251
                    Day_of_Week__c,
                    csmso__Flight_Begin__c,
                    Bundle_Item__c,
                 	Proposed_Discount__c,
                 	Proposed_Discount_Amount__c,
                 	Print_Caption__c,
                 	Print_Placement_Notes__c,
                 	// NR-21
                 	Digital_Targeting_Selection__c
                 FROM cscfga__Product_Configuration__c WHERE (cscfga__Product_Basket__c = :baskets[0].Id)];
            
            // Look through each config record and check if there is at least 1 which doesn't have a parent config
            // and which also has the Bundle_Item__c flag set to false.
            // If so then this a bespoke Sales Order.
            
            for (cscfga__Product_Configuration__c config: configs) {
                if ((config.cscfga__Parent_Configuration__c == null) & (config.Bundle_Item__c == false)) {
                    Bespoke = true;
                    break;
                }
            }
            
            for (cscfga__Product_Configuration__c config: configs) {
                if ((config.cscfga__Parent_Configuration__c == null) && (bespoke == false)) {
                    Bundle = config;
                }
                
                if ((config.cscfga__Parent_Configuration__c != null) || (bespoke == true)) {
                    if (config.Platform__c == 'Print')   Prints.add(reformatSelectedDates(config));
                    if (config.Platform__c == 'Digital') Digitals.add(reformatSelectedDates(config));
                    if (config.Platform__c == 'Xtend')   Xtends.add(reformatSelectedDates(config));
                }
            }
            
            // If a bundle is not found, then use an empty record
            if (Bundle == null) Bundle = new cscfga__Product_Configuration__c();
            
            hasXtend   = !Xtends.isEmpty();
            hasDigital = !Digitals.isEmpty();
            hasPrint   = !Prints.isEmpty();
        }
    }
    
    /*private cscfga__Product_Configuration__c formatTargeting(cscfga__Product_Configuration__c config) {
        String state = config.State__c;
        
        if ((config.State__c == 'SA') || (config.State__c == 'QLD')) {
            config.State__c = 'Geographic ' + state + ' Publication';
        } else {
            config.State__c = 'Geographical State:' + state;
        }
        
        return config;
    }*/
    
    // The Selected Dates field is a long text field containing
    // a list of dates in the form ["yyyy-MM-dd","yyyy-MM-dd",....]
    // This reformats the contents into a more readable form of d/M/yyyy, d/M/yyyy, ...
    private cscfga__Product_Configuration__c reformatSelectedDates(cscfga__Product_Configuration__c config) {       
        if (String.isNotBlank(config.Day_of_Week__c)) {
            config.Day_of_Week__c = config.Day_of_Week__c.left(3);
        }
        
        if (String.isNotBlank(config.Selected_Dates__c)) {
            // Strip out all square brackets and double quotes, and then split by commas
            List<String> dateList = config.Selected_Dates__c.replaceAll('[\\[\\]"]', '').split(',');
            
            List<String> dates = new List<String>();
            
            for (String d: dateList) {
                try {
                    // Parse the date as yyyy-MM-dd
                    DateTime dt = Date.valueOf(d.trim());
        
                    // Reformat it as d/M/yyyy
                    dates.add(dt.format('d/M/yyyy'));
                } catch (System.TypeException te) {
                    // Invalid date format, ignore
                }
            }
            
            // rejoin the list of dates
            config.Selected_Dates__c = String.join(dates, ', ');
        }
        
        config.csmso__Flight_Begin__c = adjust(config.csmso__Flight_Begin__c);

        return config;
    }
 
    public DateTime adjust(DateTime original) {
        if (original == null) return null;
        
        String dstAdjusted = original.format('yyyy-MM-dd HH:mm:ss');
        
        Integer year = Integer.valueOf(dstAdjusted.substring(0, 4));
        Integer month = Integer.valueOf(dstAdjusted.substring(5, 7));
        Integer day = Integer.valueOf(dstAdjusted.substring(8, 10));
        Integer hour = Integer.valueOf(dstAdjusted.substring(11, 13));
        Integer minute = Integer.valueOf(dstAdjusted.substring(14, 16));
        Integer second = Integer.valueOf(dstAdjusted.substring(17, 19));
        
        return DateTime.newInstanceGmt(year, month, day, hour, minute, second);
    }
    
    
    /*
     * Get the offset between the user's timezone and GMT.
     * Used for formatting dates correctly in therelated  VF page.
     */
    public Double getTZOffset() {
        TimeZone tz = UserInfo.getTimeZone();
        
        return tz.getOffset(DateTime.now()) / (1000 * 3600 * 24.0);
    }
}