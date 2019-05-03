global class CreateMarketingCloudQuoteTaxEmails implements Messaging.InboundEmailHandler {
 global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        result.success = false; 
        //String exceptionContent1 = email.subject + ' - ' + email.plainTextBody;
        //ExLog.log(new CustomException('Inbound Mail Failed'), 'config', (sObject) null, exceptionContent1);  
        //System.debug('@@CM : inbound handler : ' + exceptionContent1);
        List<String> subjArray = email.subject.split('-'); 

        if(!subjArray.isEmpty()){

            String bookingExternalId =  subjArray.get(subjArray.size() - 1).trim();
            List<Booking__c> bookingRecord = [Select Id from Booking__c where External_Id__c =:bookingExternalId];
            if(bookingRecord != null && bookingRecord.size()>0){
                try {

                    String htmlBody = email.htmlBody;
                    if(htmlBody != null) {

                        if(htmlBody.length() > 131000) {

                            htmlBody = htmlBody.substring(0,130999);

                        } 

                    }

                    insert new EmailMessage(FromAddress = email.fromAddress,
                                            FromName = email.fromName,
                                            ToAddress = email.toAddresses != null? String.join(email.toAddresses, ','):'',
                                            CcAddress = email.ccAddresses != null? String.join(email.ccAddresses, ','):'',
                                            Subject = email.subject,
                                            TextBody = email.plainTextBody,
                                            HtmlBody = htmlBody,
                                            RelatedToId = bookingRecord[0].Id);
                    result.success = true;
 
                }         
                catch (Exception ex) {
                    result.success = false;
                    System.debug('Error occured: ' + ex.getMessage());
                } 
            } else
            {
                String exceptionContent = email.subject + ' - ' + email.plainTextBody;
                ExLog.log(new CustomException('Inbound Mail Failed'), 'config', (sObject) null, exceptionContent);  

            }
        } 
        return result;
    } 

    public class CustomException extends Exception {}  
    
}