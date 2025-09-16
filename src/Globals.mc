using Toybox.System as Sys;
using Toybox.Complications as Complications;
using Toybox.Math as Math;
using Toybox.Weather as Weather;
using Toybox.Timer as Timer;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;
using Toybox.WatchUi as Ui;


// globals for devices width and height
public var dw = 0;
public var dh = 0;
public var center_x = 0;
public var center_y = 0;

public var useIcons = true;


public var drawZones = false;

//unit conversion
public const m2ft = 3.28084;
public const min2hr = 1/60.0;
public const deg2rad = Math.PI/180.0;
public const mps2miph = 0.000621371*3600;
public const pa2mmhg = 0.00750062;

//UI scaling
const SF = 1.0/227.0;
  
public var clockPosition = {
      :clock => {
        :center => [0*SF, 20*SF]
      },
      :date => {
        :center => [-10*SF, -50*SF]
      },
      :seconds => {
        :center => [120*SF, -50*SF]
      }
};

public var touchZones = [
      {
        :label => "WeatherScrollRight",
        :xy => [70*SF, 50*SF],
        :center => [20*SF, 20*SF],
        :shift => 1
      },
      {
        :label => "WeatherScrollLeft",
        :xy => [70*SF, 50*SF],
        :center => [-160*SF, 20*SF],
        :shift => -1
      },
      {
        :label => "Date",
        :xy => [80*SF, 20*SF],
        :center => [-150*SF, -50*SF],//clockPosition[:date][:center],
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY)
      },
      {
        :label => "Notifications",
        :xy => [50*SF, 20*SF],
        :center => [20*SF, 133*SF],
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_NOTIFICATION_COUNT)
      }
];

public var radialTouchOffset = 10*SF;
public var radialData = [
      {
        :label => "Heart Rate",
        :icon => null,
        :icon_size => [null, null],
        :icon_xy => [null, null],
        :rotation => null,
        :angle => 45,
        :radius => null,
        :value => null,
        :format => "%3d",
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE)
      },
      {
        :label => "Stress",
        :icon => null,
        :icon_size => [null, null],
        :icon_xy => [null, null],
        :rotation => null,
        :angle => 0,
        :radius => null,
        :value => null,
        :format => "%3d",
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_STRESS)
      },
      {
        :label => "Steps",
        :icon => null,
        :icon_size => [null, null],
        :icon_xy => [null, null],
        :rotation => null,
        :angle => 180,
        :radius => null,
        :value => null,
        :format => "%.1f",
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_STEPS)
      },
      {
        :label => "BodyBatt",
        :icon => null,
        :icon_size => [null, null],
        :icon_xy => [null, null],
        :rotation => null,
        :angle => 90,
        :radius => null,
        :value => null,
        :format => "%3d",
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY)
      },
      {
        :label => "Floors",
        :icon => null,
        :icon_size => [null, null],
        :icon_xy => [null, null],
        :rotation => null,
        :angle => 135,
        :radius => null,
        :value => null,
        :format => "%2d",
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_FLOORS_CLIMBED)
      },
      {
        :label => "Batt",
        :icon => null,
        :angle => 270,
        :radius => null,
        :value => null,
        :format => "%3d",
        :days => null,
        :pct => null,
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_BATTERY)
      }
    ];

public var sunData = [
      {
        :label => "Sunrise",
        :value => null,
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE),
        :radius => null,
        :y_offset => null,
        :day_seconds => null,
        :touchzone => 25
      },
      {
        :label => "Sunset",
        :value => null,
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET)
      }
];

