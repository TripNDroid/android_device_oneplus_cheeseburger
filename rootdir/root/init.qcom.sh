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

#check build variant for printk logging
buildvariant=`getprop ro.build.type`
case "$buildvariant" in
    "userdebug" | "eng")
        #set default loglevel to KERN_INFO
        #Modify by david@bsp, 20161101 change console loglevel to 7
        echo "7 6 1 7" > /proc/sys/kernel/printk
        ;;
    *)
        #set default loglevel to KERN_WARNING
        echo "4 4 1 4" > /proc/sys/kernel/printk
        ;;
esac

target=`getprop ro.board.platform`
if [ -f /sys/devices/soc0/soc_id ]; then
    platformid=`cat /sys/devices/soc0/soc_id`
else
    platformid=`cat /sys/devices/system/soc/soc0/id`
fi

start_battery_monitor()
{
  if ls /sys/bus/spmi/devices/qpnp-bms-*/fcc_data ; then
    chown -h root.system /sys/module/pm8921_bms/parameters/*
    chown -h root.system /sys/module/qpnp_bms/parameters/*
    chown -h root.system /sys/bus/spmi/devices/qpnp-bms-*/fcc_data
    chown -h root.system /sys/bus/spmi/devices/qpnp-bms-*/fcc_temp
    chown -h root.system /sys/bus/spmi/devices/qpnp-bms-*/fcc_chgcyl
    chmod 0660 /sys/module/qpnp_bms/parameters/*
    chmod 0660 /sys/module/pm8921_bms/parameters/*
    mkdir -p /data/bms
    chown -h root.system /data/bms
    chmod 0770 /data/bms
    start battery_monitor
  fi
}

start_charger_monitor()
{
  if ls /sys/module/qpnp_charger/parameters/charger_monitor; then
    chown -h root.system /sys/module/qpnp_charger/parameters/*
    chown -h root.system /sys/class/power_supply/battery/input_current_max
    chown -h root.system /sys/class/power_supply/battery/input_current_trim
    chown -h root.system /sys/class/power_supply/battery/input_current_settled
    chown -h root.system /sys/class/power_supply/battery/voltage_min
    chmod 0664 /sys/class/power_supply/battery/input_current_max
    chmod 0664 /sys/class/power_supply/battery/input_current_trim
    chmod 0664 /sys/class/power_supply/battery/input_current_settled
    chmod 0664 /sys/class/power_supply/battery/voltage_min
    chmod 0664 /sys/module/qpnp_charger/parameters/charger_monitor
    start charger_monitor
  fi
}

start_vm_bms()
{
  if [ -e /dev/vm_bms ]; then
    chown -h root.system /sys/class/power_supply/bms/current_now
    chown -h root.system /sys/class/power_supply/bms/voltage_ocv
    chmod 0664 /sys/class/power_supply/bms/current_now
    chmod 0664 /sys/class/power_supply/bms/voltage_ocv
    start vm_bms
  fi
}

start_msm_irqbalance_8939()
{
  if [ -f /system/bin/msm_irqbalance ]; then
    case "$platformid" in
        "239" | "293" | "294" | "295" | "304" | "313")
      start msm_irqbalance;;
    esac
  fi
}

start_msm_irqbalance()
{
  if [ -f /system/bin/msm_irqbalance ]; then
    start msm_irqbalance
  fi
}

start_copying_prebuilt_qcril_db()
{
    if [ -f /system/vendor/qcril.db -a ! -f /data/misc/radio/qcril.db ]; then
        cp /system/vendor/qcril.db /data/misc/radio/qcril.db
        chown -h radio.radio /data/misc/radio/qcril.db
    fi
}

baseband=`getprop ro.baseband`
echo 1 > /proc/sys/net/ipv6/conf/default/accept_ra_defrtr

case "$baseband" in
        "svlte2a")
        start bridgemgrd
        ;;
esac

case "$target" in
    "msm8994" | "msm8992" | "msm8998")
        start_msm_irqbalance
        ;;
    "msm8953")
  start_msm_irqbalance_8939
        if [ -f /sys/devices/soc0/soc_id ]; then
            soc_id=`cat /sys/devices/soc0/soc_id`
        else
            soc_id=`cat /sys/devices/system/soc/soc0/id`
        fi

        if [ -f /sys/devices/soc0/hw_platform ]; then
             hw_platform=`cat /sys/devices/soc0/hw_platform`
        else
             hw_platform=`cat /sys/devices/system/soc/soc0/hw_platform`
        fi
        case "$soc_id" in
             "293" | "304" )
                  case "$hw_platform" in
                       "Surf")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                       "MTP")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                       "RCM")
                                    setprop qemu.hw.mainkeys 0
                                    ;;
                  esac
                  ;;
       esac
        ;;
    esac


#
# Copy qcril.db if needed for RIL
#
start_copying_prebuilt_qcril_db
echo 1 > /data/misc/radio/db_check_done

#
# Make modem config folder and copy firmware config to that folder for RIL
#
if [ -f /data/misc/radio/ver_info.txt ]; then
    prev_version_info=`cat /data/misc/radio/ver_info.txt`
else
    prev_version_info=""
fi

cur_version_info=`cat /firmware/verinfo/ver_info.txt`
if [ ! -f /firmware/verinfo/ver_info.txt -o "$prev_version_info" != "$cur_version_info" ]; then
    rm -rf /data/misc/radio/modem_config
    mkdir /data/misc/radio/modem_config
    chmod 770 /data/misc/radio/modem_config
    cp -r /firmware/image/modem_pr/mcfg/configs/* /data/misc/radio/modem_config
#ifdef VENDOR_EDIT
# add for mbn_ota.txt , hanqingpu, 20161207
    cp -r /system/etc/firmware/mbn_ota/mbn_ota.txt /data/misc/radio/modem_config/mbn_ota.txt
#endif /*VENDOR_EDIT*/
    chown -hR radio.radio /data/misc/radio/modem_config
    cp /firmware/verinfo/ver_info.txt /data/misc/radio/ver_info.txt
    chown radio.radio /data/misc/radio/ver_info.txt
fi
cp /firmware/image/modem_pr/mbn_ota.txt /data/misc/radio/modem_config
chown radio.radio /data/misc/radio/modem_config/mbn_ota.txt
echo 1 > /data/misc/radio/copy_complete

