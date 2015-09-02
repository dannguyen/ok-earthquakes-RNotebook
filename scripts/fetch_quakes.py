#!/usr/bin/python3
"""
Fetches worldwide earthquake CSV data from USGS, one month at a time,
 and saves the data in separate files in /tmp
"""

from dateutil import rrule
from datetime import datetime, timedelta
from os import makedirs
from os.path import join
import requests
DUMP_DIR = "/tmp/usgs-quakes/"
START_DATE = datetime(1995, 1, 1)
END_DATE = datetime(2015, 9, 1)
BASE_URL = "http://earthquake.usgs.gov/fdsnws/event/1/query.csv"
TIMEFMT = '%Y-%m-%d 00:00:00'
# make the data directory
makedirs(DUMP_DIR, exist_ok = True)

tspan = rrule.rrule(rrule.MONTHLY, dtstart = START_DATE, until = END_DATE)
u_params = {'orderby': 'time-asc', 'starttime': START_DATE}
u_params['starttime'] = START_DATE.strftime(TIMEFMT)
for dt in tspan[1:]: # skip the first date since START_DATE is already assigned
    u_params['endtime'] = dt.strftime(TIMEFMT)
    # call the API
    resp = requests.get(BASE_URL, params = u_params)
    # Save the resulting text file
    # just need the year-month for the filename, i.e. first 7 chars
    fn = u_params['starttime'][0:7]
    fname = join(DUMP_DIR, fn + '.csv')
    with open(fname, 'w') as f:
        f.write(resp.text)
        print(fname)
    # set the starttime to the next date for the next iteration
    u_params['starttime'] = u_params['endtime']
