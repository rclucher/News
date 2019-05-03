@isTest
public class AT_EventsAndTasks_Test {
	@isTest
    static void testWeekdays() {
        List<AT_EventsAndTasks.DayEntries> days = AT_EventsAndTasks.getEventsAndTasks();
        
        System.assertEquals(5, days.size(), 'Should show next 5 weekdays only');
        
        for (AT_EventsAndTasks.DayEntries day: days) {
            System.assertNotEquals('Sunday', day.day);
            System.assertNotEquals('Saturday', day.day);
        }
    }
    
    @isTest
    static void testEvent() {
        System.debug('NExt Weekday: ' + nextWeekday());
        
        Event ev = new Event(ActivityDateTime = nextWeekday(), Subject = 'test', DurationInMinutes = 60, OwnerId = UserInfo.getUserId());
        
        insert ev;
        
        List<AT_EventsAndTasks.DayEntries> days = AT_EventsAndTasks.getEventsAndTasks();
        
        System.assertEquals(5, days.size(), 'Should show next 5 weekdays only');
    }
    
    @isTest
    static void testTask() {
        Task tk = new Task(ActivityDate = nextWeekday().date(), Subject = 'test', OwnerId = UserInfo.getUserId());
        
        insert tk;
        
        List<AT_EventsAndTasks.DayEntries> days = AT_EventsAndTasks.getEventsAndTasks();
        
        System.assertEquals(5, days.size(), 'Should show next 5 weekdays only');
    }
    
    public static DateTime nextWeekday() {
        List<Date> dates = new List<Date>();
        
        DateTime current = System.Now();
        
        for (String dayName = current.format('EEE'); ((dayName == 'Sun') || (dayName == 'Sat')); current = current.addDays(1)) {
            dayName = current.format('EEE');
        }
        
        return current;
    }
}