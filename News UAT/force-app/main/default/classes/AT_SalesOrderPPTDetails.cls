public class AT_SalesOrderPPTDetails {
    public String salesOrderRecordID {get; set;}
    public List<cscfga__Product_Configuration__c> PC {get; set;}
    public List<AggregateResult> PCNew {get; set;}
    public Decimal clientDiscountValue {get; set;}
    public Decimal targetDiscountValue {get; set;}
    public Decimal Sum_Of_Insertions {get; set;}
    public String Owner_Name {get; set;}
    public String Campaign_Start_Date_Formatted {get; set;}
    public String pubs {get; set;}
    
    
    public List<cscfga__Product_Configuration__c> getConfigs() {
        PC = [select ID,cscfga__Product_Basket__r.csmso__Sales_Order__r.Client_Current_Discount_FY__c, Publication__c,Line_Item_Quantity__c,
              Proposed_Discount__c,Proposed_Discount_Amount__c, Total_Target_Duration_Price__c, cscfga__Product_Basket__r.csmso__Sales_Order__r.Target_Discount__c , 
              cscfga__Product_Basket__r.csmso__Sales_Order__c, Print_Display_PPT_Threshold__c, Day_of_Week__c, Ad_Size__c, Print_Display_Selected_Days_Set__c 
              from cscfga__Product_Configuration__c where cscfga__Product_Basket__r.csmso__Sales_Order__c =:salesOrderRecordID and Print_Display_PPT_Level__c > 0];
        PCNew = [select SUM(Line_Item_Quantity__c) SUM from cscfga__Product_Configuration__c where cscfga__Product_Basket__r.csmso__Sales_Order__c =:salesOrderRecordID and Print_Display_PPT_Level__c > 0];
        Sum_Of_Insertions = (Decimal) PCNew[0].get('SUM');
        return PC;
    }
    
    public String getPublications(){
        pubs='';
        if (salesOrderRecordID!=null){
            PC = [select ID, Publication__c from cscfga__Product_Configuration__c where cscfga__Product_Basket__r.csmso__Sales_Order__c =:salesOrderRecordID and Platform__c='Print'];
            for (cscfga__Product_Configuration__c PcSingle: PC){ if (PcSingle.Publication__c != null) pubs = pubs + PcSingle.Publication__c + ', ';}
            pubs = pubs.removeEnd(', ').trim();
        }
        return pubs;
    }
    
}