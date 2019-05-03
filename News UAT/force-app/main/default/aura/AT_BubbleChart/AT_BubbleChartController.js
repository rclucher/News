({
	afterScriptsLoaded: function(component, event, helper) {
		new Chart(component.find("chart").getElement().getContext('2d'),
                  {
                    "type":"bubble",
                   	"data":
                      {
                          "datasets":[
                              {"label":"Achieved", "data": component.get('v.achieved'),"backgroundColor":"rgb(96, 145, 74)"},
                              {"label":"On target", "data": component.get('v.ontarget'),"backgroundColor":"rgb(246, 195, 51)"},
                              {"label":"Missing", "data": component.get('v.missing'),"backgroundColor":"rgb(226, 105, 95)"}
                          ]
                      },
                   	"options":{
                      "plugins": {
                          datalabels: {
                              formatter: function(value, context) {
                                  return value.name.replace(' ', '\n');;
                              },
                              font: {
                                  color: 'black'
                          	  }
                          }
                      }
                    }
                  }
                 );
	}
})