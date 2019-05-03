({
    currentAndNextPeriods: function(component, helper) {
        var action = component.get('c.getCurrentAndNextPeriods');

        action.setParams({
            nextCount: 2
        });
        
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var months = [];
                var periods = [];
                
                var periodMonths = response.getReturnValue();
                
                for (var i = 0; i < periodMonths.length; i++) {
                    periods.push(periodMonths[i].periodID);
                    
                    var even = true;
                    
                    months.push({
                        label: periodMonths[i].monthName,
                        value: periodMonths[i].monthName,
                        target:    { print: 0, digital: 0, combined: 0 },
                        actual:    { print: 0, digital: 0, combined: 0 },
                        pipeline:  { print: 0, digital: 0, combined: 0 },
                        gap:       { print: 0, digital: 0, combined: 0 },
                        percent:   0,
                        progress:  0,
                        indicator: '&nbsp;',
                        colour:    'black',
                        class:     (even ? 'even' : '')
                    });
                    
                    even = !even;
                }
                
                helper.getTargets(component, helper, periods, months, helper.completeCurrentAndNextPeriods);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
            }
        }));
        
        $A.enqueueAction(action);
    },
    completeCurrentAndNextPeriods: function(component, helper, periods, months) {
        component.set('v.months', months);
        
        helper.currentFYQuarterPeriods(component, helper);
    },
    currentFYQuarterPeriods: function(component, helper) {
        var action = component.get('c.getFYQuarterPeriods');
        
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var months = [];
                var periods = [];
                
                var periodMonths = response.getReturnValue();
                
                for (var i = 0; i < periodMonths.length; i++) {
                    periods.push(periodMonths[i].periodID);
                    
                    var even = true;
                    
                    months.push({
                        label:     periodMonths[i].monthName,
                        value:     periodMonths[i].monthName,
                        target:    { print: 0, digital: 0, combined: 0 },
                        actual:    { print: 0, digital: 0, combined: 0 },
                        pipeline:  { print: 0, digital: 0, combined: 0 },
                        gap:       { print: 0, digital: 0, combined: 0 },
                        percent:   0,
                        progress:  0,
                        indicator: '&nbsp;',
                        colour:    'black',
                        class:     (even ? 'even' : '')
                    });
                    
                    even = !even;
                }
                
                helper.getTargets(component, helper, periods, months, helper.completeFYQuarterPeriods);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
            }
        }));
        
        $A.enqueueAction(action);
    },
    completeFYQuarterPeriods: function(component, helper, periods, months) {
        var displayMonths = component.get('v.months');
        
        var quarter = {
            label:    '<i>Current FY Quarter</i>',
            value:    'Current FY Quarter',
            target:   { print: 0, digital: 0, combined: 0 },
            actual:   { print: 0, digital: 0, combined: 0 },
            pipeline: { print: 0, digital: 0, combined: 0 },
            gap:      { print: 0, digital: 0, combined: 0 },
            percent:  0,
            colour:   'black',
            class:    ((displayMonths[displayMonths.length - 1].class == 'even') ? '' : 'even')
        };
        
        for (var i = 0; i < months.length; i++) {
            quarter.target.print += months[i].target.print;
            quarter.target.digital += months[i].target.digital;
            quarter.target.combined += months[i].target.combined;
            
            quarter.actual.print += months[i].actual.print;
            quarter.actual.digital += months[i].actual.digital;
            quarter.actual.combined += months[i].actual.combined;
            
            quarter.pipeline.print += months[i].pipeline.print;
            quarter.pipeline.digital += months[i].pipeline.digital;
            quarter.pipeline.combined += months[i].pipeline.combined;
            
            /*quarter.gap.print += months[i].gap.print;
            quarter.gap.digital += months[i].gap.digital;
            quarter.gap.combined += months[i].gap.combined;*/
        }
        
        quarter.gap.print = quarter.target.print - (quarter.actual.print + quarter.pipeline.print);
        quarter.gap.digital = quarter.target.digital - (quarter.actual.digital + quarter.pipeline.digital);
        quarter.gap.combined = quarter.target.combined - (quarter.actual.combined + quarter.pipeline.combined);
        
        if (quarter.gap.print < 0) quarter.gap.print = 0;
        if (quarter.gap.digital < 0) quarter.gap.digital = 0;
        if (quarter.gap.combined < 0) quarter.gap.combined = 0;
        
        if (quarter.target.combined > 0) {
            quarter.percent = Math.floor(quarter.actual.combined / quarter.target.combined * 100);
            
            if (quarter.percent < 80) quarter.colour = '#F44336';
            if ((quarter.percent >= 80) && (quarter.percent < 100)) quarter.colour = '#FFD600';
            if (quarter.percent >= 100) quarter.colour = '#4CAF50';
            
            quarter.progress = (quarter.percent > 100) ? 100 : quarter.percent;
            if (quarter.percent > 100) {
                quarter.progress = 100;
                quarter.indicator = '+';
            } else {
                quarter.progress = quarter.percent;
                quarter.indicator = '&nbsp;';
            }
        }
        
        displayMonths.push(quarter);
        
        component.set('v.months', displayMonths);
        
        component.set('v.loading', false);
    },
    getTargets: function(component, helper, periods, months, complete) {
        var action = component.get('c.getTargetsForPeriods');
        
        action.setParams({
            periodIDs : periods
        });
        
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var targets = response.getReturnValue();

                if (targets && (targets.length > 0)) {
                    for (var i = 0; i < targets.length; i++) {
                        months[i].target.print = targets[i].print;
                        months[i].target.digital = targets[i].digital;
                        months[i].target.combined = targets[i].combined;
                    }
                    
                  	helper.getPipeline(component, helper, periods, months, complete);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                
                console.log('Error reading targets:');
                console.log(errors);
                if (errors.length) {
                    for (var i = 0; i < errors.length; i++) console.log(errors[i]);
                }
            }
        }));

        $A.enqueueAction(action);
    },
	getPipeline: function(component, helper, periods, months, complete) {
        var action = component.get('c.getPipelineForPeriods');
        
        action.setParams({
            periodIDs : periods
        });
        
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            //debugger;
            if (state === "SUCCESS") {
                var pipeline = response.getReturnValue();
                
                for (var i = 0; i < pipeline.length; i++) {
                    months[i].pipeline.print = pipeline[i].print;
                    months[i].pipeline.digital = pipeline[i].digital;
                    months[i].pipeline.combined = pipeline[i].combined;
                }
                
                helper.getActuals(component, helper, periods, months, complete);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
            }
        }));

        $A.enqueueAction(action);         
	},
    getActuals: function(component, helper, periods, months, complete) {
    	var action = component.get('c.getSalesActualsForPeriods');
        
        action.setParams({
            periodIDs : periods
        });
        
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            //debugger;
            if (state === "SUCCESS") {
                var sales = response.getReturnValue();
                
                if (sales) {
                    for (var i = 0; i < sales.length; i++) {
                        months[i].actual.print = sales[i].print;
                    	months[i].actual.digital = sales[i].digital;
                        months[i].actual.combined = sales[i].combined;
                    }
                    
                    helper.calculateGap(component, helper, periods, months, complete);
                }
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(errors);
            }
        }));
        $A.enqueueAction(action);
	},
    calculateGap: function(component, helper, periods, months, complete) {
        for (var i = 0; i < months.length; i++) {
            months[i].gap.print = months[i].target.print - (months[i].actual.print + months[i].pipeline.print);
            months[i].gap.digital = months[i].target.digital - (months[i].actual.digital + months[i].pipeline.digital);
            months[i].gap.combined = months[i].target.combined - (months[i].actual.combined + months[i].pipeline.combined);
            
            if (months[i].gap.print < 0) months[i].gap.print = 0;
			if (months[i].gap.digital < 0) months[i].gap.digital = 0;
            if (months[i].gap.combined < 0) months[i].gap.combined = 0;
            
            if (months[i].target.combined > 0) {
                months[i].percent = Math.floor(months[i].actual.combined / months[i].target.combined * 100);
                
                if (months[i].percent < 80) months[i].colour = '#F44336';
                if ((months[i].percent >= 80) && (months[i].percent < 100)) months[i].colour = '#FFD600';
                if (months[i].percent >= 100) months[i].colour = '#4CAF50';
                
                months[i].progress = (months[i].percent > 100) ? 100 : months[i].percent;
                
                if (months[i].percent > 100) {
                    months[i].progress = 100;
                    months[i].indicator = '<b>+</b>';
                } else {
                    months[i].progress = months[i].percent;
                    months[i].indicator = '&nbsp;';
                }
            }
        }
        
        complete.call(null, component, helper, periods, months);
    }
})