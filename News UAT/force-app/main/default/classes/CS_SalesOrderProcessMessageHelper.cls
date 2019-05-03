/**
 * Created by petar.mikic on 21/09/2018.
 * Helper class to be used within Sales Order Trigger delegate before Update step. aim to replace process builder flow
 * and provide more flexibility and  optimized performance.
 *
 */

public without sharing  class CS_SalesOrderProcessMessageHelper {

    public static void updateApprovalMessage(Map<Id,csmso__Sales_Order__c> triggerNewMap, Map<Id,csmso__Sales_Order__c> triggerOldMap) {

        List<Id>     soIDs = new List<Id>();
        List<String> approvedStatuses = new List<String>{'Internally Approved','Externally Approved','Manually Approved'};

        for(csmso__Sales_Order__c so: triggerNewMap.values()) {

            if (so.csmso__Status__c == 'Draft' || so.csmso__Status__c == 'Retracted') {

                if( (so.Invalid_Config_Count__c!= null && so.Invalid_Config_Count__c > 0) || String.isEmpty(so.Basket_Products__c))
                {
                    setProcessMessage(so,'','');
                    continue;
                }


                if (so.Campaign_Products_Type__c == 'Invalid' ) {
                    setProcessMessage(so,'warning',System.Label.Invalid);
                    continue;
                }

                //SFE-989 Begins
                Integer Print_Display_Approval_Level =recalculatePrintDisplayApprovalLevel(so);
                if ( (Print_Display_Approval_Level > 0 || so.Print_Display_MAX_PPT_Level__c > 0) && so.Basket_Products__c.contains('[Print Display') )
                //if ( (so.Print_Display_Approval_Level__c > 0 || so.Print_Display_MAX_PPT_Level__c > 0) && so.Basket_Products__c.contains('[Print Display') )
                //SFe-989 Ends
                {
                    setProcessMessage(so,'warning',getBespokePrintApprovalMessage(so));
                    continue;
                }

                if ( so.Margin_Flag__c!= 'Margin OK' ||  (so.Campaign_Length__c!=null && so.Campaign_Length__c > 0) && so.Basket_Products__c.contains('[News Xtend') )
                {
                    setProcessMessage(so,'','');
                    continue;
                }

                setProcessMessage(so,'preapproved',System.Label.SO_does_not_require_approval);
                continue;

            }

            //petar oa:NX-1504 block retraction if archived products in the line items
            if (so.csmso__Status__c == 'Retraction Blocked') {
                setProcessMessage(so,'error',System.Label.Retraction_Blocked_Process_Message);
            }
            //clearing message when SO passess internal or external approval (this might happen without internal)
            if (approvedStatuses.contains(so.csmso__Status__c)) {
                setProcessMessage(so,'','');
                continue;
            }


        }






    }

    /*
    *
    * @param so Currrent sales order in the trigger New map
    * @param severity Supported picklist String value from SO csmso__Process_Message_Type__c field
    * currently supporting: error, warning & information
    * @param message String value of a desired message e.g. Using a predefined label System.Label.Invalid
    */
    public static void setProcessMessage(csmso__Sales_Order__c so, String severity, String message){

        so.csmso__Process_Message_Type__c   = severity;
        so.csmso__Process_Message__c = message;

    }

    public static String getBespokePrintApprovalMessage(csmso__Sales_Order__c so){
       //SFE-989 Begins
       //Integer SOLevel  = (so.Print_Display_Approval_Level__c > 0) ? Integer.valueOf(so.Print_Display_Approval_Level__c) : 0;
       Integer Print_Display_Approval_Level =recalculatePrintDisplayApprovalLevel(so);
       Integer SOLevel  = (Print_Display_Approval_Level > 0) ? Integer.valueOf(Print_Display_Approval_Level) : 0;
       //SFE-989 Ends
       Integer PPTLevel = (so.Print_Display_MAX_PPT_Level__c > 0)  ? Integer.valueOf(so.Print_Display_MAX_PPT_Level__c) : 0;

       String printMessage = System.Label.Approval_Level +' {0} Approver.';
       String printMessageParameter = '';

        if (SOLevel > 0 && PPTLevel > 0) {
            printMessageParameter = String.valueOf(SOLevel)+' Approver. '+System.Label.SO_Level_PPT_Approval_Message+' '+ String.valueOf(PPTLevel);
        } else if (SOLevel > 0) {
            printMessageParameter = String.valueOf(SOLevel);
        } else {
            printMessageParameter = System.Label.SO_Level_PPT_Approval_Message+' '+ String.valueOf(PPTLevel);
        }


            return String.format(printMessage, new List<String>{ printMessageParameter });
    }

    /**
    * @description : SFE-989 Method to recalcualte Print Display Approval Level (Similar functionality which is in Print_Display_Approval_Level__c formula field) 
    * @param :  csmso__Sales_Order__c 
    * @return: integer value of SO Level 
    */ 
    public static Integer recalculatePrintDisplayApprovalLevel(csmso__Sales_Order__c so){
        //====
        Integer SOLevel = 0;
        if (so.Proposed_Print_Discount__c > so.Target_Discount__c) {
        if ((so.Proposed_Print_Discount__c > so.Print_Display_DT_Percent_L1__c) || 
        (so.Proposed_Print_Price__c > so.Print_Display_DT_Amount_L1__c)) {
        SOLevel = 1;
        }
        if ((so.Proposed_Print_Discount__c > so.Print_Display_DT_Percent_L2__c) || 
        (so.Proposed_Print_Price__c > so.Print_Display_DT_Amount_L2__c)) {
        SOLevel = 2;
        }
        if ((so.Print_Display_DT_Percent_L3__c > 0 && so.Proposed_Print_Discount__c > so.Print_Display_DT_Percent_L3__c) || 
        (so.Print_Display_DT_Amount_L3__c > 0 && so.Proposed_Print_Price__c > so.Print_Display_DT_Amount_L3__c)) {
        SOLevel = 3;
        }
        if (so.Print_Display_DT_Amount_L4__c > 0 && so.Proposed_Print_Price__c > so.Print_Display_DT_Amount_L4__c) {
        SOLevel = 4;
        }
        }
        if (so.Print_Display_DT_Percent_L4__c > 0 && so.Proposed_Print_Discount__c > so.Print_Display_DT_Percent_L4__c) {
        SOLevel = 4;
        }
        return SOLevel;
        //====

    }


}