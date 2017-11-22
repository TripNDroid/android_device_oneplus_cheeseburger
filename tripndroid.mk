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

# Cheeseburger device
$(call inherit-product, device/oneplus/cheeseburger/full_cheeseburger.mk)

# TripNDroid vendor config
$(call inherit-product, vendor/tripndroid/tripndroid_vendor.mk)

# TripNDroid vendor phone config
$(call inherit-product, vendor/tripndroid/tripndroid_phone.mk)

PRODUCT_NAME := tripndroid_cheeseburger
PRODUCT_DEVICE := cheeseburger

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_DEVICE="OnePlus5" \
    PRODUCT_NAME="OnePlus5" \
    BUILD_FINGERPRINT="OnePlus/OnePlus5/OnePlus5:7.1.1/NMF26X/07311003:user/release-keys" \
    PRIVATE_BUILD_DESC="OnePlus5-user 7.1.1 NMF26X 273 release-keys"

