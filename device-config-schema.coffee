module.exports =
  title: "Pimatic Flic Device Config Schemas"
  SamsungTV_2016:
    title: "Flic Button"
    type: "object"
    properties:
      ip_address:
        description:  "ip address for the samsung tv"
        type: "string"
        default: 'none'
        required: yes
      mac_address:
        description: "The mac address of the samsung tv. This can be auto-populated"
        type: "string"
      ping_interval:
        description: "Ping interval in seconds to check if TV is on"
        type: "number"
        default: 10
