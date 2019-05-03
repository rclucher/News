public with sharing class CS_SetDatesForCSVDocumentController {
    public Date startDate {get; set;}
    public Date endDate {get; set;}
    public string csvFileData {get; set;}
    public string csvName {get; set;}
    public static String[] attrNameCSV = new String[]{'Total Impressions', 'Total Cost','Provider Name', 'Product Line Name', 'Product Type Name', 'Product Name','Network Name','Discount', 'Cost Model', 'Price', 'CPM', 'Cost CPM'};
    public static INTEGER paymentScheduleAddYears = 3;
    public Boolean rendered {get; set;}
    public string numberOfRecords{get;set;}
        
    public CS_SetDatesForCSVDocumentController(){
        rendered = false;
    }
    
    public void getData(){
        if (startDate == null || endDate == null)
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Please enter both start and end date'));
            rendered = false;
            return;
        }
        
        Date temporaryDate;
        if (startDate > endDate)
        {
            temporaryDate = endDate;
            endDate = startDate;
            startDate = temporaryDate;            
        }
        
        list<cscfga__Product_Configuration__c> wantedProdConfig = new list<cscfga__Product_Configuration__c>();
        wantedProdConfig= [
            SELECT Name, cscfga__Description__c,  cscfga__Product_Basket__r.csmso__Sales_Order__r.Name, 
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__From__c,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Name,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Id,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.FirstName,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.LastName,     
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Email,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Phone ,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.Package_Name__c,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCountry,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingState,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCity,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingStreet,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingPostalCode,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Fax,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Website,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.Social_URL__c, 
                cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,        
                //** Commented for field type switch Start        
                cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c,    
                //** Commented for field type switch End   
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.FirstName,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.LastName,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.Phone,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.Dashboard__c,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.Conversion_Tracking__c,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.Creative_Services__c,
                cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c,
                cscfga__Product_Basket__r.csmso__Sales_Order__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__To__c, 
                cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Total_Price__c, 
                cscfga__Configuration_Status__c, (
                Select  Name, cscfga__Value__c, cscfga__Attribute_Definition__r.Name, cscfga__Product_Configuration__r.Name,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Name,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Id,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.FirstName,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.LastName,     
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Email,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Phone ,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCountry,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingState,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCity,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingStreet,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingPostalCode,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Fax,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Website,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c,
                    //** Commented for field type switch Start  
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c,
                    //** Commented for field type switch End  
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.FirstName,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.LastName,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.Phone,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Dashboard__c,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Conversion_Tracking__c,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Creative_Services__c,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__c,
                    cscfga__Product_Configuration__r.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Total_Price__c      
                FROM cscfga__Attributes__r 
                where cscfga__Attribute_Definition__r.Name IN : attrNameCSV  ORDER BY cscfga__Attribute_Definition__r.Name DESC NULLS LAST ) 
            FROM cscfga__Product_Configuration__c 
            WHERE cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Opportunity__r.StageName =: 'Closed Won' 
                AND (cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c =: 'Manually Approved' OR cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Status__c =: 'Externally Approved')
                AND (cscfga__Product_Basket__r.csmso__Sales_Order__r.CreatedDate >=: startDate AND cscfga__Product_Basket__r.csmso__Sales_Order__r.CreatedDate <=: endDate)];
        if (wantedProdConfig.size()>0)
        {
            prepareCSVFileData(wantedProdConfig);
        }
        else
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'No records were found for the dates you selected, please select other dates and try again'));
            rendered = false;
            return;
        }
        
        numberOfRecords = '' + wantedProdConfig.size() + ' records were found.';
    }
    
    public void prepareCSVFileData(List<cscfga__Product_Configuration__c> wantedProdConfig){
        
        string headerName = 'Source,ExternalClusterId,Company Name,CRM Customer Id,Contact First Name,Contact Last Name,Email,Phone,Address1,City,State,ZipCode,Country,Website,Social URL,Campaign Start Date,Campaign End Date,Submitter Id,Account Manager FirstName,Account Manager LastName,Account Managers Phone no,Activate Dashboard,Conversion Tracking,Creative Services,Call Tracking,Package Name,Product,Product Type,Product Desc,Line item start,Line item End,Network,Wholesale rate,Cost Model,Monthly Impression Goal,Retail Rate,Discount Percent,Wholesale CPM,Retail CPM';
        string rows = '';
        
        if(wantedProdConfig != null && wantedProdConfig.size()>0){
            for(cscfga__Product_Configuration__c prodConf : wantedProdConfig)
              {
                if(rows != null){
                    System.debug('Output CSV line for: ' + prodConf.Name + ' Description:' + prodConf.cscfga__Description__c);

                    // Iterate over all the Product Attributes and dump them for debug purposes
                    for(cscfga__Attribute__c atr: prodConf.cscfga__Attributes__r)
                    { 
                        system.debug('Output Attribute: ' + atr.name + ' Value: ' + atr.cscfga__Value__c);
                    }

                    rows = rows + findAttribute(prodConf,'Provider Name') +','; //source
                    rows = rows + '1' +',';//External Cluster ID
                    //T-26191 
                    rows = rows +'"'+ prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Name +'"'+','; //Company Name //Added '"'+ for csv display
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Id +',';//CRM customer ID
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.FirstName +',';//Contact First Name
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.LastName +',';//Contact Last Name
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Email +','; //Email
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Booking_Contact__r.Phone +',';//Phone                 
                    rows = rows + '"'+ prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingStreet +'"'+','; //Address1 //Added '"'+ for csv display
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCity +','; //City
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingState +',';//State                   
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingPostalCode +',';//ZipCode
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.BillingCountry +','; //Country
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Website +',';//Website
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Social_URL__c +',';//Social URL
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c.format() +',';//Campaign Start Date -- date only not time
                    /**Commented for field type switch Start
                         Commented for field type switch End*/
                    if (prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c != null) {
                        rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c.format() +',';//Campaign End Date --- date only not time
                    } else {
                        rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c.addYears(5).format() +',';
                    }
                    rows = rows + userinfo.getProfileId() + ','; //Submitter Id
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.FirstName +','; //Account Manager FirstName
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.LastName +','; //Account Manager LastName
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.csmso__Advertiser__r.Owner.Phone +','; //Account Managers Phone no
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Dashboard__c +',';//Active Dashboard
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Conversion_Tracking__c +',';//Conversion Tracking
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Creative_Services__c +',';//Creative Services
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Call_Tracking__c +',';//Call Tracking
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Package_Name__c +',';//Package Name
                    rows = rows + findAttribute(prodConf,'Product Line Name') +',';// Product
                    rows = rows + findAttribute(prodConf,'Product Type Name') +',';//Product Type
                    rows = rows + findAttribute(prodConf, 'Product Name') +',';//Product Description
                    rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c.format() +',';//Line item start -- date only not time
                    //**Commented for field type switch Start
                         
                    if (prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c != null) {
                        rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_End_Date2__c.format() +',';//Line item End --- date only not time
                    } 
                    //**Commented for field type switch End (take off else or comment out else part too)
                    else {
                        rows = rows + prodConf.cscfga__Product_Basket__r.csmso__Sales_Order__r.Campaign_Start_Date__c.addYears(paymentScheduleAddYears).format() +',';//T-28932
                    }
                    rows = rows + findAttribute(prodConf,'Network Name') +',';//Network
                    rows = rows + '$'+ findAttribute(prodConf, 'Total Cost') +',';// Wholesale rate
                    rows = rows + findAttribute(prodConf,'Cost Model') +','; //Cost Model
                    rows = rows + findAttribute(prodConf,'Total Impressions') +',';//Total Impressions Goal
                    rows = rows + '$' + findAttribute(prodConf,'Price') +',';//Retail Rate 
                    rows = rows + findAttribute(prodConf, 'Discount') +'%,';//Discount Percentage  
                    //T-26344
                    rows = rows + findAttribute(prodConf, 'Cost CPM') +',';//Wholesale CPM    //Changed CPM to Cost CPM
                    rows = rows + findAttribute(prodConf, 'CPM') +',';//RetailCPM  //Changed Cost CPM to CPM
                   //T-26344
                } 
                rows = rows + '\n';
            }
        }
        
        
        if(rows == null){
            rows = '';
        }
        
        csvFileData = headerName + '\n' + rows;
        
        csvFileData = csvFileData.replace('null','');
        rendered = true;
    }
    
    public String findAttribute(cscfga__Product_Configuration__c prodConf, string attrName){

        system.debug('Searching for: ' + attrName);
        for (Integer i=0; i < prodConf.cscfga__Attributes__r.size(); i++) {
            if (prodConf.cscfga__Attributes__r[i].name == attrName) {
                system.debug('Found : ' + attrName + ' value ' + prodConf.cscfga__Attributes__r[i].cscfga__Value__c);
                return(prodConf.cscfga__Attributes__r[i].cscfga__Value__c);
            }
        }
        system.debug('Searching for: ' + attrName + ' failed');
        return ' ';
    }
    
    /* Method to attach CSV file */
    public PageReference attachNewFile()
    {
        
        List<csmso__Sales_Order__c> salesOrders = [select csmso__Opportunity__r.Id, name from csmso__Sales_Order__c 
                                            WHERE csmso__Opportunity__r.Status__c =: 'Closed Won' 
                                            AND (csmso__Status__c =: 'Manually Approved' OR csmso__Status__c =: 'Externally Approved') 
                                            AND (CreatedDate >=: startDate AND CreatedDate <=: endDate)];
        // create the new attachment
        Attachment attachCSV = new Attachment();
    
        // the contents of the attachment from the csv
        Blob bodyCsv;
    
        try {
                
        } catch (VisualforceException e) {
    
        }
    
        attachCSV.Body = blob.valueOf(csvFileData);
        DateTime currenttime = DateTime.now();
        String strConvertedDate = currenttime.format('dd/MM/yyyy HH:mm:ss', 'Australia/Sydney');
        system.debug('----Australia Time--'+strConvertedDate);
        attachCSV.Name = 'Att' + startDate + '-' + endDate + ' ' +strConvertedDate+'.csv';
        csvName = 'Export ' + startDate + '-' + endDate + ' ' +strConvertedDate+'.csv'; // T-28907
        attachCSV.IsPrivate = false;
        attachCSV.ParentId = salesOrders[0].csmso__Opportunity__r.Id;
        insert attachCSV ;
        return null;        
    }
    
    /*Wrapper class*/  
   public class AttrWrapper{
       public csmso__Sales_Order__c SO;
       public list<cscfga__Product_Configuration__c> prodConfigList;
       
    }    
}