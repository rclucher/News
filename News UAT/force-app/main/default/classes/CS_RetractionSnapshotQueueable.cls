/**
 * Created by petar on 2019-03-22.
 */

public without sharing class CS_RetractionSnapshotQueueable implements Queueable{

    private List<History_Tracking__c> historyTrackings;

    public CS_RetractionSnapshotQueueable(List<History_Tracking__c> htList) {

        this.historyTrackings = htList;

    }

    public void execute(QueueableContext context) {

        CS_HistoryTrackingService.updateSnapshotAsyn(historyTrackings);
    }

}