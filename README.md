# pimatic-samsung-tv-2016
Pimatic plugin for 2016 Samsung TVs

## Plugin Config

There is only one plugin option, and that is **app_name**, which will be
the name used to register the plugin with the TV.  The default is fine, but may
be changed to suit.

## Device

The plugin provides a single device: **SamsungTV_2016**

The device is an extension of the SwitchActuator, and can be used to turnOn and turnOff the TV, through both 
the mobile-front-end and rules.

While it may be possible to send additional keys beyond KEY_POWER, I have not tried others. I’m happy 
to help anyone having issues with this version of the plugin, however, I have not interest in expanding 
it’s capabilities.  I created this for the sole purpose of turning on and off my TV via **pimatic**.

To wit, I have a KS8000, and can confirm it works perfectly to do just that.  In fact, imho, I believe 
it actually performs better than both the SmartThings SamsungTV device and the Samsung Phone Connect feature.

### Device Config
You only need to provide a value for the option **ip_address** (While I understand the ip address may be
auto-discovered, this is was much easier.)

There is one other configurable option: **update_interval**.  This is the interval at which the TV will be
polled to find it state.  The default value is 15 seconds.  Unless there is an extraordinary need
for less frequent polling, the default value will suffice. 

The **mac_address** option can be safely (and is highly encouraged) to be ignored. 
The device itself will obtain it.   


### Attribution

Special thank you to <a href="https://github.com/kyleaa">kyleaa</a> for doing all the real
work with <a href="https://github.com/kyleaa/homebridge-samsungtv2016">homebridge-samsungtv2016</a>,
from which this plugin was shamelessly borne.
 
