global class TransfereeJobHandler extends EDHU.SObjectHandler  {
    global override void beforeInsert(List<SObject> newList){
        List<Transferee_Job__c> newTJobList = (List<Transferee_Job__c>)newList;
        List<Transferee_Job__c> TJsForAssignment = new List<Transferee_Job__c>();

        System.debug('newTJobList: '+newTJobList);

        for(Transferee_Job__c tj: newTJobList){
            System.debug(tj);
            if(tj.Assigned_Location__c == 'International'){
                TransfereeJobUtility.assignToTransfereeJobQue(tj);
            } 
            else {
                TJsForAssignment.add(tj);
            }
        }
        if(TJsForAssignment.size() > 0){
            TransfereeJobUtility.assignToActiveUser(TJsForAssignment);
        }
    }
}