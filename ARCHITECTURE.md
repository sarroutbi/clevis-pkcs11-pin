# Architecture of the Clevis PKCS#11 pin

## Introduction

This document describes the different steps, requirements and procedures for the Clevis PKCS#11 pin implementation. It must be clarified that this document will define two `pin vs PIN` concepts:

* pin: This is pin as part of Clevis. Clevis has different pins, such as Tang, TPM2 or SSS. It is the same concept as a "plugin", but, they are named "pins" in this case.
* PIN: This is PIN as Personal Identification Number. This will be a numeric code used for authentication purposes to access a device, in this case, a PKCS#11 device.

Clevis is part of the NBDE set of tools that allows remote encrypted disks automated unlocking. For more information about this technology, please, check [NBDE (Network-Bound Disk Encryption) Technology][1].

As part of a new feature, Clevis PKCS#11 pin will implement code for a user to perform automated encrypted disk unlocking through PKCS#11 hardware/software.

## Clevis PKCS#11 pin

Clevis will perform the role of a PKCS#11 application, as described in the [RFC 7512: The PKCS #11 URI Scheme][2]. Clevis software will be extended through a new pin, so that it can be configured according to the information detailed in that RFC.

PKCS#11 protocol determines that a PIN must be configured into the hardware device so that unlocking process is successful. Clevis will allow users to unlock a particular encrypted disk, so that the user does not have to provide the PIN everytime unlocking is needed. User will configure the PIN in the device, and will provide a mean to notify that PIN to Clevis.

Initially, RFC7512 defines a mechanism to specify a special kind of URI (the `pkcs11` URI), that allows identifying both a device and also the information required for it to be unlocked. Special attention deserves the parameters `pin-value` and `pin-source`, which allow specifying the value of the PIN or the location of the PIN respectively. `pin-source` usage is preferred to `pin-value`, due to security constraints. However, Clevis will understand both parameters. Below you can find two examples of PKCS#11 URIs using previous described parameters:

* PKCS#11 URI with `pin-value` defined:

```
pkcs11:token=Software%20PKCS%2311%20softtoken;manufacturer=Snake%20Oil,%20Inc.?pin-value=the-pin
```

* PKCS#11 URI with `pin-source` defined:

