@isTest
public class SOApprovalRedirectTest {
    
    static testMethod void method1() {
        SOApprovalRedirect s = new SOApprovalRedirect();
        s.detectDevice();

    }
    
    static testMethod void method2() {
        SOApprovalRedirect s = new SOApprovalRedirect();
        s.isMobile = true;
        s.detectDevice();

    }
    
    

}