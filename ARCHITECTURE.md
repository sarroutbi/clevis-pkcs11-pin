# Architecture of the Clevis PKCS#11 pin

## Introduction

This document describes the different steps, requirements and procedures for the Clevis PKCS#11 pin implementation. It must be clarified that this document will define two `pin vs PIN` concepts:

* <ins>pin</ins>: This is pin as part of Clevis. Clevis has different pins, such as Tang, TPM2 or SSS. It is the same concept as a "plugin", but they are named "pins" in this case.
* <ins>PIN</ins>: This is PIN as Personal Identification Number. This will be a code used for authentication purposes to access a device, in this case, a PKCS#11 device.

Clevis is part of the NBDE set of tools that allows remote encrypted disks automated unlocking. For more information about this technology, please, check [NBDE (Network-Bound Disk Encryption) Technology][1].

As part of a new feature, Clevis PKCS#11 pin will implement code for a user to perform automated encrypted disk unlocking through PKCS#11 hardware/software.

## Clevis PKCS#11 pin

Clevis will perform the role of a PKCS#11 application, as described in the [RFC 7512: The PKCS#11 URI Scheme][2]. Clevis software will be extended through a new pin, so that it can be configured according to the information detailed in that RFC.

PKCS#11 protocol determines that a PIN must be configured into the hardware device so that the unlocking process is successful. Clevis will allow users to unlock a particular encrypted disk, and will allow the user to not provide the PIN every time unlocking is needed. User will configure the PIN in the device, and will provide a way to notify that PIN to Clevis. There will be two possibilities:

1 - Provide the PIN at Clevis configuration time: In this first case, Clevis will be configured with the PIN value or the PIN location.

2 - Provide the PIN at boot time: In this other case, Clevis will detect PKCS#11 device and will prompt for its PIN.
In case PIN is wrong, Clevis will prompt for the PIN again. It is the user's responsibility to be aware of the possible lock / brick of the device in case PIN is unknown.

Initially, RFC7512 defines a mechanism to specify a special kind of URI (the `pkcs11` URI), that allows identifying both a device and also the information required for it to be unlocked. Special attention deserves the parameters `pin-value`, which allow specifying the value of the PIN or the location of the PIN respectively. Clevis will understand, initially, the 'pin-value' parameter. Below you can find and example of PKCS#11 URIs using previous parameter:

* PKCS#11 URI with `pin-value` defined:

```
pkcs11:token=Software%20PKCS%2311%20softtoken;manufacturer=Snake%20Oil,%20Inc.?pin-value=the-pin
```

In the next section, Clevis configuration examples are provided, so that it is clarified what are the different options for a PKCS#11 device to be bound to an encrypted disk.

## Clevis configuration

Clevis will provide a mechanism for the user to bind a particular PKCS#11 device to an encrypted device. This section will show different configuration examples. The name of the new pin for Clevis will be `pkcs11`, and the way to configure it will be the same that is currently used:

```
$ clevis luks bind -h
```

```
Usage: clevis luks bind [-y] [-f] [-s SLT] [-k KEY] [-t TOKEN_ID] [-e EXISTING_TOKEN_ID] -d DEV PIN CFG
```

### Configuration to provide a PKCS#11 URI to Clevis
As first example, a user can provide the information of the device by specifying its URI to Clevis:

```
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri": "pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;
serial=0a35ba26b062b9c5;token=clevis;id=%02;object=Encryption%20Key"}'
```

### Configuration to provide a slot to Clevis
Clevis will allow specifying the slot where a PKCS#11 device is located through the parameters provided to the URI:

```
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri": "pkcs11:?slot-id=0"}'
```

It must be clarified that providing just the slot information will make Clevis to prompt also to select one of the available keys matched on the token in the selected slot, to avoid accidentally encryption with unwanted keys.


### Configuration to bind Clevis to the first PKCS11 device found
An additional option is to provide Clevis a configuration so that the first PKCS11 device found by Clevis is bound. To do so, an empty URI can be provided as shown below:

