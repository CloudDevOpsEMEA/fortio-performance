#!/usr/bin/env python3

import json
import os
from pathlib import Path
import re

# print("scenario|response_size|requested_qps|actual_qps|num_threads|latency_min|latency_avg|latency_p50|latency_p75|latency_p90|latency_p99|latency_p999|latency_max")

for folder in sorted(os.scandir("./results_max_qps"), key=lambda x: (x.is_dir(), x.name)):
  if folder.is_dir():
    scenario = os.path.basename(folder.path)
    
    file_list = Path(folder.path).rglob('*.json')
    for file in sorted(file_list):
        file_in_str = str(file)
        # print('Scenario: ' + scenario)
        response_size = re.search('resp([0-9]+)\.json', file_in_str).group(1)
        # print('Response Size: ' + response_size)

        with open(file_in_str) as json_file:
            data = json.load(json_file)

            labels = data['Labels']
            # print('Labels: ' + labels)

            requested_qps = data['RequestedQPS']
            # print('RequestedQPS: ' + requested_qps)

            actual_qps = str(data['ActualQPS']).replace('.',',')
            # print('ActualQPS: ' + actual_qps)

            num_threads = str(data['NumThreads'])
            # print('NumThreads: ' + num_threads)

            latency_min = format(data['DurationHistogram']['Min'], '.19f').replace('.',',')
            # print('Min: ' + latency_min)

            latency_avg = str(data['DurationHistogram']['Avg']).replace('.',',')
            # print('Avg: ' + latency_avg)
            
            latency_p50 = str(data['DurationHistogram']['Percentiles'][0]['Value']).replace('.',',')
            # print('P50: ' + latency_p50)

            latency_p75 = str(data['DurationHistogram']['Percentiles'][1]['Value']).replace('.',',')
            # print('P75: ' + latency_p75)

            latency_p90 = str(data['DurationHistogram']['Percentiles'][2]['Value']).replace('.',',')
            # print('P90: ' + latency_p90)

            latency_p99 = str(data['DurationHistogram']['Percentiles'][3]['Value']).replace('.',',')
            # print('P99: ' + latency_p99)

            latency_p999 = str(data['DurationHistogram']['Percentiles'][4]['Value']).replace('.',',')
            # print('P99.9: ' + latency_p999)

            latency_max = format(data['DurationHistogram']['Max'], '.19f').replace('.',',')
            # print('Max: ' + latency_max)

            print(f'{scenario}|{response_size}|{requested_qps}|{actual_qps}|{num_threads}|{latency_min}|{latency_avg}|{latency_p50}|{latency_p75}|{latency_p90}|{latency_p99}|{latency_p999}|{latency_max}')


    # for p in data['people']:
    #     print('Name: ' + p['name'])
    #     print('Website: ' + p['website'])
    #     print('From: ' + p['from'])
    #     print('')