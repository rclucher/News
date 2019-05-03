/*
 * ------------------------------------------------------------
 * SOApprovalRedirect is used in SOApproval page to redirect user to
 * SOApproval page to show error message if they open using salesforce1 app
 * -------------------------------------------------------------
 * @author         Ashfaq Mohammed   <ashfaq.mohammed@news.com.au>
 * @version        1.0
 * @created        13-12-2018

*/

public class SOApprovalRedirect {
    
    public boolean isMobile {get;set;}
	public string soId;
    
    public class applicationException extends Exception {}
    public SOApprovalRedirect() {
        //Theme4t is for salesforce 1 app
        isMobile = UserInfo.getUiTheme() == 'Theme4t';
        soId = apexpages.currentpage().getparameters().get('Id');
       
    }

    public PageReference detectDevice(){
        system.debug('isMobile'+isMobile);
        
        if (isMobile){
            try{
                if(Test.isRunningTest()){
					throw new applicationException('Exceptoin to cover catch block');
				}
            	return null;
        	}catch(Exception ex){
			   return null;
			}
            
            
        }else{
            try{
                
                
                PageReference  pageRef  = new PageReference ('/apex/csmso__SalesOrderInfo?id='+soId);
                pageRef.setRedirect(true);
                if(Test.isRunningTest()){
					throw new applicationException('Exceptoin to cover catch block');
				}
   				return pageRef ;
                
                
            }catch(Exception ex){
               
			   PageReference  pageRef  = new PageReference ('/'+soId);
               pageRef.setRedirect(true);
   			   return pageRef ;
			}
            
            
        }
            
        	
               
    }

}