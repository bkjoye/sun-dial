using Toybox.System as Sys;
using Toybox.Complications as Complications;
using Toybox.Math as Math;
using Toybox.Weather as Weather;
using Toybox.Timer as Timer;
using Toybox.Graphics as Gfx;
using Toybox.Lang as Lang;


// globals for devices width and height
public var dw = 0;
public var dh = 0;
public var center_x = 0;
public var center_y = 0;

public var drawZones = false;

//unit conversion
public const m2ft = 3.28084;
public const min2hr = 1/60.0;
public const deg2rad = Math.PI/180.0;
public const mps2miph = 0.000621371*3600;
public const pa2mmhg = 0.00750062;

public const ts_colors = {
  "PEAKING" => Gfx.COLOR_PURPLE,
  "PRODUCTIVE" => Gfx.COLOR_GREEN,
  "MAINTAINING" => Gfx.COLOR_YELLOW,
  "RECOVERY" => Gfx.COLOR_BLUE,
  "STRAINED" => Gfx.COLOR_PINK,
  "UNPRODUCTIVE" => Gfx.COLOR_ORANGE,
  "DETRAINING" => Gfx.COLOR_DK_GRAY,
  "OVERREACHING" => Gfx.COLOR_RED
};

public var clockPosition = {
  "clock" => {
    "center" => [0, 20]
  },
  "date" => {
    "center" => [-150, -50]
  },
  "seconds" => {
    "center" => [120, -50]
  }
};

public var touchZones = [
  {
    "label" => "WeatherScrollRight",
    "xy" => [70, 50],
    "center" => [20, 20],
    "shift" => 1
  },
  {
    "label" => "WeatherScrollLeft",
    "xy" => [70, 50],
    "center" => [-160, 20],
    "shift" => -1
  },
  {
    "label" => "Date",
    "xy" => [80, 20],
    "center" => clockPosition["date"]["center"],
    "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_WEEKDAY_MONTHDAY)
  }
];

public var radialTouchOffset = 10;
public var radialData = [
      {
        "label" => "Heart Rate",
        "angle" => 135,
        "radius" => null,
        "value" => null,
        "format" => "%3d",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE)
      },
      {
        "label" => "Stress",
        "angle" => 180,
        "radius" => null,
        "value" => null,
        "format" => "%3d",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_STRESS)
      },
      {
        "label" => "Steps",
        "angle" => 0,
        "radius" => null,
        "value" => null,
        "format" => "%.1f",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_STEPS)
      },
      {
        "label" => "BodyBatt",
        "angle" => 90,
        "radius" => null,
        "value" => null,
        "format" => "%3d",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY)
      },
      {
        "label" => "Floors",
        "angle" => 45,
        "radius" => null,
        "value" => null,
        "format" => "%2d",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_FLOORS_CLIMBED)
      },
      {
        "label" => "Batt",
        "angle" => 270,
        "radius" => null,
        "value" => null,
        "format" => "%3d",
        "days" => null,
        "pct" => null,
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_BATTERY)
      }
    ];

public var sunData = [
      {
        "label" => "Sunrise",
        "value" => null,
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_SUNRISE),
        "radius" => null,
        "y_offset" => null,
        "day_seconds" => null,
        "touchzone" => 25
      },
      {
        "label" => "Sunset",
        "value" => null,
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET)
      }
];

public var xyData = [
      {
        "label" => "Alt",
        "xy" => [50,20],
        "center" => [-75,90],
        "value" => null,
        "units" => "ft",
        "conversion" => m2ft,
        "format" => "%d",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_ALTITUDE)
      },
      {
        "label" => "TS",
        "xy" => [50,20],
        "center" => [-75,125],
        "value" => null,
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_TRAINING_STATUS)
      },
      {
        "label" => "RT",
        "xy" => [50,20],
        "center" => [85,90],
        "value" => null,
        "units" => "h",
        "conversion" => min2hr,
        "format" => "%d",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_RECOVERY_TIME)
      }
];

var weatherId = new Complications.Id(Complications.COMPLICATION_TYPE_CURRENT_WEATHER);
public var weatherFont;
public var tempUnits = "°F";
public var pressConversion = 1;
public var weatherTimer = new Timer.Timer();
public var weatherFlag = 0; //0 for current, 1 for hourly, 2 for daily?
public var weatherDaily as Lang.Array<Weather.DailyForecast> or Null;
public var weatherHourly as Lang.Array<Weather.HourlyForecast> or Null;
public var weatherCurrent as Weather.CurrentConditions or Null;// {

public function convertTemp(temp){
  return (1.8*temp + 32);
}

public function checkRadialData(points) {

  // iterate through each bounding box
  for(var i=0;i<radialData.size();i++) {

    var currentBounds = radialData[i];
    Sys.println("checking bounding box: " + currentBounds["label"]);

    // check if the current bounding box has been hit,
    // if so, return the corresponding complication
    if (checkBoundsForComplication(points,currentBounds["angle"],currentBounds["radius"])) {
        return currentBounds["complicationId"];
    }

  }

  var x = points[0];
  var y = points[1];

  Sys.println("Checking XY: "+x+", "+y);
  for (var i=0; i<xyData.size(); i++){
    if ((xyData[i]["center"][0]-x).abs() < xyData[i]["xy"][0] 
        && (xyData[i]["center"][1]-y).abs() < xyData[i]["xy"][1]){
      return xyData[i]["complicationId"];
    }
  }

  for (var i=0; i<touchZones.size(); i++){
    if (x > touchZones[i]["center"][0] 
          && (x-touchZones[i]["center"][0]) < 2*touchZones[i]["xy"][0] 
          && (touchZones[i]["center"][1]-y).abs() < touchZones[i]["xy"][1]){
      if (touchZones[i].hasKey("complicationId")){
        return touchZones[i]["complicationId"];
      } else {
        weatherFlag += touchZones[i]["shift"];
        if (weatherFlag > 2){
          weatherFlag = 0;
        } else if (weatherFlag < 0){
          weatherFlag = 2;
        }
      }
    }
  }
  

  y = y+sunData[0]["y_offset"];
  var click_radius = Math.sqrt(x*x + y*y);

  if ((click_radius-sunData[0]["radius"]).abs() < sunData[0]["touchzone"]){
    return sunData[0]["complicationId"];
  }

  // Return a weather complication ID if battery and sun aren't hit
  if (click_radius < sunData[0]["radius"]-sunData[0]["touchzone"]){
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

    Sys.println("Angle: "+point_angle+" Radius: "+point_radius);
    Sys.println("Angle: "+angle+" Radius: "+radius);

    if ((point_angle-angle).abs() < 22.5 && point_radius > radius) {
      return true;
    } else {
      return false;
    }
}
