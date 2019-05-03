global class NXX2_ForgotPasswordController {
    
    public NXX2_ForgotPasswordController() {
        
    }
    
    @AuraEnabled
    public static String forgotPassword(String emailId, String checkEmailUrl) {
        try {
            List<User> users = [SELECT username FROM user WHERE Email = :emailId AND username LIKE '%.newsxtend'];
            if(users.size() > 0){
                String username = users[0].username;
                Site.forgotPassword(username,'NXX2_New_Customer_Login_Reset_Password');
                ApexPages.PageReference checkEmailRef = new PageReference(checkEmailUrl);
                if(!Test.isRunningTest()){
                    aura.redirect(checkEmailRef);
                }
                return null;
            }else{
                return 'There is no any portal user related to this email address!';
            }
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }
    
    @AuraEnabled
    global static String setExperienceId(String expId) {    
        // Return null if there is no error, else it will return the error message 
        try {
            if (expId != null) {
                Site.setExperienceId(expId);               
            }
            return null; 
        } catch (Exception ex) {
            return ex.getMessage();            
        }        
    } 
}