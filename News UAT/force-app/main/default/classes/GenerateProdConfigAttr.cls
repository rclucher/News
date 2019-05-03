//*******************************************************************************
// Developed by: Malvika Sharma
// Date Created: 12.04.2016 (dd.MM.yyyy)
// Last Update: 12.04.2016 (dd.MM.yyyy)
// Description: Generates PDF of Sales Order related Attributes onclick of button
// Modification(s):
// - Change fileName to be SO-xxxxxx prefix (Alistair Borley)
//*******************************************************************************
/* GenerateProdConfigAttr class for */
global class GenerateProdConfigAttr implements csmso.SalesOrderSupport.SalesOrderCustomAction {

    public cscfga__Product_Basket__c prodBasket{get;set;}
    public user currentuser{get;set;}
    public list<cscfga__Product_Configuration__c > prodConfigs{get;set;}
    public list<cscfga__Product_Basket__c> allProdBaskets{get;set;}
    public List<LineItemWrapper> lineItems {get;set;}
    public Id soID;
    public String fileName{get;set;}
    public String soName {get; set;}
    
    /*Standard controller method */
    global GenerateProdConfigAttr (ApexPages.StandardController controller) {
        // fileName = 'Data-'+System.Now();
        soID = apexPages.currentPage().getParameters().get('id'); //To read parameters from url . This line will read Id value from url
        csmso__Sales_Order__c salesOrder = [select name from csmso__Sales_Order__c where Id = :soID]; 

        fileName = salesOrder.name + ' ' + System.Now();
        lineItems = new List<LineItemWrapper>();
       
        getSOLineItems(soID);
    }
    
    /* KK - added no-arg constructor*/
    public GenerateProdConfigAttr() {
        
    }

    /* method to get Id of the sales order and redirect to the vf page */
    global String performAction(String salesOrderId) {
        getSOLineItems(salesOrderId);
        
        string retURL=URL.getSalesforceBaseUrl().toExternalForm().replace('csmso','c')+'/apex/DownloadCSV?id='+Id.valueOf(salesOrderId);       
        return '{"status":"ok","redirectURL":"' + retURL + '"}';   
                
    }
    
    /* method to get sales order related product configs via poduct basket */
    public List<LineItemWrapper> getSOLineItems(string salesOrderId)
    {
        prodBasket = new cscfga__Product_Basket__c();
        GenerateAttrHelper helper = new GenerateAttrHelper();       
        prodBasket = helper.ProdBasketList(salesOrderId);        
        prodConfigs = helper.ProdConfigList(prodBasket.Id);           
  
        return lineItems;
   }  
   
   
   /*Wrapper class */ 
   public class LineItemWrapper{
       public String Description{get;set;}
       public String DateRange{get;set;}
       public Decimal Price{get;set;}
       public String Status{get;set;}
       public String Name{get;set;}
       public String Value{get;set;}
    }   
        
}