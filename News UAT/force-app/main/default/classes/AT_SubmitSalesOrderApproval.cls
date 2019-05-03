public class AT_SubmitSalesOrderApproval{
    public string selectedReason{get;set;}
    public string comments{get;set;}
    public string sOrderId{get;set;}  
    public string sOrderPlatform{get;set;}  
    public string sOrderLevel{get;set;} 
    public csmso__Sales_Order__c sOrder{get;set;}
    
    public String errorMessage {get; set;}
    public String infoMessage {get; set;}
    
    public AT_SalesOrderApprovals sOapproval = new AT_SalesOrderApprovals();
    public AT_SalesOrderApprovals.PlatformLevel sOPlatform{get;set;} 
    public List<AT_SalesOrderApprovals.PlatformLevel> sOPlatformList{get;set;} 
    public List<AT_SalesOrderApprovals.PlatformApprover> approverList{get;set;} 
    public AT_SalesOrderApprovals.Platform platform{get;set;} 
    public List<User> approvers{get;set;}
    public String splitPlatform{get;set;}
    public String splitPlatformRemovecurly{get;set;}
    public List<String> platforms{get;set;}
    
    public AT_SubmitSalesOrderApproval(ApexPages.StandardController controller){ //Platform__c, , Print_Approver__c
        errorMessage = null;
        infoMessage = null;
        
        sOrderId = controller.getId();
        
        System.debug('Constructor ID: ' + sOrderId);
        
        Map<String, String> params = Apexpages.currentPage().getParameters();
        
        
        System.debug('Params: ' + params);
        
        csmso__Sales_Order__c sOrder = [SELECT Id, Name, Platform_Set__c, Print_Display_Approval_Level__c, Print_Display_MAX_PPT_Level__c  FROM csmso__Sales_Order__c WHERE Id=: sOrderId LIMIT 1];
        
        sOPlatformList =  new List<AT_SalesOrderApprovals.PlatformLevel>();
        
        for (String param: params.keySet()) {
            if (param.startsWith('platform-')) {
                if (param.endsWith('Print')) {
                    sOPlatformList.add(new AT_SalesOrderApprovals.PlatformLevel(AT_SalesOrderApprovals.Platform.Print, Integer.valueOf(params.get(param))));
                } else if (param.endsWith('Threshold')) {
                    sOPlatformList.add(new AT_SalesOrderApprovals.PlatformLevel(AT_SalesOrderApprovals.Platform.Threshold, Integer.valueOf(params.get(param))));
                }
            }
        }
        
        System.debug('Platform List: ' + sOPlatformList);
        
        approverList = AT_SalesOrderApprovals.findApprovers(sOPlatformList, sOrder.Id);

        if ((approverList == null) || approverList.isEmpty()) {
            errorMessage = 'Sales order owner is missing from CPQ Approvers table. Please speak to your local operations team.';
            System.debug('Sales order owner is missing from CPQ Approvers table. Please speak to your local operations team.');
            return;
        }        

        for (Integer i = 0; i < approverList.size(); i++) {
            if (approverList[i].type == AT_SalesOrderApprovals.ApproverType.NotFound) {
                approverList.remove(i);
            }
        }
        
        if ((approverList == null) || approverList.isEmpty()) {
            errorMessage = 'Sales order owner is missing from CPQ Approvers table. Please speak to your local operations team.';
            System.debug('Sales order owner is missing from CPQ Approvers table. Please speak to your local operations team.');
            return;
        }
        
        approverList.sort();
        
        System.debug('Approver List: ' + approverList);
        
        for (Integer i = 0; i < approverList.size(); i++) {
            AT_SalesOrderApprovals.PlatformApprover pa = approverList[i];
            
            if ((pa.type == AT_SalesOrderApprovals.ApproverType.SameLevel) || (pa.type == AT_SalesOrderApprovals.ApproverType.NotFound)) {
                approverList.remove(i);
            }
        }
        
        
        if (approverList.isEmpty()) {
            infoMessage = 'Sales order does not require further approval.';
        }
    }
    
    public pageReference submitSO(){
        errorMessage = null;
        if ((selectedReason=='--Select Reason--') && (comments==null||comments=='')){
            errorMessage = 'Discount Reason not selected and Discount Notes have not been entered. Please amend before submitting for Internal Approval';
            return null;
        }else if (selectedReason=='--Select Reason--') {
            errorMessage = 'Discount Reason not selected. Please amend before submitting for Internal Approval';
            return null;
        }else if (comments==null||comments=='') {
            errorMessage = 'Discount Notes have not been entered. Please amend before submitting for Internal Approval';
            return null;
        }else{
            List<AT_SalesOrderApprovals.PlatformLevel> platformLevels = new List<AT_SalesOrderApprovals.PlatformLevel>();
            
            for (AT_SalesOrderApprovals.PlatformApprover appr: approverList) {
                platformLevels.add(new AT_SalesOrderApprovals.PlatformLevel(appr.Platform, appr.Level));
            }
            
            
            Pagereference sr = AT_SalesOrderApprovals.submitForApproval(sOrderId, platformLevels, selectedReason, comments);
            
            return sr;
        }
    }
    
    public pageReference cancel(){
        PageReference page;
        page = new PageReference('/'+sOrderId);
        page.setRedirect(true);
        return page;
    }
    
    public List<Selectoption> getSelectReason(){
        /*
* 16-10-2018: Mohsin Ali : Fixed the Approval Reason Not Populating Issue. Refer to Jira: NR-1687
* 11-11-2018: Mohsin Ali : Adding --Select Reason-- as picklist value for the business. Refer to Jira: NR-1794.
* This way, we will default it to --Select Reason-- and then let the user select the reason of choice.
*/
        List<Selectoption> selectReasonList = new List<selectoption>();
        selectReasonList.add(new selectOption('--Select Reason--', '--Select Reason--'));
        selectReasonList.add(new selectOption('Agreement Condition', 'Agreement Condition'));
        selectReasonList.add(new selectOption('Bonus Space – Contracted', 'Bonus Space – Contracted'));
        selectReasonList.add(new selectOption('Bonus Space – Non-Contracted', 'Bonus Space – Non-Contracted'));
        selectReasonList.add(new selectOption('Charity', 'Charity'));
        selectReasonList.add(new selectOption('Compensation', 'Compensation'));
        selectReasonList.add(new selectOption('Historical Rate – No Contract', 'Historical Rate – No Contract'));
        selectReasonList.add(new selectOption('Late Space/Distress', 'Late Space/Distress'));
        selectReasonList.add(new selectOption('New Business Offer', 'New Business Offer'));
        selectReasonList.add(new selectOption('News Value Bundles', 'News Value Bundles'));
        selectReasonList.add(new selectOption('Promotional Package', 'Promotional Package'));
        selectReasonList.add(new selectOption('Revenue Share', 'Revenue Share'));            
        return selectReasonList;        
    }
}