```
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri":, "pkcs11:"}'
```

In this case, Clevis will be responsible for the detection of the device and, if no device is found, responsible for dumping the corresponding error.

It must be clarified that providing an empty URI will make Clevis to prompt also to select one of the available keys matched on the token to avoid accidentally encryption with unwanted keys.

### Configuration to provide a module path to Clevis:
A module path can be provided to Clevis, so that it uses that module to access a device. This is only required in case the card is not supported by underlying Clevis software (OpenSC). For this reason, the module path field is completely optional. To provide the module location the user can provide the "module-path" to the "uri" Clevis configuration:

```
$ clevis-luks-bind -d /dev/sda1 pkcs11 '{"uri": "pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;
serial=0a35ba26b062b9c5;token=clevis;id=%02;object=Encryption%20Key?
module-path=/usr/local/lib64/libmypkcs11.so"}'
```

As it happens with the rest of devices, encrypted disks that have been bound to a PKCS#11 device can be checked with `clevis luks list` command:

```
$ clevis luks list -d /dev/sda1
```

```
1: pkcs11 '{"uri": "pkcs11:model=PKCS%2315%20emulated;manufacturer=piv_II;
serial=0a35ba26b062b9c5;token=clevis;id=%02;object=Encryption%20Key?
module-path=/usr/local/lib64/libmypkcs11.so""}'
```

For security reasons, no PIN related information will be shown.

### Examples of errors on Clevis configuration

An example of an invalid device provided is shown below:

```
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri": "pkcs11:"}'
```

```
ERROR: No PKCS11 devices detected
```

## PIN Handling
Clevis will allow the user to provide a PIN through its configuration. Clevis parameter to use will be 'pin-value':

```
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri": "pkcs11:?pin-value=123456"}'
```

In case no information about the PIN is provided, Clevis will ask for the PIN unless the System Administrator
specifies, explicitly, that no PIN is required

PIN handling will be implemented in different phases:

### Phase 1: pin-value support

The first phase will contain support to specify the PIN through 'pin-value':

```
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri": "pkcs11:?pin-value=123456"}'
```

### Phase 2: pin-source support

The second phase will contain support to specify the PIN through 'pin-source'.
The unique 'URIs' that will be handled will be the `file:` ones:

```
$ clevis luks bind -d /dev/sda1 pkcs11 '{"uri": "pkcs11:?pin-source=file:/etc/pkcs11_token_pin"}'
```

By default, Clevis will require a PIN, either through its configuration or by prompting it.

## Phases
Implementation will consist of two phases, depending on the software that will be used by Clevis for PKCS#11 device handling to be provided.
It must be remarked that **Clevis is not responsible for the device configuration**. This task is the final user responsibility.

### Phase 1: PCSC-LITE and OpenSC
In this step, Clevis will be implemented on top of `pcsc-lite` and `OpenSC` packages. The first provides a mechanism to launch a daemon that allows PKCS#11 element, while the second provides different tools for access to the device. The reason to use this approach is to take profit of the already implemented [Clevis PKCS#11 pin Proof of Concept][4]
This first phase is basically a bunch of bash scripts around pkcs11-tool, which makes the boot initramfs larger.

### Phase 2: pkcs11-provider
Using pkcs11-provider will allow supporting customers who want to use a different PKCS#11 module than OpenSC. For that cases, OpenSC might not be needed/available, as having two PKCS#11 modules attempting to talk to a single card does not usually go well. If that is the case, using pkcs11-provider would include an additional dependency to Clevis, but it is not a large one. Indeed, it is dynamically loaded into openssl.

