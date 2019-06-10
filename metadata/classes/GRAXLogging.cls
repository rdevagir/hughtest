public class GRAXLogging extends GRAXCloud {

   public List<GRAXLogRecord> Logs {get;set;}
   public String LogJSON;

   public void parse() {
	   	if (GRAXSettings.IsConfigured()==true || Test.isRunningTest()){
	   		String fieldname = '';
	   		String fieldvalue = '';
	   		GRAXLogRecord newRecord = null;
	   		JSONParser parser = JSON.createParser(LogJSON);
	   		System.debug('[GRAX.io] Parsing');
	    		while (parser.nextToken() != null) {
	    			System.debug('[GRAX.io] ' + parser.getCurrentToken());
	    			if (parser.getCurrentToken() == JSONToken.FIELD_NAME){
	    				fieldname = parser.getText();
	        			parser.nextToken();
	        			fieldvalue = parser.getText();
	        			System.debug('[GRAX.io] ' + fieldname + ' = ' + fieldvalue);
	        			
	        			if (fieldname=='logging-timestamp'){
	        				if (newRecord!=null)
	        					Logs.add(newRecord);
	        					
	        				newRecord = new GRAXLogRecord();
	        				newRecord.logging_timestamp = DateTime.ValueofGmt(GetSValue(parser).replace('T', ' ')); 
	        			}else if (fieldname=='source')
	        				newRecord.source = GetSValue(parser);
	        			else if (fieldname=='organizationid')
	        				newRecord.organizationid = GetSValue(parser);
	        			else if (fieldname=='error')
	        				newRecord.error = GetSValue(parser);	
	        			else if (fieldname=='information')
	        				newRecord.information = GetSValue(parser);	
	        			else if (fieldname=='request')
	        				newRecord.request = GetSValue(parser);			
	        		}
	        	}
	        	if (newRecord!=null)
	        		Logs.add(newRecord);
	   	}
   }
   
   private String GetSValue(JSONParser parser){
   		String retVal = '';
   		if (parser.nextToken() != null) {
   			if (parser.getCurrentToken() == JSONToken.FIELD_NAME && parser.getText() == 'S'){
   				parser.nextToken();
   				retVal = parser.getText();
   			}else
   				System.debug('[GRAX.io] parser.getText() : ' + parser.getText());
   		}
   		return retVal;
   }

   private static String getexceptionJSON(){
		if (GRAXSettings.IsConfigured()==true || Test.isRunningTest()){
		   	GRAXSettings gxcSettings = new GRAXSettings();
			String url = gxcSettings.ApiURL + '/log/exception/getlist';
			String payload = '{}';
			GRAXCloud.CallOutResponse calloutResp = GRAXCloud.calloutnow(url, payload);
			return calloutResp.response;
		}else
			return '';
	}
	
	public static GRAXLogging GetExceptions(){
		GRAXLogging graxLogs = new GRAXLogging();	
		graxLogs.Logs = new List<GRAXLogRecord>();
		graxLogs.LogJSON = GRAXLogging.getexceptionJSON();
		graxLogs.parse();
		return graxLogs;
	}
}