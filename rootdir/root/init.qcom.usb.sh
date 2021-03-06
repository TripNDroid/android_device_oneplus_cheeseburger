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

chown -h root.system /sys/devices/platform/msm_hsusb/gadget/wakeup
chmod -h 220 /sys/devices/platform/msm_hsusb/gadget/wakeup

# Set platform variables
if [ -f /sys/devices/soc0/hw_platform ]; then
    soc_hwplatform=`cat /sys/devices/soc0/hw_platform` 2> /dev/null
else
    soc_hwplatform=`cat /sys/devices/system/soc/soc0/hw_platform` 2> /dev/null
fi

if [ -f /sys/devices/soc0/machine ]; then
    soc_machine=`cat /sys/devices/soc0/machine` 2> /dev/null
else
    soc_machine=`cat /sys/devices/system/soc/soc0/machine` 2> /dev/null
fi

# Get hardware revision
if [ -f /sys/devices/soc0/revision ]; then
    soc_revision=`cat /sys/devices/soc0/revision` 2> /dev/null
else
    soc_revision=`cat /sys/devices/system/soc/soc0/revision` 2> /dev/null
fi

#
# Check ESOC for external MDM
#
# Note: currently only a single MDM is supported
#
if [ -d /sys/bus/esoc/devices ]; then
for f in /sys/bus/esoc/devices/*; do
    if [ -d $f ]; then
        if [ `grep "^MDM" $f/esoc_name` ]; then
            esoc_link=`cat $f/esoc_link`
            break
        fi
    fi
done
fi

target=`getprop ro.board.platform`

# soc_ids for 8937
if [ -f /sys/devices/soc0/soc_id ]; then
  soc_id=`cat /sys/devices/soc0/soc_id`
else
  soc_id=`cat /sys/devices/system/soc/soc0/id`
fi

#ifdef VENDOR_EDIT
boot_mode=`getprop ro.boot.ftm_mode`
echo "boot_mode: $boot_mode" > /dev/kmsg
case "$boot_mode" in
    "ftm_at" | "ftm_rf" | "ftm_wlan" | "ftm_mos")
    setprop sys.usb.config diag,adb
    echo "AFTER boot_mode: diag,adb" > /dev/kmsg
esac
#endif

#
# Allow USB enumeration with default PID/VID
#
baseband=`getprop ro.baseband`

echo 1  > /sys/class/android_usb/f_mass_storage/lun/nofua
usb_config=`getprop persist.sys.usb.config`
case "$usb_config" in
    "" | "adb") #USB persist config not set, select default configuration
      case "$esoc_link" in
          "PCIe")
              setprop persist.sys.usb.config diag,diag_mdm,serial_cdev,rmnet_qti_ether,mass_storage,adb
          ;;
          *)
    case "$baseband" in
        "apq")
            setprop persist.sys.usb.config diag,adb
        ;;
        *)
        case "$soc_hwplatform" in
            "Dragon" | "SBC")
                setprop persist.sys.usb.config diag,adb
            ;;
                  *)
      soc_machine=${soc_machine:0:3}
      case "$soc_machine" in
        "SDA")
                setprop persist.sys.usb.config diag,adb
        ;;
        *)
              case "$target" in
                      "msm8916")
              setprop persist.sys.usb.config diag,serial_smd,rmnet_bam,adb
          ;;
                "msm8937")
          case "$soc_id" in
            "313" | "320")
               setprop persist.sys.usb.config diag,serial_smd,rmnet_ipa,adb
            ;;
            *)
               setprop persist.sys.usb.config diag,serial_smd,rmnet_qti_bam,adb
            ;;
          esac
          ;;
                "msm8998" | "sdm660")
             # setprop persist.sys.usb.config diag,serial_cdev,rmnet,adb
          ;;
                *)
              setprop persist.sys.usb.config diag,adb
          ;;
                    esac
        ;;
      esac
            ;;
        esac
        ;;
    esac
    ;;
      esac
      ;;
  * ) ;; #USB persist config exists, do nothing
esac

# set USB controller's device node
case "$target" in
    "msm8998")
        setprop sys.usb.controller "a800000.dwc3"
        setprop sys.usb.rndis.func.name "gsi"
  setprop sys.usb.rmnet.func.name "gsi"
  ;;
    *)
  ;;
esac

# check configfs is mounted or not
if [ -d /config/usb_gadget ]; then
  # Chip-serial is used for unique MSM identification in Product string
  msm_serial=`cat /sys/devices/soc0/serial_number`;
  msm_serial_hex=`printf %08X $msm_serial`
  machine_type=`cat /sys/devices/soc0/machine`
#ifdef VENDOR_EDIT
#david.liu@bsp, 20170505 Fix product name for Android Auto
  product_string=`getprop ro.product.brand`
#else
# product_string="$machine_type-$soc_hwplatform _SN:$msm_serial_hex"
#endif
  echo "$product_string" > /config/usb_gadget/g1/strings/0x409/product

  # ADB requires valid iSerialNumber; if ro.serialno is missing, use dummy
  serialno=`getprop ro.serialno`
  if [ "$serialno" == "" ]; then
      serialno=1234567
  fi
  echo $serialno > /config/usb_gadget/g1/strings/0x409/serialnumber

  setprop sys.usb.configfs 1
fi

#
# set module params for embedded rmnet devices
#
rmnetmux=`getprop persist.rmnet.mux`
case "$baseband" in
    "mdm" | "dsda" | "sglte2")
        case "$rmnetmux" in
            "enabled")
                    echo 1 > /sys/module/rmnet_usb/parameters/mux_enabled
                    echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                    echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
            ;;
        esac
        echo 1 > /sys/module/rmnet_usb/parameters/rmnet_data_init
        # Allow QMUX daemon to assign port open wait time
        chown -h radio.radio /sys/devices/virtual/hsicctl/hsicctl0/modem_wait
    ;;
    "dsda2")
          echo 2 > /sys/module/rmnet_usb/parameters/no_rmnet_devs
          echo hsicctl,hsusbctl > /sys/module/rmnet_usb/parameters/rmnet_dev_names
          case "$rmnetmux" in
               "enabled") #mux is neabled on both mdms
                      echo 3 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > write /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
               "enabled_hsic") #mux is enabled on hsic mdm
                      echo 1 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
               "enabled_hsusb") #mux is enabled on hsusb mdm
                      echo 2 > /sys/module/rmnet_usb/parameters/mux_enabled
                      echo 8 > /sys/module/rmnet_usb/parameters/no_fwd_rmnet_links
                      echo 17 > /sys/module/rmnet_usb/parameters/no_rmnet_insts_per_dev
               ;;
          esac
          echo 1 > /sys/module/rmnet_usb/parameters/rmnet_data_init
          # Allow QMUX daemon to assign port open wait time
          chown -h radio.radio /sys/devices/virtual/hsicctl/hsicctl0/modem_wait
    ;;
esac

#
# Initialize RNDIS Diag option. If unset, set it to 'none'.
#
diag_extra=`getprop persist.sys.usb.config.extra`
if [ "$diag_extra" == "" ]; then
  setprop persist.sys.usb.config.extra none
fi

# soc_ids for 8937
if [ -f /sys/devices/soc0/soc_id ]; then
  soc_id=`cat /sys/devices/soc0/soc_id`
else
  soc_id=`cat /sys/devices/system/soc/soc0/id`
fi

# enable rps cpus on msm8937 target
setprop sys.usb.rps_mask 0
case "$soc_id" in
  "294" | "295")
    setprop sys.usb.rps_mask 40
  ;;
esac
