using Toybox.System as Sys;
using Toybox.Complications as Complications;
using Toybox.Math as Math;

// globals for devices width and height
public var dw = 0;
public var dh = 0;
public var center_x = 0;
public var center_y = 0;

public var bboxes = [];
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
        "angle" => 45,
        "radius" => null,
        "value" => null,
        "format" => "%.1f",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_STEPS)
      },
      {
        "label" => "BodyBatt",
        "angle" => 0,
        "radius" => null,
        "value" => null,
        "format" => "%3d",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY)
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
        "day_seconds" => null
      },
      {
        "label" => "Sunset",
        "value" => null,
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_SUNSET)
      }
];

public var xyData = [
  {
        "label" => "Date",
        "xy" => [100,80],
        "value" => null,
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_DATE)
      }
];

public function checkradialData(points) {

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

  Sys.println("Checking clock: "+x+", "+y);

  if (x.abs() < 80 && y.abs() < 40){
    return new Complications.Id(Complications.COMPLICATION_TYPE_DATE);
  }

  y = y+sunData[0]["y_offset"];
  var click_radius = Math.sqrt(x*x + y*y);

  if ((click_radius-sunData[0]["radius"]).abs() < 40){
    return sunData[0]["complicationId"];
  }

  // we didn't hit a bounding box
  return null;

}

// true if the points are contained within this boundingBox
public function checkBoundsForComplication(points,angle,radius) {
  return circContains(points,angle,radius);
}


public function circContains(points, angle, radius) {
    var x = points[0];
    var y = points[1];

    var point_angle = Math.atan2(y, x)*180/Math.PI;

    point_angle = point_angle < 0 ? point_angle+360 : point_angle;
    var point_radius = Math.sqrt(x*x + y*y);

    Sys.println("Angle: "+point_angle+" Radius: "+point_radius);
    Sys.println("Angle: "+angle+" Radius: "+radius);

    if ((point_angle-angle).abs() < 22.5 && point_radius > radius) {
      return true;
    } else {
      return false;
    }
}
