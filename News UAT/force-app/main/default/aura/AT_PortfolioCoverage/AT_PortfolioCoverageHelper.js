({
    weeksBetween: function(from, to) {
        if (!from || !to) return 1000;
        
        // The number of milliseconds in one week
        var ONE_WEEK = 1000 * 60 * 60 * 24 * 7;
        // Convert both dates to milliseconds
        //var date1_ms = from.getTime();
        //var date2_ms = to.getTime();
        // Calculate the difference in milliseconds
        var difference_ms = to - from; //Math.abs(date1_ms - date2_ms);
        // Convert back to weeks and return hole weeks
        return Math.ceil(difference_ms / ONE_WEEK);
	}
})