```
pkcs11:token=Software%20PKCS%2311%20softtoken;manufacturer=Snake%20Oil,%20Inc.?pin-source=file:/etc/pkcs11_token_pin
```
According to [RFC 7512: The PKCS #11 URI Scheme][2]:

```
 If a URI contains both "pin-source" and "pin-value" query attributes, the URI SHOULD be refused as invalid.
```

For that reason, Clevis will detect if "pin-source" and "pin-value" parameters are provided together and, if so, it will reject binding the device to a particular encrypted disk for automated unlocking.

In the next section, Clevis configuration examples are provided, so that it is clarified what are the different options for a PKCS#11 device to be bound to an encrypted disk.

## Clevis configuration

Clevis will provide a mechanism for the user to bind a particular PKCS#11 device to an encrypted device. This section will show different configuration examples. The name of the new pin for Clevis will be `pkcs11`, and the way to configure it will be the same that is currently used:

```bash
$ clevis luks bind -h
Usage: clevis luks bind [-y] [-f] [-s SLT] [-k KEY] [-t TOKEN_ID] [-e EXISTING_TOKEN_ID] -d DEV PIN CFG
```

### Configuration to provide a PKCS#11 URI to clevis
As first example, a user can provide the information of the device by specifying its URI to clevis:

```bash
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri":"pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;serial=0a35ba26b062b9c5;token=clevis?pin-source=file:/etc/clevis_pkcs11_pin"}'
```

### Configuration to provide a slot to Clevis
As it can be seen, a PKCS#11 URI can be somehow difficult to provide. For this reason, Clevis will allow specifing a slot where the device is located:

```bash
$ clevis luks bind -d /dev/sda1 pkcs11 '{"slot":0, "pin_source":"file:/etc/clevis_pkcs11_pin"}'
```
In the previous case, Clevis will be responsible for the detection of the device and, if the device is not found, it will dump an error. Alternatively, `pin_source` can be specified:

```bash
$ clevis luks bind -d /dev/sda1 pkcs11 '{"slot":0, "pin_source":"file:/etc/clevis_pkcs11_pin"}'
```

Similarly, Clevis will be responsible for the detection of the device and, if the device is not found, it will dump an error.

As it happens with the rest of the devices, encrypted disks that have been bound to a PKCS#11 device can be checked with `clevis luks list` command:

```bash
$ sudo clevis luks list -d /dev/nvme0n1p2
1: pkcs11 '{"slot":0, "pin_source":"file:/etc/clevis_pkcs11_pin", "uri": "pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;serial=0a35ba26b062b9c5;token=clevis"}'
2: tpm2 '{"hash":"sha256","key":"ecc"}'
```

### Examples of invalid configuration
Some examples of wrong configurations are provided below:

```bash
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri":"pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;serial=0a35ba26b062b9c5;token=clevis?pin-value=223344;pin-source=file:/etc/clevis_pkcs11_pin"}'
ERROR: Cannot provide a URI with both pin-value and pin-source parameters
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri":"pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;serial=0a35ba26b062b9c5;token=clevis"}'
ERROR: Cannot provide a URI without one of the pin-value or pin-source parameters
$ clevis luks bind -d /dev/sda1 pkcs11 '{"slot":0}'
ERROR: Cannot provide a URI without one of the pin-value or pin-source parameters
```

An example of and invalid device provided:

```bash
$ clevis luks bind -d /dev/sda1 pkcs11 '{"slot":1, "pin_value":"123456"}'
ERROR: No PKCS11 device detected at slot 1
```

## Phases
Implementation will consist of two phases, depending on the software that will be used by Clevis for PKCS#11 device handling to be provided.
It must be remarked that **Clevis is not responsible of the device configuration**. This task is the final user responsibility.

### Phase 1: PCSC-LITE and OpenSC
In this step, Clevis will be implemented in top of `pcsc-lite` and `OpenSC` packages. The first provides a mechanism to launch a daemon that allows PKCS#11 element, while the second provides different tools for access to the device. The reason to use this approach is to take profit of the already implemented [Clevis PKCS#11 pin Proof of Concept][3]

### Phase 2: pkcs11-provider
Using pkcs11-provider will allow supporting customers who want to use different pkcs11 module than OpenSC. For that cases, OpenSC might not be needed/available, as having two PKCS#11 modules attempting to talk to a single card does not usually go well. If that is the case, using pkcs11-provider would add an additional dependency to clevis, but it is not a large dependency. Indeed, it is dynamically loaded into openssl. This will be a complementary mechanism. Clevis will be responsible of providing the configuration mechanisms to use the modules in phase 1 or the ones in phase 2, ideally through [RFC 7512: The PKCS #11 URI Scheme][2].

## Requirements

Regarding the necessities for the pin to be implemented, some restrictions/requirements have been identified:
* Padding: In the light of recent development of side channel attacks [The Marvin Attack][4], use of RSA-PKCS1.5 is no longer recommend as padding mechanism for encryption. It is suggested to look into a way to plug in the RSA-OAEP padding scheme. It will likely involve some switch to the openssl CLI when encrypting data and a switch to pkcs11-tool  (-m RSA-OAEP probably).
* PCSC Lite: Ideally, PCSC Lite should be used with usage of the PolicyKit. However, this has not been accomplished neither in the [Clevis PKCS#11 pin Proof of Concept][3] nor in the early steps of the pin feature implementation. For that reason, in case PKCS#11 implementation is required in a particular distribution, it must be ensured that `--disable-polkit` option is available in PCSC Lite package. This requirement is limited to the Phase 1 of the development.

<!--References-->
[1]: https://access.redhat.com/articles/6987053
[2]: https://www.rfc-editor.org/rfc/rfc7512.html
[3]: https://gitlab.cee.redhat.com/scorreia/clevis-pkcs11-poc
[4]: https://people.redhat.com/~hkario/marvin/