public var xyData = [
      {
        :label => "Alt",
        :icon => null,
        :icon_size => [null, null],
        :icon_xy => [null, null],
        :xy => [50*SF, 20*SF],
        :center => [-73*SF, 93*SF],
        :value => null,
        :units => "ft",
        :conversion => m2ft,
        :format => "%d",
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_ALTITUDE)
      },
      {
        :label => "TS",
        :icon => null,
        :icon_size => [null, null],
        :icon_xy => [null, null],
        :xy => [50*SF, 20*SF],
        :center => [-70*SF, 133*SF],
        :value => null,
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS)
      },
      {
        :label => "RT",
        :icon => null,
        :icon_size => [null, null],
        :icon_xy => [null, null],
        :xy => [50*SF, 20*SF],
        :center => [83*SF, 93*SF],
        :value => null,
        :units => "h",
        :conversion => min2hr,
        :format => "%d",
        :complicationId => new Complications.Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME)
      }
];

var weatherId = new Complications.Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
public var tempUnits = "°F";
public var pressConversion = 1;
public var weatherTimer = new Timer.Timer();
public var weatherFlag = 0; //0 for current, 1 for hourly, 2 for daily?
public var weatherDaily as Lang.Array<Weather.DailyForecast> or Null;
public var weatherHourly as Lang.Array<Weather.HourlyForecast> or Null;
public var forecast_data = [[],[],[],[]];
public var minTemp = 0;
public var maxTemp = 1;
public var weatherCurrent as Weather.CurrentConditions or Null;// {

public function convertTemp(temp){
  return (1.8*temp + 32);
}

public function checkRadialData(points) {

  // iterate through each bounding box
  for(var i=0;i<radialData.size();i++) {

    var currentBounds = radialData[i];
    if (drawZones) {
    	Sys.println("checking bounding box: " + currentBounds[:label]);
    }

    // check if the current bounding box has been hit,
    // if so, return the corresponding complication
    if (checkBoundsForComplication(points,currentBounds[:angle],currentBounds[:radius])) {
        return currentBounds[:complicationId];
    }

  }

  var x = points[0];
  var y = points[1];

  if (drawZones) {
  	Sys.println("Checking XY: "+x+", "+y);
  }
  for (var i=0; i<xyData.size(); i++){
    if ((xyData[i][:center][0]-x).abs() < xyData[i][:xy][0] 
        && (xyData[i][:center][1]-y).abs() < xyData[i][:xy][1]){
      return xyData[i][:complicationId];
    }
  }

  for (var i=0; i<touchZones.size(); i++){
    if (x > touchZones[i][:center][0] 
          && (x-touchZones[i][:center][0]) < 2*touchZones[i][:xy][0] 
          && (touchZones[i][:center][1]-y).abs() < touchZones[i][:xy][1]){
      if (touchZones[i].hasKey(:complicationId)){
        return touchZones[i][:complicationId];
      } else if (touchZones[i].hasKey(:shift)) {
        weatherFlag += touchZones[i][:shift];
        if (weatherFlag > 2){
          weatherFlag = 0;
        } else if (weatherFlag < 0){
          weatherFlag = 2;
        }
        Ui.requestUpdate();
      }
    }
  }
  

  y = y+sunData[0][:y_offset];
  var click_radius = Math.sqrt(x*x + y*y);

  if ((click_radius-sunData[0][:radius]).abs() < sunData[0][:touchzone]){
    return sunData[0][:complicationId];
  }

  // Return a weather complication ID if battery and sun aren't hit
  if (click_radius < sunData[0][:radius]-sunData[0][:touchzone]){
    return weatherId;
  }

  // we didn't hit a bounding box
  return null;

}

// true if the points are contained within this boundingBox
public function checkBoundsForComplication(points,angle,radius) {
  return circContains(points,angle,radius*radius);
}


public function circContains(points, angle, radius) {
    var x = points[0];
    var y = points[1];

    var point_angle = Math.atan2(y, x)*180/Math.PI;

    point_angle = point_angle < 0 ? point_angle+360 : point_angle;
    var point_radius = x*x + y*y;

    if (drawZones) {
    	Sys.println("Angle: "+point_angle+" Radius: "+point_radius);
    }
    if (drawZones) {
    	Sys.println("Angle: "+angle+" Radius: "+radius);
    }

    if ((point_angle-angle).abs() < 22.5 && point_radius > radius) {
      return true;
    } else {
      return false;
    }
}
