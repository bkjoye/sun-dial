using Toybox.WatchUi as Ui;
using Toybox.Graphics as Gfx;
using Toybox.System as Sys;
using Toybox.Lang as Lang;
using Toybox.Application as App;
// using Toybox.ActivityMonitor as ActivityMonitor;
using Toybox.Complications as Complications;
using Toybox.Time.Gregorian as Gregorian;
using Toybox.Time as Time;
using Toybox.Weather as Weather;

// enum {
//   SCREEN_SHAPE_CIRC = 0x000001,
//   SCREEN_SHAPE_SEMICIRC = 0x000002,
//   SCREEN_SHAPE_RECT = 0x000003,
//   SCREEN_SHAPE_SEMI_OCTAGON = 0x000004
// }

public class WatchView extends Ui.WatchFace {

  function initialize() {
   Ui.WatchFace.initialize();
   getWeather();
  }

  function onLayout(dc) {

    // w,h of canvas
    dw = dc.getWidth();
    dh = dc.getHeight();

    center_x = dw/2;
    center_y = dh/2;
  }

  function onUpdate(dc) {

    // clear the screen
    dc.setColor(Gfx.COLOR_BLACK, Gfx.COLOR_BLACK);
    dc.clear();

    // grab time objects
    // var clockTime = Sys.getClockTime();
    var clockTime = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

    // define time, day, month variables
    var hour = clockTime.hour;
    var minute = clockTime.min;
    var sec = clockTime.sec;
    var font = Gfx.FONT_SYSTEM_NUMBER_HOT;
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.drawText(center_x+clockPosition["clock"]["center"][0],
                center_y-clockPosition["clock"]["center"][1],
                font,
                Lang.format("$1$:$2$", [hour.format("%02d"), minute.format("%02d")]),
                Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
                
    font = Gfx.getVectorFont({:face=>["RobotoRegular","Swiss721Regular"], :size=>34});
    dc.drawText(center_x+clockPosition["seconds"]["center"][0], 
                center_y-clockPosition["seconds"]["center"][1], 
                font, 
                sec.format("%02d"), 
                Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
    dc.drawText(center_x+clockPosition["date"]["center"][0], 
                center_y-clockPosition["date"]["center"][1], 
                font, 
                Lang.format("$1$, $2$ $3$", [clockTime.day_of_week, clockTime.month, clockTime.day]), 
                Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);

    if (hour instanceof Lang.Number && minute instanceof Lang.Number) {
      sunData[0]["day_seconds"] = hour*3600+minute*60+sec;
    }
    // draw bounding boxes (debug)
    drawRadialData(dc);
    drawSunInfo(dc);
    drawXYData(dc);
    drawWeather(dc);
    if (drawZones){
      drawTouchZones(dc);
    }

    // weatherTimer.start(self.method(:getWeather), 20*60*1000, true);
  }

  function onShow() {
    // weatherTimer.start(self.method(:getWeather), 20*60*1000, true);
    getWeather();
  }

  function onHide() {
    // weatherTimer.stop();
  }

  function onExitSleep() {
    // weatherTimer.start(self.method(:getWeather), 20*60*1000, true);
    getWeather();
  }

  function onEnterSleep() {
    // weatherTimer.stop();
  }

  function getWeather(){
    // Sys.println("Getting Weather");
    // if (weatherFlag == 0){
      weatherCurrent = Weather.getCurrentConditions();
    // } else if (weatherFlag == 0){
      weatherHourly = Weather.getHourlyForecast();
    // } else {
      weatherDaily = Weather.getDailyForecast();
    // }
  }


  // callback that updates the complication value
  function updateComplication(complication) {

    var thisComplication = Complications.getComplication(complication);

    for (var i=0; i < radialData.size(); i=i+1){

      if (complication == radialData[i]["complicationId"]) {
        if (thisComplication.getType() == Complications.COMPLICATION_TYPE_BATTERY){
          radialData[i]["days"] = Math.round(Sys.getSystemStats().batteryInDays);
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
        // if (thisComplication.shortLabel != null){
        // sunData[i]["label"] = thisComplication.shortLabel;
        // } else {
        //   sunData[i]["label"] = thisComplication.longLabel;
        // }
      }

    }

    for (var i=0; i < xyData.size(); i=i+1){

      if (complication == xyData[i]["complicationId"]) {
        var val = thisComplication.value;
        if (xyData[i].hasKey("conversion") && val != null){
          val *= xyData[i]["conversion"];
          if (val > 1000){
            val = val/1000.0;
            if (xyData[i].hasKey("units") && xyData[i]["units"].find("k ") == null){
              xyData[i]["units"] = "k "+xyData[i]["units"];
              xyData[i]["format"] = "%.1f";
            }
          } else if (xyData[i].hasKey("units") && xyData[i]["units"].find("k ") != null){
            xyData[i]["units"] = xyData[i]["units"].substring(2,null);
            xyData[i]["format"] = "%d";
          }
          xyData[i]["value"] = val;//*xyData[i]["conversion"];
        } else {
          xyData[i]["value"] = val;
        }
        if (thisComplication.shortLabel != null){
        xyData[i]["label"] = thisComplication.shortLabel;
        } //else {
        //   xyData[i]["label"] = thisComplication.longLabel;
        // }
      }

    }

  }

  // debug by drawing bounding boxes and labels
  function drawRadialData(dc) {

    dc.setPenWidth(1);
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
      // dc.drawText(x,y-(dc.getFontHeight(font)),font,label.toString(),Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
      // dc.drawText(x,y,font,value.toString(),Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);

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
        radialData[i]["radius"] = dw/2-(dc.getFontHeight(font))-radialTouchOffset;
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
    if (data["pct"]>66){
      dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    } else if (data["pct"]>33){
      dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
    } else {
      dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
    }
    dc.drawArc(center_x, center_y, radius, direction, degreeStart, degreeEnd);
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
  }

  function drawSunInfo(dc){
    var radius = dh*.75;
    var degreeStart = 120+3;
    var degreeEnd = 60-3;
    var direction = dc.ARC_CLOCKWISE;
    var offset = dh*.9;
    dc.setPenWidth(2);
    dc.drawArc(center_x, center_y+offset, radius, direction, degreeStart, degreeEnd);

    if (sunData[1]["value"] != null 
        && sunData[0]["value"] != null 
        && sunData[0]["day_seconds"] != null 
        && sunData[0]["day_seconds"] >= sunData[0]["value"] 
        && sunData[0]["day_seconds"] < sunData[1]["value"]){
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

    dc.drawRadialText(center_x, center_y+offset, font, rise_str, 
                      Gfx.TEXT_JUSTIFY_RIGHT, degreeEnd, 1.01*radius, direction);
    dc.drawRadialText(center_x, center_y+offset, font, set_str, 
                      Gfx.TEXT_JUSTIFY_LEFT, degreeStart, 1.01*radius, direction);
  }

  function drawXYData(dc){
    for (var i=0; i<xyData.size(); i++){
      var tmplabel = "null";
      if (xyData[i]["label"] != null) {
        tmplabel = xyData[i]["label"];
      }
      var x = center_x+xyData[i]["center"][0];
      var y = center_y-xyData[i]["center"][1];
      var font = Gfx.getVectorFont({:face=>["RobotoRegular","Swiss721Regular"], :size=>34});
      var text = "";
      if (xyData[i]["value"] != null){
        if (xyData[i].hasKey("units") && xyData[i].hasKey("format")){
          var val = xyData[i]["value"];
          text = Lang.format("$1$: $2$$3$", [tmplabel, val.format(xyData[i]["format"]), xyData[i]["units"]]);
        } else if (xyData[i].hasKey("units")) {
          text = Lang.format("$1$: $2$$3$", [tmplabel, xyData[i]["value"], xyData[i]["units"]]);
        } else {
          text = Lang.format("$1$: $2$", [tmplabel, xyData[i]["value"]]);
        }
      } else {
        text = tmplabel+": --";
      }
      dc.drawText(x, y, font, text, Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
    }
  }

  function drawWeather(dc){
    var font = Gfx.getVectorFont({:face=>["RobotoRegular","Swiss721Regular"], :size=>34});
    var font_sm = Gfx.getVectorFont({:face=>["RobotoRegular","Swiss721Regular"], :size=>22});
    if (weatherFlag == 0 && weatherCurrent != null){
      dc.drawText(center_x, center_y+85, font, 
                  Lang.format("$1$$2$($3$)", 
                              [
                                convertTemp(weatherCurrent.temperature).format("%d"), 
                                tempUnits, 
                                convertTemp(weatherCurrent.feelsLikeTemperature).format("%d")
                              ]), 
                  Gfx.TEXT_JUSTIFY_CENTER);
      dc.drawText(center_x-145, center_y+112, font_sm, 
                  Lang.format("H:$1$", [convertTemp(weatherCurrent.highTemperature).format("%d")]), 
                  Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(center_x-145, center_y+130, font_sm, 
                  Lang.format("L:$1$", [convertTemp(weatherCurrent.lowTemperature).format("%d")]), 
                  Gfx.TEXT_JUSTIFY_LEFT);
      // dc.drawText(center_x-145, center_y+148, font_sm, 
      //              Lang.format("$1$", [(weatherCurrent.pressure*pa2mmhg).format("%.1f")]), 
      //              Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(center_x-145, center_y+148, font_sm, 
                  Lang.format("D:$1$", [convertTemp(weatherCurrent.dewPoint).format("%d")]), 
                  Gfx.TEXT_JUSTIFY_LEFT);
      dc.drawText(center_x+145, center_y+112, font_sm, 
                  Lang.format("H:$1$%", [weatherCurrent.relativeHumidity]), 
                  Gfx.TEXT_JUSTIFY_RIGHT);
      dc.drawText(center_x+145, center_y+130, font_sm, 
                  Lang.format("P:$1$%", [weatherCurrent.precipitationChance]), 
                  Gfx.TEXT_JUSTIFY_RIGHT);
      var wTime = Gregorian.info(weatherCurrent.observationTime, Time.FORMAT_SHORT);
      dc.drawText(center_x+145, center_y+148, font_sm, 
                  Lang.format("$1$:$2$", [wTime.hour.format("%02d"), wTime.min.format("%02d")]), 
                  Gfx.TEXT_JUSTIFY_RIGHT);
      if (weatherCurrent.windBearing != null){
        drawArrow(dc, [center_x+65, center_y+132], weatherCurrent.windBearing);
        dc.drawText(center_x+65, center_y+148, font_sm, 
                    Math.round(weatherCurrent.windSpeed*mps2miph).format("%d"), 
                    Gfx.TEXT_JUSTIFY_CENTER);
      }
    } else if (weatherFlag == 1 && weatherHourly != null){
      dc.drawText(center_x, center_y+130, font, "Hourly Forecast", Gfx.TEXT_JUSTIFY_CENTER);
    } else if (weatherFlag == 2 && weatherDaily != null){
      dc.drawText(center_x, center_y+130, font, "Daily Forecast", Gfx.TEXT_JUSTIFY_CENTER);
    } else {
      dc.drawText(center_x, center_y+130, font, "No Weather Data", Gfx.TEXT_JUSTIFY_CENTER);
    }
  }

  function drawArrow(dc, center, rotation){
    var pts = [[0,0], [5, -5], [0,15], [-5, -5]];
    rotation *= -deg2rad;
    var cos = Math.cos(rotation);
    var sin = Math.sin(rotation);
    for (var i = 0; i<pts.size(); i++){
      var pts_rot = [null, null];
      pts_rot[0] = pts[i][0]*cos + pts[i][1]*sin;
      pts_rot[1] = pts[i][1]*cos - pts[i][0]*sin;

      pts[i][0] = pts_rot[0] + center[0];
      pts[i][1] = pts_rot[1] + center[1];
    }
    dc.fillPolygon(pts);
    // dc.drawCircle(center[0], center[1], 15);
  }

  function drawTouchZones(dc){
    dc.setPenWidth(2);
    dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    for (var i=0;i<radialData.size();i++) {
      dc.drawArc(center_x, center_y, radialData[i]["radius"], Gfx.ARC_CLOCKWISE, radialData[i]["angle"]+21, radialData[i]["angle"]-21);
    }
    dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
    for (var i=0;i<xyData.size();i++) {
      dc.drawRectangle(center_x+xyData[i]["center"][0]-xyData[i]["xy"][0], 
                        center_y-xyData[i]["center"][1]-xyData[i]["xy"][1],
                        xyData[i]["xy"][0]*2,
                        xyData[i]["xy"][1]*2);
    }
    dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
    for (var i=0;i<touchZones.size();i++) {
      dc.drawRectangle(center_x+touchZones[i]["center"][0], 
                        center_y-touchZones[i]["center"][1]-touchZones[i]["xy"][1],
                        touchZones[i]["xy"][0]*2,
                        touchZones[i]["xy"][1]*2);
    }
    dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
    dc.drawArc(center_x, center_y+sunData[0]["y_offset"], sunData[0]["radius"]+sunData[0]["touchzone"], Gfx.ARC_COUNTER_CLOCKWISE, 58, 122);
    dc.drawArc(center_x, center_y+sunData[0]["y_offset"], sunData[0]["radius"]-sunData[0]["touchzone"], Gfx.ARC_COUNTER_CLOCKWISE, 58, 122);
  }
}
