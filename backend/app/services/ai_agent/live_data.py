"""Real-time facts for the AI chat (weather, official exchange rates).

The free Gemini key has no Google Search quota, so questions that need live
data are answered from keyless public sources and the facts are passed to the
model. Only the city / currency asked about is sent to these services — never
any user or financial data.
"""
from __future__ import annotations

import logging
import re
import time
from concurrent.futures import ThreadPoolExecutor
from datetime import date, timedelta
from typing import Optional

import httpx

logger = logging.getLogger("aurora.ai.live")

TIMEOUT = 4.0
_cache: dict = {}
_CACHE_TTL = 600  # seconds


def _cached_get(url: str, params: Optional[dict] = None):
    key = (url, tuple(sorted((params or {}).items())))
    hit = _cache.get(key)
    if hit and time.time() - hit[0] < _CACHE_TTL:
        return hit[1]
    r = httpx.get(url, params=params, timeout=TIMEOUT, headers={"User-Agent": "AuroraFinance/1.0"})
    r.raise_for_status()
    data = r.json()
    _cache[key] = (time.time(), data)
    return data


# ---------------- weather ----------------

WEATHER_RE = re.compile(
    r"(погод|weather|ob[-\s]?havo|havo\s+qanday|температур|градус|дожд|снег|yomg['ʻ’`]?ir|qor\s+yog|прогноз|forecast|жарко|холодно|sovuq|issiq)",
    re.IGNORECASE,
)

# Known cities (ru / uz / en spellings, incl. Russian case endings) -> geocoding name.
KNOWN_CITIES = {
    r"ташкент|toshkent|tashkent": "Tashkent",
    r"самарканд|samarqand|samarkand": "Samarkand",
    r"бухар|buxoro|bukhara": "Bukhara",
    r"наманган|namangan": "Namangan",
    r"андижан|andijon|andijan": "Andijan",
    r"ферган|farg['ʻ’`]?ona|fergana": "Fergana",
    r"нукус|nukus": "Nukus",
    r"карши|qarshi|karshi": "Karshi",
    r"хив|xiva|khiva": "Khiva",
    r"ургенч|urganch|urgench": "Urgench",
    r"термез|termiz|termez": "Termez",
    r"джизак|jizzax|jizzakh": "Jizzakh",
    r"навои|navoiy|navoi": "Navoiy",
    r"гулистан|guliston|gulistan": "Gulistan",
    r"коканд|qo['ʻ’`]?qon|kokand": "Kokand",
    r"чирчик|chirchiq": "Chirchiq",
    r"алмат|almaty": "Almaty",
    r"москв|moscow|moskva": "Moscow",
    r"стамбул|istanbul": "Istanbul",
    r"дубай|dubai": "Dubai",
    r"бишкек|bishkek": "Bishkek",
}

WMO_RU = {
    0: "ясно", 1: "преимущественно ясно", 2: "переменная облачность", 3: "пасмурно",
    45: "туман", 48: "изморозь, туман", 51: "слабая морось", 53: "морось", 55: "сильная морось",
    56: "ледяная морось", 57: "сильная ледяная морось", 61: "небольшой дождь", 63: "дождь", 65: "сильный дождь",
    66: "ледяной дождь", 67: "сильный ледяной дождь", 71: "небольшой снег", 73: "снег", 75: "сильный снег",
    77: "снежная крупа", 80: "кратковременный дождь", 81: "ливень", 82: "сильный ливень",
    85: "снегопад", 86: "сильный снегопад", 95: "гроза", 96: "гроза с градом", 99: "сильная гроза с градом",
}


def _find_city(text: str) -> tuple[str, bool]:
    """Returns (city name for geocoding, explicitly mentioned)."""
    low = text.lower()
    for pattern, name in KNOWN_CITIES.items():
        if re.search(pattern, low):
            return name, True
    m = re.search(r"\b(?:в|во|in|da)\s+([A-Za-zА-Яа-яЁё'ʻ’-]{3,})", text)
    if m:
        word = m.group(1)
        # crude Russian prepositional case: "Лондоне" -> "Лондон"
        if re.match(r"[А-Яа-яЁё]", word) and word.lower().endswith("е") and len(word) > 4:
            word = word[:-1]
        if word.lower() not in {"завтра", "сегодня", "городе", "город", "мире"}:
            return word, True
    return "Tashkent", False


def weather_facts(text: str) -> Optional[str]:
    """Open-Meteo first; wttr.in if it is unreachable or rate-limits the server."""
    city, explicit = _find_city(text)
    try:
        res = _open_meteo(city, explicit)
        if res:
            return res
    except Exception as exc:
        logger.warning("Open-Meteo failed (%s), trying wttr.in", type(exc).__name__)
    return _wttr(city, explicit)


