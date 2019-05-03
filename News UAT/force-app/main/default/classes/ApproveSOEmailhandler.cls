global class ApproveSOEmailhandler implements Messaging.InboundEmailHandler {
 
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                       Messaging.InboundEnvelope env){
 
    // Create an InboundEmailResult object for returning the result of the 
    // Apex Email Service
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
  
                                                               
    // Add the from address into localvariable
    string myFromEmail = email.fromAddress;
                                                           
    //Add the messageid into localvariable
    string soId = email.subject;
    
                                                           
    //Capture Comments from email 2nd line
    string comments;
    String[] emailBodyArray = email.plainTextBody.split('\n', 0);
	System.debug('emailBodyArray[0]: ' + emailBodyArray[0]);
	if(emailBodyArray[1]!=null && emailBodyArray[1]!=''){
        //Comments if the user enter comments in 2nd line
				comments = emailBodyArray[1];
				System.debug('Approval comments : ' + comments);
    }else if (emailBodyArray[2]!=null && emailBodyArray[2]!=''){
        //Comments if the user enters comments in 3rd line leaving the 2nd line blank
        		comments = emailBodyArray[2];
				System.debug('Approval comments : ' + comments);
    }
   
    csmso__Sales_Order__c so = new csmso__Sales_Order__c();
    try {
      
     	if (soId !=null){
            so = [Select id, name, Approver_Name__c,Approval_Process_Id__c from csmso__Sales_Order__c where name =:soId limit 1  ];
        }
        
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        if(comments!=null && comments!=''){
            req.setComments(comments);
        }
        
        req.setAction('Approve');
        
        //req.setNextApproverIds(new Id[] {opp.Next_Approver__c});
        system.debug('SO.id'+so.id); 
        string workItemId = getWorkItemId(so.id,myFromEmail);
        system.debug('workItemId'+workItemId);



        
        req.setWorkitemId(workItemId);
        // Submit the request for approval
        if(workItemId!=null && workItemId!=''){
            Approval.ProcessResult Approvalresult =  Approval.process(req);
        }
        
     
    }
    
   catch (Exception e) {
       System.debug('Exception: ' + e);
   }
   
   // Set the result to true. No need to send an email back to the user 
   // with an error message
   result.success = true;
   
   // Return the result for the Apex Email Service
   return result;
  }
    
  
    public Id getWorkItemId(Id targetObjectId, string fromEmailId)
    {
        Id retVal = null;
        id orgActorid = null;
        
        id userid = [Select id from user where Email =:fromEmailId limit 1].id;

        for(ProcessInstanceWorkitem workItem  : [Select p.Id ,p.OriginalActorId from ProcessInstanceWorkitem p
            where p.ProcessInstance.TargetObjectId =: targetObjectId])
        {	
            orgActorid = workItem.OriginalActorId;
            if(userid == orgActorid){
                retVal  =  workItem.Id;
            }
            
        }

        return retVal;
    }
}