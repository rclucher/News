/**
* @author       Kamal Sharma
* @date         2018-05-25
* @className	NXX2_ConfigModel
* @description  This class have wrapper classes to provide formatted data to client side(Aura Components).
*/
public virtual class NXX2_ConfigModel {
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	SocialAdType
    * @description  Wrapper classes to provide formatted data for Social Ad Type.
    */
    public class SocialAdType{
        @AuraEnabled
        public String adType;
        @AuraEnabled
        public List<SocialAdCreativeType> creativeTypes;
        @AuraEnabled
        public List<String> buttons;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	SocialAdCreativeType
    * @description  Wrapper classes to provide formatted data for Social Ad Creative Type.
    */
    public class SocialAdCreativeType{
        @AuraEnabled
        public String creativeTypeName;
        @AuraEnabled
        public Integer textMaxLength;
        @AuraEnabled
        public Integer headlineMaxLength;
        @AuraEnabled
        public Integer linkDescriptionMaxLength;
        @AuraEnabled
        public Integer eventNameMaxLength;
    }
    
    /**
    * @author       Kamal Sharma
    * @date         2018-05-25
    * @className	NXX2_Exception
    * @description  This class will be used to throw custom exception.
    */
    public class NXX2_Exception extends Exception {
        
    }
}