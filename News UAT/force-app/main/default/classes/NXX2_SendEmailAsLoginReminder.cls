/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_SendEmailAsLoginReminder
* @description  This class exposes a method for process builder 
*				which will be called to send email to the new portal user as login reminder.
*/
global class NXX2_SendEmailAsLoginReminder {
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method will be invoked by process builder to send email to the new portal user as login reminder.
    * @param        List<User> users
    * @return       void
    */
	@InvocableMethod(label='Send Email for login reminder' description='This method will send email to the new portal user as login reminder.')
    global static void sendEmailToCustomer(List<User> users) {
        NXX2_ResetPortalUser activateUser = new NXX2_ResetPortalUser(users);   
        System.enqueueJob(activateUser);
    }
}