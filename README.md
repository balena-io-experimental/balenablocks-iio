# balenablocks-iio

Provides an easy way to work with Industrial IO sensor data.
This block uses [libiio](https://github.com/analogdevicesinc/libiio) to interface with the compatible sensors.

## Features

- Convenience script to load built-in module
- Allows loading externally built kernel modules
- Exposes the sensor data as json on port `8110`

## Usage

This block contains the `run.sh` script which has the following options

```bash
usage: run.sh [options]

options:
  --i2c-modules-addr  Space separated list of modules to enable and the respective i2c address.
  --bus="1"   The I2C bus.
  --modprobe-modules  Built-in modules to load.
  --modules-path="/usr/src/app/output"  Root path containing modules to load.
  --additional-modules  Space separated list of externally built modules to load from modules_path(Set to /usr/src/app/output).

```

_Dockerfile.template : Using built-in module - the BME680 IIO driver is already built-in balenaOS_

```Dockerfile
FROM balenaplayground/balenablocks-iio:%%BALENA_ARCH%%

CMD ["bash","run.sh" ,"--i2c-modules-addr","BME680:0x76","--modprobe-modules","BME680"]

```

_Dockerfile.template : Using externally built module_

We can use the [In-Tree Kernel Module Builder](https://github.com/balena-io-playground/balenablocks-in-tree-module-builder) to build other IIO driver modules that aren't already in balenaOS.

e.g Build and load the mma7660 accelerometer driver

```Dockerfile
FROM balenaplayground/balenablocks-in-tree-module-builder:%%BALENA_ARCH%% AS base

ENV VERSION '2.53.12+rev1.dev'
ENV BALENA_MACHINE_NAME=%%BALENA_MACHINE_NAME%%

WORKDIR /usr/src/app

# the built modules are in the output folder by default
RUN itkm_builder build --os-version "$VERSION" --modules-list 'MMA7660' --src "drivers/iio/accel"


FROM balenaplayground/balenablocks-iio:%%BALENA_ARCH%%

# copy over the built modules
COPY --from=base /usr/src/app/output output


CMD ["bash","run.sh" ,"--i2c-modules-addr","MMA7660:0x4c","--additional-modules","MMA7660"]
```

### If using in a multicontainer app or with `docker-compose` file:

_docker-compose.yml_

```yaml
version: "2"

services:
  iio:
    build: ./
    privileged: true
    labels:
      io.balena.features.kernel-modules: "1"
      io.balena.features.sysfs: "1"
    ports:
      - 8110
```

## Sample output

The block has a server running on port 8110.

_E.g output with only one device connected - the mma7660 accelerometer_

```json
[
  {
    "name": "mma7660",
    "channels": [
      {
        "id": "accel_x",
        "attrs": [
          {
            "raw": "-10"
          },
          {
            "scale": "0.467142857"
          },
          {
            "scale_available": "0.467142857"
          }
        ]
      },
      {
        "id": "accel_y",
        "attrs": [
          {
            "raw": "-12"
          },
          {
            "scale": "0.467142857"
          },
          {
            "scale_available": "0.467142857"
          }
        ]
      },
      {
        "id": "accel_z",
        "attrs": [
          {
            "raw": "10"
          },
          {
            "scale": "0.467142857"
          },
          {
            "scale_available": "0.467142857"
          }
        ]
      }
    ]
  }
]
```
