public class AT_EventsAndTasks {
    //private final static List<String> days = new List<String>{'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'};
        
    private final static Integer totalDays = 5;
    
    public class EventTask {
        @AuraEnabled
        public Id id {get; set;}
        @AuraEnabled
        public String type {get; set;}
        @AuraEnabled
        public String title {get; set;}
        @AuraEnabled
        public Datetime start {get; set;}
		@AuraEnabled
        public String displayTime {get; private set;}
        
        public EventTask(String type, Id id, String title, Datetime start) {
            this.id = id;
            this.title = title;
            this.type = type;
            this.start = start;
            
            if (start != null) {
                this.displayTime = this.start.format('h:mm a').toLowerCase().replace(' ', '');
            } else {
                this.displayTime = '(task)';
            }
        }
        
        public EventTask(String type, Id id, String title) {
            this.id = id;
            this.title = title;
            this.type = type;
            this.start = null;
            
            this.displayTime = '-';
        }
    }
    
    public class DayEntries {
        @AuraEnabled
        public List<EventTask> entries {get; set;}
        @AuraEnabled
        public String day {get; set;}
        @AuraEnabled
        public String dateMonth {get; set;}
        
        public DayEntries() {
            entries = new List<EventTask>();
        }
    }
    
    @AuraEnabled
    public static List<DayEntries> getEventsAndTasks() {
        List<Date> dates = new List<Date>();
        
        DateTime current = System.Now();
        
        Integer count = 0;
        
        while (count < totalDays) {
            String dayName = current.format('EEE');
            
            if ((dayName != 'Sun') && (dayName != 'Sat')) {
                dates.add(current.date());
                
                count++;
            }
            
            current = current.addDays(1);
        }
        
        
        Map<Date, List<EventTask>> dayMap = new Map<Date, List<EventTask>>();
        
        for (Task t: [SELECT Id, Subject, ActivityDate FROM Task WHERE (ActivityDate IN :dates) AND (OwnerId = :UserInfo.getUserId()) ORDER BY CreatedDate ASC]) {
            Date dayOfWeek = t.ActivityDate;
            
            List<EventTask> etl = dayMap.get(dayOfWeek);
            
            if (etl == null) {
                etl = new List<EventTask>();
                dayMap.put(dayOfWeek, etl);
            }
            
            etl.add(new EventTask('task', t.Id, t.Subject));
        }
        
        for (Event e: [SELECT Id, Subject, StartDatetime, ActivityDate FROM Event WHERE (ActivityDate IN :dates) AND (OwnerId = :UserInfo.getUserId()) ORDER BY StartDatetime ASC]) {
            Date dayOfWeek = e.ActivityDate;
            
            List<EventTask> etl = dayMap.get(dayOfWeek);
            
            if (etl == null) {
                etl = new List<EventTask>();
                dayMap.put(dayOfWeek, etl);
            }
            
            etl.add(new EventTask('event', e.Id, e.Subject, e.StartDateTime));
        }
        
        List<DayEntries> eventsTasks = new List<DayEntries>();
        
        for (Date d: dates) {
            DateTime dt = d;
            
            List<EventTask> etl = dayMap.get(d);
            
            if (etl == null) etl = new List<EventTask>();
            
            DayEntries de = new DayEntries();
            
            de.day = dt.format('EEEE');
            de.dateMonth = dt.format('d/MMM');
            de.entries = etl;
            
            eventsTasks.add(de);
        }
        
        return eventsTasks;
    }
}