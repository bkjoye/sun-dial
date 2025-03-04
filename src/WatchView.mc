using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Timer as Timer;
using Toybox.Complications as Complications;

enum {
  SCREEN_SHAPE_CIRC = 0x000001,
  SCREEN_SHAPE_SEMICIRC = 0x000002,
  SCREEN_SHAPE_RECT = 0x000003,
  SCREEN_SHAPE_SEMI_OCTAGON = 0x000004
}

public class WatchView extends Ui.WatchFace {

  function initialize() {
   Ui.WatchFace.initialize();
  }

  function onLayout(dc) {

    // w,h of canvas
    dw = dc.getWidth();
    dh = dc.getHeight();

    center_x = dw/2;
    center_y = dh/2;

    // define the global bounding boxes
    // defineradialData();

  }

  function onUpdate(dc) {

    // clear the screen
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
    dc.clear();

    // grab time objects
    var clockTime = Sys.getClockTime();

    // define time, day, month variables
    var hour = clockTime.hour;
    var minute = clockTime.min < 10 ? "0" + clockTime.min : clockTime.min;
    var font = Gfx.FONT_SYSTEM_NUMBER_HOT;
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.drawText(dw/2,dh/2-(dc.getFontHeight(font)/2),font,hour.toString()+":"+minute.toString(),Gfx.TEXT_JUSTIFY_CENTER);

    if (hour instanceof Lang.Number && minute instanceof Lang.Number) {
      sunData[0]["day_seconds"] = hour*3600+minute*60+clockTime.sec;
    }
    // draw bounding boxes (debug)
    drawRadialData(dc);
    drawSunInfo(dc);

  }

  function onShow() {
  }

  function onHide() {
  }

  function onExitSleep() {
  }

  function onEnterSleep() {
  }

