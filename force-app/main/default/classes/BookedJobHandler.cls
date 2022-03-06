global class BookedJobHandler extends EDHU.SObjectHandler {

    /**
     * The before insert functionality on the {{ object_name }} object
     */
    // global override void beforeInsert(List<SObject> newList){
    //     System.debug('Overriden');
    // }

    /**
     * The after insert functionality on the {{ object_name }} object
     */
    global override void afterInsert(List<SObject> newList){
        System.debug('Overriden');
        List<Booked_Job__c> newBookedJobList = (List<Booked_Job__c>)newList;

        List<Booked_Job__c> bookedJobsToSendToSurveybot = new List<Booked_Job__c>();
        for (Booked_Job__c j : newBookedJobList) {
            bookedJobsToSendToSurveybot.add(j);
        }

        if (bookedJobsToSendToSurveybot.size() > 0) {
            SurveybotQueueable q = new SurveybotQueueable('newBookedJobToSurveybot', bookedJobsToSendToSurveybot);
            System.enqueueJob(q);
        }
    }

    /**
     * The before update functionality on the {{ object_name }} object
     */
    // global override void beforeUpdate(List<SObject> newList, Map<Id, SObject> oldMap){
    //     System.debug('Overriden');
    // }

    /**
     * The after update functionality on the {{ object_name }} object
     */
    // global override void afterUpdate(List<SObject> newList, Map<Id, SObject> oldMap){
    //     System.debug('Overriden');
    // }

    /**
     * The before delete functionality on the {{ object_name }} object
     */
    // global override void beforeDelete(Map<Id, SObject> oldMap){
    //     System.debug('Overriden');
    // }

    /**
     * The after delete functionality on the {{ object_name }} object
     */
    // global override void afterDelete(Map<Id, SObject> oldMap){
    //     System.debug('Overriden');
    // }

    /**
     * The after undelete functionality on the {{ object_name }} object
     */
    // global override void afterUndelete(List<SObject> newList){
    //     System.debug('Overriden');
    // }

}