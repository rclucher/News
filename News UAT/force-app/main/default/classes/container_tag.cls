public class container_tag {
    
   @TestVisible
    private ApexPages.StandardController ctrl;
    
    public container_tag(ApexPages.StandardController controller) {
        this.ctrl = controller;
    }   
    

    public PageReference executeContainerLogic(){
            Id OrderId =  ctrl.getRecord().Id;
            String temp = GenericWebServices.startOrchProcessFor(OrderId, 'Container Tag Setup');
            
            if(temp == ''|| temp == null ){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.info, 'Container tag process has been initiated'));
                return null;            
            }
            else{
               ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, temp)); 
               return null;
            }

    }   
    
}