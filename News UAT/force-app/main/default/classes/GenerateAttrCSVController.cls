//*************************************************
// Developed by: Malvika Sharma
/* Date Created: 12.04.2016 (dd.MM.yyyy)
// Last Update: 12.04.2016 (dd.MM.yyyy)
// Description: Generates CSV of Sales Order related Attributes onclick of button
// Modifications
//     - Add in additional items to the CSV (Alistair Borley)
//     - Added in Cost CPM and CPM and renamced Coloumns
//*************************************************/

public class GenerateAttrCSVController {
public string csvFileData {get; set;}
public string csvName {get; set;}// T-28907
public static INTEGER paymentScheduleAddYears = 3; //T-28932
public Id soID;
 list<cscfga__Product_Configuration__c> prodConfigs = new list<cscfga__Product_Configuration__c>();
 
 /*Standard Controller constructor*/
 public GenerateAttrCSVController(ApexPages.StandardController controller){
 prepareCSVFileData();
 
 }
 
 /* Method to prepare CSV file data */
public void prepareCSVFileData(){
    string headerName = 'Source,ExternalClusterId,Company Name,CRM Customer Id,Contact First Name,Contact Last Name,Email,Phone,Address1,City,State,ZipCode,Country,Website,Social URL,Campaign Start Date,Campaign End Date,Submitter Id,Account Manager FirstName,Account Manager LastName,Account Managers Phone no,Activate Dashboard,Conversion Tracking,Creative Services,Call Tracking,Package Name,Product,Product Type,Product Desc,Line item start,Line item End,Network,Wholesale rate,Cost Model,Monthly Impression Goal,Retail Rate,Discount Percent,Wholesale CPM,Retail CPM';
    string rows = '';
    soID = apexPages.currentPage().getParameters().get('id');
        cscfga__Product_Basket__c prodBasket = new cscfga__Product_Basket__c();
        GenerateAttrHelper helper = new GenerateAttrHelper();       
        prodBasket = helper.ProdBasketList(soID);        
        prodConfigs = helper.ProdConfigListCSV(prodBasket.Id);         
        
        if(prodConfigs != null && prodConfigs.size()>0){
            for(cscfga__Product_Configuration__c prodConf : prodConfigs)
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
        
    }
    
    /* Search for a sepcific attibute and it's value in the List of Product Configuration Attributes*/
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
        
        csmso__Sales_Order__c salesOrder = [select csmso__Opportunity__c, name from csmso__Sales_Order__c where Id = :soID]; 
        // create the new attachment
        Attachment attachCSV = new Attachment();
    
        // the contents of the attachment from the csv
        Blob bodyCsv;
    
        try {
                
        } catch (VisualforceException e) {
    
        }
    
        attachCSV.Body = blob.valueOf(csvFileData );
        DateTime currenttime = DateTime.now();
        String strConvertedDate = currenttime.format('dd/MM/yyyy HH:mm:ss', 'Australia/Sydney');
        system.debug('----Australia Time--'+strConvertedDate);
        attachCSV.Name = salesOrder.name + ' ' +strConvertedDate+'.csv';
        csvName = salesOrder.name + ' ' +strConvertedDate+'.csv'; // T-28907
        attachCSV.IsPrivate = false;
        attachCSV.ParentId = salesOrder.csmso__Opportunity__c;
        insert attachCSV ;        
        return null;        
  }
    
   /*Wrapper class*/  
   public class AttrWrapper{
       public csmso__Sales_Order__c SO;
       public list<cscfga__Product_Configuration__c> prodConfigList;
       
    }   
}