#!/system/bin/sh
#
# Copyright (C) 2017 TripNDroid Mobile Engineering
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Function to start sensors for SSC enabled platforms
#
start_sensors()
{
    if [ -c /dev/msm_dsps -o -c /dev/sensors ]; then
        chmod -h 775 /persist/sensors
        chmod -h 664 /persist/sensors/sensors_settings
        chown -h system.root /persist/sensors/sensors_settings
        # ifdef VENDOR_EDIT
        #qiuchangping@BSP 2015-11-24 add for gyro sensitity calibration
        chmod -h 664 /persist/sensors/gyro_sensitity_cal
        chown -h system.root /persist/sensors/gyro_sensitity_cal
        # endif
        mkdir -p /data/misc/sensors
        chmod -h 775 /data/misc/sensors

        start sensors
    fi
}

start_sensors
