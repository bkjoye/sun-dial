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

  var iconMap = weatherIcons();

  function initialize() {
   Ui.WatchFace.initialize();
   getWeather();
  }

  function onLayout(dc) {

    dc.setAntiAlias(true);

    // w,h of canvas
    dw = dc.getWidth();
    dh = dc.getHeight();

    center_x = dw/2;
    center_y = dh/2;

    xSF = center_x*SF;
    ySF = center_y*SF;

    weatherFont = Ui.loadResource(Rez.Fonts.WeatherIcon);
    vectorFont = Gfx.getVectorFont({:face=>["RobotoRegular","Swiss721Regular"], :size=>.15*center_x});
    vectorFontSmall = Gfx.getVectorFont({:face=>["RobotoRegular","Swiss721Regular"], :size=>.1*center_x});
    clockFont = Gfx.FONT_SYSTEM_NUMBER_HOT;

    for (var i=0; i < xyData.size(); i=i+1){
      xyData[i][:center][0] *= center_x;
      xyData[i][:center][1] *= center_y;
      xyData[i][:xy][0] *= center_x;
      xyData[i][:xy][1] *= center_y;
    }
    var clockKeys = clockPosition.keys();
    for (var i=0; i < clockKeys.size(); i=i+1){
      clockPosition[clockKeys[i]][:center][0] *= center_x;
      clockPosition[clockKeys[i]][:center][1] *= center_y;
    }
    for (var i=0; i < touchZones.size(); i=i+1){
      touchZones[i][:center][0] *= center_x;
      touchZones[i][:center][1] *= center_y;
      touchZones[i][:xy][0] *= center_x;
      touchZones[i][:xy][1] *= center_y;
    }
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
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.drawText(center_x+clockPosition[:clock][:center][0],
                center_y-clockPosition[:clock][:center][1],
                clockFont,
                Lang.format("$1$:$2$", [hour.format("%02d"), minute.format("%02d")]),
                Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
                
    dc.drawText(center_x+clockPosition[:seconds][:center][0], 
                center_y-clockPosition[:seconds][:center][1], 
                vectorFont, 
                sec.format("%02d"), 
                Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
    dc.drawText(center_x+clockPosition[:date][:center][0], 
                center_y-clockPosition[:date][:center][1], 
                vectorFont, 
                Lang.format("$1$, $2$ $3$", [clockTime.day_of_week, clockTime.month, clockTime.day]), 
                Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);

    if (hour instanceof Lang.Number && minute instanceof Lang.Number) {
      sunData[0][:day_seconds] = hour*3600+minute*60+sec;
    }
    // draw bounding boxes (debug)
    drawRadialData(dc);
    drawSunInfo(dc);
    drawXYData(dc);
    drawWeather(dc);
    if (drawZones){
      drawTouchZones(dc);
    }
  }

  function onShow() {
    getWeather();
  }

  function onHide() {
  }

  function onExitSleep() {
    getWeather();
  }

  function onEnterSleep() {
  }

  function getWeather(){
    // iconMap = weatherIcons();
    // Sys.println("Getting Weather");
    // if (weatherFlag == 0){
      weatherCurrent = Weather.getCurrentConditions();
    // } else if (weatherFlag == 0){
      weatherHourly = Weather.getHourlyForecast();
      normalizeHourlyData();
    // } else {
      weatherDaily = Weather.getDailyForecast();
    // }
  }

  function normalizeHourlyData(){
    forecast_data = [[],[],[],[]];
    for (var i=0; i<weatherHourly.size(); i++) {
      forecast_data[0].add(weatherHourly[i].temperature);
      forecast_data[1].add(weatherHourly[i].precipitationChance);
      forecast_data[2].add(weatherHourly[i].relativeHumidity);
      forecast_data[3].add(Gregorian.info(weatherHourly[i].forecastTime, Time.FORMAT_SHORT).hour);
    }

    // var sortTemps = forecast_data[0];
    // sortTemps.sort(null);
    // maxTemp = sortTemps[sortTemps.size()-1];
    // minTemp = sortTemps[0];
    var minMaxTemps = minMax(forecast_data[0]);
    minTemp = minMaxTemps[0];
    maxTemp = minMaxTemps[1];
    var tempRange = maxTemp == minTemp ? 1 : maxTemp-minTemp;

    for (var i=0; i<forecast_data[0].size(); i++) {
      forecast_data[0][i] = (forecast_data[0][i]-minTemp)/tempRange;
      forecast_data[1][i] = forecast_data[1][i]/100.0;
      forecast_data[2][i] = forecast_data[2][i]/100.0;
    }
  }

  function minMax(data){
    var min = data[0];
    var max = data[0];

    for (var i=0; i<data.size(); i++){
      if (data[i]>max){
        max = data[i];
      }
      if (data[i]<min){
        min = data[i];
      }
    }

    return [min, max];
  }


  // callback that updates the complication value
  function updateComplication(complication) {

    var thisComplication = Complications.getComplication(complication);

    for (var i=0; i < radialData.size(); i=i+1){

      if (complication == radialData[i][:complicationId]) {
        if (thisComplication.getType() == Complications.COMPLICATION_TYPE_BATTERY){
          radialData[i][:days] = Math.round(Sys.getSystemStats().batteryInDays);
          radialData[i][:pct] = thisComplication.value;
          radialData[i][:value] = Lang.format("$1$% - $2$D", [thisComplication.value.format("%2d"), radialData[i][:days].format("%2d")]);
        } else {
          radialData[i][:value] = thisComplication.value;
        }
        if (thisComplication.shortLabel != null){
          radialData[i][:label] = thisComplication.shortLabel;
        } else {
          radialData[i][:label] = thisComplication.longLabel;
        }
      }

    }

    for (var i=0; i < sunData.size(); i=i+1){

      if (complication == sunData[i][:complicationId]) {
        sunData[i][:value] = thisComplication.value;
        // if (thisComplication.shortLabel != null){
        // sunData[i][:label] = thisComplication.shortLabel;
        // } else {
        //   sunData[i][:label] = thisComplication.longLabel;
        // }
      }

    }

    for (var i=0; i < xyData.size(); i=i+1){

      if (complication == xyData[i][:complicationId]) {
        var val = thisComplication.value;
        if (xyData[i].hasKey(:conversion) && val != null){
          val *= xyData[i][:conversion];
          if (val > 1000){
            val = val/1000.0;
            if (xyData[i].hasKey(:units) && xyData[i][:units].find("k ") == null){
              xyData[i][:units] = "k "+xyData[i][:units];
              xyData[i][:format] = "%.1f";
            }
          } else if (xyData[i].hasKey(:units) && xyData[i][:units].find("k ") != null){
            xyData[i][:units] = xyData[i][:units].substring(2,null);
            xyData[i][:format] = "%d";
          }
          xyData[i][:value] = val;//*xyData[i][:conversion];
        } else {
          xyData[i][:value] = val;
        }
        if (thisComplication.shortLabel != null){
        xyData[i][:label] = thisComplication.shortLabel;
        } //else {
        //   xyData[i][:label] = thisComplication.longLabel;
        // }
      }

    }

  }

  // debug by drawing bounding boxes and labels
  function drawRadialData(dc) {

    dc.setPenWidth(1);
    for (var i=0; i < radialData.size(); i=i+1){

      if (!radialData[i].hasKey(:angle)){
        continue;
      }

      // draw the complication label and value
      var value = radialData[i][:value] ? radialData[i][:value] : "-";
      var label = radialData[i][:label];

      dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);

      var tmplabel = "null";
      if (label != null) {
        tmplabel = label.toString();
      }
      var tmpval = "--";
      if (value != null && value instanceof Lang.Float) {
          tmpval = Lang.format("$1$k", [value.format(radialData[i][:format])]);
      } else if (value != null && value instanceof Lang.Number) {
        if (radialData[i][:format].equals("%.1f")){
          tmpval = Lang.format("$1$k", [(value/1000.0).format(radialData[i][:format])]);
        } else {        
          tmpval = value.format(radialData[i][:format]);
        }
      } else if (value != null && value instanceof Lang.String && !value.equals("-")) {
        tmpval = value;
        if (radialData[i].hasKey(:pct) && radialData[i][:pct] != null){
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

      var justification = Gfx.TEXT_JUSTIFY_CENTER;
      var angle = radialData[i][:angle];
      var radius = angle <= 180 ? dw/2-(dc.getFontHeight(vectorFont)) : dw/2-10;
      if (radialData[i][:radius] == null){
        radialData[i][:radius] = dw/2-(dc.getFontHeight(vectorFont))-radialTouchOffset;
      }
      var direction = angle <= 180 ? Gfx.RADIAL_TEXT_DIRECTION_CLOCKWISE : Gfx.RADIAL_TEXT_DIRECTION_COUNTER_CLOCKWISE;

      dc.drawRadialText(center_x, center_y, vectorFont, text, justification, angle, radius, direction);
    }

  }

  function drawBattery(dc, data){
    var radius = dh/2;
    var degreeStart = 270-22.5;
    var degreeEnd = degreeStart+(45*data[:pct]/100.0);
    var direction = dc.ARC_COUNTER_CLOCKWISE;
    dc.setPenWidth(10);
    if (data[:pct]>66){
      dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    } else if (data[:pct]>33){
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

    if (sunData[1][:value] != null 
        && sunData[0][:value] != null 
        && sunData[0][:day_seconds] != null) {
      if (sunData[0][:day_seconds] >= sunData[0][:value] 
          && sunData[0][:day_seconds] < sunData[1][:value]) {
        var day_remain = (sunData[1][:value]-sunData[0][:day_seconds]);
        var daylight_seconds = sunData[1][:value]-sunData[0][:value];
        var angle_range = (degreeStart-degreeEnd).abs();
        var angle_arc = day_remain*angle_range/daylight_seconds;
        
        angle_arc = angle_arc >= angle_range ? angle_range : angle_arc+1;
        dc.setPenWidth(10);
        dc.setColor(Gfx.COLOR_YELLOW, Gfx.COLOR_TRANSPARENT);
        dc.drawArc(center_x, center_y+offset, radius-5, direction, degreeStart, degreeStart-angle_arc);
        isDayTime = true;
      } else {
        isDayTime = false;
      }
    }
    iconMap = weatherIcons();
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);

    var rise_str = "-";
    var set_str = "-";
    direction = Gfx.RADIAL_TEXT_DIRECTION_CLOCKWISE;
    if (sunData[0][:value] != null){
      var rise_hours = sunData[0][:value]/3600;
      var rise_mins = sunData[0][:value] % 3600/60;
      rise_str = ""+rise_hours.format("%02d")+":"+rise_mins.format("%02d");
    }
    if (sunData[1][:value] != null){
      var set_hours = sunData[1][:value]/3600;
      var set_mins = sunData[1][:value] % 3600/60;
      set_str = ""+set_hours.format("%02d")+":"+set_mins.format("%02d");
    }

    if (sunData[0][:radius] == null){
      sunData[0][:radius] = radius;
      sunData[0][:y_offset] = offset;
    }

    dc.drawRadialText(center_x, center_y+offset, vectorFont, rise_str, 
                      Gfx.TEXT_JUSTIFY_RIGHT, degreeEnd, 1.01*radius, direction);
    dc.drawRadialText(center_x, center_y+offset, vectorFont, set_str, 
                      Gfx.TEXT_JUSTIFY_LEFT, degreeStart, 1.01*radius, direction);
  }

  function drawXYData(dc){
    for (var i=0; i<xyData.size(); i++){
      var tmplabel = "null";
      if (xyData[i][:label] != null) {
        tmplabel = xyData[i][:label];
      }
      var x = center_x+xyData[i][:center][0];
      var y = center_y-xyData[i][:center][1];
      var text = "";
      if (xyData[i][:value] != null){
        if (xyData[i].hasKey(:units) && xyData[i].hasKey(:format)){
          var val = xyData[i][:value];
          text = Lang.format("$1$: $2$$3$", [tmplabel, val.format(xyData[i][:format]), xyData[i][:units]]);
        } else if (xyData[i].hasKey(:units)) {
          text = Lang.format("$1$: $2$$3$", [tmplabel, xyData[i][:value], xyData[i][:units]]);
        } else if (xyData[i][:label].equals("TS")){
          var key = xyData[i][:value].toUpper();
          if (isDayTime && ts_colors.hasKey(key)){
            dc.drawText(x, y, vectorFont, tmplabel+":", Gfx.TEXT_JUSTIFY_RIGHT|Gfx.TEXT_JUSTIFY_VCENTER);
            dc.setColor(ts_colors[key], Gfx.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x+4, y-10, 20, 20, 4); //TODO
            dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
            continue;
          } else {
            text = Lang.format("$1$: $2$", [tmplabel, xyData[i][:value].substring(null,2)]);
          }
          
        } else {
          text = Lang.format("$1$: $2$", [tmplabel, xyData[i][:value]]);
        }
      } else {
        text = tmplabel+": --";
      }
      dc.drawText(x, y, vectorFont, text, Gfx.TEXT_JUSTIFY_CENTER|Gfx.TEXT_JUSTIFY_VCENTER);
    }
  }

  function drawWeather(dc){
    if (weatherFlag == 0 && weatherCurrent != null){
      // Draw current temp and feels like
      dc.drawText(center_x, center_y+85*ySF, vectorFont, 
                  Lang.format("$1$$2$($3$)", 
                              [
                                convertTemp(weatherCurrent.temperature).format("%d"), 
                                tempUnits, 
                                convertTemp(weatherCurrent.feelsLikeTemperature).format("%d")
                              ]), 
                  Gfx.TEXT_JUSTIFY_CENTER);
      // Draw current conditions icon
      dc.drawText(center_x, center_y+120*ySF, weatherFont, iconMap[weatherCurrent.condition], Gfx.TEXT_JUSTIFY_CENTER);
      
      // Left and right info columns
      var wPos = [145*xSF, 112*ySF, 130*ySF, 148*ySF];
      var wTime = Gregorian.info(weatherCurrent.observationTime, Time.FORMAT_SHORT);
      var wLText = [
                    Lang.format("H:$1$", [convertTemp(weatherCurrent.highTemperature).format("%d")]), 
                    Lang.format("L:$1$", [convertTemp(weatherCurrent.lowTemperature).format("%d")]), 
                    Lang.format("D:$1$", [convertTemp(weatherCurrent.dewPoint).format("%d")])
      ];
      var wRText = [
                    Lang.format("H:$1$%", [weatherCurrent.relativeHumidity]), 
                    Lang.format("P:$1$%", [weatherCurrent.precipitationChance]), 
                    Lang.format("$1$:$2$", [wTime.hour.format("%02d"), wTime.min.format("%02d")])
      ];
      for (var i=0; i<wRText.size(); i++){
        dc.drawText(center_x-wPos[0], center_y+wPos[i+1], vectorFontSmall, 
                    wLText[i], 
                    Gfx.TEXT_JUSTIFY_LEFT);
        dc.drawText(center_x+wPos[0], center_y+wPos[i+1], vectorFontSmall, 
                    wRText[i], 
                    Gfx.TEXT_JUSTIFY_RIGHT);
      }

      //Wind info
      if (weatherCurrent.windBearing != null){
        drawArrow(dc, [center_x+65*xSF, center_y+132*ySF], weatherCurrent.windBearing);
        dc.drawText(center_x+65*xSF, center_y+148*ySF, vectorFontSmall, 
                    Math.round(weatherCurrent.windSpeed*mps2miph).format("%d"), 
                    Gfx.TEXT_JUSTIFY_CENTER);
      }

    } else if (weatherFlag == 1 && weatherHourly != null){
      var x0 = 105*xSF;
      var y0 = center_y + 165*ySF;
      var width = 2*(center_x-105*xSF);
      var height = 50*ySF;
      drawForecastPlot(dc, x0, y0, width, height, forecast_data); 
    } else if (weatherFlag == 2 && weatherDaily != null){
      var numDays = weatherDaily.size()-1;
      var spacing = 60;//*xSF;
      var offset = (numDays-1)*spacing/2.0;
      var voffset1 = 95*ySF;
      var voffset2 = 150*ySF;
      var voffset3 = 167*ySF;
      for (var i=1; i<numDays+1; i++){
        var position = (i-1)*spacing;
        var dow = Gregorian.info(weatherDaily[i].forecastTime, Time.FORMAT_MEDIUM).day_of_week;
        dc.drawText(center_x-offset+position, center_y+voffset1, weatherFont, iconMap[weatherDaily[i].condition], Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(center_x-offset+position, center_y+voffset2, vectorFontSmall, 
                    Lang.format("$1$/$2$", 
                                [convertTemp(weatherDaily[i].highTemperature).format("%d"), 
                                 convertTemp(weatherDaily[i].lowTemperature).format("%d")]), 
                    Gfx.TEXT_JUSTIFY_CENTER);
        dc.drawText(center_x-offset+position, center_y+voffset3, vectorFontSmall, dow.substring(null, 2), Gfx.TEXT_JUSTIFY_CENTER);
      }
    } else {
      dc.drawText(center_x, center_y+130, vectorFont, "No Weather Data", Gfx.TEXT_JUSTIFY_CENTER);
    }
  }

  function drawArrow(dc, center, rotation){
    var pts = [[0,0], [5, -5], [0,15], [-5, -5]]; //TODO
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

  function drawForecastPlot(dc, x0, y0, l, h, data){
    var xs = data[3];
    // data = data.slice(null,2);
    var num_points = xs.size();//>8 ? 8 : xs.size();
    var spacing = l*1.0/(num_points-1);
    var xi = 0;
    var yi = 0;
    var yin = 0;
    var x_write_int = 3;
    
    dc.setPenWidth(2);

    yi = y0-h*data[0][0];
    for (var i=1; i<num_points; i++) {
      xi = x0+(i-1)*spacing;
      if (i % x_write_int == 0) {
        dc.drawText(xi+spacing, y0+2, vectorFontSmall, xs[i].toString(), Gfx.TEXT_JUSTIFY_CENTER);
      }
      dc.drawLine(xi, y0, xi, y0-h*.1);
      yin = y0-h*data[0][i];
      dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
      dc.drawLine(xi, yi, xi+spacing, yin);
      yi = yin;
      dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
      dc.drawLine(xi, y0-h*data[1][i-1], xi+spacing, y0-h*data[1][i]);
      dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
      dc.drawLine(xi, y0-h*data[2][i-1], xi+spacing, y0-h*data[2][i]);
    }
    dc.drawText(x0, y0+2, vectorFontSmall, xs[0].toString(), Gfx.TEXT_JUSTIFY_CENTER);
    dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
    dc.drawText(x0-4, y0-5, vectorFontSmall, convertTemp(minTemp).format("%d"), Gfx.TEXT_JUSTIFY_RIGHT|Gfx.TEXT_JUSTIFY_VCENTER);
    dc.drawText(x0-4, y0-h+8, vectorFontSmall, convertTemp(maxTemp).format("%d"), Gfx.TEXT_JUSTIFY_RIGHT|Gfx.TEXT_JUSTIFY_VCENTER);
    dc.setColor(Gfx.COLOR_LT_GRAY, Gfx.COLOR_TRANSPARENT);
    dc.drawText(x0+l+4, y0-5, vectorFontSmall, "0%", Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
    dc.drawText(x0+l+4, y0-h+8, vectorFontSmall, "100%", Gfx.TEXT_JUSTIFY_LEFT|Gfx.TEXT_JUSTIFY_VCENTER);
    dc.drawLine(x0, y0, x0+l, y0);
    dc.drawLine(x0, y0, x0, y0-h);
    dc.drawLine(x0+l, y0, x0+l, y0-h);
  }

  function drawTouchZones(dc){
    dc.setPenWidth(2);
    dc.setColor(Gfx.COLOR_GREEN, Gfx.COLOR_TRANSPARENT);
    for (var i=0;i<radialData.size();i++) {
      dc.drawArc(center_x, center_y, radialData[i][:radius], Gfx.ARC_CLOCKWISE, radialData[i][:angle]+21, radialData[i][:angle]-21);
    }
    dc.setColor(Gfx.COLOR_DK_BLUE, Gfx.COLOR_TRANSPARENT);
    for (var i=0;i<xyData.size();i++) {
      dc.drawRectangle(center_x+xyData[i][:center][0]-xyData[i][:xy][0], 
                        center_y-xyData[i][:center][1]-xyData[i][:xy][1],
                        xyData[i][:xy][0]*2,
                        xyData[i][:xy][1]*2);
    }
    dc.setColor(Gfx.COLOR_BLUE, Gfx.COLOR_TRANSPARENT);
    for (var i=0;i<touchZones.size();i++) {
      dc.drawRectangle(center_x+touchZones[i][:center][0], 
                        center_y-touchZones[i][:center][1]-touchZones[i][:xy][1],
                        touchZones[i][:xy][0]*2,
                        touchZones[i][:xy][1]*2);
    }
    dc.setColor(Gfx.COLOR_RED, Gfx.COLOR_TRANSPARENT);
    dc.drawArc(center_x, center_y+sunData[0][:y_offset], sunData[0][:radius]+sunData[0][:touchzone], Gfx.ARC_COUNTER_CLOCKWISE, 58, 122);
    dc.drawArc(center_x, center_y+sunData[0][:y_offset], sunData[0][:radius]-sunData[0][:touchzone], Gfx.ARC_COUNTER_CLOCKWISE, 58, 122);
  }

  function weatherIcons(){
    var mapping = [
    "\uF00D",// CONDITION_CLEAR
    "\uF00C",// CONDITION_PARTLY_CLOUDY
    "\uF002",// CONDITION_MOSTLY_CLOUDY
    "\uF01A",// CONDITION_RAIN
    "\uF01B",// CONDITION_SNOW
    "\uF011",// CONDITION_WINDY
    "\uF01E",// CONDITION_THUNDERSTORMS
    "\uF017",// CONDITION_WINTRY_MIX
    "\uF014",// CONDITION_FOG
    "\uF0B6",// CONDITION_HAZY
    "\uF015",// CONDITION_HAIL
    "\uF009",// CONDITION_SCATTERED_SHOWERS
    "\uF00E",// CONDITION_SCATTERED_THUNDERSTORMS
    "\uF03D",// CONDITION_UNKNOWN_PRECIPITATION
    "\uF01C",// CONDITION_LIGHT_RAIN
    "\uF019",// CONDITION_HEAVY_RAIN
    "\uF01B",// CONDITION_LIGHT_SNOW
    "\uF064",// CONDITION_HEAVY_SNOW
    "\uF004",// CONDITION_LIGHT_RAIN_SNOW
    "\uF007",// CONDITION_HEAVY_RAIN_SNOW
    "\uF013",// CONDITION_CLOUDY
    "\uF017",// CONDITION_RAIN_SNOW
    "\uF002",// CONDITION_PARTLY_CLEAR
    "\uF00C",// CONDITION_MOSTLY_CLEAR
    "\uF009",// CONDITION_LIGHT_SHOWERS
    "\uF006",// CONDITION_SHOWERS
    "\uF008",// CONDITION_HEAVY_SHOWERS
    "\uF00B",// CONDITION_CHANCE_OF_SHOWERS
    "\uF01E",// CONDITION_CHANCE_OF_THUNDERSTORMS
    "\uF021",// CONDITION_MIST
    "\uF063",// CONDITION_DUST
    "\uF006",// CONDITION_DRIZZLE
    "\uF073",// CONDITION_TORNADO
    "\uF062",// CONDITION_SMOKE
    "\uF076",// CONDITION_ICE
    "\uF082",// CONDITION_SAND
    "\uF01E",// CONDITION_SQUALL
    "\uF082",// CONDITION_SANDSTORM
    "\uF0C8",// CONDITION_VOLCANIC_ASH
    "\uF0B6",// CONDITION_HAZE
    "\uF00C",// CONDITION_FAIR
    "\uF073",// CONDITION_HURRICANE
    "\uF01E",// CONDITION_TROPICAL_STORM
    "\uF01B",// CONDITION_CHANCE_OF_SNOW
    "\uF004",// CONDITION_CHANCE_OF_RAIN_SNOW
    "\uF019",// CONDITION_CLOUDY_CHANCE_OF_RAIN
    "\uF01B",// CONDITION_CLOUDY_CHANCE_OF_SNOW
    "\uF004",// CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW
    "\uF064",// CONDITION_FLURRIES
    "\uF017",// CONDITION_FREEZING_RAIN
    "\uF0B5",// CONDITION_SLEET
    "\uF004",// CONDITION_ICE_SNOW
    "\uF030",// CONDITION_THIN_CLOUDS
    "\uF07B",// CONDITION_UNKNOWN
    ];

    if (!isDayTime){
      mapping[0] = "\uF02E";// CONDITION_CLEAR (Night)
      mapping[1] = "\uF081";// CONDITION_PARTLY_CLOUDY (Night)
      mapping[2] = "\uF086";// CONDITION_MOSTLY_CLOUDY (Night)
      mapping[11] = "\uF029";// CONDITION_SCATTERED_SHOWERS (Night)
      mapping[12] = "\uF02C";// CONDITION_SCATTERED_THUNDERSTORMS (Night)
      mapping[18] = "\uF024";// CONDITION_LIGHT_RAIN_SNOW (Night)
      mapping[19] = "\uF027";// CONDITION_HEAVY_RAIN_SNOW (Night)
      mapping[22] = "\uF086";// CONDITION_PARTLY_CLEAR (Night)
      mapping[23] = "\uF081";// CONDITION_MOSTLY_CLEAR (Night)
      mapping[24] = "\uF029";// CONDITION_LIGHT_SHOWERS (Night)
      mapping[25] = "\uF026";// CONDITION_SHOWERS (Night)
      mapping[26] = "\uF028";// CONDITION_HEAVY_SHOWERS (Night)
      mapping[27] = "\uF02B";// CONDITION_CHANCE_OF_SHOWERS (Night)
      mapping[31] = "\uF026";// CONDITION_DRIZZLE (Night)
      mapping[40] = "\uF081";// CONDITION_FAIR (Night)
      mapping[44] = "\uF024";// CONDITION_CHANCE_OF_RAIN_SNOW (Night)
      mapping[47] = "\uF024";// CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW (Night)
      mapping[51] = "\uF024";// CONDITION_ICE_SNOW (Night)

    }
    return mapping;
  }
}
