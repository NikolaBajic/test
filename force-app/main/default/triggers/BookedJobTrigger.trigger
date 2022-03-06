trigger BookedJobTrigger on Booked_Job__c (
    before insert, before update,  before delete,
    after insert,  after update,   after delete,   after undelete) {

    //Initialize the handler
    EDHU.SObjectHandler handler = EDHU.SObjectDispatcher.init('BookedJob');

    //Execute the appropriate dispatch method.
    if(handler != null){ handler.execute(Trigger.operationType, Trigger.new, Trigger.oldMap); }

}