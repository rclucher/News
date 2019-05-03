            jQuery(function() {
                jQuery( ".actionTaskStatus" ).change(function() {
                    if(jQuery(this).val()=='Completed' || jQuery(this).val()=='Cancelled')
                    {
                        var t = jQuery(this).closest("tr").next().children("td").children(".actionTaskStatus");
                        t.removeAttr( "disabled" );
                    }
                    else
                    {
                        var t = jQuery(this).closest("tr").next().children("td").children(".actionTaskStatus");
                        t.val("Not Started");
                        t.attr( "disabled","disabled" );         
                        t.change();               
                    }
                });


                jQuery( ".actionTaskStatusBlock" ).each(function( index ) {
                    var actionTaskStatusStep = 0;
                    var disableNext = false;
                    jQuery(jQuery( this ).find(".actionTaskStatus")).each(function( jndex ) {
                        actionTaskStatusStep++;
                        if(disableNext || (jQuery(this).val()!='Completed' && jQuery(this).val()!='Cancelled'))
                        {
                            disableNext = true;
                            var t = jQuery(this).closest("tr").next().children("td").children(".actionTaskStatus");
                            //t.val("Not Started");
                            t.attr( "disabled","disabled" );         
                        }
                    });
                  
                });
            });