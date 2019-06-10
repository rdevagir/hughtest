/* --------------------------------------------------------------------------
 * This file is subject to the terms and conditions defined in
 * file https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE,
 * which is part of this source code package.
 * --------------------------------------------------------------------------
 *          Copyright (c) 2017-2018 Harding Point
 *                  All rights reserved
 * --------------------------------------------------------------------------
 * Support:	Support@Grax.io
 * Website:	https://grax.io
 * Github:	https://github.com/HardingPoint/GRAXForSFDC
 * License:	https://github.com/HardingPoint/GRAXForSFDC/blob/master/LICENSE
 * --------------------------------------------------------------------------*/

public with sharing class GRAXFlow {
    public GRAXFlow() {

	    	if (GRAXSettings.IsConfigured()==false)
	    		ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please complete <a href="' + Page.GRAXSetup.getUrl() + '">GRAX Configuration</a>.'));
    
    }
    
    public string getPropURLToDisplay() { 
    	    String flowUrl = 'https://grax.io';
    		GRAXSettings__c graxsettings = GRAXSettings__c.getOrgDefaults();
    		if (graxsettings.GRAX_Flow_URL__c!=null)
        		flowUrl = graxsettings.GRAX_Flow_URL__c; 
        return flowUrl;
    }
    
    public pagereference connect(){
        pagereference p=new pagereference(getPropURLToDisplay());
        return p;
    }
    
}