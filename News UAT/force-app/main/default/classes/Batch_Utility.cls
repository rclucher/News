/*---------------------------------------------------------
* Author:  Darshan Gosar
* Description: This class contains utility methods which can be used for Batch classes
* Date: 12/17/2015
* History:
* 12/17/2015   Darshan Gosar       Created
    // SFE-766 2016-01-05 darshan.gosar@bluewolfgroup.com 
        // This class is created as part of code refactoring & to increase code coverage
* 2018-02-11    Paul Kang           Updated
    // Added SendEmail static method for sending to Data services team after Batch errors 
---------------------------------------------------------*/
global class Batch_Utility{

    // default method being called by actual batch classes
    public static boolean errorHandling(AsyncApexJob a, String batchName){
        return errorHandling(a, batchName, a.NumberOfErrors, a.Status);
    }
    
    // Added extra parameter to get better test coverage for errorHandling logic
    public static boolean errorHandling(AsyncApexJob a, String batchName, Integer numberOfErrors, String jobStatus){
        boolean errorFlag = false;
        if(a == null || numberOfErrors > 0) // Updated by Bohao Chen on 20/05/2014 for JIRA SFE-4
        {
            errorFlag =true;
            // Send an email to the Apex job's submitter notifying of job completion.
            String[] toAddresses = new String[] {a.CreatedBy.Email};
                String subject = batchName + a.Status;
            String msg = '<html><body>'
                + '<p>'
                + 'The batch Apex job processed '
                + a.TotalJobItems + ' batches with ' + numberOfErrors + ' failures.'
                + '</p><p>'
                + 'See below for failure details: <br />'
                + a.ExtendedStatus
                + '</p>'
                + '</body></html>';             
            
			// if there is error, then capture it in the Reusable Exception Logging module
            ExLog.log(new CustomException(batchName + ' execution Failed - see Additional Info'), 'config', (sObject) null, msg);            
            Global_Helper.sendMessageToUsers(subject, msg, toAddresses, 'html');
        }
        else if(jobStatus != 'Completed')
        {
            errorFlag =true;
            // Send an email to the Apex job's submitter notifying of job completion.
            String[] toAddresses = new String[] {a.CreatedBy.Email};
                String subject = batchName + ' has not been completed';
            
            String msg = '<html><body>' 
                + '<p>The batch Apex job process has not been completed.</p>'
                + '<p>The batch status is: ' + jobStatus + '</p>'
                + '</body></html>';
            
            ExLog.log(new CustomException(batchName + ' execution Failed - see Additional Info'), 'config', (sObject) null, msg);
            Global_Helper.sendMessageToUsers(subject, msg, toAddresses, 'html');
        }
        return errorFlag;
    }
    
    public class CustomException extends Exception {}   


    public static Messaging.SendEmailResult[] SendEmail(string[] toAddresses, string subject, string body) {
        return SendEmail(toAddresses,subject,body,false);
    }


    public static Messaging.SendEmailResult[] SendEmail(string[] toAddresses, string subject, string body, Boolean isHTML) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        if (isHTML == false) 
            mail.setPlainTextBody(body);
        else 
            mail.setHTMLBody(body);
        return Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
}