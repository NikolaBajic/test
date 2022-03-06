trigger TranfereeJobsTrigger on Transferee_Job__c (
    before insert, before update,  before delete,
    after insert,  after update,   after delete,   after undelete) {
If (System.Label.Trigger_flag == 'ON') {
    //Initialize the handler
    EDHU.SObjectHandler handler = EDHU.SObjectDispatcher.init('TransfereeJob');

    //Execute the appropriate dispatch method.
    if(handler != null){ handler.execute(Trigger.operationType, Trigger.new, Trigger.oldMap); }
}
}