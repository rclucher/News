/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_ResetPortalUser
* @description  This class will reset portal user.
*/
public class NXX2_ResetPortalUser implements Queueable {
	private List<User> users;
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  Constructor.
    * @param        List<User> users
    */
	public NXX2_ResetPortalUser(List<User> users) {
		this.users = users;
	}
    /**
    * @author       Kamal Sharma
    * @date         2018-05-23
    * @description  This method defined execute method of queuable interface.
    * 				This will reset password of the user and the email will be send by salesforce automatically 
    * 				on password reset. Email template will be same as metioned in community admin portal for reset password.
    * @param        QueueableContext context
    * @return       void
    */
	public void execute(QueueableContext context) {
        if(Users.size()>0){ 
            for(User user : Users){
                System.resetPassword(user.Id,true);
            }
        }
	}
}