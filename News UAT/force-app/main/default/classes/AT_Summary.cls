public class AT_Summary {
    public class Summary {
        @AuraEnabled
        public String title {get; set;}
        @AuraEnabled
        public String icon {get; set;}
        @AuraEnabled
        public Integer count {get; set;}
    }
    
    public Summary getSummary() {
        return null;
    }
}