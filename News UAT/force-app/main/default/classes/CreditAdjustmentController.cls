/**********************************************************************************************
Name          : CreditAdjustmentController 
Created By    : Malvika Sharma
Created Date  : Sep 7 2016
Description   : Class to create Order, Payment, Payment Schedule and Payment Line Item records
for SO having status as 'Externally Approved' or 'Manual Approval' onclick of 
Schedule Payments button on opportunity
-------
History                                                            
-------                                                            
VERSION     AUTHOR              DATE           DETAIL                   
------      ------              -----          -------                
1.1         Malvika Sharma      7-09-2016     Created   
**********************************************************************************************/
global class CreditAdjustmentController 
{
    public static Payment__c  paySchRec = new Payment__c ();
    public static List<Payment_Schedule__c> payRecSchedules = new List<Payment_Schedule__c>();
    public static List<cscfga__Product_Configuration__c> prodConfigs = new List<cscfga__Product_Configuration__c>();
    global static String[] attrName = new String[]{'Product Name', 'Quantity', 'Price'};    
    public static List<Payment_Line_Item__c> payLineItems = new List<Payment_Line_Item__c>();
    public static cscfga__Product_Basket__c  productBas;
    public List<Payment_Line_Item__c> paymentLineItemList{get;set;}
    public List<Payment_Schedule__c> paymentScheduleList{get;set;}
    public Map<string,List<Payment_Line_Item__c>> paymentLineMap{get;set;}
    public integer newLineItemPrice{get;set;}
    public Map<string,Boolean> showErrorMessageMap{get;set;}
    private decimal lineItemVaue{get;set;}
    public Map<string,Decimal> priceMap{get;set;}
    public Map<Id,Decimal> currentpriceMap{get;set;}
    public string copyPricingVal{get;set;}
    
    /* Standard Controller method */ 
    public CreditAdjustmentController(ApexPages.StandardController controller) {
        newLineItemPrice =0;        
        priceMap = new Map<string,Decimal>();
        showErrorMessageMap = new Map<string,Boolean>();
        paySchRec = (Payment__c)controller.getRecord();
        integer currentMonth = Date.Today().Month();
        //paymentScheduleList = [Select id, Name,Amount__c,Payment__c,Status__c,Billing_Date__c,Credit_Adjusted__c ,Credit_Approved__c ,Schedule_End_Date__c,Schedule_Start_Date__c,Sent_Date__c from Payment_Schedule__c where  Payment__c=:paySchRec.id  and CALENDAR_MONTH(Schedule_Start_Date__c)=:currentMonth];
        //paymentLineItemList = [select id,Name,Price__c,Payment_Schedule__c from Payment_Line_Item__c where Payment_Schedule__c IN : paymentScheduleList ];
        paymentLineItemList = new List<Payment_Line_Item__c>();
        paymentLineMap = new Map<string,List<Payment_Line_Item__c>>();
        currentpriceMap = new Map<Id,Decimal>();
        paymentScheduleList = [select id,Name,Payment__c, Status__c,Schedule_Start_Date__c,Credit_Adjusted__c,Billing_Date__c,Credit_Approved__c ,Schedule_End_Date__c,Sent_Date__c, (select id,Name,Price__c,Payment_Schedule__c,Basic_Price__c,Configuration_ID__c,Discount__c,List_Price__c ,Product_ID__c,Product_Name__c,Quantity__c,Recurring__c,Site_Section__c,Type__c from Payment_Line_Items__r where type__c = 'Normal') from Payment_Schedule__c where Payment__c=:paySchRec.id order by Schedule_Start_Date__c];
        Boolean psFound = false;
        Payment_Schedule__c currentPS;
        List<Payment_Schedule__c> paymentSchedules = new List<Payment_Schedule__c>();
        paymentSchedules = [SELECT Id FROM Payment_Schedule__c WHERE Payment__c=:paySchRec.id AND Status__c IN ('In Progress', 'Pending')];
        if (paymentSchedules.isEmpty()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'No payment schedules with status <b>Pending</b> or <b>In Progress</b>, please amend the end date to apply credit.'));
            return;
        }
        for (Payment_Schedule__c paymentschRec : paymentScheduleList) {
            if (paymentschRec.Schedule_Start_Date__c >= System.now().date().toStartOfMonth() && (paymentschRec.Status__c == 'Pending' || paymentschRec.Status__c == 'In Progress') && !psFound) {
                Payment_Line_Item__c[] paymentItemRecList= paymentschRec.Payment_Line_Items__r;
                paymentLineMap.put(paymentschRec.ID,paymentItemRecList);
                paymentLineItemList = paymentschRec.Payment_Line_Items__r;
                for(Payment_Line_Item__c paymentLineSum : paymentLineItemList){
                    currentpriceMap.put(paymentLineSum.id,paymentLineSum.Price__c != null ? paymentLineSum.Price__c : 0);
                }
                priceMap.put(paymentschRec.ID,lineItemVaue);
                showErrorMessageMap.put(paymentschRec.ID,false);
                currentPS = paymentschRec;
                psFound = true;
            }
        }
        system.debug(currentpriceMap);
        system.debug(paymentLineItemList);
        if (currentPS != null) {
            paymentScheduleList = new List<Payment_Schedule__c>();
            paymentScheduleList.add(currentPS);
        }
        //lineItemVaue = 0;
        for(Payment_Line_Item__c paymentLineSum : paymentLineItemList){
            /*if (paymentLineSum.Price__c != null) {
                lineItemVaue = lineItemVaue + paymentLineSum.Price__c;
            }*/
            paymentLineSum.Price__c = null;
            
        }
        system.debug('lineItemVaue -->'+lineItemVaue );
    }
    
    /*Method to save line items*/
    public PageReference savelineItem(){
        try{
        List<Payment_Line_Item__c> paymentLineItemToSave = new List<Payment_Line_Item__c>();
        List<Payment_Schedule__c> paymentsToUpdate = new List<Payment_Schedule__c>();
        for(Payment_Schedule__c payscheRec : paymentScheduleList){
            system.debug('payscheRec-->'+payscheRec);
            if(payscheRec.Status__c == 'Pending' || payscheRec.Status__c ==  'In Progress'){
                for(Payment_Line_Item__c paymentLineSum : paymentLineItemList){
                system.debug('paymentLineSum.price__c'+paymentLineSum.price__c);
                    system.debug('payscheRec.Status__c'+payscheRec.Status__c);
                    if(paymentLineSum.price__c != 0){
                    paymentLineSum.price__c = paymentLineSum.price__c * -1;
                    paymentLineSum.Type__c = 'Credit';
                    paymentLineSum.Basic_Price__c = paymentLineSum.Basic_Price__c;
                    paymentLineSum.Configuration_ID__c = paymentLineSum.Configuration_ID__c;
                    paymentLineSum.Discount__c = paymentLineSum.Discount__c;
                    paymentLineSum.List_Price__c = paymentLineSum.List_Price__c;
                    paymentLineSum.Product_ID__c = paymentLineSum.Product_ID__c;
                    paymentLineSum.Product_Name__c = paymentLineSum.Product_Name__c;
                    paymentLineSum.Quantity__c = paymentLineSum.Quantity__c;
                    paymentLineSum.Recurring__c = paymentLineSum.Recurring__c;
                    paymentLineSum.Site_Section__c = paymentLineSum.Site_Section__c;
                    paymentLineSum.Site_Section_Group__c = paymentLineSum.Site_Section_Group__c;
                    paymentLineSum.Network__c = paymentLineSum.Network__c;
                    paymentLineSum.Cost_Model__c = paymentLineSum.Cost_Model__c;
                    paymentLineItemToSave.add(paymentLineSum.clone(false, false, false, false));
                   }
                }
                payscheRec.Credit_Adjusted__c = true;
                
                paymentsToUpdate.add(payscheRec);
                //insert paymentLineItemToSave;
            }
            else{
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'No payment schedules with status <b>Pending</b> or <b>In Progress</b>, please amend the end date to apply credit.'));
                //return null;
            
            
                //payscheRec.Status__c = 'Pending';
               // Payment_Schedule__c paymentSch = payscheRec.Clone(false, false, false, false);
               // insert paymentSch;
               /*list<Payment_Schedule__c> paymentSchList = new List<Payment_Schedule__c>();
                    paymentSchList.add(new Payment_Schedule__c(
                                                                Name = payscheRec.Name,
                                                                Billing_Date__c = payscheRec.Billing_Date__c,
                                                               Credit_Adjusted__c = payscheRec.Credit_Adjusted__c,
                                                               Credit_Approved__c = payscheRec.Credit_Approved__c,
                                                               Payment__c = payscheRec.Payment__c,
                                                               Schedule_End_Date__c  = payscheRec.Schedule_End_Date__c,
                                                               Schedule_Start_Date__c = payscheRec.Schedule_Start_Date__c,
                                                               Sent_Date__c = payscheRec.Sent_Date__c,
                                                               Status__c = 'Pending'));
                insert paymentSchList;*/
                /*for(Payment_Line_Item__c paymentLineSum : paymentLineItemList){
                system.debug('paymentLineSum.price__c'+paymentLineSum.price__c);
                    if(paymentLineSum.price__c != 0){
                        paymentLineItemToSave.add(new Payment_Line_Item__c(price__c = paymentLineSum.price__c * -1,
                                                                            Payment_Schedule__c = payscheRec.id,
                                                                            Name=paymentLineSum.Name,
                                                                            Type__c = 'Credit',
                                                                            Basic_Price__c = paymentLineSum.Basic_Price__c,
                                                                            Configuration_ID__c = paymentLineSum.Configuration_ID__c,
                                                                            Discount__c = paymentLineSum.Discount__c,
                                                                            List_Price__c = paymentLineSum.List_Price__c,
                                                                            Product_ID__c = paymentLineSum.Product_ID__c,
                                                                            Product_Name__c = paymentLineSum.Product_Name__c,
                                                                            Quantity__c = paymentLineSum.Quantity__c,
                                                                            Recurring__c = paymentLineSum.Recurring__c,
                                                                            Site_Section__c = paymentLineSum.Site_Section__c,
                                                                            Site_Section_Group__c = paymentLineSum.Site_Section_Group__c,
                                                                            Network__c = paymentLineSum.Network__c,
                                                                            Cost_Model__c = paymentLineSum.Cost_Model__c));
                        }
                    }*/
                    
                //insert paymentLineItemToSave;
            }
            if (!paymentLineItemToSave.isEmpty()) {
                insert paymentLineItemToSave;
            }
            if (!paymentsToUpdate.isEmpty()) {
                update paymentsToUpdate;
            }
        }
        }catch(Exception ex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error Occured :'+ex.getMessage())); 
            return null; 
        }
        PageReference paymentiew= new ApexPages.StandardController(paySchRec).view();
        paymentiew.setRedirect(true);
        return paymentiew;
    }
    
}