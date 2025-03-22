using Toybox.Application as App;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.WatchUi as Ui;
using Toybox.Complications as Complications;

public class WatchApp extends App.AppBase {

  private function test() {
        // for (var i; i < complications.length; i++) {
        //     System.println(complications[i].complicationId);
        // }
        var sensorIterator = Complications.getComplications();
        var sensor = sensorIterator != null ? sensorIterator.next() : null;
        while (sensor != null) {
            System.print(sensor.longLabel);
			System.println(sensor.complicationId);
            sensor = sensorIterator.next();
        }
    }

    function initialize() {
      App.AppBase.initialize();
    }

    function onSettingsChanged() {
      Ui.requestUpdate();
    }

    // register all the complication callbacks
    function onStart(state) {
      // test();
      Complications.registerComplicationChangeCallback(self.method(:onComplicationChanged));
      // Complications.subscribeToUpdates(new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE));
      // Complications.subscribeToUpdates(new Complications.Id(Complications.COMPLICATION_TYPE_STEPS));
      // Complications.subscribeToUpdates(new Complications.Id(Complications.COMPLICATION_TYPE_STRESS));
      // Complications.subscribeToUpdates(new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY));
      // radialData[0][:complicationId] = new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE);
      // radialData[1][:complicationId] =new Complications.Id(Complications.COMPLICATION_TYPE_STEPS);
      // radialData[2][:complicationId] =new Complications.Id(Complications.COMPLICATION_TYPE_STRESS);
      // radialData[3][:complicationId] =new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY);
      for (var i=0; i < radialData.size(); i=i+1){
        Complications.subscribeToUpdates(radialData[i][:complicationId]);
      }
      for (var i=0; i < xyData.size(); i=i+1){
        Complications.subscribeToUpdates(xyData[i][:complicationId]);
      }
      for (var i=0; i < sunData.size(); i=i+1){
        Complications.subscribeToUpdates(sunData[i][:complicationId]);
      }
    }

    // fetches the complication when it changes, and passes to the Watchface
    function onComplicationChanged(complicationId as Complications.Id) as Void {
        if (WatchView != null) {
            try {
                WatchView.updateComplication(complicationId);
            } catch (e) {
                if (drawZones) {
                	Sys.println("error passing complicaiton to watchface");
                }
            }
        }
    }

    //! onStop() is called when your application is exiting
    function onStop(state) {
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new WatchView(), new WatchDelegate()  ];
    }

}
