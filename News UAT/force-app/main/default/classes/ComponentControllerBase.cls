public with sharing virtual class ComponentControllerBase {


  public String key{ get;
    set{
      if(value != null){
         Key = value;
         if(pageController != null)
            pageController.setComponentControllerMap(Key, this);
      }
    }
  }


  public PageControllerBase pageController { get; 
    set {
    	system.debug('@ComponentControllerBase pageController set');
      if (value != null) {
      		system.debug('value:' + value);
			pageController = value;
			pageController.setComponentController(this);
      }
    }
  }
}