def _wttr(city: str, explicit: bool) -> Optional[str]:
    data = _cached_get(f"https://wttr.in/{city}", {"format": "j1"})
    cur = (data.get("current_condition") or [{}])[0]
    area = (data.get("nearest_area") or [{}])[0]
    name = ((area.get("areaName") or [{}])[0]).get("value", city)
    country = ((area.get("country") or [{}])[0]).get("value", "")
    lines = [
        f"Weather for {name}, {country} (source: wttr.in, retrieved now)"
        + ("" if explicit else " — no city named, Tashkent assumed; say so"),
        f"Now: {cur.get('temp_C')}°C, feels like {cur.get('FeelsLikeC')}°C, "
        f"{((cur.get('weatherDesc') or [{}])[0]).get('value', '')}, wind {cur.get('windspeedKmph')} km/h",
    ]
    for i, day in enumerate(data.get("weather", [])[:3]):
        hourly = day.get("hourly", [])
        rain = max((int(h.get("chanceofrain", 0) or 0) for h in hourly), default=0)
        desc = ((hourly[len(hourly) // 2].get("weatherDesc") or [{}])[0]).get("value", "") if hourly else ""
        label = {0: "today", 1: "tomorrow"}.get(i, day.get("date"))
        lines.append(f"{day.get('date')} ({label}): {day.get('mintempC')}…{day.get('maxtempC')}°C, {desc}, "
                     f"precipitation chance {rain}%")
    return "\n".join(lines)


def _open_meteo(city: str, explicit: bool) -> Optional[str]:
    geo = _cached_get("https://geocoding-api.open-meteo.com/v1/search",
                      {"name": city, "count": 1, "language": "ru"})
    results = geo.get("results") or []
    if not results:
        return None
    place = results[0]
    fc = _cached_get("https://api.open-meteo.com/v1/forecast", {
        "latitude": place["latitude"],
        "longitude": place["longitude"],
        "current": "temperature_2m,apparent_temperature,weather_code,wind_speed_10m",
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max,weather_code,wind_speed_10m_max",
        "timezone": "auto",
        "forecast_days": 4,
    })
    cur = fc.get("current", {})
    d = fc.get("daily", {})
    lines = [
        f"Weather for {place.get('name')}, {place.get('country', '')} (source: Open-Meteo, retrieved now)"
        + ("" if explicit else " — no city named, Tashkent assumed; say so"),
        f"Now ({cur.get('time')}): {cur.get('temperature_2m')}°C, feels like {cur.get('apparent_temperature')}°C, "
        f"{WMO_RU.get(cur.get('weather_code'), cur.get('weather_code'))}, wind {cur.get('wind_speed_10m')} km/h",
    ]
    for i, day in enumerate(d.get("time", [])):
        label = {0: "today", 1: "tomorrow"}.get(i, day)
        lines.append(
            f"{day} ({label}): {d['temperature_2m_min'][i]}…{d['temperature_2m_max'][i]}°C, "
            f"{WMO_RU.get(d['weather_code'][i], d['weather_code'][i])}, "
            f"precipitation chance {d['precipitation_probability_max'][i]}%, wind up to {d['wind_speed_10m_max'][i]} km/h"
        )
    return "\n".join(lines)


# ---------------- exchange rates ----------------

RATES_RE = re.compile(
    r"(курс|kurs|exchange\s+rate|rate\s+of|валют|valyuta|доллар|dollar|евро|evro|euro|рубл|rubl|тенге|yuan|юан|lira|лир|\busd\b|\beur\b|\brub\b|\bkzt\b|\bcny\b)",
    re.IGNORECASE,
)
MAIN_CCY = ("USD", "EUR", "RUB", "KZT", "CNY", "TRY", "GBP", "AED", "KRW", "JPY")


def rates_facts(text: str) -> Optional[str]:
    data = _cached_get("https://cbu.uz/ru/arkhiv-kursov-valyut/json/")
    if not isinstance(data, list) or not data:
        return None
    by = {row.get("Ccy"): row for row in data}
    lines = [f"Official Central Bank of Uzbekistan rates (cbu.uz), date {data[0].get('Date')}, UZS per nominal unit:"]
    for c in MAIN_CCY:
        row = by.get(c)
        if row:
            lines.append(f"{row['Nominal']} {c} = {row['Rate']} UZS (change {row.get('Diff')})")
    lines.append("Commercial bank buy/sell rates differ from the official rate.")
    return "\n".join(lines)


# ---------------- entry point ----------------

def today_line() -> str:
    t = date.today()
    return f"Today is {t.isoformat()} ({t.strftime('%A')}); tomorrow is {(t + timedelta(days=1)).isoformat()}. Time zone: Asia/Tashkent."


def gather_live_facts(question: str) -> list[str]:
    """Fetches the live facts the question needs (in parallel, ~4 s max)."""
    jobs = []
    if WEATHER_RE.search(question):
        jobs.append(("weather", weather_facts))
    if RATES_RE.search(question):
        jobs.append(("rates", rates_facts))
    if not jobs:
        return []
    out: list[str] = []
    with ThreadPoolExecutor(max_workers=len(jobs)) as pool:
        futures = [(name, pool.submit(fn, question)) for name, fn in jobs]
        for name, fut in futures:
            try:
                res = fut.result(timeout=TIMEOUT * 2 + 1)
                if res:
                    out.append(res)
            except Exception as exc:  # network errors must never break the chat
                logger.warning("live %s lookup failed: %s", name, type(exc).__name__)
    return out
