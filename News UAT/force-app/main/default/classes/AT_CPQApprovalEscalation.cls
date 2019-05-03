public class AT_CPQApprovalEscalation{

public void sendEmail(){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        system.debug('Send EMAIL called');
        string[] toAddress = New String[] {'Sandhya.Rao@CloudGo.asia'};
        String subject = 'Reminder to Approve/Reject';
        String body = 'Hi approver,';
        //if (sOrder.Opportunity_Owner_Email__c != null)
        
            //toAddress = 'Sandhya.Rao@CloudGo.asia';
            
        
            // Sets the paramaters of the email

            email.setSubject( subject );

            email.setToAddresses( toAddress );

            email.setPlainTextBody( body );


            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
            system.debug('---r'+r);
            
    }
    
    Public void submitforApproval(){ //Platform__c, , Print_Approver__c
        csmso__Sales_Order__c sOrder = [SELECT Id, Approval_Level__c, Opportunity_Owner_Email__c, Digital_Approver__c 
                                        FROM csmso__Sales_Order__c 
                                        WHERE csmso__Status__c =: 'Pending'];
                                        
        List<CPQ_Approver__c> approvers = [SELECT Id, Platform__c, L1_Approver__c, L2_Approver__c, L3_Approver__c, L4_Approver__c
                                            FROM CPQ_Approver__c
                                            ];//WHERE Platform__c =: sOrder.Platform__c 
        
        List<csmso__Sales_Order__c> sOrderList = new List<csmso__Sales_Order__c>();

        for(CPQ_Approver__c approve: approvers){
            /*System.debug('--Sales Order Platform' + sOrder.Platform__c);
            if(sOrder.Platform__c == approve.Platform__c && sOrder.Platform__c == 'Print'){
                if(sOrder.Approval_Level__c == '1'){
                    sOrder.Print_Approver__c = approve.L2_Approver__c;
                }
                if(sOrder.Approval_Level__c == '2'){
                    sOrder.Print_Approver__c = approve.L2_Approver__c;
                }
                if(sOrder.Approval_Level__c == '3'){
                    sOrder.Print_Approver__c = approve.L3_Approver__c;
                }
                
            } */
            
        } sOrderList.add(sOrder);
        system.debug('++SorderList ' +sOrderList);
        if(!sOrderList.isEmpty()){
            update sOrder;
        }
                                           
        User salesRep = [SELECT Id, Email, Name FROM User WHERE Email=: sOrder.Opportunity_Owner_Email__c];

        // Create an approval request for the account
        Approval.ProcessSubmitRequest request = new Approval.ProcessSubmitRequest();
        request.setComments('Submitting Sales Order request for approval.');
        request.setObjectId(sOrder.id);

        // Submit on behalf of a specific submitter - Sales rep from CPQ approver object
        request.setSubmitterId(salesRep.Id);
        /*if(sOrder.Platform__c == 'Print'){
            request.setProcessDefinitionNameOrId('SO_Approvals_Print');
        }*/
        // Submit the record to specific process and skip the criteria evaluation
            
            request.setSkipEntryCriteria(false);
            
        // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(request, true);
            System.debug(result);
            String instanceId = result.getInstanceId();
            System.debug(instanceId);

        /*ProcessInstance approvalProcess = [SELECT ID, CreatedDate, ProcessDefinitionId, ElapsedTimeInHours, TargetObjectId, Status 
                                   FROM ProcessInstance 
                                   WHERE Id =: instanceId];
        System.debug(approvalProcess);*/

    }
}