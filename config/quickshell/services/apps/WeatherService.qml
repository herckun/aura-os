pragma Singleton
import QtQml
import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"
import "../system"

Singleton {
  id: svc

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC STATE
  // ═══════════════════════════════════════════════════════════════

  property string weather: "N/A"
  property string temp: "--"
  property int weatherCode: -1
  property bool loaded: false
  property string location: "Unknown"
  property string countryCode: ""
  property bool hasData: false
  property bool fetching: false
  property double lastFetchedAt: 0

  property string feelsLike: "--"
  property string humidity: "--"
  property string windSpeed: "--"
  property string windDir: ""
  property string pressure: "--"
  property string uvIndex: "--"
  property string sunrise: "--"
  property string sunset: "--"
  property string precip: "0"

  property var hourly: []
  property var daily: []

  property string locationOverride: ""

  property real latitude: 0
  property real longitude: 0

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  function wmoDescription(code: int): string {
    if (code === 0) return "Clear sky"
    if (code <= 3) return "Partly cloudy"
    if (code <= 49) return "Fog"
    if (code <= 59) return "Drizzle"
    if (code <= 69) return "Rain"
    if (code <= 79) return "Snow"
    if (code <= 82) return "Rain showers"
    if (code <= 86) return "Snow showers"
    if (code <= 99) return "Thunderstorm"
    return "Unknown"
  }

  function wmoIcon(code: int): string {
    if (code === 0) return "☀"
    if (code <= 3) return "☁"
    if (code <= 49) return "☾"
    if (code <= 59) return "☂"
    if (code <= 69) return "☂"
    if (code <= 79) return "❄"
    if (code <= 82) return "☂"
    if (code <= 86) return "❄"
    if (code <= 99) return "⚡"
    return "☀"
  }

  function windDirection(deg: int): string {
    var dirs = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
    return dirs[Math.round(deg / 22.5) % 16]
  }

  function fetch(): void {
    svc.fetching = true
    var override = svc.locationOverride.trim()
    if (override.length > 0) svc._geocode(override)
    else svc._geoLocate()
  }

  function setLocationOverride(loc: string): void {
    var v = (loc || "").trim()
    if (v === svc.locationOverride) return
    svc.locationOverride = v
    refetchDebounce.restart()
  }

  // ═══════════════════════════════════════════════════════════════
  //  INTERNAL STATE
  // ═══════════════════════════════════════════════════════════════

  readonly property int _baseFetchInterval: 1800000
  readonly property int _baseInitialFetchInterval: 5000

  readonly property int _fetchInterval: PerformanceService.scaleInterval(_baseFetchInterval)
  readonly property int _initialFetchInterval: PerformanceService.scaleInterval(_baseInitialFetchInterval)

  // ═══════════════════════════════════════════════════════════════
  //  PRIVATE HELPERS
  // ═══════════════════════════════════════════════════════════════

  function _geoLocate(): void {
    RequestService.get("https://ipinfo.io/json", function(r) {
      try {
        var loc = r.data.loc.split(",")
        svc.latitude = parseFloat(loc[0])
        svc.longitude = parseFloat(loc[1])
        svc.location = r.data.city || ""
        svc.countryCode = r.data.country || ""
      } catch (e) {
        svc.latitude = 48.8566
        svc.longitude = 2.3522
        svc.location = "Paris"
      }
      svc._fetchWeather()
    })
  }

  function _geocode(query: string): void {
    var parts = query.split(",")
    var city = parts[0].trim()
    var country = parts.slice(1).join(",").trim().toLowerCase()
    var url = "https://geocoding-api.open-meteo.com/v1/search?name=" +
      encodeURIComponent(city) + "&count=10&language=en&format=json"

    RequestService.get(url, function(r) {
      var hit = null
      try {
        var results = (r.data && r.data.results) || []
        for (var i = 0; i < results.length && country; i++) {
          var res = results[i]
          if ((res.country || "").toLowerCase() === country ||
              (res.country_code || "").toLowerCase() === country) {
            hit = res
            break
          }
        }
        if (!hit && results.length > 0) hit = results[0]
      } catch (e) {}

      if (!hit) {
        svc._geoLocate()
        return
      }
      svc.latitude = hit.latitude
      svc.longitude = hit.longitude
      svc.location = hit.name || city
      svc.countryCode = hit.country_code || ""
      svc._fetchWeather()
    })
  }

  function _dayLabel(iso: string, index: int): string {
    if (index === 0) return "TODAY"
    var d = new Date(iso + "T12:00")
    return ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"][d.getDay()]
  }

  function _fetchWeather(): void {
    var url = "https://api.open-meteo.com/v1/forecast?" +
      "latitude=" + svc.latitude + "&longitude=" + svc.longitude +
      "&current=temperature_2m,relative_humidity_2m,apparent_temperature," +
      "precipitation,weather_code,wind_speed_10m,wind_direction_10m,surface_pressure" +
      "&hourly=temperature_2m,weather_code,precipitation_probability" +
      "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max" +
      "&timezone=auto&forecast_days=7"

    RequestService.get(url, function(r) {
        try {
          var j = r.data
          var c = j.current
          var d = j.daily
          var h = j.hourly

          svc.temp = Math.round(c.temperature_2m) + "°"
          svc.weatherCode = c.weather_code
          svc.weather = svc.wmoDescription(c.weather_code)
          svc.feelsLike = Math.round(c.apparent_temperature) + "°"
          svc.humidity = c.relative_humidity_2m + "%"
          svc.windSpeed = Math.round(c.wind_speed_10m) + " km/h"
          svc.windDir = svc.windDirection(c.wind_direction_10m)
          svc.pressure = Math.round(c.surface_pressure) + " hPa"
          svc.precip = c.precipitation + " mm"

          if (d && d.uv_index_max) svc.uvIndex = d.uv_index_max[0].toFixed(1)
          if (d && d.sunrise) svc.sunrise = d.sunrise[0].substring(11, 16)
          if (d && d.sunset) svc.sunset = d.sunset[0].substring(11, 16)

          if (h && h.time) {
            var now = new Date()
            var hours = []
            for (var i = 0; i < h.time.length && hours.length < 12; i++) {
              if (new Date(h.time[i]) < now) continue
              hours.push({
                hour: h.time[i].substring(11, 13),
                temp: Math.round(h.temperature_2m[i]) + "°",
                code: h.weather_code[i],
                precip: (h.precipitation_probability ? h.precipitation_probability[i] : 0)
              })
            }
            svc.hourly = hours
          }

          if (d && d.time) {
            var days = []
            for (var k = 0; k < d.time.length; k++) {
              days.push({
                day: svc._dayLabel(d.time[k], k),
                code: d.weather_code[k],
                max: Math.round(d.temperature_2m_max[k]) + "°",
                min: Math.round(d.temperature_2m_min[k]) + "°"
              })
            }
            svc.daily = days
          }

          svc.hasData = true
          svc.loaded = true
          svc.lastFetchedAt = Date.now()
        } catch (e) {
          svc.loaded = true
        }
        svc.fetching = false
    })
  }

  // ═══════════════════════════════════════════════════════════════
  //  TIMERS
  // ═══════════════════════════════════════════════════════════════

  Timer {
    interval: svc._fetchInterval
    running: true
    repeat: true
    onTriggered: svc.fetch()
  }

  Timer {
    interval: svc._initialFetchInterval
    running: true
    repeat: false
    onTriggered: if (!svc.hasData) svc.fetch()
  }

  Timer {
    id: refetchDebounce
    interval: 1200
    repeat: false
    onTriggered: svc.fetch()
  }

}
