public class FillObjectBatch implements Database.Batchable<SObject>, Database.Stateful {
    public static Boolean monitor = false;
    
    public Database.querylocator start(Database.BatchableContext BC) {
        String query = 'Select Id from Large_Object__c Where Some_Number__c > 0';

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        //
    }

/*
    public Database.querylocator start(Database.BatchableContext BC) {
        String query = 'Select Id from Large_Object__c Limit 500000';

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        delete scope;
        Database.emptyRecycleBin(scope);
    }
    
*/
    
/*    
    List<GRAX_Schedule_Process__c> gspList = new List<GRAX_Schedule_Process__c>();
    Integer counter;
    
    public FillObjectBatch(Integer counter){
        gspList = [SELECT Id, Execution_Unique_Key__c FROM GRAX_Schedule_Process__c WHERE Execution_Unique_Key__c <> null];
        this.counter = counter * 8000000;
    }

    public Iterable<Integer> start(Database.BatchableContext BC) {
        List<Integer> intList = new List<Integer>();
        
        //20,000 x 2,000 records per batch = 40M total
        for (Integer i=1; i<=4000; i++) {
            intList.add(i); 
        }
        
        return intList;
    }
 
    public void execute(Database.BatchableContext BC, List<Integer> intList) {
        List<Large_Object__c> largeObjList = new List<Large_Object__c>();
        
        
        for (Integer i: intList) {
            for (Integer j=0; j<2000; j++) {
                Decimal a = getRand();
                GRAX_Schedule_Process__c gsp = gspList[Math.mod(Integer.valueOf(a), gspList.size())];
        
                largeObjList.add(
                    new Large_Object__c (
                            Name = gsp.Execution_Unique_Key__c + '_' + counter,
                            Execution_Unique_Key__c = gsp.Execution_Unique_Key__c,
                            GRAX_Schedule_Process__c = gsp.Id,
                            Some_Number__c = a,
                            Some_Datetime__c = System.now()
                        )
                );
                
                counter++;                  
            }
        }
        insert (largeObjList);
        
        System.debug(JSON.serializePretty(largeObjList)); 
    }
*/ 
    public static Decimal getRand() {
        Integer lower = 0;
        Integer upper = 100;
        
        //get a random int between 0-100
        Decimal retDec = Math.round( Math.random() * (upper - lower) ) + lower;
        
        //give it a random decimal
        retDec += Math.random();
        
        //round it to 2 decimal places
        retDec = retDec.setScale(2, System.RoundingMode.HALF_EVEN);
        
        return retDec;

    }
 
    public void finish(Database.BatchableContext BC) {
    }

    //Database.executeBatch(new FillObjectBatch(), 1);
}