This will be a complementary mechanism. Clevis will be responsible for providing the configuration mechanisms to use the modules in phase 1 or the ones in phase 2, ideally through [RFC 7512: The PKCS #11 URI Scheme][2]. The advantage of using pkcs11-provider would be that it uses self-contained code that will be part of Clevis, making Clevis to have less dependencies, as well as to use a smaller initramfs size.

## Integration with systemd

Initially, including PKCS11 Clevis pin involves some basic requirements:

* The unlock process should use multiple factors (Logical AND).
* The unlock process should not involve a passphrase.
* One of the factors should be external to the computer.

However, it must be remarked that the main usage of Clevis, up to date, is based on letting systemd-cryptsetup to unlock disks as usual (in the same way as if Clevis is not configured), so that it asks for the passphrase.

When Clevis is configured, a specific Clevis unit (clevis-luks-askpass.path) checks for directory where systemd-cryptsetup is asking for information being prompted (/run/systemd/ask-password) and sends the unlocking passphrase through a socket created under that directory.

This is done because systemd-cryptsetup uses information in /etc/crypttab and, as no special keyfile information is found on that file, it ends up asking for the passphrase through the command line.

However, if the unlock process should not involve a passphrase, the current mechanism does not work. So ... is there an alternative?

The answer is yes, there is an alternative. An AF_UNIX socket file can be specified in /etc/crypttab, so that systemd-cryptsetup checks for it and, if it exists, it won't ask the password through console, as it is done normally.

So ... how should be the password provided provided to systemd-cryptsetup? Well, the process is described here:
[AF\_UNIX Key Files](https://www.freedesktop.org/software/systemd/man/latest/crypttab.html#AF_UNIX%20Key%20Files)

At high level, when an encrypted disk unlocking with no passphrase is required, next steps will be needed:

<ul>
    <li>1 - Configure the device to use PKCS11 configuration</li>
    <li>2 - Modify crypttab so that systemd-cryptsetup does not ask for a passphrase through the console</li>
    <li>3 - Implement a specific clevis-pkcs11 unit that:
        <ul>
           <li>3.1 - Is started before systemd-cryptsetup</li>
           <li>3.2 - Reads, from /etc/crypttab, which devices need "AF_UNIX socket" unlocking</li>
           <li>3.3 - Obtain the passphrases for each of the devices</li>
           <li>3.4 - Create an AF_UNIX socket and, when systemd-cryptsetup asks for unlocking, send the passphrase to unlock the disk. A small example file that performs this operation is [available here](https://github.com/sarroutbi/clevis-pkcs11-pin/blob/main/clevis-afunix-socket-unlock.c)</li>
        </ul>
    </li>
</ul>

To summarize: for clevis PKCS11 device unlocking without password prompt, /etc/crypttab will need to be configured with a specific socket file (name it clevis-pkcs11.sock). Clevis will provide a specific systemd unit file that parses which devices are configured to use it, so that it unlocks them with no passphrase mechanism involved, but asking for Clevis PKCS11 pin, if necessary, and performing unlock consequently.

## Requirements

Regarding the necessities for the pin to be implemented, some restrictions/requirements have been identified:
* Padding: In the light of recent development of side channel attacks as [The Marvin Attack][5], use of RSA-PKCS1.5 is no longer recommended as a padding mechanism for encryption. It is suggested to look into a way to plug in the RSA-OAEP padding scheme. It will likely involve some switch to the openssl CLI when encrypting data and a switch to pkcs11-tool  (-m RSA-OAEP probably).

* PCSC Lite: Ideally, PCSC Lite should be used with usage of the PolicyKit. However, this has not been accomplished neither in the [Clevis PKCS#11 pin Proof of Concept][3] nor in the early steps of the PKCS#11 pin feature implementation. For that reason, in case PKCS#11 pin implementation is required in a particular distribution, it must be ensured that the `--disable-polkit` option is available in the PCSC Lite package. This requirement is limited to the Phase 1 of the development.

<!--References-->
[1]: https://access.redhat.com/articles/6987053
[2]: https://www.rfc-editor.org/rfc/rfc7512.html
[3]: https://developers.yubico.com/PIV/Introduction/Certificate_slots.html
[4]: https://gitlab.cee.redhat.com/scorreia/clevis-pkcs11-poc
[5]: https://people.redhat.com/~hkario/marvin
