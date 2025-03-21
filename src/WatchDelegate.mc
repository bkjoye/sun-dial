using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Timer as Timer;
using Toybox.Complications as Complications;

class WatchDelegate extends Ui.WatchFaceDelegate {

	function initialize() {
		WatchFaceDelegate.initialize();
	}

  public function onPress(clickEvent) {

    // grab the [x,y] position of the clickEvent
    var co_ords = clickEvent.getCoordinates();
    if (drawZones) {
    	Sys.println( "clickEvent x:" + co_ords[0] + ", y:" + co_ords[1]  );
    }

    co_ords[0] = co_ords[0]-center_x;
    co_ords[1] = -co_ords[1]+center_y;

    if (drawZones) {
    	Sys.println( "transformed x:" + co_ords[0] + ", y:" + co_ords[1]  );
    }

    // returns the complicationId within the radialData
    var complicationId = checkRadialData(co_ords);

    //
    if (complicationId != null) {
        if (drawZones) {
        	Sys.println( "We found a complication! let's launch it ..." );
        }
        try {
          Complications.exitTo(complicationId);
        } catch(e){
          if (drawZones) {
          	Sys.println("Failed to Open Complication");
          }
        }
        return(true);
    } else {
        if (drawZones) {
        	Sys.println( "No complication found" );
        }
    }

    return(false);

  }


}
