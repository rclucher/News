({
    loadForUsername: function(component, helper, username) {
        var action = component.get("c.getDashboardInfo");
        action.setParams({ username : username });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                var res = response.getReturnValue();

                component.set('v.userRoleID', res.roleID);
                component.set('v.view', res.type);
                
                var salesTopics = [];
                var digitalTopics = [];
                var marketingTopics = [];
                var productTopics = [];
                
                var pillars = [];
                
                for (var i = 0; i < res.pillars.length; i++) {
                    var pillar = res.pillars[i];
                    
                    pillars.push({
                        id: pillar.Pillar_Id__c,
                        name: pillar.Name
                    });
                }
                
                for (var i = 0; i < res.topics.length; i++) {
                    var topic = res.topics[i];
                    
                    var t = {
                        id: topic.Topic_ID__c.substring(2),
                        name: topic.Name,
                        max: topic.Max_Score__c,
                        pillar: topic.Pillar_Name__c
                    };
                    
                    if (t.pillar == 'Sales') salesTopics.push(t);
                    if (t.pillar == 'Digital') digitalTopics.push(t);
                    if (t.pillar == 'Marketing') marketingTopics.push(t);
                    if (t.pillar == 'Product') productTopics.push(t);
                }
                
                component.set('v.pillars', pillars);
                
                component.set('v.salesTopics',salesTopics);
                component.set('v.salesTopicCount',salesTopics.length);
                component.set('v.digitalTopics',digitalTopics);
                component.set('v.digitalTopicCount',digitalTopics.length);
                component.set('v.marketingTopics',marketingTopics);
                component.set('v.marketingTopicCount',marketingTopics.length);
                component.set('v.productTopics',productTopics);
                component.set('v.productTopicCount',productTopics.length);
                
                helper.loadPillarHeatmap(component, 'Sales', 'sales', salesTopics);
                helper.loadPillarHeatmap(component, 'Digital', 'digital', digitalTopics);
                helper.loadPillarHeatmap(component, 'Marketing', 'marketing', marketingTopics);
                helper.loadPillarHeatmap(component, 'Product', 'product', productTopics);
        
                helper.loadPillarScorecards(component, helper, pillars);
            } else if (state === "ERROR") {
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
	loadPillarHeatmap: function(component, pillar, dataAttr, topics) {
        var action = component.get("c.getTopicScores");
        action.setParams({
            pillarName : pillar,
            topicCount: topics.length,
            userRoleID: component.get('v.userRoleID')
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                
                console.log(res);
                
                var records = [];
                
                for (var i = 0; i < res.length; i++) {
                    var d = res[i];
                    
                    var score = {id: d.id, name: d.name, score: Math.round(d.score), data: []};
                    
                    for (var k = 0; k < topics.length; k++) {
                        var tp = topics[k].id;
                        
                        var matches = false;
                        
                        for (var t = 0; t < d.topics.length; t++) {
                            var topic = d.topics[t];
                            
                            if (topic.id.substring(2) == tp) {
                                matches = true;
                                break;
                            }
                        }
                        
                        if (matches && (topic.status == 'pass')) {
                            score.data.push('p');
                        } else {
                            score.data.push('i');
                        }
                    }
                    
                    records.push(score);
                }
                
                console.log(records);

                component.set('v.' + dataAttr,records);
            } else if (state === "ERROR") {
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
	},
    loadPillarScorecards: function(component, helper, pillars) {
        var action = component.get("c.getPillarScores");
        action.setParams({ userRoleID: component.get('v.userRoleID') });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log(state);
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                
                var records = [];
                
                console.log('Pillar scores:');
                console.log(res);
                
                for (var i = 0; i < res.length; i++) {
                    var d = res[i];
                    
                    var score = {id: d.id, name: d.name, score: Math.round(d.percent), status: d.status, data: []};
                    
                    for (var k = 0; k < pillars.length; k++) {
                        var pl = pillars[k];
                        
                        var matches = false;
                        
                        var percent = 0;
                        var status = '';
                        
                        for (var t = 0; t < d.pillars.length; t++) {
                            var pillar = d.pillars[t];
                            
                            if (pillar.name == pl.name) {
                                percent = Math.round(pillar.score);
                                status = pillar.status;
                                matches = true;
                                break;
                            }
                        }
                        
                        if (matches) {
                            score.data.push({score: percent, class: (status == 'pass' ? 'p' : 'i')});
                        } else {
                            score.data.push({score: 0, class: 'i'});
                        }
                    }
                    
                    records.push(score);
                }
                
                component.set('v.nitroNames', pillars);
				component.set('v.nitroCount', pillars.length + 1);
                component.set('v.nitro',records);
                
                helper.loadFinancials(component, helper, records);
            } else if (state === "ERROR") {
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
	},
    getRatio: function(revenue, target) {
        var revNum = revenue ? parseFloat(revenue) : 0;
        var targNum = target ? parseFloat(target) : 0;
        
        if (!revNum) return 0;
        
        if (targNum && targNum > 0) return Math.round((revNum / targNum) * 100);
        
        return 0;
    },
    loadFinancials: function(component, helper, records) {
        var view = component.get('v.view');
        
        var userIDs = null, roleIDs = null;
        
        if (view == 'users') {
            userIDs = [];
            for (var i = 0; i < records.length; i++) userIDs.push(records[i].id);
        } else {
            roleIDs = [];
            for (var i = 0; i < records.length; i++) roleIDs.push(records[i].id);
        }
        
        var totals = [], digitals = [];
        
        var action = component.get("c.getFinancials");
        action.setParams({ userIDs: userIDs, roleIDs: roleIDs });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var res = response.getReturnValue();
                
                for (var i = 0; i < res.length; i++) {
                    var data = res[i];
                    
                    var record = records.find(r => { return r.id === data.id });
                    
                    totals.push({
                        id: record.id,
                        name: record.name,
                        score: record.score,
                        ratio: helper.getRatio(data.combinedRevenue, data.combinedTarget),
                        target: Math.round(parseFloat(data.combinedTarget ? data.combinedTarget : 0)),
                        revenue: Math.round(parseFloat(data.combinedRevenue ? data.combinedRevenue : 0))
                    });
                    
                    digitals.push({
                        id: record.id,
                        name: record.name,
                        score: record.score,
                        ratio: helper.getRatio(data.digitalRevenue, data.digitalTarget),
                        target: Math.round(parseFloat(data.digitalTarget ? data.digitalTarget : 0)),
                        revenue: Math.round(parseFloat(data.digitalRevenue ? data.digitalRevenue : 0))
                    });
                }

                helper.loadPerformance(component, "totalPerformance", totals);
                helper.loadPerformance(component, "digitalPerformance", digitals);
            } else if (state === "ERROR") {
                console.log(response.getError());
            }
        });
        $A.enqueueAction(action);
    },
    loadPerformance: function(component, chart, records) {
		var achieved = [];
        var ontarget = [];
        var missing = [];
        
        for (var i = 0; i < records.length; i++) {
            var r = records[i];
            
            var perf = {
                name: r.name,
                x: r.score,
                y: r.ratio,
                r: 0,
                target: r.target,
                revenue: r.revenue
            };
            
            if (perf.y < 90) {
                perf.r = 10;
                perf.Status = 'Missing';
            	missing.push(perf);
            } else if (perf.y < 100) {
                perf.r = 15;
                perf.Status = 'On Target';
            	ontarget.push(perf);
            } else {
                perf.r = 12;
                perf.Status = 'Achieved';
            	achieved.push(perf);
            }
        }
        
        new Chart(component.find(chart).getElement().getContext('2d'), {
                    "type":"bubble",
                   	"data":
                      {
                          "datasets":[
                              {"label":">= 100%", "data":achieved,"backgroundColor":"rgb(96, 145, 74)"},
                              {"label":"90% to 99%", "data":ontarget,"backgroundColor":"rgb(246, 195, 51)"},
                              {"label":"< 90%", "data":missing, "backgroundColor":"rgb(226, 105, 95)"}
                          ]
                      },
                   	"options":{
                        tooltips: {
                            callbacks: {
                                label: function(tooltipItem, data) {
                                    var item = data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];
                                    
                                    return 'Name: ' + item.name;
                                },
                                afterLabel: function(tooltipItem, data) {
                                    var item = data.datasets[tooltipItem.datasetIndex].data[tooltipItem.index];
                                    
                                    return ['', 'Nitro: ' + item.x + '%', 'Performance: ' + item.y + '%','', 'Revenue: $' + item.revenue.toLocaleString(), 'Target: $' + item.target.toLocaleString()];
                                }
                            }
                        },
                        scales: {
                            yAxes: [{
                                scaleLabel: {
                                    display: true,
                                    labelString: 'Sales Performance (% of Target)'  
                                },
                                ticks: {
                                    beginAtZero: true,
                                    min: 0
                                    
                                }
                            }],
                            xAxes: [{
                                scaleLabel: {
                                    display: true,
                                    labelString: 'Nitro Score'
                                },
                                ticks: {
                                    beginAtZero: true,
                                    min: 0,
                                    max: 100
                                }
                            }]
                        },
                      "plugins": {
                          datalabels: {
                              formatter: function(value, context) {
                                  return value.name.replace(' ', '\n');;
                              },
                              textAlign: 'center',
                              color: function(context) {return 'black'; }
                          }
                      }
                    }
        });
    }
})