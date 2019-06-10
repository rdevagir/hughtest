trigger testAriel on Account (after insert) {
    /*
    if(!FillObjectBatch.monitor){
        FillObjectBatch.monitor = true;
        Database.executeBatch(new FillObjectBatch(Integer.valueOf(Trigger.new[0].Name)), 1);
    }
    */
}