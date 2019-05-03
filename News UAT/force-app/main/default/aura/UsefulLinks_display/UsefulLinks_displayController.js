({
      doInit: function(component, event, helper) {
          // Fetch the Useful Link list from the Apex controller
        helper.getUsefulLinkList(component);
      }
    })