  function defineradialData() {

    // "bounds" format is an array as follows [ x, y, r ]
    //  x,y = center of circle
    //  r = radius

    // var radius = dw/5;

    radialData = [
      {
        "label" => "Heart Rate",
        "angle" => 135,
        "value" => "",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_HEART_RATE)
      },
      {
        "label" => "Stress",
        "angle" => 180,
        "value" => null as Null or Lang.Number,
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_STRESS)
      },
      {
        "label" => "Steps",
        "angle" => 45,
        "value" => "",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_STEPS)
      },
      {
        "label" => "BodyBatt",
        "angle" => 315,
        "value" => "",
        "complicationId" => new Complications.Id(Complications.COMPLICATION_TYPE_BODY_BATTERY)
      }
    ];

  }

  // callback that updates the complication value
  function updateComplication(complication) {

    var thisComplication = Complications.getComplication(complication);

    for (var i=0; i < radialData.size(); i=i+1){

      if (complication == radialData[i]["complicationId"]) {
        if (thisComplication.getType() == Complications.COMPLICATION_TYPE_BATTERY){
          radialData[i]["days"] = Sys.getSystemStats().batteryInDays;
          radialData[i]["pct"] = thisComplication.value;
          radialData[i]["value"] = Lang.format("$1$% - $2$D", [thisComplication.value.format("%2d"), radialData[i]["days"].format("%2d")]);
        } else {
          radialData[i]["value"] = thisComplication.value;
        }
        if (thisComplication.shortLabel != null){
        radialData[i]["label"] = thisComplication.shortLabel;
        } else {
          radialData[i]["label"] = thisComplication.longLabel;
        }
      }

    }

    for (var i=0; i < sunData.size(); i=i+1){

      if (complication == sunData[i]["complicationId"]) {
        sunData[i]["value"] = thisComplication.value;
        if (thisComplication.shortLabel != null){
        sunData[i]["label"] = thisComplication.shortLabel;
        } else {
          sunData[i]["label"] = thisComplication.longLabel;
        }
      }

    }

    for (var i=0; i < xyData.size(); i=i+1){

      if (complication == xyData[i]["complicationId"]) {
        xyData[i]["value"] = thisComplication.value;
        if (thisComplication.shortLabel != null){
        xyData[i]["label"] = thisComplication.shortLabel;
        } else {
          xyData[i]["label"] = thisComplication.longLabel;
        }
      }

    }

  }

  // debug by drawing bounding boxes and labels
  function drawRadialData(dc) {

    dc.setPenWidth(1);

    if (radialData[1]["radius"] != null && false) {
      dc.drawCircle(center_x, center_y, radialData[1]["radius"]);
    }
    for (var i=0; i < radialData.size(); i=i+1){

      // var x = radialData[i]["bounds"][0];
      // var y = radialData[i]["bounds"][1];
      // var r = radialData[i]["bounds"][2];

      // // draw a circle
      // dc.setColor(Gfx.COLOR_PURPLE, Gfx.COLOR_PURPLE);
      // dc.drawCircle(x,y,r);

      if (!radialData[i].hasKey("angle")){
        continue;
      }

      // draw the complication label and value
      var value = radialData[i]["value"] ? radialData[i]["value"] : "-";
      var label = radialData[i]["label"];
      var font = Gfx.getVectorFont({:face=>["RobotoRegular","Swiss721Regular"], :size=>34});

      dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
      // dc.drawText(x,y-(dc.getFontHeight(font)),font,label.toString(),Gfx.TEXT_JUSTIFY_CENTER);
      // dc.drawText(x,y,font,value.toString(),Gfx.TEXT_JUSTIFY_CENTER);

      var tmplabel = "null";
      if (label != null) {
        tmplabel = label.toString();
      }
      var tmpval = "--";
      if (value != null && value instanceof Lang.Float) {
          tmpval = Lang.format("$1$k", [value.format(radialData[i]["format"])]);
      } else if (value != null && value instanceof Lang.Number) {
        if (radialData[i]["format"].equals("%.1f")){
          tmpval = Lang.format("$1$k", [(value/1000.0).format(radialData[i]["format"])]);
        } else {        
          tmpval = value.format(radialData[i]["format"]);
        }
      } else if (value != null && value instanceof Lang.String && !value.equals("-")) {
        tmpval = value;
        if (radialData[i].hasKey("pct") && radialData[i]["pct"] != null){
          drawBattery(dc, radialData[i]);
          tmplabel = "";
        }
      }
      var text = "";
      if (!tmplabel.equals("")){
        text = Lang.format("$1$: $2$", [tmplabel, tmpval]);//tmplabel+": "+tmpval;
      } else {
        text = Lang.format("$1$", [tmpval]);
      }
      // } else {
      //   if (Complications.getComplication(radialData[i]["complicationId"]).getType() == Complications.COMPLICATION_TYPE_INVALID){
      //     System.println("Complication Invalid");
      //   } else {
      //     System.println("Idk...");
      //   }
      // }
      var justification = Gfx.TEXT_JUSTIFY_CENTER;
      var angle = radialData[i]["angle"];
      var radius = angle <= 180 ? dw/2-(dc.getFontHeight(font)) : dw/2-10;
      if (radialData[i]["radius"] == null){
        radialData[i]["radius"] = dw/2-(dc.getFontHeight(font))-.04*dw;
      }
      var direction = angle <= 180 ? Gfx.RADIAL_TEXT_DIRECTION_CLOCKWISE : Gfx.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE;

      dc.drawRadialText(center_x, center_y, font, text, justification, angle, radius, direction);
    }

  }

  function drawBattery(dc, data){
    var radius = dh/2;
    var degreeStart = 270-22.5;
    var degreeEnd = degreeStart+(45*data["pct"]/100.0);
    var direction = dc.ARC_COUNTER_CLOCKWISE;
    dc.setPenWidth(10);
    if (data["pct"]>75){
      dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    } else if (data["pct"]>30){
      dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
    } else {
      dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
    }
    dc.drawArc(center_x, center_y, radius, direction, degreeStart, degreeEnd);
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
  }

  function drawSunInfo(dc){
    var radius = dh*.75;
    var degreeStart = 120;
    var degreeEnd = 60;
    var direction = dc.ARC_CLOCKWISE;
    var offset = dh*.9;
    dc.setPenWidth(2);
    dc.drawArc(center_x, center_y+offset, radius, direction, degreeStart, degreeEnd);

    if (sunData[1]["value"] != null && sunData[0]["value"] != null && sunData[0]["day_seconds"] >= sunData[0]["value"] && sunData[0]["day_seconds"] < sunData[1]["value"]){
      var day_remain = (sunData[1]["value"]-sunData[0]["day_seconds"]);
      var daylight_seconds = sunData[1]["value"]-sunData[0]["value"];
      var angle_range = (degreeStart-degreeEnd).abs();
      var angle_arc = day_remain*angle_range/daylight_seconds;
      // angle_arc = angle_arc > 0 ? angle_arc : 1;
      angle_arc = angle_arc >= angle_range ? angle_range : angle_arc+1;
      dc.setPenWidth(10);
      dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
      dc.drawArc(center_x, center_y+offset, radius-5, direction, degreeStart, degreeStart-angle_arc);
    }
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);

    // var value = radialData[i]["value"] ? radialData[i]["value"] : "-";
    var rise_str = "-";
    var set_str = "-";
    var font = Gfx.getVectorFont({:face=>["RobotoRegular","Swiss721Regular"], :size=>34});
    direction = Gfx.RADIAL_TEXT_DIRECTION_CLOCKWISE;
    if (sunData[0]["value"] != null){
      var rise_hours = sunData[0]["value"]/3600;
      // var rise_whole_hours = Math.floor(rise_hours);
      var rise_mins = sunData[0]["value"] % 3600/60;
      rise_str = ""+rise_hours.format("%02d")+":"+rise_mins.format("%02d");
    }
    if (sunData[1]["value"] != null){
      var set_hours = sunData[1]["value"]/3600;
      // var set_whole_hours = Math.floor(set_hours);
      var set_mins = sunData[1]["value"] % 3600/60;
      set_str = ""+set_hours.format("%02d")+":"+set_mins.format("%02d");
    }

    if (sunData[0]["radius"] == null){
      sunData[0]["radius"] = radius;
      sunData[0]["y_offset"] = offset;
    }

    dc.drawRadialText(center_x, center_y+offset, font, rise_str, Gfx.TEXT_JUSTIFY_RIGHT, degreeEnd, radius, direction);
    dc.drawRadialText(center_x, center_y+offset, font, set_str, Gfx.TEXT_JUSTIFY_LEFT, degreeStart, radius, direction);
  }


}
